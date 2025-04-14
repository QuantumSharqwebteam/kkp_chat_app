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
  Function(Map<String, dynamic>)? _onIncomingCall;
  Function(Map<String, dynamic>)? _onCallAnswered;
  Function(Map<String, dynamic>)? _onCallTerminated;
  Function(Map<String, dynamic>)? _onSignalCandidate;
  bool isChatPageOpen = false;

  io.Socket get socket => _socket;

  String? senderId;
  String? senderName;
  String? targetId;

  List<String> _roomMembers = [];
  StreamController<List<String>> _statusController =
      StreamController<List<String>>.broadcast();

  Stream<List<String>> get statusStream => _statusController.stream;

  List<String> get onlineUsers => List.from(_roomMembers);

  SocketService._internal();

  void initSocket(String userName, String userEmail, String role) {
    _statusController.close();
    _statusController = StreamController<List<String>>.broadcast();
    _socket = io.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'reconnection': false,
    });

    senderId = userEmail;
    senderName = userName;

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

    _socket.on('incomingCall', (data) {
      debugPrint('📥 incomingCall: $data'); // ✅ Log full structure
      if (_onIncomingCall != null) {
        _onIncomingCall!(data);
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
      debugPrint('📥 signalCandidate: $data'); // ✅
      if (_onSignalCandidate != null) {
        _onSignalCandidate!(data);
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
    _onSignalCandidate = callback;
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

  void _showPushNotification(Map<String, dynamic> data) {
    debugPrint('🔔 Push Notification: New message received: $data');
  }

  void toggleChatPageOpen(bool toggle) {
    isChatPageOpen = toggle;
  }
}
