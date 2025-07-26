import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:kkpchatapp/core/services/chat_storage_service.dart';
import 'package:kkpchatapp/core/services/handle_notification_clicks.dart';
import 'package:kkpchatapp/core/services/notification_service.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/main.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'dart:async';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService(GlobalKey<NavigatorState> navigatorKey) {
    return _instance;
  }

  final NotificationService notiService = NotificationService();

  late io.Socket _socket;
  bool _isConnected = false;
  final String serverUrl = dotenv.env["SOCKET_IO_URL"]!;
  //ChatStorageService chatStorageService = ChatStorageService();
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;
  final Duration _reconnectInterval = const Duration(seconds: 3);
  Function(Map<String, dynamic>)? _onMessageReceived;
  Function(String)? _onMessageDeleted;
  Function(Map<String, dynamic>)? _onIncomingCall;
  // Function(Map<String, dynamic>)? _onCallAnswered;
  Function(Map<String, dynamic>)? _onCallTerminated;
  Function? _onDisconnect;
  Function? _onConnect;
  Function(Map<String, dynamic>)? _onChatStatus;
  Function(Map<String, dynamic>)? _onMessagesReadUpTo;

  bool isChatPageOpen = false;
  String? activeCustomerId;

  Function? onMessageReceivedCallback;

  List<String> _roomMembers = [];
  StreamController<List<String>> _statusController =
      StreamController<List<String>>.broadcast();

  Stream<List<String>> get statusStream => _statusController.stream;

  List<String> get onlineUsers => List.from(_roomMembers);

  FlutterLocalNotificationsPlugin? _notificationsPlugin;

  SocketService._internal();

  void onMessageReceived(Function(Map<String, dynamic>) callback,
      {Function? refreshCallback}) {
    _onMessageReceived = callback;
    onMessageReceivedCallback = refreshCallback;
  }

  void initSocket(String userName, String userEmail, String role,
      {String? token}) {
    _statusController.close();
    _statusController = StreamController<List<String>>.broadcast();
    _socket = io.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'reconnection': false,
    });

    _socket.onConnect((_) {
      _isConnected = true;
      _reconnectAttempts = 0;
      debugPrint('✅ Connected to socket server');
      _socket.emit('join', {
        'user': userName,
        'userId': userEmail,
        "role": role,
        "token": token,
      });
      if (_onConnect != null) {
        _onConnect!(); // Trigger the connect callback
      }
    });

    _socket.on('socketId', (socketId) {
      debugPrint('📌 Assigned Socket ID: $socketId');
    });

    _socket.on('roomMembers', (roomMembers) {
      debugPrint('👥 Current Room Members: $roomMembers');
      _updateRoomMembers(List<String>.from(roomMembers));
    });

    // _socket.on('receiveMessage', (data) {
    //   debugPrint(data.toString());
    //   if (isChatPageOpen && _onMessageReceived != null) {
    //     _onMessageReceived!(data);
    //   } else if (!isChatPageOpen && _onMessageReceived != null) {
    //     _chatNotification(data);
    //   } else {
    //     return;
    //   }
    // });
    _socket.on('receiveMessage', (data) {
      debugPrint("recived message socket : ${data.toString()}");
      final String senderId = data['senderId'] ?? '';
      final String targetId = data['targetId'] ?? '';

      if (isChatPageOpen &&
          (activeCustomerId == senderId || activeCustomerId == targetId)) {
        _onMessageReceived?.call(data);
      } else {
        debugPrint("recived message socket : ${data.toString()}");
        _chatNotification(data);
      }
    });

    _socket.on('incomingCall', (data) {
      debugPrint('📥 Agora incomingCall: $data');
      if (_onIncomingCall != null) {
        // CallOverlayService().startRinging();
        _onIncomingCall!(data);
      }
    });

    // _socket.on('callAnswered', (data) {
    //   debugPrint('📥 callAnswered: $data');
    //   _onCallAnswered?.call(data);
    // });

    // inside SocketService.initSocket after _socket.on('callTerminated' …)
    _socket.on('callTerminated', (data) {
      debugPrint('📥 callTerminated from server: $data');

      _onCallTerminated?.call(data);
    });

    _socket.on('messageDeleted', (data) {
      debugPrint("socket message deleted: ${data.toString()}");
      final messageId = data['messageId'];

      if (isChatPageOpen) {
        // If the chat page is open, call the existing callback
        _onMessageDeleted?.call(messageId);
      } else {
        // If the chat page is not open, handle the deletion in the background
        _handleBackgroundMessageDeletion(data);
      }
    });

    _socket.on('chatStatus', (data) {
      debugPrint("📥 chatStatus: ${data.toString()}");
      if (isChatPageOpen) {
        _onChatStatus?.call(data);
      } else {
        debugPrint("📥 Handling chatStatus in background.");
        _handleBackgroundChatStatus(data);
      }
    });

    _socket.on('messagesReadUpTo', (data) {
      debugPrint("📥 messagesReadUpTo: ${data.toString()}");
      if (isChatPageOpen) {
        _onMessagesReadUpTo?.call(data);
      } else {
        debugPrint("📥 Background messagesReadUpTo: $data");
        _handleBackgroundMessagesReadUpTo(data);
      }
    });

    _socket.onDisconnect((_) {
      _isConnected = false;
      for (String email in _roomMembers) {
        LocalDbHelper.updateLastSeenTime(email);
        debugPrint(
            "⏳ Saved last seen for $email: ${DateTime.now().toIso8601String()}");
      }
      debugPrint('⚠️ Disconnected from socket server');
      _attemptReconnect(userName, userEmail, role);
    });

    _socket.onError((error) {
      debugPrint('❌ Socket Error: $error');
      _attemptReconnect(userName, userEmail, role);
    });

    _socket.connect();
  }

  void onDisconnect(Function callback) {
    _onDisconnect = callback;
  }

  void onConnect(Function callback) {
    _onConnect = callback;
  }

  void onChatStatus(Function(Map<String, dynamic>) callback) {
    debugPrint("🔧 Chat status callback set");
    _onChatStatus = callback;
  }

  void onMessagesReadUpTo(Function(Map<String, dynamic>) callback) {
    debugPrint("🔧 Messages read up to callback set");
    _onMessagesReadUpTo = callback;
  }

  void sendChatOpened({
    String? agentEmail,
    required String customerEmail,
    required String role,
    required String lastMessageTimestamp,
  }) {
    if (!_isConnected) {
      debugPrint("⚠️ Cannot send chatOpened — socket not connected.");
      return;
    }
    final payload = {
      'customerEmail': customerEmail,
      'role': role,
      'lastMessageTimestamp': lastMessageTimestamp,
    };
    if (agentEmail != null && role == 'agent') {
      payload['agentEmail'] = agentEmail;
    }

    _socket.emit('chatOpened', payload);
    debugPrint("📤 Sending chatOpened event with payload: $payload");
  }

  void sendMarkAsReadUpTo({
    String? agentEmail,
    required String customerEmail,
    required String role,
    required String lastMessageTimestamp,
  }) {
    if (!_isConnected) {
      debugPrint("⚠️ Cannot send markAsReadUpTo — socket not connected.");
      return;
    }
    final payload = {
      'customerEmail': customerEmail,
      'role': role,
      'lastMessageTimestamp': lastMessageTimestamp,
    };
    if (agentEmail != null && role == 'agent') {
      payload['agentEmail'] = agentEmail;
    }
    debugPrint("📤 Sending markAsReadUpTo event with payload: $payload");
    _socket.emit('markAsReadUpTo', payload);
  }

  void sendChatClosed({
    String? agentEmail,
    required String customerEmail,
    required String role,
  }) {
    if (!_isConnected) {
      debugPrint("⚠️ Cannot send chatClosed — socket not connected.");
      return;
    }
    final payload = {
      'customerEmail': customerEmail,
      'role': role,
    };
    if (agentEmail != null && role == 'agent') {
      payload['agentEmail'] = agentEmail;
    }

    _socket.emit('chatClosed', payload);
    debugPrint("📤 Sending chatClosed event with payload: $payload");
  }

  void _handleBackgroundChatStatus(Map<String, dynamic> data) async {
    debugPrint("📥 Background Chat Status : ${data.toString()}");
    final status = data['status'];
    final customerEmail = data['customerEmail'];
    final lastMessageTimestampStr = data['lastMessageTimestamp'];
    debugPrint("Background Chat Status Updated: $status");

    if (status == 'opened' &&
        lastMessageTimestampStr != null &&
        customerEmail != null) {
      final lastMessageTimestamp = DateTime.tryParse(lastMessageTimestampStr);
      if (lastMessageTimestamp != null) {
        // Set the receiver as on the chat page using LocalDbHelper
        LocalDbHelper.saveReceiverOnChatPageStatus(true);

        final userType = await LocalDbHelper.getUserType();
        if (userType == "0") {
          // Customer
          final messages =
              await ChatStorageService().getCustomerMessages(customerEmail);
          for (var message in messages) {
            if (message.timestamp.isBefore(lastMessageTimestamp) ||
                message.timestamp == lastMessageTimestamp) {
              message.read = true;
              await ChatStorageService().saveMessage(message, customerEmail);
            }
          }
          debugPrint(
              "✅ Updated customer messages as read up to $lastMessageTimestampStr");
        } else {
          // Agent
          // Required from backend
          final agentEmail = data['agentEmail'];
          final boxName = '$agentEmail$customerEmail';
          final messages = await ChatStorageService().getMessages(boxName);
          for (var message in messages) {
            if (message.timestamp.isBefore(lastMessageTimestamp) ||
                message.timestamp == lastMessageTimestamp) {
              message.read = true;
              await ChatStorageService().saveMessage(message, boxName);
            }
          }
          debugPrint(
              "✅ Updated agent messages as read up to $lastMessageTimestampStr in box: $boxName");
        }
      }
    } else if (status == 'closed') {
      // Set the receiver as not on the chat page using LocalDbHelper
      LocalDbHelper.saveReceiverOnChatPageStatus(false);
    }
  }

  void _handleBackgroundMessagesReadUpTo(Map<String, dynamic> data) async {
    final customerEmail = data['customerEmail'];
    final lastMessageTimestampStr = data['lastMessageTimestamp'];
    if (customerEmail == null || lastMessageTimestampStr == null) return;

    final userType = await LocalDbHelper.getUserType();
    final lastMessageTimestamp = DateTime.tryParse(lastMessageTimestampStr);
    if (lastMessageTimestamp == null) return;

    if (userType == "0") {
      // Customer
      final messages =
          await ChatStorageService().getCustomerMessages(customerEmail);
      for (var message in messages) {
        if (message.timestamp.isBefore(lastMessageTimestamp)) {
          message.read = true;
          await ChatStorageService().saveMessage(message, customerEmail);
        }
      }
      debugPrint(
          "✅ Updated customer messages as read up to $lastMessageTimestampStr");
    } else {
      // Agent
      final agentEmail = data['agentEmail']; // Required from backend

      final boxName = '$agentEmail$customerEmail';
      final messages = await ChatStorageService().getMessages(boxName);
      for (var message in messages) {
        if (message.timestamp.isBefore(lastMessageTimestamp)) {
          message.read = true;
          await ChatStorageService().saveMessage(message, boxName);
        }
      }
      debugPrint(
          "✅ Updated agent messages as read up to $lastMessageTimestampStr in box: $boxName");
    }

    if (onMessageReceivedCallback != null) {
      onMessageReceivedCallback!(); // Refresh UI if needed
    }
  }

  void _handleBackgroundMessageDeletion(Map<String, dynamic> data) async {
    final messageId = data['messageId'];
    final senderId = data['senderId'];
    final targetId = data['targetId'];

    final userType = await LocalDbHelper.getUserType();

    if (userType == "0") {
      // For customers, retrieve messages using getCustomerMessages
      final messages = await ChatStorageService().getCustomerMessages(targetId);
      debugPrint("Retrieved messages for customer: ${messages.length}");

      final index =
          messages.indexWhere((message) => message.messageId == messageId);
      if (index != -1) {
        messages[index].isDeleted = true;
        messages[index].message = "This message is deleted";

        // Save the updated message state to local storage
        await ChatStorageService().saveMessage(messages[index], targetId);
        debugPrint(
            "Message marked as deleted for customer with ID: $messageId");

        // Verify the message is updated in the storage
        final updatedMessages =
            await ChatStorageService().getCustomerMessages(targetId);
        final updatedIndex = updatedMessages
            .indexWhere((message) => message.messageId == messageId);
        if (updatedIndex != -1 && updatedMessages[updatedIndex].isDeleted) {
          debugPrint("Successfully updated message in storage for customer.");
        } else {
          debugPrint("Failed to update message in storage for customer.");
        }
      } else {
        debugPrint("Message not found for deletion with ID: $messageId");
      }
    } else {
      // For agents, the box name is a combination of targetId and senderId
      String boxName = '$targetId$senderId';

      // Retrieve and update the message in local storage
      final messages = await ChatStorageService().getMessages(boxName);
      final index =
          messages.indexWhere((message) => message.messageId == messageId);
      if (index != -1) {
        messages[index].isDeleted = true;
        messages[index].message = "This message is deleted";

        // Save the updated message state to local storage
        await ChatStorageService().saveMessage(messages[index], boxName);

        // Update the last message status
        updateLastMessage(senderId, "message deleted");
      }
    }
  }

  void _updateRoomMembers(List<String> newRoomMembers) {
    if (_statusController.isClosed) return;
    Set<String> previousUsers = Set.from(_roomMembers);
    Set<String> currentUsers = Set.from(newRoomMembers);

    for (String email in previousUsers.difference(currentUsers)) {
      LocalDbHelper.updateLastSeenTime(email);
      debugPrint(
          "⏳ Updated last seen for $email: ${DateTime.now().toIso8601String()}");
    }

    _roomMembers = newRoomMembers;
    _statusController.add(List.from(_roomMembers));
  }

  void getRoomMembers() {
    _socket.emit('roomMembers');
  }

  bool isUserOnline(String email) {
    return _roomMembers.contains(email);
  }

  void updateLastSeenTime(String email) {
    LocalDbHelper.updateLastSeenTime(email);
  }

  String getLastSeenTime(String email) {
    if (_roomMembers.contains(email)) return "Online";

    DateTime? lastSeen = LocalDbHelper.getLastSeenTime(email);
    if (lastSeen == null) return "Not Available";

    Duration diff = DateTime.now().difference(lastSeen);
    if (diff.inSeconds < 30) return "Just now";
    if (diff.inMinutes < 1) return "Few seconds ago";
    if (diff.inMinutes == 1) return "1 min ago";
    if (diff.inHours < 1) return "${diff.inMinutes} min ago";
    if (diff.inHours == 1) return "1 hour ago";
    if (diff.inDays < 1) return "${diff.inHours}h ago";
    if (diff.inDays == 1) return "Yesterday";
    return "${diff.inDays}d ago";
  }

  void onReceiveMessage(Function(Map<String, dynamic>) callback) {
    _onMessageReceived = callback;
  }

  void onMessageDeleted(Function(String) callback) {
    _onMessageDeleted = callback;
  }

  void onIncomingCall(Function(Map<String, dynamic>) callback) {
    _onIncomingCall = callback;
  }

  // void onCallAnswered(Function(Map<String, dynamic>) callback) {
  //   _onCallAnswered = callback;
  // }

  void onCallTerminated(Function(Map<String, dynamic>) callback) {
    _onCallTerminated = callback;
  }

  void _attemptReconnect(String userName, String userEmail, String role) {
    if (!_isConnected && _reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      debugPrint(
          '🔄 Reconnecting... Attempt $_reconnectAttempts/$_maxReconnectAttempts');

      Future.delayed(_reconnectInterval, () {
        if (!_isConnected) {
          _socket.connect();
          _socket.emit(
              'join', {'user': userName, 'userId': userEmail, "role": role});
        }
      });
    } else {
      debugPrint('🚫 Max reconnection attempts reached or user logged out.');
      if (_onDisconnect != null) {
        _onDisconnect!(); // Trigger the disconnect callback only when max attempts are reached
      }
      // Reset reconnection attempts and reinitialize the socket
      _reconnectAttempts = 0;
      Future.delayed(_reconnectInterval, () {
        debugPrint('🔄 Reinitializing socket connection...');
        _socket.connect();
        _socket.emit(
            'join', {'user': userName, 'userId': userEmail, "role": role});
      });
    }
  }

  void updateLastMessage(String email, String message) {
    LocalDbHelper.updateLastMessage(email, message);
  }

  String getLastMessage(String email) {
    String? lastMessage = LocalDbHelper.getLastMessage(email);
    if (lastMessage == null) return "last message";
    return lastMessage;
  }

  void sendMessage({
    String? targetEmail,
    String? message,
    required String senderEmail,
    required String senderName,
    String type = 'text',
    Map<String, dynamic>? form,
    String? mediaUrl,
    String? timestamp,
    String? messageId,
    bool read = false,
  }) {
    if (_isConnected) {
      Map<String, dynamic> messageData = {
        'senderId': senderEmail,
        'senderName': senderName,
        'type': type,
        'read': read,
      };

      if (targetEmail != null) messageData['targetId'] = targetEmail;
      if (message != null) messageData['message'] = message;
      if (form != null) messageData['form'] = form;
      if (mediaUrl != null) messageData['mediaUrl'] = mediaUrl;
      if (timestamp != null) messageData['timestamp'] = timestamp;
      if (messageId != null) messageData["messageId"] = messageId;

      _socket.emit('sendMessage', messageData);
      // debugPrint("message sent :${messageData.toString()}");

      // Save the last message for the user last chatted
      if (type == "product") {
        updateLastMessage(targetEmail ?? "", "shared product");
      } else if (message != null &&
          message.contains("Your order is confirmed with form Id")) {
        // Handle order confirmation
        updateLastMessage(targetEmail ?? "", "Order Confirmed");
      } else if (message != null &&
          message.contains("Your order is declined with form Id")) {
        // Handle order decline
        updateLastMessage(targetEmail ?? "", "Order Declined");
      } else {
        updateLastMessage(targetEmail ?? "", messageData['message']);
      }
    } else {
      debugPrint('Socket is not connected. Cannot send message.');
    }
  }

  void deleteMessage(String messageId, String senderId, [String? targetId]) {
    if (_isConnected) {
      // Create a map with the required parameters
      Map<String, dynamic> messageData = {
        'messageId': messageId,
        'senderId': senderId,
      };

      // Add targetId to the map if it is provided
      if (targetId != null) {
        messageData['targetId'] = targetId;
      }

      // Emit the deleteMessage event with the constructed map
      _socket.emit('deleteMessage', messageData);
      debugPrint("🗑️ Delete message event emitted: $messageId");
    } else {
      debugPrint('Socket is not connected. Cannot delete message.');
    }
  }

  void sendAgoraCall({
    String? targetId,
    required String channelName,
    required String callerId,
    required String callerName,
    required String callId,
    required String timestamp,
  }) {
    if (_isConnected) {
      final payload = {
        'channelName': channelName,
        'callerId': callerId,
        'callerName': callerName,
        'callId': callId,
        'timestamp': timestamp,
      };
      if (targetId != null) payload['targetId'] = targetId;
      debugPrint('📤 Emitting Agora call: $payload');
      _socket.emit('initiateCall', payload);
    }
  }

  void terminateCall({
    required String targetId,
    required String callId,
    String? channelName,
  }) {
    if (_isConnected) {
      final data = {
        'targetId': targetId,
        'callId': callId,
      };
      if (channelName != null) {
        data['channelName'] = channelName;
      }
      debugPrint("❌ Sending terminate call: $data");
      _socket.emit('terminateCall', data);
    }
  }

  void disconnect() {
    if (_isConnected) {
      _socket.disconnect();
      _isConnected = false;
      debugPrint('🛑 Socket disconnected');
    }
  }

  void dispose() {
    if (_isConnected) {
      _socket.clearListeners();
      _statusController.close();
      _socket.disconnect();
      _isConnected = false;
      debugPrint('🛑🛑 Socket service disposed completely');
    } else {
      _socket.clearListeners();
      _reconnectAttempts = _maxReconnectAttempts;
      debugPrint('🛑 🛑 Socket disposed finally ');
    }
  }


  // Future<void> _chatNotification(Map<String, dynamic> data) async {
  //   debugPrint('🔔 Foreground Push Notification: $data');
  //   if (!data.containsKey('type') ||
  //       !data.containsKey('senderId') ||
  //       !data.containsKey('message')) {
  //     debugPrint('ℹ️ Ignoring non-chat notification: $data');
  //     return;
  //   }

  //   final userType = await LocalDbHelper.getUserType();

  //   if (userType == "0") {
  //     final currentUserEmail = data["targetId"];
  //     final boxNameWithCount = "${currentUserEmail}count";
  //     final box = await Hive.openBox<int>(boxNameWithCount);
  //     int count = box.get('count', defaultValue: 0)! + 1;
  //     await box.put('count', count);
  //     if (onMessageReceivedCallback != null) {
  //       onMessageReceivedCallback!();
  //     }
  //   } else {
  //     final senderId = data['senderId'];
  //     final targetId = data['targetId'];

  //     // Increment unread count in the dedicated box
  //     await LocalDbHelper.incrementUnreadCount(targetId, senderId);

  //     // // Also update the individual count box for backward compatibility
  //     // final boxNameWithCount = "$targetId${senderId}count";
  //     // final box = await Hive.openBox<int>(boxNameWithCount);
  //     // int count = box.get('count', defaultValue: 0)! + 1;
  //     // await box.put('count', count);

  //     // Update last message
  //     if (data['type'] == "product") {
  //       updateLastMessage(data["senderId"], "shared product");
  //     } else {
  //       updateLastMessage(data['senderId'], data['message']);
  //     }

  //     // Notify the provider to update the UI
  //     if (onMessageReceivedCallback != null) {
  //       onMessageReceivedCallback!();
  //     }
  //   }

  //   // Show local notification (rest of the method remains the same)
  //   if (_notificationsPlugin == null) {
  //     _notificationsPlugin = FlutterLocalNotificationsPlugin();
  //     const androidSettings = AndroidInitializationSettings('app_logo');
  //     const iosSettings = DarwinInitializationSettings(
  //       requestAlertPermission: true,
  //       requestSoundPermission: true,
  //       requestBadgePermission: true,
  //       defaultPresentAlert: true,
  //       defaultPresentSound: true,
  //       defaultPresentBadge: true,
  //     );
  //     const initSettings = InitializationSettings(
  //       android: androidSettings,
  //       iOS: iosSettings,
  //     );
  //     await _notificationsPlugin!.initialize(initSettings,
  //         onDidReceiveNotificationResponse: _handleNotificationTap);
  //   }

  //   // Request permissions for iOS
  //   await _notificationsPlugin!
  //       .resolvePlatformSpecificImplementation<
  //           IOSFlutterLocalNotificationsPlugin>()
  //       ?.requestPermissions(
  //         alert: true,
  //         badge: true,
  //         sound: true,
  //       );

  //   const androidDetails = AndroidNotificationDetails(
  //     'your_channel_id',
  //     'your_channel_name',
  //     channelDescription: 'your_channel_description',
  //     importance: Importance.max,
  //     priority: Priority.high,
  //   );
  //   const iosDetails = DarwinNotificationDetails(
  //     presentAlert: true,
  //     presentBadge: true,
  //     presentSound: true,
  //   );
  //   final notificationDetails =
  //       NotificationDetails(android: androidDetails, iOS: iosDetails);
  //   final title = "New Message from ${data['senderName']}";
  //   final id = title.hashCode;
  //   await _notificationsPlugin!.show(
  //     id,
  //     title,
  //     data['message'],
  //     notificationDetails,
  //     payload: jsonEncode(data),
  //   );
  // }
