import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class AudioCallService {
  final io.Socket _socket;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  AudioCallService(this._socket) {
    _initPeerConnection();
  }

  void _initPeerConnection() {
    final config = {
      'iceServers': [
        {'url': 'stun:stun.l.google.com:19302'},
      ]
    };

    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
    };

    _createPeerConnection(config, mediaConstraints);
  }

  void _createPeerConnection(Map<String, dynamic> config,
      Map<String, dynamic> mediaConstraints) async {
    _peerConnection = await createPeerConnection(config);

    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });

    _peerConnection?.onIceCandidate = (candidate) {
      _socket.emit('candidate', candidate.toMap());
    };

    _peerConnection?.onTrack = (event) {
      if (event.track.kind == 'audio') {
        _remoteStream?.addTrack(event.track);
      }
    };
  }

  Future<void> createOffer(String targetId) async {
    final offer = await _peerConnection?.createOffer({});
    await _peerConnection?.setLocalDescription(offer!);
    _socket.emit('offer', {
      'targetId': targetId,
      'offer': offer?.toMap(),
    });
  }

  Future<void> handleOffer(dynamic offer) async {
    await _peerConnection?.setRemoteDescription(RTCSessionDescription(
      offer['sdp'],
      offer['type'],
    ));
    final answer = await _peerConnection?.createAnswer({});
    await _peerConnection?.setLocalDescription(answer!);
    _socket.emit('answer', answer?.toMap());
  }

  Future<void> handleAnswer(dynamic answer) async {
    await _peerConnection?.setRemoteDescription(RTCSessionDescription(
      answer['sdp'],
      answer['type'],
    ));
  }

  void handleCandidate(dynamic candidate) {
    final candidateMap = candidate as Map<String, dynamic>;
    final sdpMid = candidateMap['sdpMid'] as String?;
    final sdpMLineIndex = candidateMap['sdpMLineIndex'] as int?;

    final iceCandidate = RTCIceCandidate(
      candidateMap['candidate'],
      sdpMid,
      sdpMLineIndex,
    );

    _peerConnection?.addCandidate(iceCandidate);
  }

  void hangUp() {
    _socket.emit('hangUp');
    _peerConnection?.close();
    _localStream?.dispose();
    _remoteStream?.dispose();
    _peerConnection = null;
    _localStream = null;
    _remoteStream = null;
  }

  void dispose() {
    _peerConnection?.dispose();
    _localStream?.dispose();
    _remoteStream?.dispose();
  }
}
