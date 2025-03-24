import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'dart:async';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  late io.Socket _socket;
  bool _isConnected = false;
  final String serverUrl = dotenv.env["SOCKET_IO_URL"]!;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;
  final Duration _reconnectInterval = const Duration(seconds: 3);

  Function(Map<String, dynamic>)? _onMessageReceived;

  // Default value for chat page open state
  bool isChatPageOpen = false;

  SocketService._internal();

  void initSocket(String userName, String userEmail) {
    _socket = io.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'reconnection': false,
    });

    _socket.onConnect((_) {
      _isConnected = true;
      _reconnectAttempts = 0;
      debugPrint('✅ Connected to socket server');
      _socket.emit('join', {'user': userName, 'userId': userEmail});
    });

    _socket.on('socketId', (socketId) {
      debugPrint('📌 Assigned Socket ID: $socketId');
    });

    _socket.on('roomMembers', (roomMembers) {
      debugPrint('👥 Current Room Members: $roomMembers');
    });

    _socket.on('receiveMessage', (data) {
      if (!isChatPageOpen) {
        _showPushNotification(data);
      }

      if (_onMessageReceived != null) {
        _onMessageReceived!(data);
      } else {
        debugPrint('📩 New message received but no listener attached: $data');
      }
    });

    _socket.onDisconnect((_) {
      _isConnected = false;
      debugPrint('⚠️ Disconnected from socket server');
      _attemptReconnect(userName, userEmail);
    });

    _socket.onError((error) {
      debugPrint('❌ Socket Error: $error');
      _attemptReconnect(userName, userEmail);
    });

    _socket.connect();
  }

  void onReceiveMessage(Function(Map<String, dynamic>) callback) {
    _onMessageReceived = callback;
  }

  void _attemptReconnect(String userName, String userEmail) {
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      debugPrint(
          '🔄 Reconnecting... Attempt $_reconnectAttempts/$_maxReconnectAttempts');

      Future.delayed(_reconnectInterval, () {
        if (!_isConnected) {
          _socket.connect();
        }
      });
    } else {
      debugPrint('🚫 Max reconnection attempts reached.');
    }
  }

  void sendMessage(String targetEmail, String message, String senderEmail,
      String senderName) {
    if (_isConnected) {
      _socket.emit('sendMessage', {
        'targetId': targetEmail,
        'message': message,
        'senderId': senderEmail,
        'senderName': senderName,
      });
    }
  }

  void listenForMessages(Function(dynamic) onMessageReceived) {
    _socket.on('receiveMessage', (data) {
      if (isChatPageOpen) {
        onMessageReceived(data);
      } else {
        _showPushNotification(data);
      }
    });
  }

  void getOnlineUsers() {
    _socket.emit('roomMembers');
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

  void listenForIncomingCall(Function(dynamic) onIncomingCall) {
    _socket.on('incomingCall', (data) {
      onIncomingCall(data);
    });
  }

  void answerCall(String targetSocketId, String mediaType, bool mediaStatus) {
    _socket.emit('answerCall', {
      'to': targetSocketId,
      'mediaType': mediaType,
      'mediaStatus': mediaStatus,
    });
  }

  void changeMediaStatus(String mediaType, bool isActive) {
    _socket.emit('changeMediaStatus', {
      'mediaType': mediaType,
      'isActive': isActive,
    });
  }

  void terminateCall(String targetEmail) {
    _socket.emit('terminateCall', {'targetId': targetEmail});
  }

  void disconnect() {
    if (_isConnected) {
      _socket.disconnect();
    }
  }

  // Function to show push notification
  void _showPushNotification(Map<String, dynamic> data) {
    // Implement your push notification logic here
    debugPrint('🔔 Push Notification: New message received: $data');
  }

  // Method to toggle the chat page open state
  void toggleChatPageOpen(bool toggle) {
    isChatPageOpen = toggle;
  }
}
