import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:kkpchatapp/core/services/socket_service.dart';
import 'package:kkpchatapp/data/repositories/chat_reopsitory.dart';
import 'package:kkpchatapp/main.dart' show isAppInitialized, navigatorKey;
import 'package:kkpchatapp/presentation/common/chat/call_provider.dart';
import 'package:provider/provider.dart';

class CallKitService {
  static final CallKitService instance = CallKitService._();
  CallKitService._();

  // In-memory pending call data keyed by callId.
  // The `extra` field in CallKitParams covers the killed-app case.
  final Map<String, Map<String, dynamic>> _pendingCalls = {};
  // Records when each call was shown — used to detect simulator false-declines.
  // iOS Simulator fires actionCallDecline/Timeout in ~0 ms; a real user cannot
  // physically respond faster than ~800 ms.
  final Map<String, DateTime> _callShowTimestamps = {};
  StreamSubscription? _eventSubscription;

  // Prevents the circular loop:
  //   CallProvider.endCall → CallKitService.endCall → actionCallEnded → CallProvider.endCall
  bool _endingFromProvider = false;

  void init() {
    _eventSubscription?.cancel();
    _eventSubscription = FlutterCallkitIncoming.onEvent.listen(_onCallEvent);
    // Check if the user accepted a call while the app was killed
    _restoreKilledStateAccept();
  }

  Future<void> showIncomingCall({
    required String callId,
    required String channelName,
    required String callerName,
    required String callerId,
    required int uid,
  }) async {
    _pendingCalls[callId] = {
      'channelName': channelName,
      'callerName': callerName,
      'callerId': callerId,
      'uid': uid,
    };
    _callShowTimestamps[callId] = DateTime.now();

    final params = CallKitParams(
      id: callId,
      nameCaller: callerName,
      handle: callerName,
      type: 0, // audio
      appName: 'KKP Group',
      ios: const IOSParams(
        handleType: 'generic',
        supportsHolding: false,
        supportsGrouping: false,
        supportsUngrouping: false,
        supportsDTMF: false,
        iconName: 'AppIcon',
        ringtonePath: 'system_ringtone_default',
      ),
      // isCustomNotification: true = full-screen notification (WhatsApp style on Android).
      // More reliable than ConnectionService (isCustomNotification: false) across all
      // Android versions and avoids needing the user to grant MANAGE_OWN_CALLS interactively.
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#0B3D91',
        actionColor: '#4CAF50',
        textColor: '#ffffff',
        isCustomSmallExNotification: true,
      ),
      // `extra` is stored inside CallKit on iOS so it survives app kill.
      // On Android it comes back in the event body.
      extra: {
        'channelName': channelName,
        'callerName': callerName,
        'callerId': callerId,
        'uid': uid.toString(),
      },
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  Future<void> endCall(String callId) async {
    _pendingCalls.remove(callId);
    _callShowTimestamps.remove(callId);
    _endingFromProvider = true;
    try {
      await FlutterCallkitIncoming.endCall(callId);
    } catch (e) {
      debugPrint('CallKitService.endCall error: $e');
    } finally {
      _endingFromProvider = false;
    }
  }

  Future<void> endAllCalls() async {
    _pendingCalls.clear();
    _callShowTimestamps.clear();
    _endingFromProvider = true;
    try {
      await FlutterCallkitIncoming.endAllCalls();
    } catch (e) {
      debugPrint('CallKitService.endAllCalls error: $e');
    } finally {
      _endingFromProvider = false;
    }
  }

  // ── Event handling ──────────────────────────────────────────────────────────

  Future<void> _onCallEvent(CallEvent? event) async {
    if (event == null) return;
    final body = (event.body as Map?)?.cast<String, dynamic>() ?? {};
    final callId = body['id']?.toString() ?? body['uuid']?.toString();

    switch (event.event) {
      case Event.actionCallAccept:
        if (callId != null) await _handleAccept(callId, body);
        break;
      case Event.actionCallDecline:
        if (callId != null) await _handleDecline(callId, body);
        break;
      case Event.actionCallTimeout:
        if (callId != null) await _handleTimeout(callId, body);
        break;
      case Event.actionCallEnded:
        // Fired when:
        //   (a) We called endCall() ourselves — skip to avoid loop
        //   (b) System ended the call (iOS green-bar dismiss, lock-screen swipe, etc.)
        //       → we need to clean up the active Agora call
        if (callId != null && !_endingFromProvider) {
          _pendingCalls.remove(callId);
          await _endActiveAgoraCallIfRunning();
        }
        break;
      default:
        break;
    }
  }

  Future<void> _handleAccept(String callId, Map<String, dynamic> body) async {
    // Prefer in-memory data (foreground/background); fall back to CallKit
    // extra field (killed-app restore path).
    Map<String, dynamic>? data = _pendingCalls[callId];
    if (data == null) {
      final extra = (body['extra'] as Map?)?.cast<String, dynamic>() ?? {};
      final uid = int.tryParse(extra['uid']?.toString() ?? '');
      if (uid == null || extra['channelName'] == null) {
        debugPrint('CallKitService: accept ignored — missing extra data');
        return;
      }
      data = {
        'channelName': extra['channelName'].toString(),
        'callerName': extra['callerName']?.toString() ?? '',
        'callerId': extra['callerId']?.toString() ?? '',
        'uid': uid,
      };
    }

    _pendingCalls.remove(callId);

    // Wait for the Flutter app to finish its own init (killed-state cold start)
    int attempts = 0;
    while (!isAppInitialized && attempts < 80) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint('CallKitService: accept — context unavailable after waiting');
      return;
    }

    // ignore: use_build_context_synchronously
    final callProvider = Provider.of<CallProvider>(context, listen: false);
    await callProvider.startNewCall(
      channelName: data['channelName'] as String,
      remoteUserName: data['callerName'] as String,
      uid: data['uid'] as int,
      callId: callId,
      isCaller: false,
      targetUserId: data['callerId'] as String?,
    );
  }

