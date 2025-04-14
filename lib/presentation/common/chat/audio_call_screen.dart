import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:kkp_chat_app/core/services/socket_service.dart';

enum CallDirection { receivingCall, requestingCall }

class AudioCallScreenArgs {
  final String remoteUserFullName;
  final String remoteUserId;
  final String senderEmail;
  final String senderName;
  final CallDirection callDirection;
  final Map<String, dynamic>? signalData;

  AudioCallScreenArgs({
    required this.callDirection,
    required this.remoteUserFullName,
    required this.remoteUserId,
    required this.senderEmail,
    required this.senderName,
    this.signalData,
  });
}

class AudioCallScreen extends StatefulWidget {
  final AudioCallScreenArgs args;

  const AudioCallScreen({super.key, required this.args});

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  final SocketService _socketService = SocketService();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  bool _isSpeakerOn = false;
  bool _isCallRunning = false;

  @override
  void initState() {
    super.initState();
    _initialize();

    // 👇 Listen for remote ICE candidates
    _socketService.onSignalCandidate((candidate) async {
      debugPrint('🧊 Received remote ICE candidate');
      try {
        await _peerConnection?.addCandidate(
          RTCIceCandidate(
            candidate['candidate'],
            candidate['sdpMid'],
            candidate['sdpMLineIndex'],
          ),
        );
      } catch (e) {
        debugPrint('⚠️ Failed to add candidate: $e');
      }
    });
  }

  Future<void> _initialize() async {
    await _localRenderer.initialize();
    if (widget.args.callDirection == CallDirection.requestingCall) {
      await _initiateCall();
    } else {
      await _answerCall();
    }
  }

  Future<void> _initiateCall() async {
    try {
      await _createPeerConnection();
      await _getUserMedia();
      final offer = await _peerConnection!.createOffer({
        'offerToReceiveAudio': true,
      });
      await _peerConnection!.setLocalDescription(offer);

      _socketService.initiateCall(
        targetId: widget.args.remoteUserId,
        signalData: offer.toMap(),
        senderId: widget.args.senderEmail,
        senderName: widget.args.senderName,
      );
      setState(() {
        _isCallRunning = true;
      });
    } catch (e) {
      debugPrint('⚠️ Error initiating call: $e');
    }
  }

  Future<void> _answerCall() async {
    try {
      await _createPeerConnection();
      await _getUserMedia();

      // ⬇️ Set the offer received from the caller
      final remoteOffer = RTCSessionDescription(
        widget.args.signalData!['sdp'],
        widget.args.signalData!['type'],
      );
      await _peerConnection!.setRemoteDescription(remoteOffer);

      // ⬇️ Now create and send the answer
      final answer = await _peerConnection!.createAnswer({
        'offerToReceiveAudio': true,
      });
      await _peerConnection!.setLocalDescription(answer);

      _socketService.answerCall(
        to: widget.args.remoteUserId,
        signalData: answer.toMap(),
      );

      setState(() {
        _isCallRunning = true;
      });
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
        debugPrint('🎥 Remote track added');
        if (event.track.kind == 'audio') {
          _remoteStream = event.streams.first;
          debugPrint('🔊 Remote audio stream assigned');
          debugPrint(
              '🔊 Remote audio tracks: ${_remoteStream?.getAudioTracks().length}');
        }
      };

      _peerConnection!.onIceCandidate = (candidate) {
        debugPrint('📡 Sending ICE candidate');
        _socketService.signalCandidate(
          to: widget.args.remoteUserId,
          candidate: {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        );
      };

      _peerConnection!.onConnectionState = (state) {
        debugPrint('🔌 Connection state: $state');
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          debugPrint('⚠️ Peer connection failed');
          _handleCallTerminated();
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
        'audio': {
          'mandatory': {
            'echoCancellation': 'true',
            'googEchoCancellation': 'true',
            'googEchoCancellation2': 'true',
            'googNoiseSuppression': 'true',
            'googDAEchoCancellation': 'true',
          },
          'optional': [],
        },
      };
      MediaStream stream =
          await navigator.mediaDevices.getUserMedia(mediaConstraints);
      debugPrint('🎤 Local media stream obtained');
      debugPrint('🔍 Local audio tracks: ${stream.getAudioTracks().length}');
      _localStream = stream;
      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });
      _localRenderer.srcObject = _localStream;
      return stream;
    } catch (e) {
      debugPrint('⚠️ Error getting user media: $e');
      rethrow;
    }
  }

  void _handleCallTerminated() {
    try {
      _peerConnection?.close();
      _localStream?.dispose();
      _remoteStream?.dispose();
      _localRenderer.dispose();
      setState(() {
        _isCallRunning = false;
      });
      Navigator.of(context).pop();
      debugPrint('🔄 Resources disposed');
    } catch (e) {
      debugPrint('⚠️ Error handling call termination: $e');
    }
  }

  void _endCall() {
    _socketService.terminateCall(targetId: widget.args.remoteUserId);
    _handleCallTerminated();
  }

  void _toggleSpeaker() async {
    _isSpeakerOn = !_isSpeakerOn;
    await Helper.setSpeakerphoneOn(_isSpeakerOn);
    setState(() {});
  }

  @override
  void dispose() {
    _peerConnection?.close();
    _localStream?.dispose();
    _remoteStream?.dispose();
    _localRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Call with ${widget.args.remoteUserFullName}'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isCallRunning ? 'In Call...' : 'Calling...',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(_isSpeakerOn ? Icons.volume_up : Icons.hearing),
              label: Text(_isSpeakerOn ? 'Speaker On' : 'Speaker Off'),
              onPressed: _toggleSpeaker,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.call_end),
              label: Text('End Call'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: _endCall,
            ),
          ],
        ),
      ),
    );
  }
}
