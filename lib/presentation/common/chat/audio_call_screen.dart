import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/core/services/socket_service.dart';

import 'dart:async';
// Assuming AppColors path
// Import Helper if needed for setSpeakerphoneOn
// import 'package:flutter_webrtc/flutter_webrtc.dart'; // Already imported

class AudioCallScreen extends StatefulWidget {
  final String targetId; // Email of the person you are calling/being called by
  final String selfId; // Your own email
  final bool isCaller;
  final String? callerName; // Optional: Pass caller name for display
  final Map<String, dynamic>? initialOffer; // For callees

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
  // --- Video Renderers Removed ---
  // RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  // RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  // --- End Video Renderers Removed ---

  Timer? _callTimer;
  int _elapsedSeconds = 0;
  bool _callConnected = false;
  bool _isMuted = false;
  bool _isSpeakerOn = false;

  final SocketService _socketService = SocketService();

  @override
  void initState() {
    super.initState();
    // --- Renderer Initialization Removed ---
    // await _localRenderer.initialize();
    // await _remoteRenderer.initialize();
    // --- End Renderer Initialization Removed ---
    _initCall();
  }

  Future<void> _initCall() async {
    try {
      await _createPeerConnection(); // Create connection first
      await _setupLocalMedia(); // Then setup local media (audio only)
      _setupSocketListeners(); // Then setup listeners

      if (widget.isCaller) {
        await _makeOffer(); // Caller makes the offer
      } else if (widget.initialOffer != null) {
        debugPrint(
            "Callee detected, handling initial offer passed via constructor.");
        await handleIncomingOffer(widget.initialOffer!);
      } else if (!widget.isCaller) {
        debugPrint(
            "⚠️ Warning: Callee screen loaded without initial offer data!");
        _handleCallError("Missing call initiation data.");
      }
    } catch (e) {
      debugPrint("Error initializing call: $e");
      _handleCallError("Initialization failed");
    }
  }

