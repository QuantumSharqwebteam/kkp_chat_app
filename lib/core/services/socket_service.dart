import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:kkp_chat_app/data/local_storage/local_db_helper.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  late io.Socket _socket;
  bool _isConnected = false;
  final String serverUrl = dotenv.env['SOCKET_IO_URL']!;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;
  final Duration _reconnectInterval = const Duration(seconds: 3);

  String? senderId;
  String? senderName;
  String? targetId;

  List<String> _roomMembers = [];
  late StreamController<List<String>> _statusController;
  Stream<List<String>> get statusStream => _statusController.stream;
  List<String> get onlineUsers => List.from(_roomMembers);

  Function(Map<String, dynamic>)? _onMessageReceived;
  Function(Map<String, dynamic>)? _onIncomingCall;
  Function(Map<String, dynamic>)? _onCallAnswered;
  Function(Map<String, dynamic>)? _onCallTerminated;
  Function(Map<String, dynamic>)? _onSignalCandidate;
  bool isChatPageOpen = false;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  // A set to keep track of ongoing offers
  final Set<String> _ongoingOffers = <String>{};

  SocketService._internal();

  void init(String userName, String userEmail, String role) {
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
      _socket.emit('join', {
        'user': userName,
        'userId': userEmail,
        'role': role,
      });
    });

    _socket.on('socketId', (socketId) {
      debugPrint('Assigned Socket ID: $socketId');
    });

    _socket.on('roomMembers', (roomMembers) {
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
      _onIncomingCall?.call(data);
    });

    _socket.on('callAnswered', (data) {
      _onCallAnswered?.call(data);
    });

    _socket.on('signalCandidate', (data) {
      _onSignalCandidate?.call(data);
      handleCandidate(data['candidate']);
    });

    _socket.on('callTerminated', (data) {
      _onCallTerminated?.call(data);
      hangUp();
    });

    _socket.onDisconnect((_) {
      _isConnected = false;
      for (String email in _roomMembers) {
        LocalDbHelper.updateLastSeenTime(email);
      }
      _attemptReconnect(userName, userEmail, role);
    });

    _socket.onError((error) {
      _attemptReconnect(userName, userEmail, role);
    });

    _socket.connect();
    _initPeerConnection();
  }

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

    _peerConnection?.close();
    _peerConnection = null;
    _localStream?.dispose();
    _localStream = null;
    _remoteStream?.dispose();
    _remoteStream = null;
  }

  void _showPushNotification(Map<String, dynamic> data) {
    debugPrint('Push Notification: New message received: $data');
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

  void _initPeerConnection() async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
        {'urls': 'stun:stun2.l.google.com:19302'},
        {'urls': 'stun:stun3.l.google.com:19302'},
        {'urls': 'stun:stun4.l.google.com:19302'},
      ],
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

    if (_peerConnection != null && _localStream != null) {
      for (var track in _localStream!.getTracks()) {
        _peerConnection!.addTrack(track, _localStream!);
      }
    }

    _peerConnection?.onIceCandidate = (candidate) {
      _socket.emit('signalCandidate', {
        'candidate': candidate.toMap(),
        'targetId': targetId,
      });
    };

    _peerConnection?.onTrack = (event) {
      if (event.track.kind == 'audio') {
        _remoteStream?.addTrack(event.track);
      }
    };
  }

  Future<void> createOffer(String to) async {
    // Check if an offer is already being processed for this target
    if (_ongoingOffers.contains(to)) {
      debugPrint('Offer already in progress for target: $to');
      return;
    }

    // Add the target to the ongoing offers set
    _ongoingOffers.add(to);
    targetId = to;

    try {
      final offer = await _peerConnection?.createOffer();
      if (offer == null) {
        debugPrint('Error: Failed to create offer.');
        _ongoingOffers.remove(to); // Remove target if offer creation fails
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
    } catch (e) {
      debugPrint('Error creating offer: $e');
    } finally {
      // Remove the target from the ongoing offers set after the offer is sent
      _ongoingOffers.remove(to);
    }
  }

  Future<void> handleOffer(dynamic offerData) async {
    if (_peerConnection == null) {
      debugPrint('Error: PeerConnection is null.');
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

        debugPrint('Answer sent to ${offerData['from']}');
      }
    } catch (e) {
      debugPrint('Error in handleOffer: $e');
    }
  }

  Future<void> handleAnswer(dynamic answer) async {
    try {
      final signal = answer['signal'];
      if (signal == null || signal['sdp'] == null || signal['type'] == null) {
        debugPrint('Invalid answer signal data');
        return;
      }
      await _peerConnection?.setRemoteDescription(
        RTCSessionDescription(signal['sdp'], signal['type']),
      );
      debugPrint('Answer handled successfully');
    } catch (e) {
      debugPrint('Error handling answer: $e');
    }
  }

  void handleCandidate(dynamic candidate) {
    try {
      final c = RTCIceCandidate(
        candidate['candidate'],
        candidate['sdpMid'],
        candidate['sdpMLineIndex'],
      );
      _peerConnection?.addCandidate(c);
      debugPrint('ICE candidate added successfully');
    } catch (e) {
      debugPrint('Error adding ICE candidate: $e');
    }
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
