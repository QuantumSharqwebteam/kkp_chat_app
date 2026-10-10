import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kkpchatapp/core/services/call_kit_service.dart';
import 'package:kkpchatapp/core/services/notification_service.dart';
import 'package:kkpchatapp/core/services/socket_service.dart';
import 'package:kkpchatapp/data/models/chat_message_model.dart';
import 'package:kkpchatapp/data/repositories/chat_reopsitory.dart';
import 'package:kkpchatapp/presentation/common/chat/agora_audio_call_screen.dart';
import 'package:kkpchatapp/presentation/common/chat/outgoing_call_ui.dart';
import 'package:permission_handler/permission_handler.dart';

class CallProvider with ChangeNotifier {
  final GlobalKey<NavigatorState> navigatorKey;
  late final SocketService _socketService;

  CallProvider(this.navigatorKey) {
    _socketService = SocketService(navigatorKey);
    _socketService.onCallTerminated(_onRemoteTerminated);
  }

  /// Receiver joins an existing channel — the caller is normally already
  /// there, so onUserJoined fires within a second or two. If nobody shows up
  /// in this window the caller has already gone: stop instead of showing
  /// "Ringing..." until the 40 s caller timeout.
  static const _receiverJoinTimeout = Duration(seconds: 12);
  static const _callerRingTimeout = Duration(seconds: 40);

  /// Other side hung up / cancelled.
  ///
  /// BUG FIX: previously this only acted when `callId == _callId`. While the
  /// agent's phone is still RINGING (not yet answered) `_callId` is null, so
  /// the event was dropped: the incoming-call banner stayed up, and tapping
  /// Answer joined an empty channel stuck on "Ringing...".
  void _onRemoteTerminated(Map<String, dynamic> data) {
    debugPrint("📡 Call termination event received: $data");
    final id = data['callId']?.toString();
    final channel = data['channelName']?.toString();
    final fromCallLog = data['source'] == 'callLog';
    if ((id == null || id.isEmpty) && (channel == null || channel.isEmpty)) {
      return;
    }

    final matchesActive = (id != null && id.isNotEmpty && id == _callId) ||
        ((id == null || id.isEmpty) &&
            channel != null &&
            channel == _channelName);

    if (matchesActive) {
      // A "not answered" log must never kill a call that is already connected.
      if (fromCallLog && isRemoteConnected) return;
      endCall(notifyRemote: false);
      return;
    }

    // Not the active call → it's (probably) still ringing on this device.
    if (id != null && id.isNotEmpty) {
      CallKitService.instance
          .dismissCancelledCall(id, fromCallLog: fromCallLog);
    }

    // Agora was pre-warmed for that ringing call — release it, nothing to join.
    final preWarmMatches = channel != null
        ? channel == _preWarmChannelName
        : !fromCallLog; // a bare call log can't prove it's the same call
    if (_callId == null && preWarmMatches) {
      _releasePreWarm();
    }
  }

  void _releasePreWarm() {
    _preWarmToken = _preWarmChannelName = null;
    if (_isInitialized) {
      debugPrint('🧹 [CallProvider] Releasing pre-warmed Agora engine');
      _agoraEngine.release();
      _isInitialized = false;
    }
  }

  /// True if [callId] is no longer the call this provider is working on
  /// (ended / replaced while we were awaiting something).
  bool _isStale(String callId) => _callId != callId;

