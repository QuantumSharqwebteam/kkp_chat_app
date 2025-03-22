import 'package:flutter/foundation.dart';
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

  Function(Map<String, dynamic>)?
      _onMessageReceived; // Callback for received messages

  SocketService._internal();

  // Initialize socket connection
  void initSocket(String userName, String userEmail) {
    _socket = io.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'reconnection': false, // We will handle reconnection manually
    });

    _socket.onConnect((_) {
      _isConnected = true;
      _reconnectAttempts = 0; // Reset reconnect attempts on success
      print('✅ Connected to socket server');

      // Emit join event
      _socket.emit('join', {'user': userName, 'userId': userEmail});
    });

    _socket.on('socketId', (socketId) {
      print('📌 Assigned Socket ID: $socketId');
    });

    _socket.on('roomMembers', (roomMembers) {
      print('👥 Current Room Members: $roomMembers');
    });

    // ✅ Handle received messages and call the callback if set
    _socket.on('receiveMessage', (data) {
      if (_onMessageReceived != null) {
        _onMessageReceived!(data);
      } else {
        print('📩 New message received but no listener attached: $data');
      }
    });

    _socket.onDisconnect((_) {
      _isConnected = false;
      print('⚠️ Disconnected from socket server');
      _attemptReconnect(userName, userEmail);
    });

    _socket.onError((error) {
      print('❌ Socket Error: $error');
      _attemptReconnect(userName, userEmail);
    });

    _socket.connect();
  }

  // ✅ Set callback for receiving messages
  void onReceiveMessage(Function(Map<String, dynamic>) callback) {
    _onMessageReceived = callback;
  }

  // Attempt reconnection
  void _attemptReconnect(String userName, String userEmail) {
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      print(
          '🔄 Reconnecting... Attempt $_reconnectAttempts/$_maxReconnectAttempts');

      Future.delayed(_reconnectInterval, () {
        if (!_isConnected) {
          _socket.connect();
        }
      });
    } else {
      print('🚫 Max reconnection attempts reached.');
    }
  }

  // Send a message
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

  // Listen for incoming messages (alternative approach)
  void listenForMessages(Function(dynamic) onMessageReceived) {
    _socket.on('receiveMessage', (data) {
      onMessageReceived(data);
    });
  }

  // Get the list of online users
  void getOnlineUsers() {
    _socket.emit('roomMembers');
  }

  // Handle call initiation
  void initiateCall(String targetEmail, dynamic signalData, String senderEmail,
      String senderName) {
    _socket.emit('initiateCall', {
      'targetId': targetEmail,
      'signalData': signalData,
      'senderId': senderEmail,
      'senderName': senderName,
    });
  }

  // Listen for incoming calls
  void listenForIncomingCall(Function(dynamic) onIncomingCall) {
    _socket.on('incomingCall', (data) {
      onIncomingCall(data);
    });
  }

  // Handle answering a call
  void answerCall(String targetSocketId, String mediaType, bool mediaStatus) {
    _socket.emit('answerCall', {
      'to': targetSocketId,
      'mediaType': mediaType,
      'mediaStatus': mediaStatus,
    });
  }

  // Change media status (mute/unmute, video on/off)
  void changeMediaStatus(String mediaType, bool isActive) {
    _socket.emit('changeMediaStatus', {
      'mediaType': mediaType,
      'isActive': isActive,
    });
  }

  // Handle call termination
  void terminateCall(String targetEmail) {
    _socket.emit('terminateCall', {'targetId': targetEmail});
  }

  // Disconnect socket connection
  void disconnect() {
    if (_isConnected) {
      _socket.disconnect();
    }
  }
}
