// import 'dart:async';

// import 'package:agora_rtc_engine/agora_rtc_engine.dart';
// import 'package:audioplayers/audioplayers.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:kkpchatapp/data/models/chat_message_model.dart';
// import 'package:kkpchatapp/data/repositories/chat_reopsitory.dart';
// import 'package:permission_handler/permission_handler.dart';

// class CallService {
//   late RtcEngine agoraEngine;
//   bool _isInitialized = false;
//   bool _isJoined = false;
//   int? _remoteUid;
//   bool _isMuted = false;
//   bool _isSpeakerOn = true;
//   Duration _callDuration = Duration.zero;
//   Timer? _durationTimer;
//   Timer? _callTimeoutTimer;
//   bool _isRinging = false;
//   final AudioPlayer _ringingPlayer = AudioPlayer();
//   final String agoraAppId = dotenv.env['AGORA_APP_ID']!;
//   final ChatRepository chatRepository = ChatRepository();
//   String? _callId;

//   final StreamController<int> _callDurationController =
//       StreamController<int>.broadcast();
//   Stream<int> get callDurationStream => _callDurationController.stream;

//   bool get isJoined => _isJoined;
//   int? get remoteUid => _remoteUid;
//   bool get isMuted => _isMuted;
//   bool get isSpeakerOn => _isSpeakerOn;
//   Duration get callDuration => _callDuration;
//   bool get isRinging => _isRinging;

//   Future<void> initialize() async {
//     await _handlePermissions();
//     await _setupVoiceSDKEngine();
//     _isInitialized = true;
//   }

//   Future<void> _handlePermissions() async {
//     final micStatus = await Permission.microphone.request();
//     if (!micStatus.isGranted) {
//       throw Exception("Microphone permission not granted");
//     }
//   }

//   Future<void> _setupVoiceSDKEngine() async {
//     agoraEngine = createAgoraRtcEngine();
//     await agoraEngine.initialize(RtcEngineContext(appId: agoraAppId));
//     _setupEventHandlers();
//     await agoraEngine.enableAudio();
//   }

//   void _setupEventHandlers() {
//     agoraEngine.registerEventHandler(RtcEngineEventHandler(
//       onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
//         debugPrint("✅ Local user ${connection.localUid} joined the channel");
//         _isJoined = true;
//       },
//       onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
//         debugPrint("👤 Remote user $remoteUid joined");
//         _remoteUid = remoteUid;
//         _stopRinging();
//         _startCallTimer();
//         _callTimeoutTimer?.cancel();
//       },
//       onUserOffline: (RtcConnection connection, int remoteUid,
//           UserOfflineReasonType reason) {
//         debugPrint("❌ Remote user $remoteUid left due to $reason");
//         final totalCallDuration = formatDuration(_callDuration);
//         _updateCallData("answered", callDuration: totalCallDuration);
//         _endCall();
//       },
//       onLeaveChannel: (RtcConnection connection, RtcStats stats) {
//         debugPrint("🚪 Local user left the channel");
//         if (_remoteUid == null) {
//           _updateCallData("not answered");
//         }
//       },
//     ));
//   }

//   Future<void> join(String channelName, int uid, String callId) async {
//     if (!_isInitialized) {
//       await initialize();
//     }
//     _resetCallState(); // Reset all call-related states
//     _callId = callId;
//     final token = await chatRepository.fetchAgoraToken(channelName, uid);
//     await agoraEngine.joinChannel(
//       token: token!,
//       channelId: channelName,
//       uid: uid,
//       options: const ChannelMediaOptions(
//         autoSubscribeAudio: true,
//         publishMicrophoneTrack: true,
//         clientRoleType: ClientRoleType.clientRoleBroadcaster,
//       ),
//     );
//     _startRinging();
//     _callTimeoutTimer = Timer(const Duration(seconds: 40), () {
//       if (_remoteUid == null) {
//         _updateCallData("not answered");
//         _endCall();
//       }
//     });
//   }

//   void _resetCallState() {
//     _callDuration = Duration.zero;
//     _durationTimer?.cancel();
//     _isMuted = false;
//     _isSpeakerOn = true;
//     _isRinging = false;
//     _ringingPlayer.stop();
//   }

//   void _startCallTimer() {
//     _durationTimer?.cancel();
//     _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
//       _callDuration += const Duration(seconds: 1);
//       if (!_callDurationController.isClosed) {
//         _callDurationController.add(_callDuration.inSeconds);
//       }
//     });
//   }

//   Future<void> _updateCallData(String callStatus,
//       {String? callDuration}) async {
//     if (_callId == null) {
//       debugPrint("Call ID is null. Cannot update call data.");
//       return;
//     }
//     try {
//       await chatRepository.updateCallData(
//         _callId!,
//         callStatus,
//         callDuration: callDuration,
//       );
//     } catch (e) {
//       debugPrint("Error updating call data: $e");
//     }
//   }

//   ChatMessageModel createCallDetailsMessage(
//       String callStatus, String callDuration) {
//     return ChatMessageModel(
//       timestamp: DateTime.now(),
//       type: 'call',
//       callStatus: callStatus,
//       callDuration: callDuration,
//       callId: _callId,
//     );
//   }

//   void toggleMute() {
//     if (_isJoined) {
//       _isMuted = !_isMuted;
//       agoraEngine.muteLocalAudioStream(_isMuted);
//     }
//   }

//   void toggleSpeaker() {
//     if (_isJoined) {
//       _isSpeakerOn = !_isSpeakerOn;
//       agoraEngine.setEnableSpeakerphone(_isSpeakerOn);
//     }
//   }

//   void _endCall() {
//     _durationTimer?.cancel();
//     _callTimeoutTimer?.cancel();
//     agoraEngine.leaveChannel();
//     _stopRinging();
//   }

//   Future<void> _startRinging() async {
//     if (_isRinging) return;
//     _isRinging = true;
//     await _ringingPlayer.setReleaseMode(ReleaseMode.loop);
//     await _ringingPlayer.play(AssetSource('sounds/ringtone.mp3'));
//   }

//   Future<void> _stopRinging() async {
//     if (!_isRinging) return;
//     _isRinging = false;
//     await _ringingPlayer.stop();
//   }

//   String formatDuration(Duration duration) {
//     String twoDigits(int n) => n.toString().padLeft(2, '0');
//     final minutes = twoDigits(duration.inMinutes.remainder(60));
//     final seconds = twoDigits(duration.inSeconds.remainder(60));
//     return "$minutes:$seconds";
//   }

//   void releaseEngine() {
//     _durationTimer?.cancel();
//     _callTimeoutTimer?.cancel();
//     _stopRinging();
//     agoraEngine.leaveChannel();
//     agoraEngine.release();
//     _resetCallState();
//     if (!_callDurationController.isClosed) {
//       _callDurationController.close();
//     }
//   }
// }
