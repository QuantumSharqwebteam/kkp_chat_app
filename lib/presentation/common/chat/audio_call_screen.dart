import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/core/services/socket_service.dart';
import 'dart:async';

class AudioCallScreen extends StatefulWidget {
  final String targetId;
  final String selfId;
  final bool isCaller;
  final String? callerName;
  final Map<String, dynamic>? initialOffer;

  const AudioCallScreen({
    super.key,
    required this.targetId,
    required this.selfId,
    required this.isCaller,
    this.callerName,
    this.initialOffer,
  });

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  Timer? _callTimer;
  int _elapsedSeconds = 0;
  bool _callConnected = false;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isCallScreenActive = false;

  final SocketService _socketService = SocketService();

  @override
  void initState() {
    super.initState();
    _initCall();
  }

  Future<void> _initCall() async {
    if (_isCallScreenActive) return;
    _isCallScreenActive = true;

    try {
      await _createPeerConnection();

      // 🔧 CHANGE: check for null after peer connection creation
      if (_peerConnection == null) {
        _handleCallError("PeerConnection failed to initialize");
        return;
      }

      await _setupLocalMedia();
      _setupSocketListeners();

      if (widget.isCaller) {
        await _makeOffer();
      }
      // 🔧 REMOVED: handling of widget.initialOffer - moved to socket
    } catch (e) {
      debugPrint("Init call error: $e");
      _handleCallError("Initialization failed");
    }
  }

  Future<void> _createPeerConnection() async {
    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
      'iceTransportPolicy': 'all',
    };

    final Map<String, dynamic> offerSdpConstraints = {
      "mandatory": {
        "OfferToReceiveAudio": true,
        "OfferToReceiveVideo": false,
      },
      "optional": [],
    };