Future<void> _chatNotification(Map<String, dynamic> data) async {
  debugPrint('🔔 Push Notification Received: $data');

  if (!data.containsKey('type') ||
      !data.containsKey('senderId') ||
      !data.containsKey('message') ||
      !data.containsKey('targetId')) {
    debugPrint('ℹ️ Missing required fields. Ignoring.');
    return;
  }

  try {
    await _initializeNotifications();

    final userType = await LocalDbHelper.getUserType();
    final senderId = data['senderId'].toString();
    final targetId = data['targetId'].toString();
    final message = data['message'].toString();
    final senderName = data['senderName']?.toString() ?? senderId;
    final type = data['type'].toString();

    const groupKey = 'com.yourcompany.kkpchat';

    // 🧠 Local DB Update
    if (userType == "0") {
      final box = await Hive.openBox<int>("${targetId}count");
      final current = box.get('count', defaultValue: 0)!;
      await box.put('count', current + 1);
      await box.close(); // 🚨 important
    } else {
      await LocalDbHelper.incrementUnreadCount(targetId, senderId);
      final content = type == "product" ? "shared product" : message;
      await LocalDbHelper.updateLastMessage(senderId, content);
    }

    // 🔁 UI update
    onMessageReceivedCallback?.call();

    // ✅ Local Notification
    if (userType == "0") {
      final count = await LocalDbHelper.getUserTotalUnread(targetId);
      await _showNotification(
        id: senderId.hashCode,
        title: "New Message",
        body: "$count unread message${count > 1 ? 's' : ''}",
        payload: data,
        groupKey: groupKey,
        isSummary: true,
      );
    } else {
      final unreadCounts = await LocalDbHelper.getMergedUnreadCounts(targetId);
      final isOnChatPage = LocalDbHelper.getReceiverOnChatPageStatus() ?? false;

      if (!isOnChatPage) {
        await _showNotification(
          id: senderId.hashCode,
          title: senderName,
          body: type == "product" ? "Shared a product" : message,
          payload: data,
          groupKey: groupKey,
          isSummary: false,
        );
      }

      final totalMessages = unreadCounts.values.fold(0, (a, b) => a + b);

      if (totalMessages > 0) {
        final previewLines = <String>[];
        for (final entry in unreadCounts.entries) {
          final name = await LocalDbHelper.getNameFromId(entry.key) ?? entry.key;
          previewLines.add("$name: ${entry.value} message${entry.value > 1 ? 's' : ''}");
        }

        await _showNotification(
          id: 9999,
          title: "New Messages",
          body: "$totalMessages messages from ${unreadCounts.length} chats",
          payload: {'summary': true},
          groupKey: groupKey,
          isSummary: true,
          lines: previewLines,
        );
      }

    }
  } catch (e, st) {
    debugPrint('❌ _chatNotification Error: $e\n$st');
  }
}
Future<void> _showNotification({
  required int id,
  required String title,
  required String body,
  required dynamic payload,
  required String groupKey,
  required bool isSummary,
  List<String>? lines,
}) async {
  final androidDetails = AndroidNotificationDetails(
    'high_importance_channel',
    'Chat Notifications',
    channelDescription: 'Important chat messages',
    importance: Importance.max,
    priority: Priority.high,
    groupKey: groupKey,
    setAsGroupSummary: isSummary,
    enableVibration: true,
    playSound: true,
    visibility: NotificationVisibility.public,
    styleInformation: lines != null && lines.isNotEmpty
        ? InboxStyleInformation(
            lines,
            contentTitle: title,
            summaryText: body,
          )
        : null,
  );

  const iosDetails = DarwinNotificationDetails(
    threadIdentifier: 'com.yourcompany.kkpchat',
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  await _notificationsPlugin!.show(
    id,
    title,
    body,
    NotificationDetails(android: androidDetails, iOS: iosDetails),
    payload: jsonEncode(payload),
  );
}
Future<void> _initializeNotifications() async {
  if (_notificationsPlugin == null) {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();

    const androidSettings = AndroidInitializationSettings('app_logo');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
      requestBadgePermission: true,
      defaultPresentAlert: true,
      defaultPresentSound: true,
      defaultPresentBadge: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin!.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Chat Notifications',
      description: 'Important chat messages',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification'),
      enableVibration: true,
    );

    await _notificationsPlugin!
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _notificationsPlugin!
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }
}







  void toggleChatPageOpen(bool toggle) {
    isChatPageOpen = toggle;
  }

  void setChatPageState({required bool isOpen, String? customerId}) {
    isChatPageOpen = isOpen;
    activeCustomerId = isOpen ? customerId : null;
  }

  Future<void> _handleNotificationTap(NotificationResponse response) async {
    debugPrint("Notification tapped: ${response.payload}");

    if (response.payload != null) {
      // Check if the payload is the string "incoming_call"
      if (response.payload == "incoming_call") {
        // Just open the app, no additional action needed
        debugPrint("Incoming call notification tapped, opening the app.");
        return; // Exit the method after handling the incoming call notification
      }

      // If not an incoming call notification, attempt to decode the payload as JSON
      try {
        final Map<String, dynamic> notificationData =
            jsonDecode(response.payload!);
        if ("0" == await LocalDbHelper.getUserType()) {
          handleNotificationClickForCustomer(navigatorKey, notificationData);
        } else {
          handleNotificationClickForAgent(navigatorKey, notificationData);
        }
      } catch (e) {
        debugPrint("Failed to decode JSON: $e");
      }
    }
  }
}
