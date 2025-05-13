import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kkpchatapp/core/services/chat_storage_service.dart';
import 'package:kkpchatapp/core/services/handle_notification_clicks.dart';
import 'package:kkpchatapp/core/services/notification_service.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/models/chat_message_model.dart';
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
  ChatStorageService chatStorageService = ChatStorageService();
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;
  final Duration _reconnectInterval = const Duration(seconds: 3);
  Function(Map<String, dynamic>)? _onMessageReceived;
  Function(Map<String, dynamic>)? _onIncomingCall;
  Function(Map<String, dynamic>)? _onCallAnswered;
  Function(Map<String, dynamic>)? _onCallTerminated;
  Function(Map<String, dynamic>)? _onSignalCandidate;
  bool isChatPageOpen = false;

  List<String> _roomMembers = [];
  StreamController<List<String>> _statusController =
      StreamController<List<String>>.broadcast();

  Stream<List<String>> get statusStream => _statusController.stream;

  List<String> get onlineUsers => List.from(_roomMembers);

  SocketService._internal();

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
    });

    _socket.on('socketId', (socketId) {
      debugPrint('📌 Assigned Socket ID: $socketId');
    });

    _socket.on('roomMembers', (roomMembers) {
      debugPrint('👥 Current Room Members: $roomMembers');
      _updateRoomMembers(List<String>.from(roomMembers));
    });

    _socket.on('receiveMessage', (data) {
      debugPrint(data.toString());
      if (isChatPageOpen && _onMessageReceived != null) {
        _onMessageReceived!(data);
      } else if (!isChatPageOpen && _onMessageReceived != null) {
        // trigger foreground notification upon clicking it will open chat page
        _chatNotification(data);
      } else {
        return;
      }
    });

    // for agora
    _socket.on('incomingCall', (data) {
      debugPrint('📥 Agora incomingCall: $data');

      // Expected `data` structure:
      // {
      //   "channelName": "test123",
      //   "token": "agora_temp_token",
      //   "callerName": "Agent Smith",
      //   "callerId": "agent@example.com"
      // }

      if (_onIncomingCall != null) {
        _onIncomingCall!(data);
      } else {
        debugPrint("⚠️ No onIncomingCall handler set.");
      }
    });

    _socket.on('callAnswered', (data) {
      debugPrint('📥 callAnswered: $data'); // ✅
      if (_onCallAnswered != null) {
        _onCallAnswered!(data);
      }
    });

    _socket.on('callTerminated', (data) {
      debugPrint('📥 callTerminated');
      _onCallTerminated?.call(data);
    });

    _socket.on('signalCandidate', (data) {
      debugPrint('📥 signalCandidate: $data');
      // Check if the callback is assigned, then invoke it
      if (_onSignalCandidate != null) {
        _onSignalCandidate!(data); // Callback is executed here
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

  void _updateRoomMembers(List<String> newRoomMembers) {
    if (_statusController.isClosed) {
      debugPrint("StatusController is closed. Cannot update room members.");
      return;
    }

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
    if (_roomMembers.contains(email)) {
      return "Online";
    }

    DateTime? lastSeen = LocalDbHelper.getLastSeenTime(email);
    if (lastSeen == null) return "Not Available";

    Duration diff = DateTime.now().difference(lastSeen);
    if (diff.inSeconds < 30) {
      return "Just now";
    } else if (diff.inMinutes < 1) {
      return "Few seconds ago";
    } else if (diff.inMinutes == 1) {
      return "1 min ago";
    } else if (diff.inHours < 1) {
      return "${diff.inMinutes} min ago";
    } else if (diff.inHours == 1) {
      return "1 hour ago";
    } else if (diff.inDays < 1) {
      return "${diff.inHours}h ago";
    } else if (diff.inDays == 1) {
      return "Yesterday";
    } else {
      return "${diff.inDays}d ago";
    }
  }

  void onReceiveMessage(Function(Map<String, dynamic>) callback) {
    _onMessageReceived = callback;
  }

  void onIncomingCall(Function(Map<String, dynamic>) callback) {
    _onIncomingCall = callback;
  }

  void onCallAnswered(Function(Map<String, dynamic>) callback) {
    _onCallAnswered = callback;
  }

  void onCallTerminated(Function(Map<String, dynamic>) callback) {
    _onCallTerminated = callback;
  }

  void onSignalCandidate(Function(Map<String, dynamic>) callback) {
    _onSignalCandidate = callback; // Assign the callback to the variable
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
    }
  }

  void sendMessage({
    String? targetEmail,
    String? message,
    required String senderEmail,
    required String senderName,
    String type = 'text',
    Map<String, dynamic>? form,
    String? mediaUrl,
  }) {
    if (_isConnected) {
      Map<String, dynamic> messageData = {
        'senderId': senderEmail,
        'senderName': senderName,
        'type': type,
      };

      if (targetEmail != null) {
        messageData['targetId'] = targetEmail;
      }

      if (message != null) {
        messageData['message'] = message;
      }

      if (form != null) {
        messageData['form'] = form;
      }

      if (mediaUrl != null) {
        messageData['mediaUrl'] = mediaUrl;
      }

      _socket.emit('sendMessage', messageData);
    } else {
      debugPrint('Socket is not connected. Cannot send message.');
    }
  }

  void sendAgoraCall({
    String? targetId, // email or userId of the customer
    required String channelName,
    // required String token,
    required String callerId,
    required String callerName,
    required String callId,
  }) {
    if (_isConnected) {
      final payload = {
        // 'targetId': targetId,
        'channelName': channelName,
        // 'token': token,
        'callerId': callerId,
        'callerName': callerName,
        'callId': callId,
      };
      if (targetId != null) {
        payload['targetId'] = targetId;
      }
      debugPrint('📤 Emitting Agora call: $payload');
      _socket.emit('initiateCall', payload);
    } else {
      debugPrint('❌ Socket not connected. Cannot start Agora call.');
    }
  }

  void initiateCall({
    required String targetId,
    required dynamic signalData,
    required String senderId,
    required String senderName,
  }) {
    debugPrint("📞 Sending offer: $signalData"); // ✅ ADDED

    if (_isConnected) {
      _socket.emit('initiateCall', {
        'targetId': targetId,
        'signalData': signalData,
        'senderId': senderId,
        'senderName': senderName,
      });
    } else {
      debugPrint('Socket is not connected. Cannot initiate call.');
    }
  }

  void answerCall({
    required String to,
    required dynamic signalData,
  }) {
    if (_isConnected) {
      debugPrint("✅ Sending answer: $signalData"); // ✅ ADDED
      _socket.emit('answerCall', {
        'to': to,
        'signalData': signalData,
      });
    } else {
      debugPrint('Socket is not connected. Cannot answer call.');
    }
  }

  void terminateCall({
    required String targetId,
  }) {
    if (_isConnected) {
      debugPrint("❌ Sending terminate call to $targetId"); // ✅ ADDED
      _socket.emit('terminateCall', {
        'targetId': targetId,
      });
    } else {
      debugPrint('Socket is not connected. Cannot terminate call.');
    }
  }

  void signalCandidate({
    required String to,
    required dynamic candidate,
  }) {
    if (_isConnected) {
      debugPrint("🧊 Sending ICE candidate: $candidate"); // ✅ ADDED
      _socket.emit('signalCandidate', {
        'to': to,
        'candidate': candidate,
      });
    } else {
      debugPrint('Socket is not connected. Cannot signal candidate.');
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
    debugPrint('🔔 Foreground Push Notification@@@@@@@@@@: $data');

    // Check if the user is a customer
    if (await LocalDbHelper.getUserType() == "0") {
      // Get the customer's email
      final customerEmail = LocalDbHelper.getProfile()?.email;

      if (customerEmail != null) {
        // Save the message to Hive local storage
        final message = ChatMessageModel(
          message: data["message"],
          timestamp: DateTime.parse(DateTime.now().toIso8601String()),
          sender: data["senderId"],
          type: data["type"] ?? "text",
          mediaUrl: data["mediaUrl"],
          form: data["form"],
        );

        chatStorageService.saveMessage(message, customerEmail);
      }
    }

    if (await LocalDbHelper.getUserType() != "0") {
      // Get the customer's email
      final agentEmail = LocalDbHelper.getProfile()?.email;

      if (agentEmail != null) {
        String boxName = agentEmail + data['senderId'];
        // Save the message to Hive local storage
        final message = ChatMessageModel(
          message: data["message"],
          timestamp: DateTime.parse(DateTime.now().toIso8601String()),
          sender: data["senderId"],
          type: data["type"] ?? "text",
          mediaUrl: data["mediaUrl"],
          form: data["form"],
        );

        chatStorageService.saveMessage(message, boxName);
      }
    }

    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_logo');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
      requestBadgePermission: true,
      defaultPresentAlert: true,
      defaultPresentSound: true,
      defaultPresentBadge: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS);

    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse:
            (NotificationResponse notificationResponse) async {
      _handleNotificationTap(notificationResponse);
    });

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('your_channel_id', 'your_channel_name',
            channelDescription: 'your_channel_description',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker');

    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iosPlatformChannelSpecifics);

    final String title = "New Message from ${data['senderName']}";
    final int notificationId = title.hashCode;

    flutterLocalNotificationsPlugin.show(
      notificationId, // Notification ID
      title, // Notification title
      data['message'], // Notification body
      platformChannelSpecifics,
      payload: jsonEncode(data),
    );
  }

  void toggleChatPageOpen(bool toggle) {
    isChatPageOpen = toggle;
  }

  // Handle notification tap
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
