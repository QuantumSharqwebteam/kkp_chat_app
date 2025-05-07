import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/config/theme/image_constants.dart';
import 'package:kkpchatapp/data/repositories/chat_reopsitory.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/media_button.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_image.dart';
import 'package:permission_handler/permission_handler.dart';

import 'dart:async';

class AgoraAudioCallScreen extends StatefulWidget {
  final bool isCaller;
  //final String token;
  final String channelName;
  final String? remoteUserId;
  final String remoteUserName;
  final int uid;
  final String? messageId;

  const AgoraAudioCallScreen({
    super.key,
    required this.isCaller,
    //required this.token,
    required this.channelName,
    this.remoteUserId,
    required this.remoteUserName,
    required this.uid,
    this.messageId,
  });

  @override
  State<AgoraAudioCallScreen> createState() => _AgoraAudioCallScreenState();
}

class _AgoraAudioCallScreenState extends State<AgoraAudioCallScreen> {
  late final RtcEngine _engine;
  bool _joined = false;
  int? _remoteUid;
  bool _muted = false;
  bool _isSpeakerOn = true; // default to speaker ON
  Duration _callDuration = Duration.zero;
  Timer? _durationTimer;
  Timer? _callTimeoutTimer;
  bool _isRinging = false;
  final ChatRepository chatRepository = ChatRepository();
  final AudioPlayer _ringingPlayer = AudioPlayer();
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

      // different token for each user who wants to join in the room
      final token =
          await chatRepository.fetchAgoraToken(widget.channelName, widget.uid);

      await _engine.joinChannel(
        token: token!,
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

      if (widget.isCaller) {
        _startRinging(); //Start ringing on caller side
      }

      /// Timeout if remote user doesn’t join
      _callTimeoutTimer = Timer(const Duration(seconds: 40), () {
        if (_remoteUid == null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No answer. Call ended.")),
          );
          _updateCallData("missed");
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

  Future<void> _updateCallData(String callStatus,
      {String? callDuration}) async {
    if (widget.messageId == null) {
      debugPrint("⚠️⚠️⚠️ Message ID is null. Cannot update call data.");
      return;
    }

    try {
      await chatRepository.updateCallData(
        widget.messageId!,
        callStatus,
        callDuration: callDuration,
      );
      debugPrint(
          "✅ ✅ Call data updated successfully: $callStatus, Duration: $callDuration");
    } catch (e) {
      debugPrint("❌ Error updating call data: $e");
      // Handle the error as needed, e.g., show a message to the user
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
          _stopRinging(); // Stop ringing
          _startCallTimer();
        }
        _callTimeoutTimer?.cancel();

        // Update call status to answered
        // _updateCallData('answered');
      },
      onUserOffline: (RtcConnection connection, int remoteUid,
          UserOfflineReasonType reason) {
        debugPrint("❌ Remote user $remoteUid left due to $reason");
        if (mounted) {
          setState(() => _remoteUid = null);
          final totalCallDuration = _formatDuration(_callDuration);
          _updateCallData("answered", callDuration: totalCallDuration);
          _endCall();
        }
      },
      onLeaveChannel: (RtcConnection connection, RtcStats stats) {
        debugPrint("🚪 Local user left the channel");
      },
      onError: (ErrorCodeType code, String message) {
        debugPrint("⚠️Error joinning channel Agora error: $code - $message");
      },
    ));
  }

  void _toggleMute() {
    if (_joined) {
      setState(() => _muted = !_muted);
      _engine.muteLocalAudioStream(_muted);
    }
  }

  void _toggleSpeaker() {
    if (_joined) {
      setState(() => _isSpeakerOn = !_isSpeakerOn);
      _engine.setEnableSpeakerphone(_isSpeakerOn);
    }
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
    _stopRinging(); //Stop ringing if still active
    // if (_remoteUid == null) {
    //   // Update call status to missed
    //   _updateCallData('missed');
    // } else {
    //   // Update call status to answered and send call duration
    //   final callDuration = _formatDuration(_callDuration);
    //   _updateCallData('answered', callDuration: callDuration);
    // }
    if (mounted) Navigator.pop(context);
  }

  //  Start ringing
  Future<void> _startRinging() async {
    if (_isRinging) return;
    _isRinging = true;
    await _ringingPlayer.setReleaseMode(ReleaseMode.loop);
    await _ringingPlayer.play(
        AssetSource('sounds/ringtone.mp3')); // 🔔 Make sure this file exists
  }

  //Stop ringing
  Future<void> _stopRinging() async {
    if (!_isRinging) return;
    _isRinging = false;
    await _ringingPlayer.stop();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _callTimeoutTimer?.cancel();
    _stopRinging();
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
      backgroundColor: AppColors.backgroundDCEBFF,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            Text(
              widget.remoteUserName,
              style: AppTextStyles.black24_700,
            ),
            const SizedBox(height: 20),
            if (_joined)
              Text(
                _remoteUid != null
                    ? "In call... ${_formatDuration(_callDuration)}"
                    : "Ringing...",
                style: AppTextStyles.grey5C5C5C_18_700,
              )
            else
              // const CircularProgressIndicator(color: Colors.white),
              Text(
                "Connecting....",
                style: AppTextStyles.grey5C5C5C_18_700,
              ),
            const SizedBox(height: 70),
            Center(
              child: const CustomImage(
                imagePath: ImageConstants.profileAvatar,
                height: 200,
                width: 200,
              ),
            ),
            const Spacer(),
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppColors.grey5C5C5C,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  MediaButton(
                    backgroundColor:
                        _isSpeakerOn ? Colors.white : AppColors.black2E2E2E,
                    iconColor: _isSpeakerOn ? Colors.black : Colors.white,
                    onTap: _toggleSpeaker,
                    iconData: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                  ),
                  MediaButton(
                    backgroundColor:
                        _muted ? Colors.white : AppColors.black2E2E2E,
                    iconColor: _muted ? Colors.black : Colors.white,
                    onTap: _toggleMute,
                    iconData: _muted ? Icons.mic_off : Icons.mic,
                  ),
                  MediaButton(
                    backgroundColor: AppColors.inActiveRed,
                    iconColor: Colors.white,
                    onTap: _endCall,
                    iconData: Icons.call_end,
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
