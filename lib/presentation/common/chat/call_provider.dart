import 'package:flutter/material.dart';
import 'package:kkpchatapp/core/services/socket_service.dart';
import 'package:kkpchatapp/data/models/chat_message_model.dart';
import 'package:kkpchatapp/presentation/common/chat/agora_audio_call_screen.dart';
import 'package:kkpchatapp/presentation/common/chat/outgoing_call_ui.dart';
import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kkpchatapp/data/repositories/chat_reopsitory.dart';
import 'package:permission_handler/permission_handler.dart';

// class CallProvider with ChangeNotifier {
//   final CallService _callService = CallService();
//   final GlobalKey<NavigatorState> navigatorKey;

//   CallProvider(this.navigatorKey);

//   bool _isCallScreenVisible = false;
//   bool _isOutgoingCallVisible = false;
//   ChatMessageModel? _callDetailsMessage;

//   OverlayEntry? _outgoingCallOverlay;

//   // Call metadata
//   String? _channelName;
//   String? _remoteUserName;
//   int? _uid;
//   String? _callId;
//   bool _isCaller = false;

//   bool get isCallScreenVisible => _isCallScreenVisible;
//   bool get isOutgoingCallVisible => _isOutgoingCallVisible;
//   ChatMessageModel? get callDetailsMessage => _callDetailsMessage;

//   String? get channelName => _channelName;
//   String? get remoteUserName => _remoteUserName;
//   int? get uid => _uid;
//   String? get callId => _callId;
//   bool get isCaller => _isCaller;

//   Future<void> initializeCallService() async {
//     await _callService.initialize();
//   }

//   Future<void> startNewCall({
//     required String channelName,
//     required String remoteUserName,
//     required int uid,
//     required String callId,
//     required bool isCaller,
//   }) async {
//     _channelName = channelName;
//     _remoteUserName = remoteUserName;
//     _uid = uid;
//     _callId = callId;
//     _isCaller = isCaller;

//     await initializeCallService();
//     await _callService.join(channelName, uid, callId);
//     showCallScreen();

//     navigatorKey.currentState?.push(
//       MaterialPageRoute(builder: (_) => const AgoraAudioCallScreen()),
//     );
//   }

//   void showCallScreen() {
//     _isCallScreenVisible = true;
//     _isOutgoingCallVisible = false;
//     removeOutgoingCallOverlay(); // remove if present
//     notifyListeners();
//   }

//   void minimizeCallScreen() {
//     _isCallScreenVisible = false;
//     _isOutgoingCallVisible = true;

//     if (navigatorKey.currentState?.canPop() ?? false) {
//       navigatorKey.currentState?.pop();
//     }

//     showOutgoingCallOverlay(); // Show minimized UI in overlay
//     notifyListeners();
//   }

//   void showOutgoingCallOverlay() {
//     removeOutgoingCallOverlay();

//     _outgoingCallOverlay = OverlayEntry(
//       builder: (context) => Positioned(
//         top: MediaQuery.of(context).padding.top + 12,
//         left: 0,
//         right: 0,
//         child: SafeArea(
//           child: Material(
//             color: Colors.transparent,
//             child: OutgoingCallUI(
//               onTap: () {
//                 showCallScreen();
//                 navigatorKey.currentState?.push(
//                   MaterialPageRoute(
//                     builder: (_) => const AgoraAudioCallScreen(),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ),
//       ),
//     );

//     navigatorKey.currentState?.overlay?.insert(_outgoingCallOverlay!);
//   }

//   void removeOutgoingCallOverlay() {
//     _outgoingCallOverlay?.remove();
//     _outgoingCallOverlay = null;
//   }

//   void endCall() {
//     _callService.releaseEngine();
//     _isCallScreenVisible = false;
//     _isOutgoingCallVisible = false;
//     removeOutgoingCallOverlay();
//     notifyListeners();
//   }

//   void setCallDetailsMessage(ChatMessageModel message) {
//     _callDetailsMessage = message;
//     notifyListeners();
//   }

//   CallService get callService => _callService;
// }

class CallProvider with ChangeNotifier {
  final GlobalKey<NavigatorState> navigatorKey;
  CallProvider(this.navigatorKey) {
    _socketService = SocketService(navigatorKey);
    _listenToSocketTermination();
  }

