import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AgoraAudioCallScreen extends StatefulWidget {
  final bool isCaller;
  final String token;
  final String channelName;
  final String remoteUserId;
  final String remoteUserName;

  const AgoraAudioCallScreen({
    super.key,
    required this.isCaller,
    required this.token,
    required this.channelName,
    required this.remoteUserId,
    required this.remoteUserName,
  });

  @override
  State<AgoraAudioCallScreen> createState() => _AgoraAudioCallScreenState();
}

class _AgoraAudioCallScreenState extends State<AgoraAudioCallScreen> {
  late RtcEngine _engine;
  bool _joined = false;
  int? _remoteUid;
  bool _muted = false;
  final String agoraAppId = dotenv.env['AGORA_APP_ID']!;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    _engine = createAgoraRtcEngine();

    await _engine.initialize(RtcEngineContext(
      appId: agoraAppId,
    ));

    _setupEventHandlers();

    await _engine.enableAudio();

    await _engine.joinChannel(
      token: widget.token,
      channelId: widget.channelName,
      uid: 0, // 0 lets Agora assign UID automatically
      options: const ChannelMediaOptions(),
    );
  }

  void _setupEventHandlers() {
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("✅ Local user ${connection.localUid} joined the channel");
          setState(() => _joined = true);
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("👤 Remote user $remoteUid joined");
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          debugPrint("❌ Remote user $remoteUid left due to $reason");
          setState(() {
            _remoteUid = null;
          });
          Navigator.pop(context); // End call when remote user leaves
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          debugPrint("🚪 Local user left the channel");
        },
      ),
    );
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _engine.muteLocalAudioStream(_muted);
  }

  void _endCall() {
    _engine.leaveChannel();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.remoteUserName,
                style: const TextStyle(color: Colors.white, fontSize: 24)),
            const SizedBox(height: 20),
            if (_joined)
              Text(
                _remoteUid != null ? "In call..." : "Ringing...",
                style: const TextStyle(color: Colors.white70),
              )
            else
              const CircularProgressIndicator(),
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
