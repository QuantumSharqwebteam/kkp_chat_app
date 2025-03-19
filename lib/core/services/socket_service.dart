import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:shared_preferences/shared_preferences.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  late io.Socket _socket;
  final String serverUrl = "https://video-call-server-gm7i.onrender.com";
  int retryCount = 0;
  static const int maxRetries = 5;
  String? socketId;

  Function(dynamic data)? onReceiveMessage;

  SocketService._internal();

  void initSocket() {
    _socket = io.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'reconnection': true, // Auto-reconnect enabled
      'reconnectionAttempts': maxRetries,
      'reconnectionDelay': 2000, // Delay between retries
    });

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

    _socket.on('socketId', (data) {
      debugPrint('Socket ID: $data');
      socketId = data;
    });

    _socket.on('receiveMessage', (data) {
      debugPrint('Received message: $data');
      if (onReceiveMessage != null) {
        onReceiveMessage!(data);
        //local save of chat will also be handled.
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

  void sendMessage(String targetId, String message, String senderName) {
    if (_socket.connected && targetId.isNotEmpty) {
      _socket.emit('sendMessage', {
        'targetId': targetId, // Ensure message is sent to the correct user
        'message': message,
        'senderName': senderName,
      });
    } else {
      saveMessage(message);
    }
  }

  void retrySendingMessages() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> pendingMessages = prefs.getStringList('pendingMessages') ?? [];

    for (String message in pendingMessages) {
      sendMessage('targetId', message, 'senderName');
    }

    pendingMessages.clear();
    await prefs.setStringList('pendingMessages', []);
  }

  void saveMessage(String message) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> pendingMessages = prefs.getStringList('pendingMessages') ?? [];
    pendingMessages.add(message);
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
