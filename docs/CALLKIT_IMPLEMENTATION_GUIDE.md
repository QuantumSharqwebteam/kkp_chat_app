# Native Call UI Implementation Guide
## Flutter CallKit Incoming — iOS (CallKit) + Android (Full-Screen Notification)

---

## Table of Contents

1. [What We Built](#1-what-we-built)
2. [Package Choice](#2-package-choice)
3. [Architecture Overview](#3-architecture-overview)
4. [Step-by-Step Implementation](#4-step-by-step-implementation)
   - [4.1 pubspec.yaml](#41-pubspecyaml)
   - [4.2 iOS — Info.plist](#42-ios--infoplist)
   - [4.3 iOS — Runner.entitlements](#43-ios--runnerentitlements)
   - [4.4 iOS — AppDelegate.swift](#44-ios--appdelegateswift)
   - [4.5 Android — AndroidManifest.xml](#45-android--androidmanifestxml)
   - [4.6 Android — build.gradle](#46-android--buildgradle)
   - [4.7 CallKitService (core singleton)](#47-callkitservice-core-singleton)
   - [4.8 main.dart](#48-maindart)
   - [4.9 Host Screens](#49-host-screens)
   - [4.10 CallProvider](#410-callprovider)
   - [4.11 SocketService — background handling](#411-socketservice--background-handling)
5. [Call Flow Diagrams](#5-call-flow-diagrams)
6. [Key Problems & How We Solved Them](#6-key-problems--how-we-solved-them)
7. [Testing Checklist](#7-testing-checklist)

---

## 1. What We Built

**Before:** Incoming calls showed a Flutter `OverlayEntry` banner that only worked while the app was in the foreground.

**After:** The WhatsApp model:
- iOS — native **CallKit** screen appears on the lock screen, no unlock needed
- Android — native **full-screen notification** (WhatsApp-style) on the lock screen
- User accepts → app opens to our existing `AgoraAudioCallScreen`
- User declines → call logged as "not answered", caller notified via socket
- All existing Agora + socket logic is untouched

---

## 2. Package Choice

```
flutter_callkit_incoming: ^2.2.0   (resolves to 2.5.8)
```

**Why this package:**
- Single API for both iOS (CallKit) and Android (full-screen notification)
- Provides an event stream (`FlutterCallkitIncoming.onEvent`) for Accept / Decline / Timeout / Ended
- Stores `extra` metadata inside the native call record — survives app kill
- Actively maintained, widely used

**iOS vs Android internals:**

| Platform | Mechanism | Works on lock screen |
|----------|-----------|---------------------|
| iOS | `CXProvider` / `CXCallController` (CallKit) | Yes |
| Android (`isCustomNotification: true`) | Full-screen notification + `CallkitIncomingActivity` | Yes |
| Android (`isCustomNotification: false`) | `ConnectionService` / `TelecomManager` | Yes, but fails silently on many devices |

We chose `isCustomNotification: true` on Android because `ConnectionService` requires the user to interactively grant `MANAGE_OWN_CALLS` and silently fails on many Android OEM builds.

---

## 3. Architecture Overview

```
SOCKET EVENT / FCM PUSH
        │
        ▼
  marketing_host.dart          (agent role)
  customer_host.dart           (customer role)
  _handleIncomingCall()
        │
        ▼
  CallKitService.showIncomingCall()
  ┌─────────────────────────────────────┐
  │  _pendingCalls[callId] = data       │  ← in-memory store
  │  _callShowTimestamps[callId] = now  │  ← simulator guard
  │  FlutterCallkitIncoming             │
  │    .showCallkitIncoming(params)     │
  └─────────────────────────────────────┘
        │
        ▼
  Native OS call screen (lock screen)
        │
   ┌────┴────┐
   │         │
 Accept    Decline
   │         │
   ▼         ▼
_handleAccept  _handleDecline
   │               │
   │         updateCallData("not answered")
   │         socket.terminateCall()
   │
   ▼
CallProvider.startNewCall()
   │
   ▼
AgoraAudioCallScreen
   │
 End call
   │
   ▼
CallProvider.endCall()
   │
   ▼
CallKitService.endCall()     ← dismisses native UI
```

---

## 4. Step-by-Step Implementation

### 4.1 pubspec.yaml

```yaml
dependencies:
  flutter_callkit_incoming: ^2.2.0
```

Run `flutter pub get` after adding.

---

### 4.2 iOS — Info.plist

Location: `ios/Runner/Info.plist`

Add `voip` to the `UIBackgroundModes` array. This tells iOS that your app handles VoIP calls and allows CallKit to wake the app.

```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
    <string>processing</string>
    <string>voip</string>       <!-- ADD THIS -->
</array>
```

**Why:** Without `voip` in background modes, iOS will not give your app CPU time to present a CallKit screen when the app is backgrounded. The call would either be missed or the screen would appear too late.

---

### 4.3 iOS — Runner.entitlements

Location: `ios/Runner/Runner.entitlements`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "...">
<plist version="1.0">
<dict>
    <key>aps-environment</key>
    <string>development</string>
</dict>
</plist>
```

No additional entitlements are required beyond `aps-environment` for the current implementation.

---

### 4.4 iOS — AppDelegate.swift

Location: `ios/Runner/AppDelegate.swift`

Key additions:

**a. Import CallKit:**
```swift
import CallKit
```

**b. Suppress duplicate FCM notification when CallKit is already showing:**

When a call arrives via FCM and CallKit is already showing the native call screen, iOS would normally also show a push notification banner — resulting in two simultaneous alerts. This `willPresent` override prevents that:

```swift
override func userNotificationCenter(_ center: UNUserNotificationCenter,
  willPresent notification: UNNotification,
  withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

  let userInfo = notification.request.content.userInfo
  let isCallNotification = (userInfo["notificationType"] as? String) == "incoming_call"
    || (userInfo["type"] as? String) == "incoming_call"

  if isCallNotification {
    let activeCalls = CXCallObserver().calls
    if activeCalls.contains(where: { !$0.hasEnded }) {
      completionHandler([])   // suppress banner — CallKit is already showing
      return
    }
  }

  if #available(iOS 14.0, *) {
    completionHandler([.banner, .sound, .badge])
  } else {
    completionHandler([.alert, .sound, .badge])
  }
}
```

**c. Socket background keepalive (already existed):**

The method channel `com.kkpchatapp/background_task` lets Flutter call `beginBackgroundTask` / `endBackgroundTask` to keep the socket alive for ~30 seconds after the app backgrounds.

---

### 4.5 Android — AndroidManifest.xml

Location: `android/app/src/main/AndroidManifest.xml`

**Permissions to add:**
```xml
<uses-permission android:name="android.permission.READ_PHONE_STATE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

**Do NOT add:**
- `MANAGE_OWN_CALLS` — only needed for `isCustomNotification: false` (ConnectionService mode)
- `CALL_PHONE` — not needed for our use case

**Inside `<application>`, add the broadcast receiver:**
```xml
<receiver
    android:name="com.hiennv.flutter_callkit_incoming.CallkitIncomingBroadcastReceiver"
    android:exported="true">
    <intent-filter>
        <action android:name="com.hiennv.flutter_callkit_incoming.action.CALL_INCOMING"/>
        <action android:name="com.hiennv.flutter_callkit_incoming.action.CALL_ACCEPT"/>
        <action android:name="com.hiennv.flutter_callkit_incoming.action.CALL_DECLINE"/>
        <action android:name="com.hiennv.flutter_callkit_incoming.action.CALL_ENDED"/>
        <action android:name="com.hiennv.flutter_callkit_incoming.action.CALL_TIMEOUT"/>
        <action android:name="com.hiennv.flutter_callkit_incoming.action.CALL_CALLBACK"/>
    </intent-filter>
</receiver>
```

**Do NOT redeclare `CallkitIncomingActivity`:**

The plugin's own `AndroidManifest.xml` already declares this activity with `@style/CallkitIncomingTheme`. If you redeclare it with a different theme (e.g. `@style/LaunchTheme`), the manifest merger will throw:

```
Attribute activity#CallkitIncomingActivity@theme value=(@style/LaunchTheme)
is also present at [:flutter_callkit_incoming] value=(@style/CallkitIncomingTheme)
```

Let the plugin own its activity declaration.

---

### 4.6 Android — build.gradle

Location: `android/app/build.gradle`

Upgrade Java/Kotlin target from the deprecated `VERSION_1_8` to `VERSION_11`:

```groovy
compileOptions {
    sourceCompatibility = JavaVersion.VERSION_11   // was VERSION_1_8
    targetCompatibility = JavaVersion.VERSION_11
    coreLibraryDesugaringEnabled true
}

kotlinOptions {
    jvmTarget = JavaVersion.VERSION_11             // was VERSION_1_8
}
```

**Why:** Java 8 is deprecated in modern Android Gradle toolchains. Using it produces ~30 warnings per build (`source value 8 is obsolete`). Java 11 is the minimum non-deprecated version.

---

### 4.7 CallKitService (core singleton)

Location: `lib/core/services/call_kit_service.dart`

This is the central piece. Here is the complete file with explanations for each section:

```dart
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
  // ── Singleton ──────────────────────────────────────────────────────────────
  static final CallKitService instance = CallKitService._();
  CallKitService._();

  // ── State ──────────────────────────────────────────────────────────────────
  
  // Stores call metadata while the call is ringing (in-memory).
  // Key = callId, Value = {channelName, callerName, callerId, uid}
  // This is the primary data source for _handleAccept.
  final Map<String, Map<String, dynamic>> _pendingCalls = {};

  // Timestamps for simulator guard (see _handleDecline).
  final Map<String, DateTime> _callShowTimestamps = {};

  StreamSubscription? _eventSubscription;

  // Prevents a circular endCall loop:
  //   CallProvider.endCall() → CallKitService.endCall()
  //   → FlutterCallkitIncoming.endCall() → actionCallEnded event
  //   → _endActiveAgoraCallIfRunning() → CallProvider.endCall() again ← BAD
  bool _endingFromProvider = false;
```

**`init()` — called once at app startup:**

```dart
  void init() {
    _eventSubscription?.cancel();
    _eventSubscription = FlutterCallkitIncoming.onEvent.listen(_onCallEvent);
    // Handle the case where the app was killed and user accepted from lock screen
    _restoreKilledStateAccept();
  }
```

**`showIncomingCall()` — called by the host screens:**

```dart
  Future<void> showIncomingCall({
    required String callId,
    required String channelName,
    required String callerName,
    required String callerId,
    required int uid,
  }) async {
    // 1. Store data in memory so _handleAccept can retrieve it
    _pendingCalls[callId] = {
      'channelName': channelName,
      'callerName': callerName,
      'callerId': callerId,
      'uid': uid,
    };
    // 2. Record show time (simulator guard)
    _callShowTimestamps[callId] = DateTime.now();

    // 3. Build params
    final params = CallKitParams(
      id: callId,
      nameCaller: callerName,
      handle: callerName,
      type: 0, // 0 = audio, 1 = video
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
      android: const AndroidParams(
        isCustomNotification: true,   // WhatsApp-style full-screen notification
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#0B3D91',
        actionColor: '#4CAF50',
        textColor: '#ffffff',
        isCustomSmallExNotification: true,
      ),
      // IMPORTANT: extra is persisted inside the native call record.
      // On iOS, CallKit stores this in its database — it survives app kill.
      // On Android, it comes back in the event body.
      // This is the fallback data source for _handleAccept when _pendingCalls
      // is empty (app was killed before user accepted).
      extra: {
        'channelName': channelName,
        'callerName': callerName,
        'callerId': callerId,
        'uid': uid.toString(),
      },
    );

    // 4. Show the native OS call screen
    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }
```

**`endCall()` — called by CallProvider when in-call screen ends the call:**

```dart
  Future<void> endCall(String callId) async {
    _pendingCalls.remove(callId);
    _callShowTimestamps.remove(callId);
    _endingFromProvider = true;   // set flag to block the circular loop
    try {
      await FlutterCallkitIncoming.endCall(callId);
    } finally {
      _endingFromProvider = false;
    }
  }
```

**`_handleAccept()` — user tapped Accept on the native call screen:**

```dart
  Future<void> _handleAccept(String callId, Map<String, dynamic> body) async {
    // Try in-memory first (normal foreground/background path)
    Map<String, dynamic>? data = _pendingCalls[callId];

    if (data == null) {
      // Fallback: app was killed, read from CallKit extra field
      final extra = (body['extra'] as Map?)?.cast<String, dynamic>() ?? {};
      final uid = int.tryParse(extra['uid']?.toString() ?? '');
      if (uid == null || extra['channelName'] == null) return;
      data = {
        'channelName': extra['channelName'].toString(),
        'callerName': extra['callerName']?.toString() ?? '',
        'callerId': extra['callerId']?.toString() ?? '',
        'uid': uid,
      };
    }

    _pendingCalls.remove(callId);

    // If the app was killed and is cold-starting, wait for Flutter init to finish
    // (providers to be registered, navigatorKey to have a context, etc.)
    int attempts = 0;
    while (!isAppInitialized && attempts < 80) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    final context = navigatorKey.currentContext;
    if (context == null) return;

    // Navigate to the Agora call screen via CallProvider
    final callProvider = Provider.of<CallProvider>(context, listen: false);
    await callProvider.startNewCall(
      channelName: data['channelName'] as String,
      remoteUserName: data['callerName'] as String,
      uid: data['uid'] as int,
      callId: callId,
      isCaller: false,           // we are the receiver
      targetUserId: data['callerId'] as String?,
    );
  }
```

**`_handleDecline()` — user tapped Decline:**

```dart
  Future<void> _handleDecline(String callId, Map<String, dynamic> body) async {
    // ── Simulator guard ──────────────────────────────────────────────────────
    // iOS Simulator does NOT support CallKit. When showCallkitIncoming() is
    // called on a simulator, the plugin immediately fires actionCallDecline
    // (within ~0 ms) because CallKit silently fails. Without this guard, every
    // call on the simulator would instantly be marked "not answered".
    //
    // Real users cannot physically tap Decline in under 800 ms.
    final showTime = _callShowTimestamps.remove(callId);
    if (showTime != null &&
        DateTime.now().difference(showTime).inMilliseconds < 800) {
      debugPrint('CallKitService: ignoring instant decline — iOS Simulator');
      return;
    }
    // ── End simulator guard ──────────────────────────────────────────────────

    final data = _pendingCalls.remove(callId);
    final extra = (body['extra'] as Map?)?.cast<String, dynamic>() ?? {};
    final callerId = (data?['callerId'] ?? extra['callerId'])?.toString();
    final channelName = (data?['channelName'] ?? extra['channelName'])?.toString();

    // 1. Log the call as "not answered" in your backend
    await ChatRepository().updateCallData(callId, 'not answered');

    // 2. Notify the caller to stop ringing
    if (callerId != null && channelName != null) {
      SocketService(navigatorKey).terminateCall(
        targetId: callerId,
        callId: callId,
        channelName: channelName,
      );
    }
  }
```

**`_handleTimeout()` — call rang with no answer:**

```dart
  Future<void> _handleTimeout(String callId, Map<String, dynamic> body) async {
    // Same simulator guard as _handleDecline
    final showTime = _callShowTimestamps.remove(callId);
    if (showTime != null &&
        DateTime.now().difference(showTime).inMilliseconds < 800) {
      return;
    }
    _pendingCalls.remove(callId);
    await ChatRepository().updateCallData(callId, 'missed');
  }
```

**`_endActiveAgoraCallIfRunning()` — OS ended a call that was in progress:**

This fires via `actionCallEnded` when the user swipes away the iOS green in-call bar while `AgoraAudioCallScreen` is showing.

```dart
  Future<void> _endActiveAgoraCallIfRunning() async {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    final callProvider = Provider.of<CallProvider>(context, listen: false);
    if (callProvider.isCallScreenVisible) {
      callProvider.endCall(notifyRemote: true);
    }
  }
```

**`_restoreKilledStateAccept()` — app killed, user accepted from lock screen:**

```dart
  Future<void> _restoreKilledStateAccept() async {
    // activeCalls() returns calls that were shown while the app was killed.
    // The extra payload contains all the data we need.
    final calls = await FlutterCallkitIncoming.activeCalls();
    if (calls == null) return;
    for (final call in calls as List<dynamic>) {
      final callMap = (call as Map).cast<String, dynamic>();
      final isAccepted = callMap['isAccepted'] == true || callMap['hasAccepted'] == true;
      if (isAccepted) {
        final callId = callMap['id']?.toString() ?? callMap['uuid']?.toString();
        if (callId != null) await _handleAccept(callId, callMap);
      }
    }
  }
```

---

### 4.8 main.dart

**a. Import the service:**
```dart
import 'package:kkpchatapp/core/services/call_kit_service.dart';
```

**b. Initialize after Firebase:**
```dart
// In main(), after Firebase.initializeApp():
CallKitService.instance.init();
```

**c. Background FCM handler — show native call UI for killed state:**

When a push notification with `notificationType: incoming_call` arrives while the app is killed, the `firebaseMessagingBackgroundHandler` runs in a separate isolate. We show the CallKit UI directly from here:

```dart
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (message.data['notificationType'] == 'incoming_call' ||
      message.data['type'] == 'incoming_call') {
    final callId = message.data['callId'] ??
        DateTime.now().millisecondsSinceEpoch.toString();
    final callerName = message.data['callerName'] ?? 'Incoming Call';

    final params = CallKitParams(
      id: callId,
      nameCaller: callerName,
      handle: callerName,
      type: 0,
      appName: 'KKP Group',
      extra: {
        'channelName': message.data['channelName'] ?? '',
        'callerName': callerName,
        'callerId': message.data['callerId'] ?? '',
        'uid': message.data['uid'] ?? '0',
      },
      // ... ios and android params
    );
    await FlutterCallkitIncoming.showCallkitIncoming(params);
    return; // skip normal notification handling
  }

  // ... handle other notification types
}
```

**Why this works:** `FlutterCallkitIncoming` uses a method channel backed by a background Flutter engine. On iOS, calling `showCallkitIncoming` from the background isolate invokes the native `CXProvider` directly. On Android, it fires the full-screen notification.

---

### 4.9 Host Screens

Both `marketing_host.dart` (agent) and `customer_host.dart` (customer) follow the same pattern.

**Before (old overlay approach):**
```dart
// Heavy: audio player, OverlayEntry, timer, etc.
void _handleIncomingCall(Map<String, dynamic> callData) {
  _audioPlayer.play(...);
  _activeCallOverlay = OverlayEntry(builder: (_) => IncomingCallWidget(...));
  Overlay.of(context).insert(_activeCallOverlay!);
  _incomingCallTimeoutTimer = Timer(Duration(seconds: 30), () { ... });
}
```

**After (new native UI approach):**
```dart
import 'package:kkpchatapp/core/services/call_kit_service.dart';

String? _activeIncomingCallId;  // track which call is currently ringing

Future<void> _handleIncomingCall(Map<String, dynamic> callData) async {
  if (!mounted) return;
  final channelName = callData['channelName'] as String;
  final callerName  = callData['callerName']  as String;
  final callerId    = callData['callerId']    as String;
  final callId      = callData['callId'].toString();
  final uid         = Utils().generateIntUidFromEmail(agentEmail!);

  _activeIncomingCallId = callId;

  await CallKitService.instance.showIncomingCall(
    callId:      callId,
    channelName: channelName,
    callerName:  callerName,
    callerId:    callerId,
    uid:         uid,
  );
}

void _handleCallTermination(Map<String, dynamic> data) {
  final terminatedCallId = data['callId']?.toString();
  if (terminatedCallId == null || terminatedCallId.isEmpty) return;
  if (_activeIncomingCallId == terminatedCallId) {
    _activeIncomingCallId = null;
    CallKitService.instance.endCall(terminatedCallId); // dismiss native UI
  }
}
```

Also wire `_handleCallTermination` in your socket init block:
```dart
_socketService.onCallTerminated(_handleCallTermination);
```

**What was removed:**
- `AudioPlayer` / `audioplayers` import
- `IncomingCallWidget` import
- `_activeCallOverlay` field (OverlayEntry)
- `_incomingCallTimeoutTimer` field
- `_removeIncomingCallOverlay()` method
- All audio start/stop logic from `dispose()`

---

### 4.10 CallProvider

Location: `lib/presentation/common/chat/call_provider.dart`

In `endCall()`, after stopping the Agora engine and before resetting state, dismiss the native call UI:

```dart
Future<void> endCall({bool notifyRemote = false}) async {
  // ... existing Agora cleanup ...
  
  // Dismiss the native CallKit / full-screen notification UI
  if (_callId != null) {
    CallKitService.instance.endCall(_callId!);
  }

  // ... _resetState(), notifyListeners(), etc.
}
```

**Why:** Without this, if the user ends the call from the `AgoraAudioCallScreen` (the in-app UI), the native green in-call bar on iOS would stay on screen. This line ensures the two UIs stay in sync.

---

### 4.11 SocketService — background handling

Location: `lib/core/services/socket_service.dart`

**Problem:** The original code emitted `leave` immediately when the app paused, telling the server the user went offline. This meant the server would not route incoming calls via socket even during the ~30-second iOS background task window.

**Fix — do NOT emit `leave` on pause:**

```dart
void _onAppPaused() {
  // Do NOT emit 'leave' here. The server's socket disconnect event fires
  // automatically when the socket drops (~30 s background task), so the
  // server marks the user offline at the right time.
  // Emitting 'leave' early cuts the background window short.
  if (_isConnected) {
    _pendingRejoin = true;
  }
}
```

With this fix, the timeline is:
1. App backgrounds → socket stays alive (~30 s background task)
2. Call arrives within 30 s → `incomingCall` socket event fires → CallKit UI shown ✓
3. After 30 s → socket disconnects → server's disconnect handler marks user offline

For calls arriving after the socket disconnects, the backend must send an **FCM data push** with `notificationType: incoming_call`.

---

## 5. Call Flow Diagrams

### Foreground / Background (within 30s, socket alive)

```
Caller initiates call
        │
        ▼
Backend emits socket event 'incomingCall'
        │
        ▼
SocketService receives event
        │
        ▼
marketing_host / customer_host
  _handleIncomingCall()
        │
        ▼
CallKitService.showIncomingCall()
        │
        ▼
Native OS lock-screen call UI appears
        │
   ┌────┴─────┐
   │          │
 Accept     Decline
   │          │
   ▼          ▼
_handleAccept  _handleDecline
   │           └─ updateCallData("not answered")
   │           └─ socket.terminateCall()
   ▼
CallProvider.startNewCall()
   │
   ▼
AgoraAudioCallScreen opens
   │
 User ends call
   │
   ▼
CallProvider.endCall()
   └─ CallKitService.endCall()  ← dismisses native UI
```

### Killed State (Android via FCM)

```
Backend sends FCM data push {notificationType: "incoming_call"}
        │
        ▼
firebaseMessagingBackgroundHandler (separate isolate)
        │
        ▼
FlutterCallkitIncoming.showCallkitIncoming(params)
  [extra field stores call metadata]
        │
        ▼
Full-screen notification on lock screen
        │
      Accept
        │
        ▼
App cold-starts
        │
        ▼
CallKitService.init()
  └─ _restoreKilledStateAccept()
       └─ FlutterCallkitIncoming.activeCalls()
       └─ _handleAccept(callId, callMap)
              └─ waits for isAppInitialized
              └─ CallProvider.startNewCall()
```

### Caller Cancels While Ringing

```
Caller ends call → Backend emits 'callTerminated' socket event
        │
        ▼
marketing_host / customer_host
  _handleCallTermination()
        │
        ▼
CallKitService.endCall(callId)
        │
        ▼
Native call screen dismissed
```

---

## 6. Key Problems & How We Solved Them

### Problem 1: Circular endCall loop

**Symptom:** `endCall()` called twice, Agora engine disposed twice, crash.

**Cause:**
```
CallProvider.endCall() 
  → CallKitService.endCall()
    → FlutterCallkitIncoming.endCall()
      → fires Event.actionCallEnded
        → _endActiveAgoraCallIfRunning()
          → CallProvider.endCall()   ← loop!
```

**Fix:** Boolean guard `_endingFromProvider` in `CallKitService`:
```dart
Future<void> endCall(String callId) async {
  _endingFromProvider = true;   // block the loop
  await FlutterCallkitIncoming.endCall(callId);
  _endingFromProvider = false;
}

// In _onCallEvent for actionCallEnded:
if (callId != null && !_endingFromProvider) {
  await _endActiveAgoraCallIfRunning();  // only runs if OS ended the call
}
```

---

### Problem 2: iOS Simulator auto-declines every call

**Symptom:** Every incoming call is immediately logged "not answered" with no UI shown.

**Cause:** iOS Simulator does not support CallKit. When `showCallkitIncoming()` is called on a simulator, the plugin fires `actionCallDecline` in ~0 ms.

**Fix:** Time-based guard in `_handleDecline` and `_handleTimeout`:
```dart
final showTime = _callShowTimestamps.remove(callId);
if (showTime != null &&
    DateTime.now().difference(showTime).inMilliseconds < 800) {
  return; // ignore — simulator false-positive
}
```

**Testing note:** CallKit only works on a physical iPhone. Always test call UI on a real device.

---

### Problem 3: Background call not received (socket disconnected)

**Symptom:** Call arrives 1 minute after app backgrounds — no CallKit UI.

**Cause:** 
1. `leave` emitted on pause → server stops routing calls
2. Background task expires (~30 s) → socket disconnects

**Fix for cause 1:** Removed `leave` emission from `_onAppPaused()`.

**Fix for cause 2:** Backend must send FCM data push alongside socket event for all calls. Our `firebaseMessagingBackgroundHandler` already handles it.

---

### Problem 4: Android manifest merge failure

**Symptom:**
```
Attribute activity#CallkitIncomingActivity@theme value=(@style/LaunchTheme)
is also present at [:flutter_callkit_incoming] value=(@style/CallkitIncomingTheme)
```

**Cause:** We redeclared `CallkitIncomingActivity` in our manifest with a different theme.

**Fix:** Remove the `<activity>` declaration for `CallkitIncomingActivity` from your app's manifest. The plugin already owns this declaration.

---

### Problem 5: Double alert — FCM banner + CallKit screen

**Symptom:** When a call arrives via FCM, both the CallKit native call screen AND a notification banner appear.

**Fix:** The `willPresent` override in `AppDelegate.swift` checks if CallKit has an active call. If so, it suppresses the notification banner (`completionHandler([])`).

---

## 7. Testing Checklist

| Scenario | Expected Result |
|----------|----------------|
| App **foreground** — receive call | Native CallKit / full-screen notification appears |
| App **foreground** — tap Accept | `AgoraAudioCallScreen` opens, audio works |
| App **foreground** — tap Decline | Call logged "not answered", caller sees terminate |
| App **foreground** — caller hangs up | Native UI dismissed, no action needed |
| App **background** (within 30s) | Native call UI on lock screen |
| App **background** — Accept from lock screen | App opens to `AgoraAudioCallScreen` |
| End call from `AgoraAudioCallScreen` | Native iOS green bar dismisses |
| iOS Simulator — receive call | No "not answered" logged, no crash (simulator guard active) |
| iOS **physical device** — lock screen | Full CallKit sheet with Answer/Decline buttons |
| Android — receive call | Full-screen notification with Accept/Decline |

---

*This guide documents the implementation as of May 2026. Package version: `flutter_callkit_incoming: 2.5.8`.*
