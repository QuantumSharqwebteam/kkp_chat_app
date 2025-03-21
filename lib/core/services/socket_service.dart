import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  late io.Socket _socket;
  final String serverUrl = dotenv.env['SOCKET_IO_URL']!;
  int retryCount = 0;
  static const int maxRetries = 5;
  String? socketId;

  // Store online users (userId -> socketId mapping)
  final Map<String, String> onlineUsers = {};

  Function(dynamic data)? onReceiveMessage;
  Function(dynamic data)? onIncomingCall;
  Function(dynamic data)? onCallAnswered;
  Function(dynamic data)? onCallTerminated;
  Function(dynamic data)? onMediaStatusChanged;

  SocketService._internal();

  void initSocket() {
    _socket = io.io(
      serverUrl,
      <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'reconnection': true,
        'reconnectionAttempts': maxRetries,
        'reconnectionDelay': 2000,
      },
    );

    _socket.onConnect((_) {
      debugPrint('Connected to server');
      retryCount = 0;
      socketId = _socket.id;
      retrySendingMessages();
    });

    _socket.onConnectError((error) {
      debugPrint('Connection error: $error');
      handleReconnect();
    });

    _socket.onDisconnect((_) {
      debugPrint('Disconnected from server');
      handleReconnect();
    });

    // Get my socket ID
    _socket.on('socketId', (data) {
      debugPrint('Socket ID: $data');
      socketId = data;
    });

    // Get online users and store socket IDs
    _socket.on('roomMembers', (data) {
      debugPrint('Online Users: $data');
      if (data is List) {
        onlineUsers.clear();
        for (var user in data) {
          if (user is Map<String, dynamic> &&
              user.containsKey('userId') &&
              user.containsKey('id')) {
            onlineUsers[user['userId']] =
                user['id']; // Store userId -> socketId
          }
        }
      }
    });

    _socket.on('receiveMessage', (data) {
      debugPrint('Received message: $data');
      onReceiveMessage?.call(data);
    });

    _socket.on('incomingCall', (data) {
      debugPrint('Incoming call: $data');
      onIncomingCall?.call(data);
    });

    _socket.on('callAnswered', (data) {
      debugPrint('Call answered: $data');
      onCallAnswered?.call(data);
    });

    _socket.on('callTerminated', (data) {
      debugPrint('Call terminated: $data');
      onCallTerminated?.call(data);
    });

    _socket.on('mediaStatusChanged', (data) {
      debugPrint('Media status changed: $data');
      onMediaStatusChanged?.call(data);
    });

    connect();
  }

  void connect() {
    _socket.connect();
  }

  void disconnect() {
    _socket.disconnect();
  }

  void joinRoom(String user, String userId, Function(dynamic) callback) {
    debugPrint("Joining room: user=$user, userId=$userId");

    _socket.emitWithAck('join', {'user': user, 'userId': userId},
        ack: (response) {
      debugPrint("Join room response: $response");

      if (response is Map<String, dynamic> && response.containsKey('id')) {
        onlineUsers[userId] = response['id']; // Store my own socket ID
      }

      callback(response);
    });
  }

  void sendMessage(
      String targetUserId, String message, String senderId, String senderName) {
    String? targetSocketId = onlineUsers[targetUserId];

    if (targetSocketId == null) {
      debugPrint("User $targetUserId is offline or not found.");
      return;
    }

    String timestamp = DateTime.now().toIso8601String();

    if (_socket.connected) {
      _socket.emit('sendMessage', {
        'targetId':
            targetUserId, // this will be the socket id to whom the sender is sending message
        'message': message,
        'senderId':
            senderId, // this will be the current user email who is sending message
        'senderName': senderName,
        'timestamp': timestamp,
      });
    } else {
      saveMessage(targetUserId, message, senderId, senderName);
    }
  }

  void initiateCall(
      String targetId, dynamic signalData, String senderId, String senderName) {
    _socket.emit('initiateCall', {
      'targetId': targetId,
      'signalData': signalData,
      'senderId': senderId,
      'senderName': senderName,
    });
  }

  void answerCall(
      String to, dynamic signalData, String mediaType, bool mediaStatus) {
    _socket.emit('answerCall', {
      'to': to,
      'signalData': signalData,
      'mediaType': mediaType,
      'mediaStatus': mediaStatus,
    });
  }

  void terminateCall(String targetId) {
    _socket.emit('terminateCall', {'targetId': targetId});
  }

  void changeMediaStatus(String mediaType, bool isActive) {
    _socket.emit(
        'changeMediaStatus', {'mediaType': mediaType, 'isActive': isActive});
  }

  Future<void> retrySendingMessages() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> pendingMessages = prefs.getStringList('pendingMessages') ?? [];

    for (String message in pendingMessages) {
      List<String> parts = message.split('|');
      if (parts.length == 4) {
        sendMessage(parts[0], parts[1], parts[2], parts[3]);
      }
    }

    pendingMessages.clear();
    await prefs.setStringList('pendingMessages', []);
  }

  Future<void> saveMessage(String targetId, String message, String senderId,
      String senderName) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> pendingMessages = prefs.getStringList('pendingMessages') ?? [];
    pendingMessages.add("$targetId|$message|$senderId|$senderName");
    await prefs.setStringList('pendingMessages', pendingMessages);
  }

  void handleReconnect() async {
    retryCount++;
    if (retryCount <= maxRetries) {
      debugPrint('Retrying connection... Attempt $retryCount');
      await Future.delayed(Duration(seconds: 2));
      connect();
    } else {
      debugPrint('Max retry attempts reached.');
    }
  }
}
