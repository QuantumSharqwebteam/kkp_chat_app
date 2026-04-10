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
  // int _reconnectAttempts = 0;
  // final int _maxReconnectAttempts = 5;
  // final Duration _reconnectInterval = const Duration(seconds: 3);
  Function(Map<String, dynamic>)? _onMessageReceived;
  Function(String)? _onMessageDeleted;
  Function(Map<String, dynamic>)? _onIncomingCall;
  // Function(Map<String, dynamic>)? _onCallAnswered;
  final List<Function(Map<String, dynamic>)> _onCallTerminatedListeners = [];
  // Function? _onDisconnect;
  Function? _onConnect;
  Function(Map<String, dynamic>)? _onChatStatus;
  Function(Map<String, dynamic>)? _onMessagesReadUpTo;

  Function(Map<String, dynamic>)? _onProductAdd;
  Function(Map<String, dynamic>)? _onProductUpdate;
  Function(String)? _onProductDelete;

  // Group chat callbacks
  Function(Map<String, dynamic>)? _onGroupMessageReceived;
  Function(Map<String, dynamic>)? _onGroupMessageDeleted;
  Function(Map<String, dynamic>)? _onGroupMessageEdited;

  bool isChatPageOpen = false;
  String? activeCustomerId;

  bool isGroupChatPageOpen = false;

  Function? onMessageReceivedCallback;

  List<String> _roomMembers = [];
  StreamController<List<String>> _statusController = StreamController<List<String>>.broadcast();

  Stream<List<String>> get statusStream => _statusController.stream;

  List<String> get onlineUsers => List.from(_roomMembers);

  FlutterLocalNotificationsPlugin? _notificationsPlugin;

  SocketService._internal();

  ({String formId, num rate})? _extractRateUpdateInfo(String? messageText) {
    if (messageText == null || messageText.isEmpty) return null;

    final regex = RegExp(
      r'Rate\s+updated\s+as\s+([0-9]+(?:\.[0-9]+)?)\s+for\s+form\s+with\s+Id\s*:\s*([A-Za-z0-9]+)',
      caseSensitive: false,
    );
    final match = regex.firstMatch(messageText);
    if (match == null) return null;

    final parsedRate = num.tryParse(match.group(1) ?? '');
    final formId = match.group(2);
    if (parsedRate == null || formId == null || formId.isEmpty) return null;

    return (formId: formId, rate: parsedRate);
  }

  Future<void> _applyFormRateUpdateInBackground(Map<String, dynamic> data) async {
    String? targetFormId;
    final Map<String, dynamic> formPatch = {};

    if (data['type'] == 'form' && data['form'] is Map) {
      final incomingForm = Map<String, dynamic>.from(data['form'] as Map);
      final formId = incomingForm['_id']?.toString();
      if (formId != null && formId.isNotEmpty) {
        targetFormId = formId;
        formPatch.addAll(incomingForm);
        formPatch['_formOptionsUnlocked'] = true;
      }
    }

    final rateUpdate = _extractRateUpdateInfo(data['message']?.toString());
    if (targetFormId == null && rateUpdate != null) {
      final normalizedRate = rateUpdate.rate % 1 == 0 ? rateUpdate.rate.toInt() : rateUpdate.rate;
      targetFormId = rateUpdate.formId;
      formPatch['rate'] = normalizedRate;
      formPatch['_formOptionsUnlocked'] = true;
    }

    if (targetFormId == null) return;

    final senderId = data['senderId']?.toString();
    final targetId = data['targetId']?.toString();
    if (senderId == null || senderId.isEmpty || targetId == null || targetId.isEmpty) return;

    final userType = await LocalDbHelper.getUserType();
    final boxName = userType == "0" ? targetId : '$targetId$senderId';

    final storage = ChatStorageService();
    final cachedMessages = await storage.getMessages(boxName, page: 1, limit: 100000);
    bool updated = false;

    for (final msg in cachedMessages) {
      final form = msg.form;
      if (form == null) continue;
      if (form['_id']?.toString() != targetFormId) continue;

      final updatedForm = Map<String, dynamic>.from(form);
      updatedForm.addAll(formPatch);
      msg.form = updatedForm;
      await storage.saveMessage(msg, boxName);
      updated = true;
    }

    if (updated) {
      debugPrint(
        "✅ Updated cached form options for formId: $targetFormId in box: $boxName",
      );
      if (onMessageReceivedCallback != null) {
        onMessageReceivedCallback!();
      }
    }
  }

  void onMessageReceived(Function(Map<String, dynamic>) callback, {Function? refreshCallback}) {
    _onMessageReceived = callback;
    onMessageReceivedCallback = refreshCallback;
  }

  void initSocket(String userName, String userEmail, String role, {String? token}) {
    // ✅ Prevent duplicate socket creation
    if (_isConnected) {
      debugPrint('⚠️ Socket already connected, skipping init');
      return;
    }
    _statusController.close();
    _statusController = StreamController<List<String>>.broadcast();
    _socket = io.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'reconnection': true,
      'reconnectionAttempts': 10,
      'reconnectionDelay': 2000,
      'reconnectionDelayMax': 10000,
      'timeout': 20000,
    });

    _socket.onConnect((_) {
      _isConnected = true;
      // _reconnectAttempts = 0;
      debugPrint('✅ Connected to socket server');
      _socket.emit('join', {
        'user': userName,
        'userId': userEmail,
        "role": role,
        "token": token,
      });
      if (_onConnect != null) {
        _onConnect?.call(); // Trigger the connect callback
      }
    });

    _socket.on('socketId', (socketId) {
      debugPrint('📌 Assigned Socket ID: $socketId');
    });

    _socket.on('roomMembers', (roomMembers) {
      debugPrint('👥 Current Room Members: $roomMembers');
      _updateRoomMembers(List<String>.from(roomMembers));
    });

    // Group chat listener
    _socket.on('receiveGroupMessage', (data) {
      debugPrint('📥 Received group message: $data');
      if (isGroupChatPageOpen) {
        _onGroupMessageReceived?.call(data);
      } else {
        _groupChatNotification(data);
      }
    });

    _socket.on('receiveMessage', (data) {
      debugPrint("recived message socket : ${data.toString()}");
      final String senderId = data['senderId'] ?? '';
      final String targetId = data['targetId'] ?? '';

      if (isChatPageOpen && (activeCustomerId == senderId || activeCustomerId == targetId)) {
        _onMessageReceived?.call(data);
      } else {
        debugPrint("recived message socket : ${data.toString()}");
        if (data is Map) {
          _applyFormRateUpdateInBackground(Map<String, dynamic>.from(data));
        }
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

      final payload = Map<String, dynamic>.from((data as Map?) ?? const {});
      for (final listener in List<Function(Map<String, dynamic>)>.from(_onCallTerminatedListeners)) {
        listener(payload);
      }
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

    _socket.on('productAdd', (data) {
      debugPrint("[Socket] New product added: $data");
      if (_onProductAdd != null) {
        final payload = Map<String, dynamic>.from((data as Map?) ?? const {});
        _onProductAdd!(payload);
      }
    });

    _socket.on('productUpdate', (data) {
      debugPrint("[Socket] Product updated: $data");
      if (_onProductUpdate != null) {
        final payload = Map<String, dynamic>.from((data as Map?) ?? const {});
        _onProductUpdate!(payload);
      }
    });

    _socket.on('productDelete', (data) {
      debugPrint("[Socket] Product deleted: $data");
      final dynamic productId = data is Map ? (data['productId'] ?? data['_id']) : data;
      if (_onProductDelete != null && productId != null) {
        _onProductDelete!(productId.toString());
      }
    });

    _socket.on('groupMessageMarkedDeleted', (data) {
      debugPrint('🗑️ Group message marked as deleted: $data');
      if (isGroupChatPageOpen) {
        _onGroupMessageDeleted?.call(data);
      } else {
        // Handle in background if needed
        _handleBackgroundGroupMessageDeletion(data);
      }
    });

    _socket.on('groupMessageEdited', (data) {
      debugPrint('✏️ Group message edited: $data');
      if (isGroupChatPageOpen) {
        _onGroupMessageEdited?.call(data);
      } else {
        // Handle in background if needed
        _handleBackgroundGroupMessageEdit(data);
      }
    });

    _socket.onDisconnect((_) {
      _isConnected = false;
      for (String email in _roomMembers) {
        LocalDbHelper.updateLastSeenTime(email);
        debugPrint("⏳ Saved last seen for $email: ${DateTime.now().toIso8601String()}");
      }
      debugPrint('⚠️ Disconnected from socket server');
      // _attemptReconnect(userName, userEmail, role);
    });

    // _socket.onError((error) {
    //   debugPrint('❌ Socket Error: $error');
    //   _attemptReconnect(userName, userEmail, role);
    // });

    _socket.connect();
  }

  // void onDisconnect(Function callback) {
  //   _onDisconnect = callback;
  // }

  void onConnect(Function callback) {
    _onConnect = callback;
  }

  void onProductAdd(Function(Map<String, dynamic>) callback) {
    _onProductAdd = callback;
  }

  void onProductUpdate(Function(Map<String, dynamic>) callback) {
    _onProductUpdate = callback;
  }

  void onProductDelete(Function(String) callback) {
    _onProductDelete = callback;
  }

  void onChatStatus(Function(Map<String, dynamic>) callback) {
    debugPrint("🔧 Chat status callback set");
    _onChatStatus = callback;
  }

  void onMessagesReadUpTo(Function(Map<String, dynamic>) callback) {
    debugPrint("🔧 Messages read up to callback set");
    _onMessagesReadUpTo = callback;
  }

  void toggleGroupChatPageOpen(bool toggle) {
    debugPrint("🔄 [SocketService] Toggling group chat page: ${toggle ? "OPEN" : "CLOSED"}");
    isGroupChatPageOpen = toggle;
  }

  void setGroupChatPageState(bool isOpen) {
    debugPrint("🔄 [SocketService] Setting group chat page state: ${isOpen ? "OPEN" : "CLOSED"}");
    isGroupChatPageOpen = isOpen;
  }

  void onGroupMessageReceived(Function(Map<String, dynamic>) callback) {
    debugPrint("🔧 [SocketService] Group message callback registered");
    _onGroupMessageReceived = callback;
  }

  // Add these methods to register callbacks
  void onGroupMessageDeleted(Function(Map<String, dynamic>) callback) {
    debugPrint("🔧 [SocketService] Group message deleted callback registered");
    _onGroupMessageDeleted = callback;
  }

  void onGroupMessageEdited(Function(Map<String, dynamic>) callback) {
    debugPrint("🔧 [SocketService] Group message edited callback registered");
    _onGroupMessageEdited = callback;
  }

  void sendGroupMessage({
    required String message,
    required String senderId,
    required String senderName,
    required String groupId,
    String type = 'text',
    String? mediaUrl,
    String? fileName,
    List<String>? mentions,
    String? replyTo,
    String? timestamp,
    String? messageId,
  }) {
    if (!_isConnected) {
      debugPrint('Socket is not connected. Cannot send group message.');
      return;
    }

    final payload = {
      'message': message,
      'senderId': senderId,
      'senderName': senderName,
      'groupId': groupId,
      'type': type,
      'mediaUrl': mediaUrl,
      'fileName': fileName,
      'mentions': mentions,
      'replyTo': replyTo,
      'timestamp': timestamp,
      'messageId': messageId,
    };

    _socket.emit('sendGroupMessage', payload);
    debugPrint('📤 Sent group message: $payload');
  }

  // Add these methods to handle background events
  void _handleBackgroundGroupMessageDeletion(Map<String, dynamic> data) async {
    debugPrint("🗑️ Handling group message deletion in background: ${data.toString()}");
    final messageId = data['messageId'];

    try {
      // Update the message in local storage
      final localMessages = await LocalDbHelper.getGroupMessages();
      final index = localMessages.indexWhere((msg) => msg.messageId == messageId);

      if (index != -1) {
        final updatedMessage = localMessages[index].copyWith(
          isDeleted: true,
          message: "This message was deleted",
        );
        await LocalDbHelper.updateGroupMessage(updatedMessage);
        debugPrint("✅ Updated deleted message in local storage: $messageId");
      }
    } catch (e) {
      debugPrint("❌ Error updating deleted message in background: $e");
    }
  }

  void _handleBackgroundGroupMessageEdit(Map<String, dynamic> data) async {
    debugPrint("✏️ Handling group message edit in background: ${data.toString()}");
    final messageId = data['messageId'];
    final newMessage = data['newMessage'];

    try {
      // Update the message in local storage
      final localMessages = await LocalDbHelper.getGroupMessages();
      final index = localMessages.indexWhere((msg) => msg.messageId == messageId);

      if (index != -1) {
        final updatedMessage = localMessages[index].copyWith(
          message: newMessage,
          isEdited: true,
        );
        await LocalDbHelper.updateGroupMessage(updatedMessage);
        debugPrint("✅ Updated edited message in local storage: $messageId");
      }
    } catch (e) {
      debugPrint("❌ Error updating edited message in background: $e");
    }
  }

// Add this method to delete a group message
  void deleteGroupMessage(
      {required String messageId, required String senderId, required String groupId}) {
    if (!_isConnected) {
      debugPrint('Socket is not connected. Cannot delete group message.');
      return;
    }

    final payload = {
      'messageId': messageId,
      'senderId': senderId,
      "groupId": groupId,
    };

    _socket.emit('deleteGroupMessage', payload);
    debugPrint('🗑️ Delete group message event emitted: $messageId');
  }

// Add this method to edit a group message
  void editGroupMessage(
      {required String messageId,
      required String senderId,
      required String newMessage,
      required String groupId}) {
    if (!_isConnected) {
      debugPrint('Socket is not connected. Cannot edit group message.');
      return;
    }

    final payload = {
      'messageId': messageId,
      'senderId': senderId,
      'newMessage': newMessage,
      "groupId": groupId
    };

    _socket.emit('editGroupMessage', payload);
    debugPrint('✏️ Edit group message event emitted: $messageId');
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

    if (status == 'opened' && lastMessageTimestampStr != null && customerEmail != null) {
      final lastMessageTimestamp = DateTime.tryParse(lastMessageTimestampStr);
      if (lastMessageTimestamp != null) {
        // Set the receiver as on the chat page using LocalDbHelper
        LocalDbHelper.saveReceiverOnChatPageStatus(true);

        final userType = await LocalDbHelper.getUserType();
        if (userType == "0") {
          // Customer
          final messages = await ChatStorageService().getCustomerMessages(customerEmail);
          for (var message in messages) {
            if (message.timestamp.isBefore(lastMessageTimestamp) ||
                message.timestamp == lastMessageTimestamp) {
              message.read = true;
              await ChatStorageService().saveMessage(message, customerEmail);
            }
          }
          debugPrint("✅ Updated customer messages as read up to $lastMessageTimestampStr");
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
      final messages = await ChatStorageService().getCustomerMessages(customerEmail);
      for (var message in messages) {
        if (message.timestamp.isBefore(lastMessageTimestamp)) {
          message.read = true;
          await ChatStorageService().saveMessage(message, customerEmail);
        }
      }
      debugPrint("✅ Updated customer messages as read up to $lastMessageTimestampStr");
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

      final index = messages.indexWhere((message) => message.messageId == messageId);
      if (index != -1) {
        messages[index].isDeleted = true;
        messages[index].message = "This message is deleted";

        // Save the updated message state to local storage
        await ChatStorageService().saveMessage(messages[index], targetId);
        debugPrint("Message marked as deleted for customer with ID: $messageId");

        // Verify the message is updated in the storage
        final updatedMessages = await ChatStorageService().getCustomerMessages(targetId);
        final updatedIndex =
            updatedMessages.indexWhere((message) => message.messageId == messageId);
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
      final index = messages.indexWhere((message) => message.messageId == messageId);
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
      debugPrint("⏳ Updated last seen for $email: ${DateTime.now().toIso8601String()}");
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
    if (!_onCallTerminatedListeners.contains(callback)) {
      _onCallTerminatedListeners.add(callback);
    }
  }

  void offCallTerminated(Function(Map<String, dynamic>) callback) {
    _onCallTerminatedListeners.remove(callback);
  }

  // void _attemptReconnect(String userName, String userEmail, String role) {
  //   if (!_isConnected && _reconnectAttempts < _maxReconnectAttempts) {
  //     _reconnectAttempts++;
  //     debugPrint('🔄 Reconnecting... Attempt $_reconnectAttempts/$_maxReconnectAttempts');

  //     Future.delayed(_reconnectInterval, () {
  //       if (!_isConnected) {
  //         _socket.connect();
  //         _socket.emit('join', {'user': userName, 'userId': userEmail, "role": role});
  //       }
  //     });
  //   } else {
  //     debugPrint('🚫 Max reconnection attempts reached or user logged out.');
  //     if (_onDisconnect != null) {
  //       _onDisconnect!(); // Trigger the disconnect callback only when max attempts are reached
  //     }
  //     // Reset reconnection attempts and reinitialize the socket
  //     _reconnectAttempts = 0;
  //     Future.delayed(_reconnectInterval, () {
  //       debugPrint('🔄 Reinitializing socket connection...');
  //       _socket.connect();
  //       _socket.emit('join', {'user': userName, 'userId': userEmail, "role": role});
  //     });
  //   }
  // }

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
      } else if (message != null && message.contains("Your order is confirmed with form Id")) {
        // Handle order confirmation
        updateLastMessage(targetEmail ?? "", "Order Confirmed");
      } else if (message != null && message.contains("Your order is declined with form Id")) {
        // Handle order decline
        updateLastMessage(targetEmail ?? "", "Order Declined");
      } else {
        updateLastMessage(targetEmail ?? "", messageData['message']);
      }
    } else {
      debugPrint('Socket is not connected. Cannot send message.');
    }
  }

  void sendForm({
    required String senderId,
    required String targetId,
    required String senderName,
    required Map<String, dynamic> form,
    required String timestamp,
    required String messageId,
    String? orderId,
  }) {
    if (_isConnected) {
      final formData = {
        'senderId': senderId,
        'targetId': targetId,
        'senderName': senderName,
        'form': form,
        'timestamp': timestamp,
        'messageId': messageId,
      };
      if (orderId != null) {
        formData['orderId'] = orderId;
      }
      _socket.emit('sendForm', formData);
      debugPrint('📤 Sent form via socket: $formData');
    } else {
      debugPrint('Socket is not connected. Cannot send form.');
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
      //   _reconnectAttempts = _maxReconnectAttempts;
      debugPrint('🛑 🛑 Socket disposed finally ');
    }
  }

  Future<void> _chatNotification(Map<String, dynamic> data) async {
    debugPrint('🔔 Foreground Push Notification: $data');
    if (!data.containsKey('type') ||
        !data.containsKey('senderId') ||
        !data.containsKey('message')) {
      debugPrint('ℹ️ Ignoring non-chat notification: $data');
      return;
    }

    final userType = await LocalDbHelper.getUserType();
    final String notificationMessage = data['type'] == "product"
        ? "Shared product"
        : (data['message'] is String ? data['message'] as String : data['message'].toString());

    if (userType == "0") {
      // Customer-side notification logic
      final currentUserEmail = data["targetId"];
      final boxNameWithCount = "${currentUserEmail}count";
      final box = await Hive.openBox<int>(boxNameWithCount);
      int count = box.get('count', defaultValue: 0)! + 1;
      await box.put('count', count);
      if (onMessageReceivedCallback != null) {
        onMessageReceivedCallback!();
      }

      // Send notification to the customer
      final title = "New Message from Agent";
      final id = 200;

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
        await _notificationsPlugin!
            .initialize(initSettings, onDidReceiveNotificationResponse: _handleNotificationTap);
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
      final notificationDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _notificationsPlugin!.show(
        id,
        title,
        notificationMessage,
        notificationDetails,
        payload: jsonEncode(data),
      );
    } else {
      // for agent side
      final senderId = data['senderId']; // AgentEmail
      final targetId = data['targetId']; // customerEmail

      // Increment unread count in the dedicated box
      await LocalDbHelper.incrementUnreadCount(targetId, senderId);

      // // Also update the individual count box for backward compatibility
      // final boxNameWithCount = "$targetId${senderId}count";
      // final box = await Hive.openBox<int>(boxNameWithCount);
      // int count = box.get('count', defaultValue: 0)! + 1;
      // await box.put('count', count);

      // Update last message
      if (data['type'] == "product") {
        updateLastMessage(data["senderId"], "shared product");
      } else {
        updateLastMessage(data['senderId'], data['message']);
      }

      // Notify the provider to update the UI
      if (onMessageReceivedCallback != null) {
        onMessageReceivedCallback!();
      }
    }

    // Show local notification (rest of the method remains the same)
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
      await _notificationsPlugin!
          .initialize(initSettings, onDidReceiveNotificationResponse: _handleNotificationTap);
    }

    // Request permissions for iOS
    await _notificationsPlugin!
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

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
    final notificationDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);
    // final title = "New Message from ${data['senderName']}";
    // final id = title.hashCode;
    // await _notificationsPlugin!.show(
    //   id,
    //   title,
    //   data['message'],
    //   notificationDetails,
    //   payload: jsonEncode(data),
    // );

    // Start of added code for consolidating notifications
    if (userType != "0") {
      // Agent-side notification logic
      const consolidatedNotificationId = 999;
      final box =
          await Hive.openBox<int>('${LocalDbHelper.unreadCountsBoxKey}_${data['targetId']}');
      final totalUnreadMessages = box.values.fold<int>(0, (sum, value) => sum + value);
      final usersWithUnread = box.values.where((count) => count > 0).length;

      String title;
      String message;
      String payload;

      if (usersWithUnread == 1) {
        final unreadCount =
            await LocalDbHelper.getUnreadCount(data['targetId'], data['senderId']) ?? 0;

        if (unreadCount > 1) {
          title = "$unreadCount messages from ${data['senderName']}";
          message = "You have $unreadCount unread messages";
        } else {
          title = "New message from ${data['senderName']}";
          message = notificationMessage;
        }

        payload = jsonEncode(data); // Normal payload to open chat
      } else {
        title = "$totalUnreadMessages unread messages from $usersWithUnread users";
        message = "You have $totalUnreadMessages unread messages";
        payload = "general_chat_summary"; // Special payload
      }

      await _notificationsPlugin!.show(
        consolidatedNotificationId,
        title,
        message,
        notificationDetails,
        payload: payload,
      );
    } else {
      final title = "New Message from Agent";
      final id = 200;

      await _notificationsPlugin!.show(
        id,
        title,
        notificationMessage,
        notificationDetails,
        payload: jsonEncode(data),
      );
    }
  }

  void toggleChatPageOpen(bool toggle) {
    isChatPageOpen = toggle;
  }

  void setChatPageState({required bool isOpen, String? customerId}) {
    isChatPageOpen = isOpen;
    activeCustomerId = isOpen ? customerId : null;
  }

  /// Handles notifications for group messages when the chat is not open
  /// Handles notifications for group messages when the chat is not open
  Future<void> _groupChatNotification(Map<String, dynamic> data) async {
    debugPrint('🔔 Group Chat Notification: $data');

    // Check if this is a valid group message notification
    if (!data.containsKey('type') ||
        !data.containsKey('senderId') ||
        !data.containsKey('message') ||
        !data.containsKey('senderName')) {
      debugPrint('ℹ️ Ignoring invalid group chat notification: $data');
      return;
    }

    try {
      // Initialize notifications plugin if not already done
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
        await _notificationsPlugin!
            .initialize(initSettings, onDidReceiveNotificationResponse: _handleNotificationTap);
      }

      // Request permissions for iOS
      await _notificationsPlugin!
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );

      // Create notification details
      const androidDetails = AndroidNotificationDetails(
        'group_chat_channel_id',
        'Internal Chat Notifications',
        channelDescription: 'Notifications for internal team chat messages',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: 'app_logo',
        largeIcon: DrawableResourceAndroidBitmap('app_logo'),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Create more descriptive notification title and content
      final title = "New update from Internal Chat (${data['senderName']})";
      String messageContent;

      switch (data['type']) {
        case 'media':
          messageContent = "[Image]";
          break;
        case 'document':
          messageContent = "[Document]";
          break;
        case 'voice':
          messageContent = "[Voice message]";
          break;
        case 'text':
        default:
          // For text messages, show a preview if it's not too long
          messageContent = data['message'].length > 30
              ? "${data['message'].substring(0, 30)}..."
              : data['message'];
          break;
      }

      // Use a fixed ID for group notifications to replace previous ones
      const notificationId = 1001;

      // Show the notification
      await _notificationsPlugin!.show(
        notificationId,
        title,
        messageContent,
        notificationDetails,
        payload: jsonEncode({
          'isGroupMessage': true, // This flag identifies it as a group message
          'notificationType': 'groupChat',
          ...data, // Include all original data
        }),
      );

      // Increment unread count for group chat using LocalDbHelper
      try {
        await LocalDbHelper.incrementGroupChatUnreadCount();
        debugPrint("✅ Incremented group chat unread count");
      } catch (e) {
        debugPrint("❌ Error incrementing group chat unread count: $e");
      }
    } catch (e) {
      debugPrint('❌ Error showing group chat notification: $e');
    }
  }

  /// Handles notification taps
  Future<void> _handleNotificationTap(NotificationResponse response) async {
    debugPrint("Notification tapped: ${response.payload}");

    if (response.payload == null) {
      debugPrint("Notification payload is null");
      return;
    }

    try {
      // Check if this is a group message notification
      if (response.payload is String) {
        try {
          final Map<String, dynamic> notificationData = jsonDecode(response.payload!);

          // Handle group message notification
          if (notificationData['isGroupMessage'] == true) {
            debugPrint("Group message notification tapped");
            await handleGroupLocalNotificationTap(navigatorKey, notificationData);
            return;
          }
        } catch (e) {
          debugPrint("Not a JSON payload or not a group message: $e");
        }
      }

      // Check if the payload is the string "incoming_call"
      if (response.payload == "incoming_call") {
        debugPrint("Incoming call notification tapped, opening the app.");
        return;
      }

      if (response.payload == "general_chat_summary") {
        debugPrint("Summary notification tapped, just opening the app.");
        return;
      }

      // Handle regular message notifications
      try {
        final Map<String, dynamic> notificationData = jsonDecode(response.payload!);
        if ("0" == await LocalDbHelper.getUserType()) {
          handleNotificationClickForCustomer(navigatorKey, notificationData);
        } else {
          handleNotificationClickForAgent(navigatorKey, notificationData);
        }
      } catch (e) {
        debugPrint("Failed to decode JSON: $e");
      }
    } catch (e) {
      debugPrint("Error handling notification tap: $e");
    }
  }
}
