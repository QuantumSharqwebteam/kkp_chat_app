import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:kkp_chat_app/core/services/socket_service.dart';

typedef OnCallConnected = void Function();
typedef OnCallEnded = void Function(bool isPeerHangup);
typedef OnError = void Function(String message);

class VoiceCallService {
  final String selfId;
  final String? targetId;
  final bool isCaller;
  final String? callerName;
  final SocketService _socketService = SocketService();

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  OnCallConnected? onCallConnected;
  OnCallEnded? onCallEnded;
  OnError? onError;

  VoiceCallService({
    required this.selfId,
    this.targetId,
    required this.isCaller,
    this.callerName,
  });

  MediaStream? get localStream => _localStream;

  Future<void> init() async {
    try {
      await _createPeerConnection();
      await _setupLocalMedia();
      _setupSocketListeners();

      if (isCaller) {
        await _makeOffer();
      }
    } catch (e) {
      onError?.call("Call initialization failed: $e");
    }
  }

  Future<void> initWithOffer(Map<String, dynamic> offer) async {
    try {
      await _createPeerConnection();
      await _setupLocalMedia();
      _setupSocketListeners();

      if (!isCaller && offer.isNotEmpty) {
        await _handleOffer(offer);
      }
    } catch (e) {
      onError?.call("Call initialization with offer failed: $e");
    }
  }

  Future<void> _createPeerConnection() async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'}
      ],
    };

    _peerConnection = await createPeerConnection(config);

    _peerConnection!.onIceCandidate = (candidate) {
      _socketService.sendSignalCandidate(targetId!, candidate.toMap());
    };

    _peerConnection!.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        onCallConnected?.call();
      } else if ([
        RTCPeerConnectionState.RTCPeerConnectionStateDisconnected,
        RTCPeerConnectionState.RTCPeerConnectionStateFailed,
        RTCPeerConnectionState.RTCPeerConnectionStateClosed,
      ].contains(state)) {
        onCallEnded?.call(false);
      }
    };

    _peerConnection!.onTrack = (event) {
      // Handle remote audio if needed
    };
  }

  Future<void> _setupLocalMedia() async {
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });

    for (var track in _localStream!.getAudioTracks()) {
      await _peerConnection?.addTrack(track, _localStream!);
    }
  }

  Future<void> _makeOffer() async {
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    _socketService.initiateCall(
      targetId!,
      offer.toMap(),
      selfId,
      callerName ?? "Unknown",
    );
  }

  Future<void> _handleOffer(Map<String, dynamic> offer) async {
    final desc = RTCSessionDescription(offer['sdp'], offer['type']);
    await _peerConnection!.setRemoteDescription(desc);
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    _socketService.answerCall(
      targetEmail: targetId,
      answerData: answer.toMap(),
    );
  }

  void _setupSocketListeners() {
    _socketService.listenForCallAnswered((answer) async {
      if (!isCaller) return;
      final desc = RTCSessionDescription(answer['sdp'], answer['type']);
      await _peerConnection?.setRemoteDescription(desc);
    });

    _socketService.listenForSignalCandidate((candidateMap) {
      final candidate = RTCIceCandidate(
        candidateMap['candidate'],
        candidateMap['sdpMid'],
        candidateMap['sdpMLineIndex'],
      );
      _peerConnection?.addCandidate(candidate);
    });

    _socketService.listenForCallTerminated((_) {
      onCallEnded?.call(true);
    });

    _socketService.listenForIncomingCall((data) async {
      if (_peerConnection == null || isCaller) return;

      final signal = data['signal'];
      if (signal['sdp'] != null && signal['type'] != null) {
        await _handleOffer(signal);
        onCallConnected?.call();
      }
    });
  }

  void toggleMute(bool isMuted) {
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = !isMuted;
    });
  }

  Future<void> toggleSpeaker(bool isSpeakerOn) async {
    await Helper.setSpeakerphoneOn(isSpeakerOn);
  }

  void endCall() {
    _peerConnection?.close();
    _peerConnection = null;

    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _localStream = null;

    _socketService.terminateCall(targetId!);
    onCallEnded?.call(false);
  }
}
