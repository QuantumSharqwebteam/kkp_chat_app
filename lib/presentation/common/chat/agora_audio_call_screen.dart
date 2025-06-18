import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kkpchatapp/core/services/event_bus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/config/theme/image_constants.dart';

import 'package:kkpchatapp/core/services/call_overlay_service.dart';
import 'package:kkpchatapp/core/services/socket_service.dart';
import 'package:kkpchatapp/data/models/chat_message_model.dart';
import 'package:kkpchatapp/data/repositories/chat_reopsitory.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/media_button.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_image.dart';
import 'package:kkpchatapp/provider/call_timer_provider.dart';
import 'package:kkpchatapp/main.dart';

class AgoraAudioCallScreen extends StatefulWidget {
  const AgoraAudioCallScreen({
    super.key,
    required this.isCaller,
    required this.channelName,
    required this.remoteUserName,
    required this.uid,
    this.remoteUserId,
    this.callId,
    this.timestamp,
    this.navigatorKey,
  });

  final bool isCaller;
  final String channelName;
  final String? remoteUserId;
  final String remoteUserName;
  final int uid;
  final String? callId;
  final DateTime? timestamp;
  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  State<AgoraAudioCallScreen> createState() => _AgoraAudioCallScreenState();
}

class _AgoraAudioCallScreenState extends State<AgoraAudioCallScreen> {
  // --------------------------------------------------------------------------
  bool _isMinimised = false; // true while overlay pill is visible
  bool _callEnded = false; // set only inside _endCall()

  late final RtcEngine _engine;
  bool _joined = false;
  int? _remoteUid;
  bool _muted = false;
  bool _isSpeakerOn = true;

  Timer? _callTimeoutTimer;

  final String _appId = dotenv.env['AGORA_APP_ID']!;
  final ChatRepository _chatRepo = ChatRepository();
  final _socketService = SocketService(navigatorKey);
  final _overlay = CallOverlayService();
  // --------------------------------------------------------------------------

