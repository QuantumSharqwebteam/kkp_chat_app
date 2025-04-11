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
  Function(dynamic)? _onIncomingCall;
  Function(Map<String, dynamic>)? _onCallAnswered;
  Function(Map<String, dynamic>)? _onSignalCandidate;
  Function(dynamic)? _onCallTerminated;
  bool isChatPageOpen = false;

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
      debugPrint('📞 Incoming Call Received: $data');
      _onIncomingCall?.call(data);
    });

    _socket.on('callAnswered', (data) {
      debugPrint('✅ Call Answered Received: $data');
      if (data is Map<String, dynamic> && data.containsKey('answer')) {
        _onCallAnswered?.call(data['answer']);
      } else {
        debugPrint('⚠️ Call Answered data format incorrect: $data');
      }
    });

    _socket.on('signalCandidate', (data) {
      debugPrint('🧊 Signal Candidate Received: $data');
      if (data is Map<String, dynamic> && data.containsKey('candidate')) {
        _onSignalCandidate?.call(data['candidate']);
      } else {
        debugPrint('⚠️ Signal Candidate data format incorrect: $data');
      }
    });

    _socket.on('callTerminated', (data) {
      debugPrint('❌ Call Terminated Received: $data');
      _onCallTerminated?.call(data);
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

  void terminateCall(String targetEmail) {
    debugPrint("📵 [CONNECTION] Terminating call with $targetEmail");
    _socket.emit('terminateCall', {'targetId': targetEmail});
  }

  void initiateCall(String targetEmail, Map<String, dynamic> offer,
      String selfId, String callerName) {
    if (!_isConnected) {
      debugPrint("📡 Socket not connected. Cannot initiate call.");
      return;
    }
    _socket.emit('initiateCall', {
      'targetId': targetEmail,
      'from': selfId,
      'callerName': callerName,
      'signal': offer,
    });
    debugPrint('🚀 Initiating call to $targetEmail');
  }

  void answerCall(
      {String? targetEmail, required Map<String, dynamic> answerData}) {
    if (!_isConnected) {
      debugPrint("📡 Socket not connected. Cannot answer call.");
      return;
    }
    _socket.emit('answerCall', {
      'to': targetEmail,
      'signal': answerData,
    });
    debugPrint('✅ Answering call to $targetEmail');
  }

  void sendSignalCandidate(String targetId, Map<String, dynamic> candidate) {
    if (!_isConnected) {
      debugPrint("📡 Socket not connected. Cannot send candidate.");
      return;
    }
    _socket.emit('signalCandidate', {
      'to': targetId,
      'candidate': candidate,
    });
    debugPrint('🧊 Sending candidate to $targetId: $candidate');
  }

  void listenForIncomingCall(Function(dynamic) callback) {
    _onIncomingCall = callback;
  }

  void listenForCallAnswered(Function(Map<String, dynamic>) callback) {
    _onCallAnswered = callback;
  }

  void listenForSignalCandidate(Function(Map<String, dynamic>) callback) {
    _onSignalCandidate = callback;
  }

  void listenForCallTerminated(Function(dynamic) callback) {
    _onCallTerminated = callback;
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