  Future<void> _handleDecline(String callId, Map<String, dynamic> body) async {
    // iOS Simulator fires an instant decline (~0 ms) because CallKit is not
    // supported. Guard: ignore any decline within 800 ms of showing the call.
    final showTime = _callShowTimestamps.remove(callId);
    if (showTime != null &&
        DateTime.now().difference(showTime).inMilliseconds < 800) {
      debugPrint(
          'CallKitService: ignoring instant decline — iOS Simulator has no CallKit');
      return;
    }

    final data = _pendingCalls.remove(callId);

    // Defensive cast: on Android the body values arrive as _Map<dynamic,dynamic>
    final rawExtra = body['extra'];
    final extra = rawExtra is Map
        ? Map<String, dynamic>.from(rawExtra)
        : <String, dynamic>{};

    final callerId = (data?['callerId'] ?? extra['callerId'])?.toString();
    final channelName =
        (data?['channelName'] ?? extra['channelName'])?.toString();

    try {
      await ChatRepository().updateCallData(callId, 'not answered');
    } catch (e) {
      debugPrint('CallKitService.decline updateCallData error: $e');
    }

    if (callerId != null && callerId.isNotEmpty &&
        channelName != null && channelName.isNotEmpty) {
      try {
        SocketService(navigatorKey).terminateCall(
          targetId: callerId,
          callId: callId,
          channelName: channelName,
        );
      } catch (e) {
        debugPrint('CallKitService.decline terminateCall error: $e');
      }
    } else {
      debugPrint(
          'CallKitService: decline — callerId or channelName missing, terminate not sent '
          '(callerId=$callerId, channelName=$channelName)');
    }
  }

  Future<void> _handleTimeout(String callId, Map<String, dynamic> body) async {
    final showTime = _callShowTimestamps.remove(callId);
    if (showTime != null &&
        DateTime.now().difference(showTime).inMilliseconds < 800) {
      debugPrint(
          'CallKitService: ignoring instant timeout — iOS Simulator has no CallKit');
      return;
    }

    _pendingCalls.remove(callId);
    try {
      await ChatRepository().updateCallData(callId, 'missed');
    } catch (e) {
      debugPrint('CallKitService.timeout updateCallData error: $e');
    }
  }

  // Called when the OS ends a call that our app already accepted (e.g. user
  // swipes away the iOS in-call green bar while on AgoraAudioCallScreen).
  Future<void> _endActiveAgoraCallIfRunning() async {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    try {
      // ignore: use_build_context_synchronously
      final callProvider = Provider.of<CallProvider>(context, listen: false);
      if (callProvider.isCallScreenVisible) {
        callProvider.endCall(notifyRemote: true);
      }
    } catch (e) {
      debugPrint('CallKitService._endActiveAgoraCallIfRunning error: $e');
    }
  }

  // Cold-start after user accepted from lock screen while app was killed.
  // Validates every active call before restoring — stale / invalid calls
  // are ended immediately to prevent Agora from initialising unnecessarily
  // (which was causing IrisMethodChannel to stay alive / memory leak).
  Future<void> _restoreKilledStateAccept() async {
    try {
      final calls = await FlutterCallkitIncoming.activeCalls();
      if (calls == null || (calls as List).isEmpty) return;

      bool restoredAny = false;
      for (final call in calls) {
        final callMap = (call as Map).cast<String, dynamic>();
        final callId =
            callMap['id']?.toString() ?? callMap['uuid']?.toString();
        if (callId == null) continue;

        final isAccepted =
            callMap['isAccepted'] == true || callMap['hasAccepted'] == true;

        if (!isAccepted) {
          // Stale ringing notification from a previous session — clear it.
          debugPrint(
              'CallKitService: clearing stale non-accepted call $callId');
          await FlutterCallkitIncoming.endCall(callId);
          continue;
        }

        // Validate the call data before attempting to rejoin Agora.
        final rawExtra = callMap['extra'];
        final extra = rawExtra is Map
            ? Map<String, dynamic>.from(rawExtra)
            : <String, dynamic>{};
        final uid = int.tryParse(extra['uid']?.toString() ?? '');
        final channelName = extra['channelName']?.toString() ?? '';

        // uid must be a positive integer and channelName must be set.
        // uid=0 happens when the FCM background handler couldn't compute the
        // real uid — treat it as stale and end the call.
        if (uid == null || uid <= 0 || channelName.isEmpty) {
          debugPrint(
              'CallKitService: clearing invalid accepted call $callId '
              '(uid=$uid, channel="$channelName") — prevents Agora memory leak');
          await FlutterCallkitIncoming.endCall(callId);
          continue;
        }

        restoredAny = true;
        await _handleAccept(callId, callMap);
      }

      if (!restoredAny) {
        // Safety net: if nothing was worth restoring, wipe the slate clean.
        await FlutterCallkitIncoming.endAllCalls();
      }
    } catch (e) {
      debugPrint('CallKitService._restoreKilledStateAccept error: $e');
      // Safety net: clear all stale calls so Agora is never init'd spuriously.
      try {
        await FlutterCallkitIncoming.endAllCalls();
      } catch (_) {}
    }
  }
}