  // ======================   LIFECYCLE   =====================================
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _overlay.init(widget.navigatorKey ?? navigatorKey);
      _initAgora();
    });

    // _socketService.onCallTerminated((data) {
    //   if (data['callId'] == widget.callId) {
    //     _overlay.hide();
    //     _endCall();
    //   }
    // });
    EventBus().stream.listen((event) {
      if (event['type'] == 'call_terminated' &&
          event['data']['callId'] == widget.callId) {
        _endCall();
      }
    });
  }

  @override
  void dispose() {
    _callTimeoutTimer?.cancel();

    // Leave channel only when call is finished,
    // not when the screen is just minimised
    if (_callEnded || !_isMinimised) {
      _engine.leaveChannel();
      _engine.release();
    }
    super.dispose();
  }

  // ======================   AGORA INIT   ====================================
  Future<void> _initAgora() async {
    await _handlePermissions();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(appId: _appId));

    _setupEventHandlers();
    await _engine.enableAudio();

    final token =
        await _chatRepo.fetchAgoraToken(widget.channelName, widget.uid);

    try {
      await _engine.joinChannel(
        token: token!,
        channelId: widget.channelName,
        uid: widget.uid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          autoSubscribeAudio: true,
          publishMicrophoneTrack: true,
        ),
      );
    } on AgoraRtcException catch (e) {
      if (e.code == -17) {
        // Already in channel → mark as joined and keep going
        setState(() => _joined = true);
        // make sure timer is running
        //  context.read<CallTimerProvider>().start();
      } else {
        rethrow; // any other error should still surface
      }
    }

    if (widget.isCaller) CallOverlayService().startRinging();

    // "No answer" timeout (40 s)
    _callTimeoutTimer = Timer(const Duration(seconds: 40), () {
      if (_remoteUid == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No answer. Call ended.')),
          );
        }
        _updateCallData('not answered');
        _endCall();
      }
    });
  }

  Future<void> _handlePermissions() async {
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      throw Exception('Microphone permission not granted');
    }
  }

  // ======================   AGORA EVENTS   ==================================
  void _setupEventHandlers() {
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (_, __) => setState(() => _joined = true),
        onUserJoined: (_, uid, __) {
          setState(() {
            _remoteUid = uid;
            CallOverlayService().stopRinging();
          });
          context.read<CallTimerProvider>().start(); // start timer
          _callTimeoutTimer?.cancel();
        },
        onUserOffline: (_, __, ___) => _endCall(),
      ),
    );
  }

  // ======================   UI TOGGLES   ====================================
  void _toggleMute() {
    _muted = !_muted;
    _engine.muteLocalAudioStream(_muted);
    setState(() {});
  }

  void _toggleSpeaker() {
    _isSpeakerOn = !_isSpeakerOn;
    _engine.setEnableSpeakerphone(_isSpeakerOn);
    setState(() {});
  }

  // =================   MINIMISE / EXPAND / HANG‑UP   ========================
  void _minimiseToOverlay() {
    _isMinimised = true;
    _overlay.show(
      remoteName: widget.remoteUserName,
      onExpand: () {
        _overlay.hide();
        _isMinimised = false;
        (widget.navigatorKey ?? navigatorKey).currentState!.push(
              MaterialPageRoute(
                builder: (_) => AgoraAudioCallScreen(
                  isCaller: false,
                  channelName: widget.channelName,
                  uid: widget.uid,
                  remoteUserId: widget.remoteUserId,
                  remoteUserName: widget.remoteUserName,
                  callId: widget.callId,
                  timestamp: widget.timestamp,
                  navigatorKey: widget.navigatorKey,
                ),
              ),
            );
      },
      onHangup: _endCall,
    );
    Navigator.of(context).pop();
  }

  void _endCall() {
    _callEnded = true;
    _callTimeoutTimer?.cancel();
    CallOverlayService().stopRinging();

    final timerProv = context.read<CallTimerProvider>();
    timerProv.stop();

    final bool answered = timerProv.duration > Duration.zero;
    final status = answered ? 'answered' : 'not answered';
    final duration = timerProv.formatted;

    _updateCallData(status, callDuration: duration);
    _engine.leaveChannel();
    _overlay.hide();
    timerProv.reset();

    if (mounted) {
      Navigator.pop(context, _createCallMessage(status, duration));
    }
  }

  // =======================   SERVER UPDATE   ================================
  Future<void> _updateCallData(String status, {String? callDuration}) async {
    if (widget.callId == null) return;
    await _chatRepo.updateCallData(widget.callId!, status,
        callDuration: callDuration);
  }

  ChatMessageModel _createCallMessage(String status, String duration) {
    return ChatMessageModel(
      type: 'call',
      callStatus: status,
      callDuration: duration,
      timestamp: widget.timestamp ?? DateTime.now(),
      callId: widget.callId,
    );
  }

  // ============================   UI   ======================================
  @override
  Widget build(BuildContext context) {
    final timer = context.watch<CallTimerProvider>();

    return WillPopScope(
      onWillPop: () async {
        _minimiseToOverlay();
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundDCEBFF,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 30),
              Text(widget.remoteUserName, style: AppTextStyles.black24_700),
              const SizedBox(height: 20),
              Text(
                _joined ? 'In call… ${timer.formatted}' : 'Connecting…',
                style: AppTextStyles.grey5C5C5C_18_700,
              ),
              const SizedBox(height: 70),
              const Center(
                child: CustomImage(
                  imagePath: ImageConstants.profileAvatar,
                  height: 200,
                  width: 200,
                ),
              ),
              const Spacer(),
              Container(
                margin: const EdgeInsets.all(16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                decoration: BoxDecoration(
                  color: AppColors.grey5C5C5C,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    MediaButton(
                      backgroundColor:
                          _isSpeakerOn ? Colors.white : AppColors.black2E2E2E,
                      iconColor: _isSpeakerOn ? Colors.black : Colors.white,
                      onTap: _toggleSpeaker,
                      iconData:
                          _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
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
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down,
                          color: Colors.white),
                      onPressed: _minimiseToOverlay,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
