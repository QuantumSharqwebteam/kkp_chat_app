import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/core/services/socket_service.dart';

import 'dart:async';

class AudioCallScreen extends StatefulWidget {
  final String targetId;
  final String selfId;
  final bool isCaller;

  const AudioCallScreen({
    super.key,
    required this.targetId,
    required this.selfId,
    required this.isCaller,
  });

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  Timer? _callTimer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _initCall();
  }

  Future<void> _initCall() async {
    await WebRTC.initialize(); // required once app-wide
    await _createPeerConnection();
    await _setupMediaStream();
    _setupSocketListeners();

    if (widget.isCaller) {
      await _makeOffer();
    }
  }

  Future<void> _createPeerConnection() async {
    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    _peerConnection = await createPeerConnection(configuration);

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      SocketService().sendSignalCandidate(widget.targetId, candidate.toMap());
    };
  }

  Future<void> _setupMediaStream() async {
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });

    for (var track in _localStream!.getTracks()) {
      await _peerConnection?.addTrack(track, _localStream!);
    }
  }

  Future<void> _makeOffer() async {
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    SocketService().initiateCall(
      widget.targetId,
      offer.toMap(),
      widget.selfId,
      "Caller Name",
    );
  }

  void _setupSocketListeners() {
    SocketService().listenForIncomingCall((data) async {
      final offer = RTCSessionDescription(
        data['signal']['sdp'],
        data['signal']['type'],
      );

      await _peerConnection?.setRemoteDescription(offer);

      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      SocketService().answerCall(
        targetSocketId: data['from'],
        answerData: answer.toMap(),
      );

      _startCallTimer(); // Start timer after answering
    });

    SocketService().listenForCallAnswered((answerMap) async {
      final answer = RTCSessionDescription(
        answerMap['sdp'],
        answerMap['type'],
      );

      await _peerConnection?.setRemoteDescription(answer);

      _startCallTimer(); // Start timer after receiving answer
    });

    SocketService().listenForSignalCandidate((candidateMap) {
      final candidate = RTCIceCandidate(
        candidateMap['candidate'],
        candidateMap['sdpMid'],
        candidateMap['sdpMLineIndex'],
      );
      _peerConnection?.addCandidate(candidate);
    });
  }

  void _startCallTimer() {
    if (_callTimer != null && _callTimer!.isActive) return;

    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  String _formattedDuration() {
    final minutes = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _hangUp() {
    _callTimer?.cancel();
    SocketService().terminateCall(widget.targetId);
    _peerConnection?.close();
    _localStream?.dispose();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _peerConnection?.close();
    _localStream?.dispose();
    _callTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(height: 10),
            Column(
              children: [
                Text(
                  widget.targetId,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  _formattedDuration(),
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
            const CircleAvatar(
              radius: 70,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.black60opac),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: () {
                      //  Speaker toggle logic
                    },
                    icon: const Icon(Icons.volume_up, color: Colors.white),
                    color: Colors.grey[800],
                    iconSize: 28,
                  ),
                  IconButton(
                    onPressed: () {
                      // Mute/unmute logic
                    },
                    icon: const Icon(Icons.mic_off, color: Colors.white),
                    color: Colors.grey[800],
                    iconSize: 28,
                  ),
                  IconButton(
                    onPressed: _hangUp,
                    icon: const Icon(Icons.call_end, color: Colors.red),
                    iconSize: 40,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
