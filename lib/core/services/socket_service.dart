import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kkp_chat_app/data/local_storage/local_db_helper.dart';
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

  bool isChatPageOpen = false;
  List<String> _roomMembers = [];
  // Map<String, DateTime> lastSeenTimes = {};
  List<String> get onlineUsers => List.from(_roomMembers);

  StreamController<List<String>> _statusController =
      StreamController.broadcast();

  Stream<List<String>> get statusStream => _statusController.stream;

  SocketService._internal();

  void initSocket(String userName, String userEmail, String role) {
    _statusController.close(); // Ensure the old controller is closed
    _statusController =
        StreamController<List<String>>.broadcast(); // Re-initialize
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
      for (String email in _roomMembers) {
        LocalDbHelper.updateLastSeenTime(
            email); // ✅ Save last seen time in Hive
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

    // Mark users who went offline
    for (String email in previousUsers.difference(currentUsers)) {
      LocalDbHelper.updateLastSeenTime(email); // ✅ Store in Hive
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
    bool isOnline = _roomMembers.contains(email);
    // debugPrint("User $email online status: $isOnline");
    return isOnline;
  }

  void updateLastSeenTime(String email) {
    LocalDbHelper.updateLastSeenTime(email);
  }

  String getLastSeenTime(String email) {
    if (_roomMembers.contains(email)) {
      return "Online"; //  If online, show "Online"
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

  // Send offer or answer
  void initiateCall(String targetEmail, Map<String, dynamic> signalData,
      String senderEmail, String senderName) {
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

  void answerCall({
    required String targetSocketId,
    required Map<String, dynamic> answerData, // should include 'sdp' and 'type'
    String mediaType = 'audio',
    bool mediaStatus = true,
  }) {
    _socket.emit('answerCall', {
      'to': targetSocketId,
      'sdp': answerData['sdp'],
      'type': answerData['type'],
      'mediaType': mediaType,
      'mediaStatus': mediaStatus,
    });
  }

  void sendSignalCandidate(String targetId, Map<String, dynamic> candidate) {
    _socket.emit('signalCandidate', {
      'targetId': targetId,
      'candidate': candidate,
    });
  }

  void listenForSignalCandidate(Function(Map<String, dynamic>) callback) {
    _socket.on('signalCandidate', (data) {
      if (data is Map<String, dynamic>) {
        callback(data);
      } else if (data is Map) {
        callback(Map<String, dynamic>.from(data));
      } else {
        debugPrint("Invalid signalCandidate format: $data");
      }
    });
  }

  void listenForCallAnswered(Function(dynamic) callback) {
    _socket.on('callAnswered', callback);
  }

  void terminateCall(String targetEmail) {
    _socket.emit('terminateCall', {'targetId': targetEmail});
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

  void _showPushNotification(Map<String, dynamic> data) {
    debugPrint('🔔 Push Notification: New message received: $data');
  }

  void toggleChatPageOpen(bool toggle) {
    isChatPageOpen = toggle;
  }
}