  Future<void> _createPeerConnection() async {
    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        // Add TURN servers here if needed
      ],
      'iceTransportPolicy': 'all',
    };
    // Explicitly configure for AUDIO ONLY
    final Map<String, dynamic> offerSdpConstraints = {
      "mandatory": {
        "OfferToReceiveAudio": true,
        "OfferToReceiveVideo": false, // Explicitly false
      },
      "optional": [],
    };

    _peerConnection =
        await createPeerConnection(configuration, offerSdpConstraints);

    // onIceCandidate remains the same
    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      debugPrint('🧊 Got local ICE candidate: ${candidate.candidate}');
      _socketService.sendSignalCandidate(widget.targetId, candidate.toMap());
    };

    // onConnectionState remains the same
    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      debugPrint('🔌 Peer Connection State: $state');
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

    // --- onAddStream is less preferred, use onTrack ---
    // _peerConnection!.onAddStream = (MediaStream stream) { ... };

    // onTrack: Handles incoming tracks (will only receive audio)
    _peerConnection!.onTrack = (RTCTrackEvent event) {
      debugPrint('➕ Received remote track: ${event.track.kind}');
      if (event.track.kind == 'audio') {
        // Audio will play automatically. No rendering needed.
        debugPrint('🔊 Remote audio track received.');
        // You might attach event.streams[0] to an audio element if needed on web,
        // but on mobile it should usually just work.
      }
      // No need to handle video tracks
      // else if (event.track.kind == 'video') {
      //   _remoteRenderer.srcObject = event.streams[0];
      // }
      setState(() {}); // Update UI potentially (e.g., show connected status)
    };
  }

  Future<void> _setupLocalMedia() async {
    try {
      // Request AUDIO ONLY
      final mediaConstraints = <String, dynamic>{
        'audio': true,
        'video': false, // Explicitly false
      };
      _localStream =
          await navigator.mediaDevices.getUserMedia(mediaConstraints);

      // --- Renderer srcObject assignment removed ---
      // _localRenderer.srcObject = _localStream;
      // --- End Renderer srcObject assignment removed ---

      // Add tracks to the peer connection
      _localStream?.getAudioTracks().forEach((track) async {
        // Only iterate audio tracks
        debugPrint('➕ Adding local audio track: ${track.label}');
        if (_peerConnection != null && _localStream != null) {
          try {
            await _peerConnection?.addTrack(track, _localStream!);
          } catch (e) {
            debugPrint("Error adding local audio track: $e");
          }
        }
      });
      setState(() {});
    } catch (e) {
      debugPrint("Error getting user media (audio): $e");
      _handleCallError(
          "Could not access microphone. Please check permissions.");
    }
  }

  // _makeOffer remains the same (constraints already set in createPeerConnection)
  Future<void> _makeOffer() async {
    if (_peerConnection == null) return;
    try {
      // Constraints for createOffer are often less critical if OfferToReceive is set
      // But you can specify them here too if needed:
      // final offerConstraints = <String, dynamic>{
      //    'mandatory': {
      //       'OfferToReceiveAudio': true,
      //       'OfferToReceiveVideo': false,
      //    },
      //    'optional': [],
      // };
      // final offer = await _peerConnection!.createOffer(offerConstraints);
      final offer = await _peerConnection!
          .createOffer(); // Use constraints from createPeerConnection
      await _peerConnection!.setLocalDescription(offer);
      debugPrint("🍦 Created Audio Offer and set Local Description");

      _socketService.initiateCall(
        widget.targetId,
        offer.toMap(),
        widget.selfId,
        widget.callerName ?? "Unknown Caller",
      );
    } catch (e) {
      debugPrint("Error creating/sending audio offer: $e");
      _handleCallError("Failed to initiate call");
    }
  }

  // _setupSocketListeners remains the same
  void _setupSocketListeners() {
    // Listener for when the callee answers (Only relevant for the original caller)
    _socketService.listenForCallAnswered((answerMap) async {
      if (!widget.isCaller || _peerConnection == null) return;
      debugPrint("✅ Received Call Answer");
      final answer = RTCSessionDescription(answerMap['sdp'], answerMap['type']);
      try {
        await _peerConnection?.setRemoteDescription(answer);
        debugPrint("✅ Set Remote Description (Answer)");
      } catch (e) {
        debugPrint("Error setting remote description (answer): $e");
      }
    });

    // Listener for ICE candidates from the peer (Both caller and callee listen)
    _socketService.listenForSignalCandidate((candidateMap) {
      if (_peerConnection == null) return;
      debugPrint("🧊 Received ICE Candidate");
      final candidate = RTCIceCandidate(
        candidateMap['candidate'],
        candidateMap['sdpMid'],
        candidateMap['sdpMLineIndex'],
      );
      try {
        _peerConnection?.addCandidate(candidate).then((_) {
          debugPrint("🧊 Added Remote ICE Candidate successfully");
        }).catchError((e) {
          debugPrint("Error adding remote ICE candidate: $e");
        });
      } catch (e) {
        debugPrint("Synchronous error calling addCandidate: $e");
      }
    });

    // Listener for when the other user hangs up (Both listen)
    _socketService.listenForCallTerminated((data) {
      debugPrint("❌ Received Call Terminated signal");
      _handleCallEnd(isPeerHangup: true);
    });
  }

  // handleIncomingOffer remains the same (constraints already set in createPeerConnection)
  Future<void> handleIncomingOffer(Map<String, dynamic> offerMap) async {
    if (widget.isCaller || _peerConnection == null) {
      debugPrint(
          "handleIncomingOffer called inappropriately (isCaller: ${widget.isCaller}, peerConnection: ${_peerConnection == null})");
      return;
    }

    debugPrint("📞 Processing incoming audio offer...");
    final offer = RTCSessionDescription(offerMap['sdp'], offerMap['type']);

    try {
      await _peerConnection!.setRemoteDescription(offer);
      debugPrint("✅ Set Remote Description (Offer)");

      // Constraints for createAnswer (usually inherits from offer/connection)
      // final answerConstraints = <String, dynamic>{
      //    'mandatory': {
      //       'OfferToReceiveAudio': true, // We expect audio
      //       'OfferToReceiveVideo': false, // We don't offer video
      //    },
      //    'optional': [],
      // };
      // final answer = await _peerConnection!.createAnswer(answerConstraints);
      final answer =
          await _peerConnection!.createAnswer(); // Use default constraints
      await _peerConnection!.setLocalDescription(answer);
      debugPrint("✅ Created Audio Answer and set Local Description");

      _socketService.answerCall(
        targetEmail: widget.targetId,
        answerData: answer.toMap(),
      );
    } catch (e) {
      debugPrint("Error handling incoming offer / creating answer: $e");
      _handleCallError("Failed to answer call");
    }
  }

  // _connectCall remains the same
  void _connectCall() {
    if (mounted && !_callConnected) {
      debugPrint("🎉 Call Connected!");
      setState(() {
        _callConnected = true;
      });
      _startCallTimer();
    }
  }

  // _startCallTimer remains the same
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

  // _formattedDuration remains the same
  String _formattedDuration() {
    final minutes = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // _handleCallEnd: Remove renderer disposal
  void _handleCallEnd({bool isPeerHangup = false}) {
    if (!mounted) return;

    debugPrint("📞 Handling call end. Peer hangup: $isPeerHangup");

    _callTimer?.cancel();
    _callTimer = null;

    _peerConnection?.close().catchError((e) {
      debugPrint("Error closing peer connection: $e");
    });
    _peerConnection = null;

    _localStream?.getTracks().forEach((track) {
      track.stop();
      track.dispose();
    });
    _localStream?.dispose();
    _localStream = null;

    // --- Renderer Disposal Removed ---
    // _localRenderer.dispose();
    // _remoteRenderer.dispose();
    // --- End Renderer Disposal Removed ---

    _socketService.listenForCallAnswered((_) {});
    _socketService.listenForSignalCandidate((_) {});
    _socketService.listenForCallTerminated((_) {});

    if (!isPeerHangup) {
      _socketService.terminateCall(widget.targetId);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  // _hangUp remains the same
  void _hangUp() {
    debugPrint("User initiated hang up.");
    _handleCallEnd(isPeerHangup: false);
  }

  // _handleCallError remains the same
  void _handleCallError(String message) {
    debugPrint("Error: $message");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
    _handleCallEnd(isPeerHangup: false);
  }

  // _toggleMute remains the same
  void _toggleMute() {
    if (_localStream != null) {
      bool enabled = !_isMuted; // Target state
      _localStream!.getAudioTracks().forEach((track) {
        track.enabled = enabled;
      });
      setState(() {
        _isMuted = !enabled;
      }); // Update state AFTER applying
      debugPrint("🎤 Mic Muted: $_isMuted");
    }
  }

  // _toggleSpeaker remains the same
  void _toggleSpeaker() async {
    if (_localStream != null) {
      final audioTracks = _localStream!.getAudioTracks();
      if (audioTracks.isNotEmpty) {
        bool targetSpeakerState = !_isSpeakerOn;
        try {
          await Helper.setSpeakerphoneOn(targetSpeakerState);
          setState(() {
            _isSpeakerOn = targetSpeakerState;
          }); // Update state on success
          debugPrint("🔊 Speaker On: $_isSpeakerOn");
        } catch (e) {
          debugPrint("Error setting speakerphone state: $e");
        }
      } else {
        debugPrint("🔊 Cannot toggle speaker: No active audio tracks.");
      }
    } else {
      debugPrint("🔊 Cannot toggle speaker: Local stream is null or inactive.");
    }
  }

  // dispose remains the same
  @override
  void dispose() {
    debugPrint("Disposing AudioCallScreen");
    _handleCallEnd(isPeerHangup: false);
    super.dispose();
  }

  // build: Remove any RTCVideoView widgets
  @override
  Widget build(BuildContext context) {
    String displayName = widget.isCaller
        ? widget.targetId
        : (widget.callerName ?? widget.targetId);

    return Scaffold(
      backgroundColor: AppColors.background, // Use your theme/colors
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Or themed color
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

  // _buildConnectedCallUI: Removed video renderer placeholders
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

          // --- Remote Video Renderer Removed ---
          // SizedBox(
          //   height: 200, width: 150,
          //   child: RTCVideoView(_remoteRenderer) // REMOVED
          // ),
          // --- End Remote Video Renderer Removed ---

          _buildCallControls(),
        ],
      ),
    );
  }

  // _buildConnectingUI remains the same
  Widget _buildConnectingUI(String displayName) {
    // ... (same as before)
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
                    onPressed: () {
                      debugPrint(
                          "Accept button pressed - connection process initiated.");
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

  // _buildCallControls remains the same
  Widget _buildCallControls() {
    // ... (same as before)
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Colors.white.withOpacity(0.9),
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
          SizedBox(width: 48), // Placeholder space
          SizedBox(width: 48), // Placeholder space
        ],
      ),
    );
  }
}
