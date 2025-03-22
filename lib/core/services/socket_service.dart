import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  late io.Socket _socket;
  final String serverUrl = dotenv.env["SOCKET_IO_URL"]!;
  int retryCount = 0;
  static const int maxRetries = 5;

  Function(dynamic data)? onReceiveMessage;
  Function(dynamic data)? onIncomingCall;
  Function(dynamic data)? onMediaStatusChanged;
  Function(dynamic data)? onCallAnswered;
  Function()? onCallTerminated;

  SocketService._internal();

  void initSocket() {
    _socket = io.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'reconnection': true,
      'reconnectionAttempts': maxRetries,
      'reconnectionDelay': 2000,
    });

    _socket.onConnect((_) {
      debugPrint('Connected to server');
      retryCount = 0;
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

    _socket.on('receiveMessage', (data) {
      debugPrint('Received message: $data');
      if (onReceiveMessage != null) {
        onReceiveMessage!(data);
      }
    });

    _socket.on('incomingCall', (data) {
      debugPrint('Incoming call: $data');
      if (onIncomingCall != null) {
        onIncomingCall!(data);
      }
    });

    _socket.on('mediaStatusChanged', (data) {
      debugPrint('Media status changed: $data');
      if (onMediaStatusChanged != null) {
        onMediaStatusChanged!(data);
      }
    });

    _socket.on('callAnswered', (data) {
      debugPrint('Call answered: $data');
      if (onCallAnswered != null) {
        onCallAnswered!(data);
      }
    });

    _socket.on('callTerminated', (data) {
      debugPrint('Call terminated');
      if (onCallTerminated != null) {
        onCallTerminated!();
      }
    });

    connect();
  }

  void connect() {
    _socket.connect();
  }

  void disconnect() {
    _socket.disconnect();
  }

  void joinRoom(String user, String userId) {
    _socket.emit('join', {'user': user, 'userId': userId});
  }

  void sendMessage(String targetEmail, String message, String senderEmail,
      String senderName) {
    if (_socket.connected && targetEmail.isNotEmpty) {
      _socket.emit('sendMessage', {
        'targetId': targetEmail,
        'message': message,
        'senderId': senderEmail,
        'senderName': senderName,
      });
    } else {
      saveMessage(targetUserId, message, senderId, senderName);
    }
  }

  void initiateCall(String targetEmail, dynamic signalData, String senderEmail,
      String senderName) {
    _socket.emit('initiateCall', {
      'targetId': targetEmail,
      'signalData': signalData,
      'senderId': senderEmail,
      'senderName': senderName,
    });
  }

  void answerCall(String to, dynamic data) {
    _socket.emit('answerCall', {
      'to': to,
      'mediaType': data['mediaType'],
      'mediaStatus': data['mediaStatus'],
    });
  }

  void terminateCall(String targetEmail) {
    _socket.emit('terminateCall', {'targetId': targetEmail});
  }

  void initiateCall(String targetEmail, dynamic signalData, String senderEmail,
      String senderName) {
    _socket.emit('initiateCall', {
      'targetId': targetEmail,
      'signalData': signalData,
      'senderId': senderEmail,
      'senderName': senderName,
    });
  }

  void answerCall(String to, dynamic data) {
    _socket.emit('answerCall', {
      'to': to,
      'mediaType': data['mediaType'],
      'mediaStatus': data['mediaStatus'],
    });
  }

  void terminateCall(String targetEmail) {
    _socket.emit('terminateCall', {'targetId': targetEmail});
  }

  void retrySendingMessages() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> pendingMessages = prefs.getStringList('pendingMessages') ?? [];

    for (String message in pendingMessages) {
      sendMessage('targetEmail', message, 'senderEmail', 'senderName');
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
