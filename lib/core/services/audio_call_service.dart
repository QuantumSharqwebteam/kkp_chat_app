import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'socket_service.dart';

class AudioCallService {
  static final AudioCallService _instance = AudioCallService._internal();
  factory AudioCallService() => _instance;

  final SocketService _socketService = SocketService();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  final List<RTCIceCandidate> _iceCandidates = [];

  AudioCallService._internal() {
    _initRenderers();
    _socketService.onIncomingCall(_handleIncomingCall);
    _socketService.onCallAnswered(_handleCallAnswered);
    _socketService.onCallTerminated(_handleCallTerminated);
    _socketService.onSignalCandidate(_handleSignalCandidate);
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    debugPrint('📹 Local and remote renderers initialized');
  }

  Future<void> initiateCall(
      String targetId, String senderId, String senderName) async {
    try {
      debugPrint('📞 Initiating call to $targetId');
      await _initRenderers();
      await _createPeerConnection();
      _localStream = await _getUserMedia();
      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });
      _localRenderer.srcObject = _localStream;

      RTCSessionDescription offer = await _peerConnection!.createOffer({});
      await _peerConnection!.setLocalDescription(offer);

      _socketService.initiateCall(
        targetId: targetId,
        signalData: offer.toMap(),
        senderId: senderId,
        senderName: senderName,
      );
      debugPrint('📢 Offer sent to $targetId');
    } catch (e) {
      debugPrint('⚠️ Error initiating call: $e');
    }
  }

  Future<void> answerCall(String callerId, dynamic signalData) async {
    try {
      debugPrint('📞 Answering call from $callerId');
      await _initRenderers();
      await _createPeerConnection();
      _localStream = await _getUserMedia();
      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });
      _localRenderer.srcObject = _localStream;

      RTCSessionDescription offer = RTCSessionDescription(
        signalData['sdp'],
        signalData['type'],
      );
      await _peerConnection!.setRemoteDescription(offer);

      RTCSessionDescription answer = await _peerConnection!.createAnswer({});
      await _peerConnection!.setLocalDescription(answer);

      _socketService.answerCall(
        to: callerId,
        signalData: answer.toMap(),
      );
      debugPrint('📢 Answer sent to $callerId');
    } catch (e) {
      debugPrint('⚠️ Error answering call: $e');
    }
  }

  Future<void> _createPeerConnection() async {
    try {
      _peerConnection = await createPeerConnection({
        'iceServers': [
          {
            'urls': [
              'stun:stun1.l.google.com:19302',
              'stun:stun2.l.google.com:19302'
            ]
          }
        ]
      });

      _peerConnection!.onTrack = (event) {
        _remoteRenderer.srcObject = event.streams[0];
        debugPrint('🎥 Remote track added');
      };

      _peerConnection!.onIceCandidate = (candidate) async {
        _iceCandidates.add(candidate);
        final remoteDescription = await _peerConnection!.getRemoteDescription();
        if (remoteDescription != null && remoteDescription.sdp != null) {
          _socketService.signalCandidate(
            to: remoteDescription.sdp!.split(' ')[3],
            candidate: candidate.toMap(),
          );
          debugPrint('🧊 ICE candidate signaled');
        } else {
          debugPrint('⚠️ Remote description or SDP is null');
        }
      };

      _peerConnection!.onConnectionState = (state) {
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          debugPrint('⚠️ Peer connection failed');
          _handleCallTerminated({});
        }
      };

      debugPrint('🔗 Peer connection created');
    } catch (e) {
      debugPrint('⚠️ Error creating peer connection: $e');
    }
  }

  Future<MediaStream> _getUserMedia() async {
    try {
      final Map<String, dynamic> mediaConstraints = {
        'audio': true,
        'video': false,
      };
      MediaStream stream =
          await navigator.mediaDevices.getUserMedia(mediaConstraints);
      debugPrint('🎤 Local media stream obtained');
      return stream;
    } catch (e) {
      debugPrint('⚠️ Error getting user media: $e');
      rethrow;
    }
  }

  void _handleIncomingCall(Map<String, dynamic> data) {
    try {
      debugPrint('📞 Incoming call from ${data['from']}');
      // Show call UI and allow user to answer or reject the call
    } catch (e) {
      debugPrint('⚠️ Error handling incoming call: $e');
    }
  }

  void _handleCallAnswered(Map<String, dynamic> data) async {
    try {
      RTCSessionDescription answer = RTCSessionDescription(
        data['sdpAnswer']['sdp'],
        data['sdpAnswer']['type'],
      );
      await _peerConnection!.setRemoteDescription(answer);
      debugPrint('📢 Call answered, remote description set');

      for (RTCIceCandidate candidate in _iceCandidates) {
        _peerConnection!.addCandidate(candidate);
      }
    } catch (e) {
      debugPrint('⚠️ Error setting remote description: $e');
    }
  }

  void _handleCallTerminated(Map<String, dynamic> data) {
    try {
      debugPrint('📞 Call terminated');
      _peerConnection?.close();
      _localStream?.dispose();
      _localRenderer.dispose();
      _remoteRenderer.dispose();
      _iceCandidates.clear();
      debugPrint('🔄 Resources disposed');
    } catch (e) {
      debugPrint('⚠️ Error handling call termination: $e');
    }
  }

  void _handleSignalCandidate(Map<String, dynamic> data) {
    try {
      RTCIceCandidate candidate = RTCIceCandidate(
        data['candidate']['candidate'],
        data['candidate']['sdpMid'],
        data['candidate']['sdpMLineIndex'],
      );
      _peerConnection!.addCandidate(candidate);
      debugPrint('🧊 ICE candidate added');
    } catch (e) {
      debugPrint('⚠️ Error adding ICE candidate: $e');
    }
  }

  void terminateCall(String targetId) {
    try {
      _socketService.terminateCall(targetId: targetId);
      _handleCallTerminated({});
      debugPrint('📞 Terminating call to $targetId');
    } catch (e) {
      debugPrint('⚠️ Error terminating call: $e');
    }
  }

  void dispose() {
    try {
      _peerConnection?.close();
      _localStream?.dispose();
      _localRenderer.dispose();
      _remoteRenderer.dispose();
      debugPrint('🔄 AudioCallService disposed');
    } catch (e) {
      debugPrint('⚠️ Error disposing AudioCallService: $e');
    }
  }
}