  // Agora + Call State
  late final SocketService _socketService;

  late RtcEngine _agoraEngine;
  bool _isInitialized = false;
  bool _isJoined = false;
  int? _remoteUid;
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  Duration _callDuration = Duration.zero;
  Timer? _durationTimer;
  Timer? _callTimeoutTimer;
  bool _isRinging = false;
  final AudioPlayer _ringingPlayer = AudioPlayer();
  final StreamController<int> _callDurationController =
      StreamController<int>.broadcast();
  String? _callId;
  final ChatRepository _chatRepository = ChatRepository();

  // UI + Metadata
  bool _isCallScreenVisible = false;
  bool _isOutgoingCallVisible = false;
  OverlayEntry? _outgoingCallOverlay;
  String? _channelName;
  String? _remoteUserName;
  int? _uid;
  bool _isCaller = false;
  ChatMessageModel? _callDetailsMessage;

  // Getters
  int? get uid => _uid;
  String? get channelName => _channelName;
  String? get remoteUserName => _remoteUserName;
  bool get isCallScreenVisible => _isCallScreenVisible;
  bool get isOutgoingCallVisible => _isOutgoingCallVisible;
  ChatMessageModel? get callDetailsMessage => _callDetailsMessage;
  int? get remoteUid => _remoteUid;
  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;
  Duration get callDuration => _callDuration;
  Stream<int> get callDurationStream => _callDurationController.stream;
  bool get isRemoteConnected => _remoteUid != null;
  String get callDurationFormatted => _formatDuration(_callDuration);

