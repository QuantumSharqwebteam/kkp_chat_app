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
  final Duration _reconnectInterval = const Duration(seconds: 5);
  //Timer? _roomMembersTimer;
  Function(Map<String, dynamic>)? _onMessageReceived;

  // Default value for chat page open state
  bool isChatPageOpen = false;

  bool _isLoggingOut = false;

  // Store room members (Now used for online users as well)
  List<String> _roomMembers = [];

  // Getter for room members (Online Users)
  List<String> get roomMembers => _roomMembers;

  // Store last seen timestamps
  Map<String, DateTime> lastSeenTimes = {};

  final StreamController<List<String>> _statusController =
      StreamController.broadcast();

  Stream<List<String>> get statusStream => _statusController.stream;
  SocketService._internal();

  void initSocket(String userName, String userEmail, String role) {
    _socket = io.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'reconnection': false,
    });

    _socket.onConnect((_) {
      _isConnected = true;
      _reconnectAttempts = 0;
      debugPrint('✅ Connected to socket server');
      _socket
          .emit('join', {'user': userName, 'userId': userEmail, "role": role});
    });

    _socket.on('socketId', (socketId) {
      debugPrint('📌 Assigned Socket ID: $socketId');
    });

    _socket.on('roomMembers', (roomMembers) {
      debugPrint('👥 Current Room Members: $roomMembers');
      _updateRoomMembers(List<String>.from(roomMembers));
    });

    _socket.on('receiveMessage', (data) {
      if (isChatPageOpen && _onMessageReceived != null) {
        _onMessageReceived!(data);
      } else {
        _showPushNotification(data);
      }
    });

    _socket.onDisconnect((_) {
      _isConnected = false;
      debugPrint('⚠️ Disconnected from socket server');
      if (!_isLoggingOut) {
        _attemptReconnect(userName, userEmail);
      }
    });

    _socket.onError((error) {
      debugPrint('❌ Socket Error: $error');
      if (!_isLoggingOut) {
        _attemptReconnect(userName, userEmail);
      }
    });

    _socket.connect();
  }

  // Update room members (Now also used for online users)
  void _updateRoomMembers(List<String> newRoomMembers) {
    Set<String> previousUsers = Set.from(_roomMembers);
    Set<String> currentUsers = Set.from(newRoomMembers);

    // Store last seen timestamps for offline users
    for (String email in previousUsers.difference(currentUsers)) {
      lastSeenTimes[email] = DateTime.now();
    }

    _roomMembers = newRoomMembers;

    // Force UI to refresh by emitting a new list instance
    _statusController.add(List.from(_roomMembers));
  }

  // //room members list every few seconds.
  // void startRoomMembersUpdates() {
  //   _roomMembersTimer?.cancel(); // Cancel any existing timer
  //   _roomMembersTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
  //     getRoomMembers(); // Fetch latest room members every 5 seconds
  //   });
  // }

  // void stopRoomMembersUpdates() {
  //   _roomMembersTimer?.cancel(); // Stop the timer when not needed
  // }

  // Request the latest room members list from the server
  void getRoomMembers() {
    _socket.emit('roomMembers');
  }

  // Check if a user is online from the room members list
  bool isUserOnline(String email) {
    bool isOnline = _roomMembers.contains(email);
    debugPrint("User $email online status: $isOnline");
    return isOnline;
  }

  // Get last seen time or online status
  String getLastSeenTime(String email) {
    if (_roomMembers.contains(email)) {
      return "Online";
    }

    DateTime? lastSeen = lastSeenTimes[email];
    if (lastSeen == null) return "Offline";

    Duration diff = DateTime.now().difference(lastSeen);
    if (diff.inSeconds < 60) {
      return "${diff.inSeconds}s ago";
    } else if (diff.inMinutes < 60) {
      return "${diff.inMinutes}m ago";
    } else if (diff.inHours < 24) {
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

  void _attemptReconnect(String userName, String userEmail) {
    if (!_isConnected && _reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      debugPrint(
          '🔄 Reconnecting... Attempt $_reconnectAttempts/$_maxReconnectAttempts');

      Future.delayed(_reconnectInterval, () {
        if (!_isConnected) {
          _socket.connect();
        }
      });
    } else {
      debugPrint('🚫 Max reconnection attempts reached or user logged out.');
    }
  }

  void sendMessage({
    required String targetEmail,
    required String message,
    required String senderEmail,
    required String senderName,
    String type = 'text',
    String? form,
    String? imageUrl,
  }) {
    if (_isConnected) {
      Map<String, dynamic> messageData = {
        'targetId': targetEmail,
        'message': message,
        'senderId': senderEmail,
        'senderName': senderName,
        'type': type,
      };

      if (form != null) {
        messageData['form'] = form;
      }

      if (imageUrl != null) {
        messageData['imageUrl'] = imageUrl;
      }

      _socket.emit('sendMessage', messageData);
    } else {
      debugPrint('Socket is not connected. Cannot send message.');
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

  void terminateCall(String targetEmail) {
    _socket.emit('terminateCall', {'targetId': targetEmail});
  }

  void disconnect() {
    if (_isConnected) {
      _socket.disconnect();
      debugPrint('🛑 Socket disconnected');
    }
  }

  void dispose() {
    _isLoggingOut = true;
    if (_isConnected) {
      _socket.disconnect();
      _isConnected = false;
      debugPrint('🛑 Socket disconnected');
    }

    _socket.clearListeners();
    _statusController.close();
    _reconnectAttempts = 0;

    debugPrint('🛑🛑 Socket service disposed completely');
  }

  void _showPushNotification(Map<String, dynamic> data) {
    debugPrint('🔔 Push Notification: New message received: $data');
  }

  void toggleChatPageOpen(bool toggle) {
    isChatPageOpen = toggle;
  }
}
