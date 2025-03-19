import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:shared_preferences/shared_preferences.dart';

class SocketService {
  io.Socket? socket;
  final String serverUrl = "https://video-call-server-gm7i.onrender.com";
  int retryCount = 0;
  static const int maxRetries = 3;
  late String socketId;

  // Callback to handle received messages
  Function(dynamic data)? onReceiveMessage;

  void connect() async {
    socket = io.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket!.onConnect((_) {
      print('Connected to server');
      retryCount = 0; // Reset retry count on successful connection
      socketId = socket!.id!; // Store the socket ID
      retrySendingMessages();
    });

    socket!.onConnectError((error) {
      print('Connection error: $error');
      handleReconnect();
    });

    socket!.onDisconnect((_) {
      print('Disconnected from server');
      handleReconnect();
    });

    socket!.on('socketId', (data) {
      print('Socket ID: $data');
      socketId = data;
    });

    socket!.on('receiveMessage', (data) {
      print('Received message: $data');
      if (onReceiveMessage != null) {
        onReceiveMessage!(data);
        //local save of chat will also be handled.
      }
    });

    await _tryConnect();
  }

  Future<void> _tryConnect() async {
    try {
      socket!.connect();
    } catch (e) {
      print('Failed to connect: $e');
      handleReconnect();
    }
  }

  void handleReconnect() async {
    retryCount++;
    if (retryCount <= maxRetries) {
      print('Retrying connection... Attempt $retryCount');
      await Future.delayed(Duration(seconds: 2)); // Wait before retrying
      _tryConnect();
    } else {
      print('Max retry attempts reached. Connection failed.');
    }
  }

  void sendMessage(String targetId, String message, String senderName) {
    if (socket!.connected) {
      socket!.emit('sendMessage',
          {'targetId': targetId, 'message': message, 'senderName': senderName});
    } else {
      saveMessage(message);
    }
  }

  void disconnect() {
    socket!.disconnect();
  }

  void retrySendingMessages() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> pendingMessages = prefs.getStringList('pendingMessages') ?? [];

    for (String message in pendingMessages) {
      sendMessage('targetId', message,
          'senderName'); // Replace with actual targetId and senderName
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
}