  // Start a New Call
  Future<void> startNewCall({
    required String channelName,
    required String remoteUserName,
    required int uid,
    required String callId,
    required bool isCaller,
  }) async {
    _channelName = channelName;
    _remoteUserName = remoteUserName;
    _uid = uid;
    _callId = callId;
    _isCaller = isCaller;

    await _initialize();
    await Future.delayed(const Duration(milliseconds: 500));
    await _joinChannel(channelName, uid, callId);

    _showCallScreen();
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const AgoraAudioCallScreen()),
    );
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;

    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) throw Exception("Microphone permission denied");

    _agoraEngine = createAgoraRtcEngine();
    await _agoraEngine
        .initialize(RtcEngineContext(appId: dotenv.env['AGORA_APP_ID']!));

    _setupEventHandlers();

    await _agoraEngine.enableAudio();
    _isInitialized = true;
  }

  Future<void> _joinChannel(String channelName, int uid, String callId) async {
    //  _resetState();
    _callId = callId;

    final token = await _chatRepository.fetchAgoraToken(channelName, uid);
    await _agoraEngine.joinChannel(
      token: token!,
      channelId: channelName,
      uid: uid,
      options: const ChannelMediaOptions(
        autoSubscribeAudio: true,
        publishMicrophoneTrack: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );

    if (_isCaller) {
      _startRinging();
    }

    _callTimeoutTimer = Timer(const Duration(seconds: 40), () {
      if (_remoteUid == null) {
        _updateCallData("not answered");
        endCall();
      }
    });
  }

  void _setupEventHandlers() {
    _agoraEngine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        debugPrint("✅ Local user ${connection.localUid} joined");
        _isJoined = true;
        notifyListeners();
      },
      onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        debugPrint("👤 Remote user $remoteUid joined");
        _remoteUid = remoteUid;
        _stopRinging();
        _startTimer();
        _callTimeoutTimer?.cancel();
        notifyListeners();
      },
      onUserOffline: (RtcConnection connection, int remoteUid,
          UserOfflineReasonType reason) {
        debugPrint("❌ Remote user $remoteUid left due to $reason");
        if (remoteUid == _remoteUid) {
          final duration = _formatDuration(_callDuration);
          _updateCallData("answered", callDuration: duration);
          endCall();
        }
      },
      onLeaveChannel: (RtcConnection connection, RtcStats stats) {
        debugPrint("🚪 Local user left the channel");
        if (_remoteUid == null) {
          _updateCallData("not answered");
        }
      },
      onError: (ErrorCodeType code, String message) {
        debugPrint("⚠️Error joinning channel Agora error: $code - $message");
      },
    ));
  }

  void _listenToSocketTermination() {
    _socketService.onCallTerminated((data) {
      debugPrint("📡 Call termination event received: $data");

      final terminatedCallId = data['callId'];
      if (terminatedCallId == _callId) {
        debugPrint("🔚 Call terminated remotely. Ending call...");
        endCall();
      }
    });
  }

  // Timer
  void _startTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _callDuration += const Duration(seconds: 1);
      if (!_callDurationController.isClosed) {
        _callDurationController.add(_callDuration.inSeconds);
      }
    });
  }

  // Toggle Mute/Speaker
  void toggleMute() {
    if (_isJoined) {
      _isMuted = !_isMuted;
      _agoraEngine.muteLocalAudioStream(_isMuted);
      notifyListeners();
    }
  }

  void toggleSpeaker() {
    if (_isJoined) {
      _isSpeakerOn = !_isSpeakerOn;
      _agoraEngine.setEnableSpeakerphone(_isSpeakerOn);
      notifyListeners();
    }
  }

  // UI Management
  void _showCallScreen() {
    _isCallScreenVisible = true;
    _isOutgoingCallVisible = false;
    removeOutgoingCallOverlay();
    notifyListeners();
  }

  void minimizeCallScreen() {
    _isCallScreenVisible = false;
    _isOutgoingCallVisible = true;

    if (navigatorKey.currentState?.canPop() ?? false) {
      navigatorKey.currentState?.pop();
    }

    showOutgoingCallOverlay();
    notifyListeners();
  }

  void showOutgoingCallOverlay() {
    removeOutgoingCallOverlay();
    _outgoingCallOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 12,
        left: 0,
        right: 0,
        child: SafeArea(
          child: Material(
            color: Colors.transparent,
            child: OutgoingCallUI(
              onTap: () {
                _showCallScreen();
                navigatorKey.currentState?.push(
                  MaterialPageRoute(
                      builder: (_) => const AgoraAudioCallScreen()),
                );
              },
            ),
          ),
        ),
      ),
    );

    navigatorKey.currentState?.overlay?.insert(_outgoingCallOverlay!);
  }

  void removeOutgoingCallOverlay() {
    _outgoingCallOverlay?.remove();
    _outgoingCallOverlay = null;
  }

  void endCall() {
    _durationTimer?.cancel();
    _callTimeoutTimer?.cancel();
    _stopRinging();
    _agoraEngine.leaveChannel();
    _agoraEngine.release();
    _isInitialized = false;
    // ✅ Pop the call screen if it's visible
    if (_isCallScreenVisible && navigatorKey.currentState?.canPop() == true) {
      navigatorKey.currentState?.pop();
    }
    _isCallScreenVisible = false;
    _isOutgoingCallVisible = false;

    removeOutgoingCallOverlay();
    _resetState();
    notifyListeners();
  }

  void _resetState() {
    _remoteUid = null;
    _isJoined = false;
    _isMuted = false;
    _isSpeakerOn = true;
    _callDuration = Duration.zero;
    _durationTimer?.cancel();
    _callTimeoutTimer?.cancel();
    _callDurationController.add(0);
    _ringingPlayer.stop();

    _callId = null;
    _channelName = null;
    _remoteUserName = null;
    _uid = null;
    _isCaller = false;
    _callDetailsMessage = null;
  }

  Future<void> _startRinging() async {
    if (_isRinging) return;
    _isRinging = true;
    await _ringingPlayer.setReleaseMode(ReleaseMode.loop);
    await _ringingPlayer.play(AssetSource('sounds/ringtone.mp3'));
  }

  Future<void> _stopRinging() async {
    if (!_isRinging) return;
    _isRinging = false;
    await _ringingPlayer.stop();
  }

  Future<void> _updateCallData(String status, {String? callDuration}) async {
    if (_callId == null) return;
    try {
      await _chatRepository.updateCallData(_callId!, status,
          callDuration: callDuration);
    } catch (e) {
      debugPrint("Failed to update call data: $e");
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  ChatMessageModel createCallDetailsMessage(String status, String duration) {
    return ChatMessageModel(
      timestamp: DateTime.now(),
      type: 'call',
      callStatus: status,
      callDuration: duration,
      callId: _callId,
    );
  }

  void setCallDetailsMessage(ChatMessageModel message) {
    _callDetailsMessage = message;
    notifyListeners();
  }
}
