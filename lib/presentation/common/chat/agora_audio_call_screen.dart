import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';

import 'dart:async';

class AgoraAudioCallScreen extends StatefulWidget {
  final bool isCaller;
  final String token;
  final String channelName;
  final String remoteUserId;
  final String remoteUserName;
  final int uid;

  const AgoraAudioCallScreen({
    super.key,
    required this.isCaller,
    required this.token,
    required this.channelName,
    required this.remoteUserId,
    required this.remoteUserName,
    required this.uid,
  });

  @override
  State<AgoraAudioCallScreen> createState() => _AgoraAudioCallScreenState();
}

class _AgoraAudioCallScreenState extends State<AgoraAudioCallScreen> {
  late final RtcEngine _engine;
  bool _joined = false;
  int? _remoteUid;
  bool _muted = false;
  Duration _callDuration = Duration.zero;
  Timer? _durationTimer;
  Timer? _callTimeoutTimer;

  final String agoraAppId = dotenv.env['AGORA_APP_ID']!;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAgora();
    });
  }

  Future<void> _initAgora() async {
    try {
      await _handlePermissions();

      _engine = createAgoraRtcEngine();
      await _engine.initialize(RtcEngineContext(appId: agoraAppId));

      _setupEventHandlers();

      await _engine.enableAudio();

      /// Delay for internal readiness
      await Future.delayed(const Duration(milliseconds: 500));

      await _engine.joinChannel(
        token: widget.token,
        channelId: widget.channelName,
        uid: widget.uid,
        options: ChannelMediaOptions(
            autoSubscribeAudio: true,
            publishMicrophoneTrack: true,
            clientRoleType: ClientRoleType.clientRoleBroadcaster
            //: ClientRoleType.clientRoleAudience,
            //channelProfile: ChannelProfileType.channelProfileCommunication,
            ),
      );
      debugPrint("Attempting to join channel: ${widget.channelName}");

      /// Timeout if remote user doesn’t join
      _callTimeoutTimer = Timer(const Duration(seconds: 50), () {
        if (_remoteUid == null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No answer. Call ended.")),
          );
          _endCall();
        }
      });
    } catch (e) {
      debugPrint("❗ Agora init error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to join the call.")),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _handlePermissions() async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      throw Exception("Microphone permission not granted");
    }
  }

  void _setupEventHandlers() {
    _engine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        debugPrint("✅ Local user ${connection.localUid} joined the channel");
        if (mounted) setState(() => _joined = true);
      },
      onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        debugPrint("👤 Remote user $remoteUid joined");
        if (mounted) {
          setState(() => _remoteUid = remoteUid);
          _startCallTimer();
        }
        _callTimeoutTimer?.cancel();
      },
      onUserOffline: (RtcConnection connection, int remoteUid,
          UserOfflineReasonType reason) {
        debugPrint("❌ Remote user $remoteUid left due to $reason");
        if (mounted) {
          setState(() => _remoteUid = null);
          _endCall();
        }
      },
      onLeaveChannel: (RtcConnection connection, RtcStats stats) {
        debugPrint("🚪 Local user left the channel");
      },
      onError: (errorCode, errorMessage) {
        debugPrint("Error joining channel: $errorCode, $errorMessage");
      },
    ));
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _engine.muteLocalAudioStream(_muted);
  }

  void _startCallTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _callDuration += const Duration(seconds: 1);
        });
      }
    });
  }

  void _endCall() {
    _durationTimer?.cancel();
    _callTimeoutTimer?.cancel();
    _engine.leaveChannel();
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _callTimeoutTimer?.cancel();
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.remoteUserName,
              style: const TextStyle(color: Colors.white, fontSize: 24),
            ),
            const SizedBox(height: 20),
            if (_joined)
              Text(
                _remoteUid != null
                    ? "In call... ${_formatDuration(_callDuration)}"
                    : "Ringing...",
                style: const TextStyle(color: Colors.white70),
              )
            else
              const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 60),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(_muted ? Icons.mic_off : Icons.mic,
                      color: Colors.white),
                  onPressed: _toggleMute,
                ),
                IconButton(
                  icon: const Icon(Icons.call_end, color: Colors.red),
                  onPressed: _endCall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
