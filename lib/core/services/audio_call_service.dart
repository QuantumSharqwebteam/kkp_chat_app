import 'dart:developer';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'socket_service.dart';

class AudioCallService {
  static final AudioCallService _instance = AudioCallService._internal();
  factory AudioCallService() => _instance;

  final SocketService _socketService = SocketService();
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  List<RTCIceCandidate> _iceCandidates = [];

  AudioCallService._internal() {
    _initRenderers();
    _socketService.onIncomingCall(_handleIncomingCall);
    _socketService.onCallAnswered(_handleCallAnswered);
    _socketService.onCallTerminated(_handleCallTerminated);
    _socketService.onSignalCandidate(_handleSignalCandidate);
  }

  void _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  Future<void> initiateCall(
      String targetId, String senderId, String senderName) async {
    await _createPeerConnection();
    _localStream = await _getUserMedia();
    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });
    _localRenderer.srcObject = _localStream;

    RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    _socketService.initiateCall(
      targetId: targetId,
      signalData: offer.toMap(),
      senderId: senderId,
      senderName: senderName,
    );
  }

  Future<void> answerCall(String callerId, dynamic signalData) async {
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

    RTCSessionDescription answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    _socketService.answerCall(
      to: callerId,
      signalData: answer.toMap(),
    );
  }

  Future<void> _createPeerConnection() async {
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
    };

    _peerConnection!.onIceCandidate = (candidate) async {
      _iceCandidates.add(candidate);
      final remoteDescription = await _peerConnection!.getRemoteDescription();
      if (remoteDescription != null) {
        _socketService.signalCandidate(
          to: remoteDescription.sdp!.split(' ')[3],
          candidate: candidate.toMap(),
        );
      }
    };
  }

  Future<MediaStream> _getUserMedia() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': false,
    };
    MediaStream stream =
        await navigator.mediaDevices.getUserMedia(mediaConstraints);
    return stream;
  }

  void _handleIncomingCall(Map<String, dynamic> data) {
    // Handle incoming call notification
    log('Incoming call from ${data['from']}');
    // Show call UI and allow user to answer or reject the call
  }

  void _handleCallAnswered(Map<String, dynamic> data) async {
    RTCSessionDescription answer = RTCSessionDescription(
      data['sdpAnswer']['sdp'],
      data['sdpAnswer']['type'],
    );
    await _peerConnection!.setRemoteDescription(answer);

    for (RTCIceCandidate candidate in _iceCandidates) {
      _peerConnection!.addCandidate(candidate);
    }
  }

  void _handleCallTerminated(Map<String, dynamic> data) {
    // Handle call termination
    _peerConnection?.close();
    _localStream?.dispose();
    _localRenderer.srcObject = null;
    _remoteRenderer.srcObject = null;
    _iceCandidates.clear();
  }

  void _handleSignalCandidate(Map<String, dynamic> data) {
    RTCIceCandidate candidate = RTCIceCandidate(
      data['candidate']['candidate'],
      data['candidate']['sdpMid'],
      data['candidate']['sdpMLineIndex'],
    );
    _peerConnection!.addCandidate(candidate);
  }

  void terminateCall(String targetId) {
    _socketService.terminateCall(targetId: targetId);
    _handleCallTerminated({});
  }

  void dispose() {
    _peerConnection?.close();
    _localStream?.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
  }
}