    _peerConnection =
        await createPeerConnection(configuration, offerSdpConstraints);

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      debugPrint('Sending ICE candidate: ${candidate.toMap()}');
      _socketService.sendSignalCandidate(widget.targetId, candidate.toMap());
    };
    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          _connectCall();
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
        case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
          _handleCallEnd(isPeerHangup: false);
          break;
        default:
          break;
      }
    };

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.track.kind == 'audio') {
        debugPrint('🔊 Remote audio track received.');
      }
      setState(() {});
    };
  }

  Future<void> _setupLocalMedia() async {
    final mediaConstraints = <String, dynamic>{
      'audio': true,
      'video': false,
    };
    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

    _localStream?.getAudioTracks().forEach((track) async {
      await _peerConnection?.addTrack(track, _localStream!);
    });
    setState(() {});
  }

  Future<void> _makeOffer() async {
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    _socketService.initiateCall(
      widget.targetId,
      offer.toMap(),
      widget.selfId,
      widget.callerName ?? "Unknown Caller",
    );
  }

  void _setupSocketListeners() {
    // For caller - receive answer
    _socketService.listenForCallAnswered((answerMap) async {
      if (!widget.isCaller || _peerConnection == null) return;
      final sdp = answerMap['sdp'];
      final type = answerMap['type'];
      if (sdp != null && type != null) {
        final answer = RTCSessionDescription(sdp, type);
        await _peerConnection?.setRemoteDescription(answer);
      }
    });

    // Receive ICE candidates
    _socketService.listenForSignalCandidate((candidateMap) {
      if (_peerConnection == null) return;
      final candidate = RTCIceCandidate(
        candidateMap['candidate'],
        candidateMap['sdpMid'],
        candidateMap['sdpMLineIndex'],
      );
      _peerConnection?.addCandidate(candidate);
    });

    // Handle peer hang up
    _socketService.listenForCallTerminated((data) {
      _handleCallEnd(isPeerHangup: true);
    });

    // ✅ NEW: treat `incomingCall` as offer for callee
    _socketService.listenForIncomingCall((data) async {
      if (_peerConnection == null || widget.isCaller) return;

      final signal = data['signal'];
      final from = data['from'];
      final name = data['name'];
      if (signal != null && signal['sdp'] != null && signal['type'] != null) {
        final offer = RTCSessionDescription(signal['sdp'], signal['type']);
        await _peerConnection!.setRemoteDescription(offer);
        final answer = await _peerConnection!.createAnswer();
        await _peerConnection!.setLocalDescription(answer);

        _socketService.answerCall(
          targetEmail: from, // send back to original caller
          answerData: answer.toMap(),
        );

        setState(() {
          _callConnected = true;
        });
      }
    });
  }

  // Future<void> handleIncomingOffer(Map<String, dynamic> offerMap) async {
  //   if (widget.isCaller || _peerConnection == null) return;

  //   final offer = RTCSessionDescription(offerMap['sdp'], offerMap['type']);
  //   await _peerConnection!.setRemoteDescription(offer);
  //   final answer = await _peerConnection!.createAnswer();
  //   await _peerConnection!.setLocalDescription(answer);
  //   _socketService.answerCall(
  //     targetEmail: widget.targetId,
  //     answerData: answer.toMap(),
  //   );
  // }

  void _connectCall() {
    if (mounted && !_callConnected) {
      setState(() {
        _callConnected = true;
      });
      _startCallTimer();
    }
  }

  void _startCallTimer() {
    if (_callTimer != null && _callTimer!.isActive) return;
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
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

  void _handleCallEnd({bool isPeerHangup = false}) {
    if (!mounted) return;

    _callTimer?.cancel();
    _callTimer = null;

    _peerConnection?.close();
    _peerConnection = null;

    _localStream?.getTracks().forEach((track) {
      track.stop();
    });
    _localStream?.dispose();
    _localStream = null;

    _socketService.listenForCallAnswered((_) {});
    _socketService.listenForSignalCandidate((_) {});
    _socketService.listenForCallTerminated((_) {});

    if (!isPeerHangup) {
      _socketService.terminateCall(widget.targetId);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  void _hangUp() {
    _handleCallEnd(isPeerHangup: false);
  }

  void _handleCallError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
    _handleCallEnd(isPeerHangup: false);
  }

  void _toggleMute() {
    if (_localStream != null) {
      bool enabled = !_isMuted;
      _localStream!.getAudioTracks().forEach((track) {
        track.enabled = enabled;
      });
      setState(() {
        _isMuted = !enabled;
      });
    }
  }

  void _toggleSpeaker() async {
    if (_localStream != null) {
      final audioTracks = _localStream!.getAudioTracks();
      if (audioTracks.isNotEmpty) {
        bool targetSpeakerState = !_isSpeakerOn;
        await Helper.setSpeakerphoneOn(targetSpeakerState);
        setState(() {
          _isSpeakerOn = targetSpeakerState;
        });
      }
    }
  }

  @override
  void dispose() {
    _isCallScreenActive = false;
    _handleCallEnd(isPeerHangup: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String displayName = widget.isCaller
        ? widget.targetId
        : (widget.callerName ?? widget.targetId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(_callConnected
            ? "Connected"
            : (widget.isCaller ? "Calling..." : "Incoming Call")),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: _callConnected
            ? _buildConnectedCallUI(displayName)
            : _buildConnectingUI(displayName),
      ),
    );
  }

  Widget _buildConnectedCallUI(String displayName) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Column(
            children: [
              Text(
                displayName,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const SizedBox(height: 10),
              Text(
                _formattedDuration(),
                style: const TextStyle(fontSize: 18, color: Colors.black54),
              ),
            ],
          ),
          const CircleAvatar(
            radius: 80,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, size: 70, color: Colors.white),
          ),
          _buildCallControls(),
        ],
      ),
    );
  }

  Widget _buildConnectingUI(String displayName) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.isCaller ? "Calling" : "Incoming Call from",
              style: TextStyle(color: Colors.black54, fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              displayName,
              style: TextStyle(
                  color: Colors.black87,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.blue),
            const SizedBox(height: 30),
            Text(
              widget.isCaller ? "Ringing..." : "Connecting...",
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
            const SizedBox(height: 50),
            if (!widget.isCaller && !_callConnected)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    heroTag: 'rejectCallBtn_${widget.targetId}',
                    onPressed: _hangUp,
                    backgroundColor: Colors.red,
                    child: Icon(Icons.call_end, color: Colors.white),
                  ),
                  FloatingActionButton(
                    heroTag: 'acceptCallBtn_${widget.targetId}',
                    onPressed: () async {
                      // You might also want to ensure media and peer connection are ready
                      final signal =
                          widget.initialOffer?['signal']; // optional safety
                      if (signal != null) {
                        final offer = RTCSessionDescription(
                            signal['sdp'], signal['type']);
                        await _peerConnection!.setRemoteDescription(offer);
                        final answer = await _peerConnection!.createAnswer();
                        await _peerConnection!.setLocalDescription(answer);
                        _socketService.answerCall(
                          targetEmail: widget.targetId,
                          answerData: answer.toMap(),
                        );
                      }
                    },
                    backgroundColor: Colors.green,
                    child: Icon(Icons.call, color: Colors.white),
                  ),
                ],
              )
            else
              ElevatedButton.icon(
                onPressed: _hangUp,
                icon: const Icon(Icons.call_end, color: Colors.white),
                label: const Text("Cancel"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    textStyle: TextStyle(fontSize: 16)),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildCallControls() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Colors.white.withValues(alpha: 0.9),
          boxShadow: [
            BoxShadow(
                color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
          ]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: _toggleSpeaker,
            icon: Icon(
              _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
              color: _isSpeakerOn ? Colors.blue : Colors.black54,
            ),
            iconSize: 30,
          ),
          IconButton(
            onPressed: _toggleMute,
            icon: Icon(
              _isMuted ? Icons.mic_off : Icons.mic,
              color: _isMuted ? Colors.red : Colors.black54,
            ),
            iconSize: 30,
          ),
          SizedBox(width: 10),
          FloatingActionButton(
            heroTag: 'hangUpBtn_${widget.targetId}',
            onPressed: _hangUp,
            backgroundColor: Colors.red,
            child: const Icon(Icons.call_end, color: Colors.white, size: 35),
          ),
          SizedBox(width: 10),
          SizedBox(width: 48),
          SizedBox(width: 48),
        ],
      ),
    );
  }
}
