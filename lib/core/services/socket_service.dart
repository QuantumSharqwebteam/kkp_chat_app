import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kkp_chat_app/data/local_storage/local_db_helper.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Combined service for chat (Socket.IO) and WebRTC audio calls
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  // Socket.IO
  late io.Socket _socket;
  bool _isConnected = false;
  final String serverUrl = dotenv.env['SOCKET_IO_URL']!;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;
  final Duration _reconnectInterval = const Duration(seconds: 3);

  // User info
  String? senderId;
  String? senderName;
  String? targetId;

  // Room members tracking
  List<String> _roomMembers = [];
  late StreamController<List<String>> _statusController;
  Stream<List<String>> get statusStream => _statusController.stream;
  List<String> get onlineUsers => List.from(_roomMembers);

  // Chat callbacks
  Function(Map<String, dynamic>)? _onMessageReceived;
  Function(Map<String, dynamic>)? _onIncomingCall;
  Function(Map<String, dynamic>)? _onCallAnswered;
  Function(Map<String, dynamic>)? _onCallTerminated;
  Function(Map<String, dynamic>)? _onSignalCandidate;
  bool isChatPageOpen = false;

  // WebRTC
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  SocketService._internal();

  /// Initialize both Socket.IO and WebRTC peer connection
  void init(String userName, String userEmail, String role) {
    // Setup status stream
    _statusController = StreamController<List<String>>.broadcast();

    // Initialize Socket.IO
    _socket = io.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'reconnection': false,
    });

    senderId = userEmail;
    senderName = userName;

    // Socket events
    _socket.onConnect((_) {
      _isConnected = true;
      _reconnectAttempts = 0;
      debugPrint('✅ Connected to socket server');
      _socket.emit('join', {
        'user': userName,
        'userId': userEmail,
        'role': role,
      });
    });

    _socket.on('socketId', (socketId) {
      debugPrint('📌 Assigned Socket ID: $socketId');
    });

    _socket.on('roomMembers', (roomMembers) {
      debugPrint('👥 Current Room Members: $roomMembers');
      _updateRoomMembers(List<String>.from(roomMembers));
    });

    // Chat message
    _socket.on('receiveMessage', (data) {
      if (isChatPageOpen && _onMessageReceived != null) {
        _onMessageReceived!(data);
      } else {
        _showPushNotification(data);
      }
    });

    // Audio call signaling events

    _socket.on('incomingCall', (data) {
      debugPrint('📥 incomingCall: $data');
      _onIncomingCall?.call(data);
      if (data != null) {
        handleOffer(data);
      } else {
        debugPrint('Error: signalData is null in incomingCall.');
      }
    });

    _socket.on('callAnswered', (data) {
      debugPrint('📥 callAnswered: $data');
      _onCallAnswered?.call(data);
      if (data != null) {
        handleAnswer(data);
      } else {
        debugPrint('Error: signalData is null in callAnswered.');
      }
    });

    _socket.on('signalCandidate', (data) {
      debugPrint('📥 signalCandidate: $data');
      _onSignalCandidate?.call(data);
      handleCandidate(data['candidate']);
    });

    _socket.on('callTerminated', (data) {
      debugPrint('📥 callTerminated');
      _onCallTerminated?.call(data);
      hangUp();
    });

    // Error & disconnect
    _socket.onDisconnect((_) {
      _isConnected = false;
      for (String email in _roomMembers) {
        LocalDbHelper.updateLastSeenTime(email);
      }
      debugPrint('⚠️ Disconnected from socket server');
      _attemptReconnect(userName, userEmail, role);
    });

    _socket.onError((error) {
      debugPrint('❌ Socket Error: $error');
      _attemptReconnect(userName, userEmail, role);
    });

    _socket.connect();

    // Initialize WebRTC peer connection
    _initPeerConnection();
  }

  // ======================== Chat Methods ========================

  void _updateRoomMembers(List<String> newMembers) {
    if (_statusController.isClosed) return;
    Set<String> prev = Set.from(_roomMembers);
    Set<String> curr = Set.from(newMembers);
    for (String email in prev.difference(curr)) {
      LocalDbHelper.updateLastSeenTime(email);
    }
    _roomMembers = newMembers;
    _statusController.add(List.from(_roomMembers));
  }

  void getRoomMembers() => _socket.emit('roomMembers');
  bool isUserOnline(String email) => _roomMembers.contains(email);
  void updateLastSeenTime(String email) =>
      LocalDbHelper.updateLastSeenTime(email);
  String getLastSeenTime(String email) {
    if (_roomMembers.contains(email)) return 'Online';
    DateTime? lastSeen = LocalDbHelper.getLastSeenTime(email);
    if (lastSeen == null) return 'Not Available';
    final diff = DateTime.now().difference(lastSeen);
    if (diff.inSeconds < 30) return 'Just now';
    if (diff.inMinutes < 1) return 'Few seconds ago';
    if (diff.inMinutes == 1) return '1 min ago';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inHours == 1) return '1 hour ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  void onReceiveMessage(Function(Map<String, dynamic>) cb) =>
      _onMessageReceived = cb;
  void onIncomingCall(Function(Map<String, dynamic>) cb) =>
      _onIncomingCall = cb;
  void onCallAnswered(Function(Map<String, dynamic>) cb) =>
      _onCallAnswered = cb;
  void onCallTerminated(Function(Map<String, dynamic>) cb) =>
      _onCallTerminated = cb;
  void onSignalCandidate(Function(Map<String, dynamic>) cb) =>
      _onSignalCandidate = cb;
  void toggleChatPageOpen(bool open) => isChatPageOpen = open;

  void sendMessage({
    String? targetEmail,
    String? message,
    required String senderEmail,
    required String senderName,
    String type = 'text',
    Map<String, dynamic>? form,
    String? mediaUrl,
  }) {
    if (!_isConnected) {
      debugPrint('Socket is not connected. Cannot send message.');
      return;
    }
    final data = {
      'senderId': senderEmail,
      'senderName': senderName,
      'type': type,
      if (targetEmail != null) 'targetId': targetEmail,
      if (message != null) 'message': message,
      if (form != null) 'form': form,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
    };
    _socket.emit('sendMessage', data);
  }

  void disconnect() {
    if (_isConnected) {
      _socket.disconnect();
      _isConnected = false;
    }
  }

  void dispose() {
    if (_isConnected) {
      _socket.clearListeners();
      _statusController.close();
      _socket.disconnect();
      _isConnected = false;
    } else {
      _socket.clearListeners();
      _reconnectAttempts = _maxReconnectAttempts;
    }
    _peerConnection?.dispose();
    _localStream?.dispose();
    _remoteStream?.dispose();
  }

  void _showPushNotification(Map<String, dynamic> data) {
    debugPrint('🔔 Push Notification: New message received: $data');
  }

  void _attemptReconnect(String userName, String userEmail, String role) {
    if (!_isConnected && _reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      Future.delayed(_reconnectInterval, () {
        if (!_isConnected) {
          _socket.connect();
          _socket.emit('join', {
            'user': userName,
            'userId': userEmail,
            'role': role,
          });
        }
      });
    }
  }

  // ======================== WebRTC Methods ========================

  void _initPeerConnection() async {
    final config = {
      'iceServers': [
        {'url': 'stun:stun.l.google.com:19302'},
      ]
    };
    final Map<String, dynamic> mediaConstraints = {
      'audio': {
        'mandatory': {
          'echoCancellation': 'true',
          'googEchoCancellation': 'true',
          'googNoiseSuppression': 'true',
        },
        'optional': [],
      }
    };
    _peerConnection = await createPeerConnection(config);
    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    _remoteStream = await createLocalMediaStream('remote');

    // Add local tracks
    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });

    // ICE candidate handling
    _peerConnection?.onIceCandidate = (candidate) {
      _socket.emit('signalCandidate', {
        'candidate': candidate.toMap(),
        'targetId': targetId,
      });
    };

    // Remote track handling
    _peerConnection?.onTrack = (event) {
      if (event.track.kind == 'audio') {
        _remoteStream?.addTrack(event.track);
      }
    };
  }

  Future<void> createOffer(String to) async {
    targetId = to;
    final offer = await _peerConnection?.createOffer();
    if (offer == null) {
      debugPrint('Error: Failed to create offer.');
      return;
    }
    await _peerConnection?.setLocalDescription(offer);
    _socket.emit('initiateCall', {
      'targetId': to,
      'signalData': offer.toMap(),
      'senderId': senderId,
      'senderName': senderName,
    });
    debugPrint('Offer sent to $to: sdp=${offer.sdp}, type=${offer.type}');
  }

  Future<void> handleOffer(dynamic offerData) async {
    if (_peerConnection == null) {
      debugPrint('Error: PeerConnection is null.');
      return;
    }

    // Guard: do not handle offer if already in stable state
    if (_peerConnection!.signalingState ==
        RTCSignalingState.RTCSignalingStateStable) {
      debugPrint('🔄 Skipping handleOffer: Already in stable state.');
      return;
    }

    try {
      final offer = RTCSessionDescription(
          offerData['signal']['sdp'], offerData['signal']['type']);

      await _peerConnection?.setRemoteDescription(offer);

      final answer = await _peerConnection?.createAnswer();
      if (answer != null) {
        await _peerConnection?.setLocalDescription(answer);

        _socket.emit('answerCall', {
          'to': offerData['from'],
          'signalData': answer.toMap(),
        });

        debugPrint('✅ Answer sent to ${offerData['from']}');
      }
    } catch (e) {
      debugPrint('❌ Error in handleOffer: $e');
    }
  }

  Future<void> handleAnswer(dynamic answer) async {
    await _peerConnection?.setRemoteDescription(
      RTCSessionDescription(answer['sdp'], answer['type']),
    );
  }

  void handleCandidate(dynamic candidate) {
    final c = RTCIceCandidate(
      candidate['candidate'],
      candidate['sdpMid'],
      candidate['sdpMLineIndex'],
    );
    _peerConnection?.addCandidate(c);
  }

  void hangUp() {
    _socket.emit('terminateCall', {
      'targetId': targetId,
    });
    _peerConnection?.close();
    _localStream?.dispose();
    _remoteStream?.dispose();
    _peerConnection = null;
    _localStream = null;
    _remoteStream = null;
  }
}
