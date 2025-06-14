import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
//import 'package:kkpchatapp/core/services/chat_storage_service.dart';
import 'package:kkpchatapp/core/services/handle_notification_clicks.dart';
import 'package:kkpchatapp/core/services/notification_service.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
// import 'package:kkpchatapp/data/models/chat_message_model.dart';
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
      final String senderId = data['senderId'] ?? '';
      final String targetId = data['targetId'] ?? '';

      if (isChatPageOpen &&
          (activeCustomerId == senderId || activeCustomerId == targetId)) {
        _onMessageReceived?.call(data);
      } else {
        _chatNotification(data);
      }
    });

    _socket.on('incomingCall', (data) {
      debugPrint('📥 Agora incomingCall: $data');
      if (_onIncomingCall != null) {
        _onIncomingCall!(data);
      }
    });

    // _socket.on('callAnswered', (data) {
    //   debugPrint('📥 callAnswered: $data');
    //   _onCallAnswered?.call(data);
    // });

    _socket.on('callTerminated', (data) {
      debugPrint('📥 callTerminated :${data.toString()}');
      _onCallTerminated?.call(data);
    });

    _socket.on('messageDeleted', (data) {
      final messageId = data['messageId'];
      _onMessageDeleted?.call(messageId);
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
    String? targetEmail, // email to whom we are sending the email
    String? message,
    required String senderEmail, // from which email we are sending
    required String senderName,
    String type = 'text',
    Map<String, dynamic>? form,
    String? mediaUrl,
    String? timestamp,
    String? messageId,
  }) {
    if (_isConnected) {
      Map<String, dynamic> messageData = {
        'senderId': senderEmail,
        'senderName': senderName,
        'type': type,
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
      } else {
        updateLastMessage(targetEmail ?? "", messageData['message']);
      }
    } else {
      debugPrint('Socket is not connected. Cannot send message.');
    }
  }

  void deleteMessage(String messageId) {
    if (_isConnected) {
      _socket.emit('deleteMessage', {'messageId': messageId});
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

  Future<void> _chatNotification(Map<String, dynamic> data) async {
    debugPrint('🔔 Foreground Push Notification: $data');

    final userType = await LocalDbHelper.getUserType();

    // final message = ChatMessageModel(
    //   message: data["message"] ?? "",
    //   timestamp: DateTime.now(),
    //   sender: data["senderId"] ?? "",
    //   type: data["type"] ?? "text",
    //   mediaUrl: data["mediaUrl"],
    //   form: data["form"],
    // );

    if (userType == "0") {
      // chatStorageService.saveMessage(message, data['targetId']);

      // Store message count in Hive
      final currentUserEmail = LocalDbHelper.getProfile()!.email;
      final boxNameWithCount = "${currentUserEmail}count";
      final box = await Hive.openBox<int>(boxNameWithCount);
      int count = box.get('count', defaultValue: 0)! + 1;
      await box.put('count', count);

      if (onMessageReceivedCallback != null) {
        onMessageReceivedCallback!();
      }
    } else {
      final boxName = data['targetId'] + data['senderId'];
      final boxNameWithCount = "${boxName}count";
      final box = await Hive.openBox<int>(boxNameWithCount);
      int count = box.get('count', defaultValue: 0)! + 1;
      await box.put('count', count);
      // chatStorageService.saveMessage(message, boxName);
      // Save the last message for the
      if (data['type'] == "product") {
        updateLastMessage(data["senderId"], "shared product");
      } else {
        updateLastMessage(data['senderId'], data['message']);
      }
      if (onMessageReceivedCallback != null) {
        onMessageReceivedCallback!();
      }
    }

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

      await _notificationsPlugin!.initialize(initSettings,
          onDidReceiveNotificationResponse: _handleNotificationTap);
    }

    const androidDetails = AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    final title = "New Message from ${data['senderName']}";
    final id = title.hashCode;

    await _notificationsPlugin!.show(
      id,
      title,
      data['message'],
      notificationDetails,
      payload: jsonEncode(data),
    );
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
      final Map<String, dynamic> notificationData =
          jsonDecode(response.payload!);

      if ("0" == await LocalDbHelper.getUserType()) {
        handleNotificationClickForCustomer(navigatorKey, notificationData);
      } else {
        handleNotificationClickForAgent(navigatorKey, notificationData);
      }
    }
  }
}