  void _showCallEndedMessage() {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('Call ended')),
    );
  }

  final ChatRepository _chatRepository = ChatRepository();
  final AudioPlayer _ringingPlayer = AudioPlayer();
  final StreamController<int> _durationCtrl = StreamController<int>.broadcast();

  late RtcEngine _agoraEngine;
  bool _isInitialized = false, _isJoined = false, _isRinging = false;
  bool _isMuted = false, _isSpeakerOn = true, _isCaller = false;
  bool _isCallScreenVisible = false, _isOutgoingCallVisible = false;

  /// Ensures the call log is written exactly once per call, no matter who
  /// ends it (local hang-up, remote hang-up, timeout, socket terminate).
  bool _callFinalized = false;

  int? _remoteUid, _uid;
  Duration _callDuration = Duration.zero;
  Timer? _durationTimer, _callTimeoutTimer;
  String? _callId, _targetUserId, _myUserId, _channelName, _remoteUserName;
  String? _preWarmToken, _preWarmChannelName;
  OverlayEntry? _outgoingCallOverlay;
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
  bool get isCaller => _isCaller;
  String? get callId => _callId;
  Duration get callDuration => _callDuration;
  Stream<int> get callDurationStream => _durationCtrl.stream;
  bool get isRemoteConnected => _remoteUid != null;
  String get callDurationFormatted => _formatDuration(_callDuration);

  /// Status line for the call screen. The RECEIVER must never show
  /// "Ringing..." — its phone already rang; it is only connecting.
  String get callStatusText {
    if (isRemoteConnected) return callDurationFormatted;
    return _isCaller ? 'Ringing...' : 'Connecting...';
  }

  /// Email/ID of whoever PLACED the call (used as the call message sender).
  /// Never null for the caller: falls back to the socket's logged-in email.
  String? get callerId {
    if (_isCaller) {
      final me = _myUserId ?? _socketService.currentUserEmail;
      return (me != null && me.trim().isNotEmpty) ? me.trim() : null;
    }
    final other = _targetUserId;
    return (other != null && other.trim().isNotEmpty) ? other.trim() : null;
  }

  /// Called when the native incoming-call UI appears: init Agora + cache token.
  Future<void> preWarm({required String channelName, required int uid}) async {
    if (_isInitialized && _preWarmChannelName == channelName) return;
    debugPrint('🔥 [CallProvider] Pre-warming Agora for channel $channelName');
    try {
      await _initialize();
      final token = await _chatRepository.fetchAgoraToken(channelName, uid);
      if (token != null) {
        _preWarmToken = token;
        _preWarmChannelName = channelName;
      }
    } catch (e) {
      debugPrint('⚠️ [CallProvider] Pre-warm failed (non-fatal): $e');
    }
  }

  /// [targetUserId] is ALWAYS the other party:
  ///   - caller  → the person being called
  ///   - receiver → the caller (callerId from the incomingCall payload)
  /// The receiver MUST pass it, otherwise its local call log can't be patched.
  Future<void> startNewCall({
    required String channelName,
    required String remoteUserName,
    required int uid,
    required String callId,
    required bool isCaller,
    String? targetUserId,
    String?
        myUserId, // logged-in user's email/ID — ALWAYS pass this for the caller
  }) async {
    // Receiver answered a call the caller already cut → don't join at all.
    if (!isCaller && CallKitService.instance.wasTerminated(callId)) {
      debugPrint(
          '📴 [CallProvider] $callId already ended by caller — not joining');
      await CallKitService.instance.endCall(callId);
      _showCallEndedMessage();
      return;
    }

    _channelName = channelName;
    _remoteUserName = remoteUserName;
    _uid = uid;
    _callId = callId;
    _isCaller = isCaller;
    _targetUserId = targetUserId;
    _myUserId = myUserId ?? _socketService.currentUserEmail;
    _callFinalized = false;
    _callDetailsMessage = null;

    if (_isCaller && (callerId == null)) {
      debugPrint(
          '⚠️ [CallProvider] Caller email unknown — call log will have no sender. '
          'Pass myUserId to startNewCall().');
    }
    if (!_isCaller && (_targetUserId == null || _targetUserId!.isEmpty)) {
      debugPrint(
          '⚠️ [CallProvider] Receiver has no targetUserId (caller email) — '
          'local call log cannot be patched to "answered".');
    }

    await NotificationService.plugin.cancelAll();
    await _initialize();
    if (_isStale(callId)) return; // hung up while we were initialising
    if (_preWarmChannelName != channelName) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (_isStale(callId)) return;
    }
    final joined = await _joinChannel(channelName, uid, callId);
    if (!joined || _isStale(callId)) return;
    _openCallScreen();
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;
    if (!(await Permission.microphone.request()).isGranted) {
      throw Exception("Microphone permission denied");
    }
    _agoraEngine = createAgoraRtcEngine();
    await _agoraEngine
        .initialize(RtcEngineContext(appId: dotenv.env['AGORA_APP_ID']!));
    _setupEventHandlers();
    await _agoraEngine.enableAudio();
    _isInitialized = true;
  }

  /// Returns false if the call was ended while we were getting ready.
  Future<bool> _joinChannel(String channelName, int uid, String callId) async {
    String? token;
    if (_preWarmToken != null && _preWarmChannelName == channelName) {
      token = _preWarmToken;
      _preWarmToken = _preWarmChannelName = null;
      debugPrint('⚡ [CallProvider] Using pre-warmed token');
    } else {
      token = await _chatRepository.fetchAgoraToken(channelName, uid);
    }

    // endCall() may have run during the token fetch and released the engine.
    if (_isStale(callId) || !_isInitialized) return false;
    if (token == null) {
      debugPrint('⚠️ [CallProvider] No Agora token — ending call');
      endCall(notifyRemote: _isCaller);
      return false;
    }

    await _agoraEngine.joinChannel(
      token: token,
      channelId: channelName,
      uid: uid,
      options: const ChannelMediaOptions(
        autoSubscribeAudio: true,
        publishMicrophoneTrack: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );

    if (_isStale(callId)) {
      // Hung up during joinChannel — endCall already released the engine.
      return false;
    }

    // Remote may already be in the channel (receiver case) — onUserJoined can
    // fire before we get here, so only ring / arm the timer if still waiting.
    if (_remoteUid != null) return true;

    if (_isCaller) _startRinging();

    _callTimeoutTimer?.cancel();
    _callTimeoutTimer = Timer(
      _isCaller ? _callerRingTimeout : _receiverJoinTimeout,
      () {
        if (_isStale(callId) || _remoteUid != null) return;
        // Caller: endCall() writes the "not answered" log via _finalizeCallLog().
        // Receiver: the caller is gone (hung up before we connected).
        final wasReceiver = !_isCaller;
        endCall(notifyRemote: true);
        if (wasReceiver) _showCallEndedMessage();
      },
    );
    return true;
  }

  void _setupEventHandlers() {
    _agoraEngine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (conn, __) {
        debugPrint("✅ Local user ${conn.localUid} joined");
        _isJoined = true;
        notifyListeners();
      },
      onUserJoined: (_, remoteUid, __) {
        debugPrint("👤 Remote user $remoteUid joined");
        _remoteUid = remoteUid;
        _stopRinging();
        _startTimer();
        _callTimeoutTimer?.cancel();
        notifyListeners();
      },
      onUserOffline: (_, remoteUid, reason) {
        debugPrint("❌ Remote user $remoteUid left due to $reason");
        if (remoteUid != _remoteUid) return;
        // Remote hung up — endCall() writes the "answered" log.
        endCall(notifyRemote: false);
      },
      onError: (code, msg) => debugPrint("⚠️ Agora error: $code - $msg"),
    ));
  }

  void _startTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _callDuration += const Duration(seconds: 1);
      if (!_durationCtrl.isClosed) _durationCtrl.add(_callDuration.inSeconds);
    });
  }

  void toggleMute() {
    if (!_isJoined) return;
    _isMuted = !_isMuted;
    _agoraEngine.muteLocalAudioStream(_isMuted);
    notifyListeners();
  }

  void toggleSpeaker() {
    if (!_isJoined) return;
    _isSpeakerOn = !_isSpeakerOn;
    _agoraEngine.setEnableSpeakerphone(_isSpeakerOn);
    notifyListeners();
  }

  // UI
  void _openCallScreen() {
    _isCallScreenVisible = true;
    _isOutgoingCallVisible = false;
    removeOutgoingCallOverlay();
    notifyListeners();
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const AgoraAudioCallScreen()),
    );
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
            child: OutgoingCallUI(onTap: _openCallScreen),
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

  /// Writes the call log (local bubble + local cache + server status) once.
  /// MUST run before _resetState(), which wipes the caller/duration info.
  void _finalizeCallLog() {
    if (_callFinalized || _callId == null) return;
    _callFinalized = true;

    final callId = _callId!;
    final peer = _targetUserId;
    final answered = _remoteUid != null || _callDuration > Duration.zero;
    final status = answered ? 'answered' : 'not answered';
    final duration = _formatDuration(_callDuration);

    debugPrint('📞 [CallProvider] finalize callId=$callId '
        'isCaller=$_isCaller status=$status duration=$duration peer=$peer');

    setCallDetailsMessage(createCallDetailsMessage(status, duration));

    // Server record:
    //  - Caller always writes (answered / not answered).
    //  - Receiver writes ONLY "answered" as a backup — restores the old
    //    behaviour where both sides reported, so the log isn't stuck at the
    //    server's "missed" placeholder if the caller's app dies / goes
    //    offline before its update lands. Both sides send "answered", so
    //    there's no conflicting race.
    if (_isCaller || answered) {
      _updateCallData(callId, status, callDuration: answered ? duration : null);
    }

    // Local cache: THIS is what fixes the agent seeing "Call missed".
    // The chat list was cached with the server placeholder ("missed") while
    // the call was ringing; nothing ever updated it afterwards.
    if (peer != null && peer.isNotEmpty && (_isCaller || answered)) {
      _socketService.patchCallLog(
        callId: callId,
        peerEmail: peer,
        callStatus: status,
        callDuration: answered ? duration : null,
      );
    }
  }

  void endCall({bool notifyRemote = true}) {
    _finalizeCallLog();

    _durationTimer?.cancel();
    _callTimeoutTimer?.cancel();
    _stopRinging();
    NotificationService.plugin.cancelAll();

    if (notifyRemote && _targetUserId != null && _callId != null) {
      _socketService.terminateCall(
        targetId: _targetUserId!,
        callId: _callId!,
        channelName: _channelName,
      );
    }

    // Guard: engine may not be created yet (e.g. early socket terminate).
    if (_isInitialized) {
      _agoraEngine.leaveChannel();
      _agoraEngine.release();
      _isInitialized = false;
    }

    if (_isCallScreenVisible && navigatorKey.currentState?.canPop() == true) {
      navigatorKey.currentState?.pop();
    }
    removeOutgoingCallOverlay();
    if (_callId != null) CallKitService.instance.endCall(_callId!);

    _resetState();
    notifyListeners();
  }

  void _resetState() {
    _remoteUid = _uid = null;
    _isJoined = _isMuted = _isCaller = false;
    _isCallScreenVisible = _isOutgoingCallVisible = false;
    _isSpeakerOn = true;
    _callFinalized = false;
    _callDuration = Duration.zero;
    if (!_durationCtrl.isClosed) _durationCtrl.add(0);
    _ringingPlayer.stop();
    _callId = _targetUserId = _myUserId = _channelName = _remoteUserName = null;
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

  /// Takes callId explicitly: this runs async after _resetState() nulls _callId.
  Future<void> _updateCallData(String callId, String status,
      {String? callDuration}) async {
    try {
      await _chatRepository.updateCallData(callId, status,
          callDuration: callDuration);
    } catch (e) {
      debugPrint("Failed to update call data: $e");
    }
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}";
  }

  ChatMessageModel createCallDetailsMessage(String status, String duration) {
    final caller = callerId ?? '';
    return ChatMessageModel(
      sender: caller, // caller is the sender → correct side
      callerId: caller, // survives Hive/API reload
      timestamp: DateTime.now(),
      type: 'call',
      callStatus: status,
      callDuration: duration,
      callId: _callId,
      messageId: _callId,
      read: true,
    );
  }

  void setCallDetailsMessage(ChatMessageModel message) {
    _callDetailsMessage = message;
    notifyListeners();
  }
}
