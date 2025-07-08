// // lib/core/services/call_overlay_service.dart
// import 'package:audioplayers/audioplayers.dart';
// import 'package:flutter/material.dart';
// import 'package:kkpchatapp/config/theme/app_text_styles.dart';
// import 'package:kkpchatapp/core/services/socket_service.dart';
// import 'package:kkpchatapp/main.dart';
// import 'package:kkpchatapp/provider/call_timer_provider.dart';
// import 'package:provider/provider.dart';

// class CallOverlayService {
//   // ---------------- singleton boilerplate ----------------
//   static final CallOverlayService _i = CallOverlayService._internal();
//   factory CallOverlayService() => _i;
//   CallOverlayService._internal();
//   final _socketService =
//       SocketService(navigatorKey); // or inject this in `init()`
//   String? _activeCallId;

//   // ---------------- overlay ----------------
//   late OverlayState _overlayState;
//   OverlayEntry? _entry;

//   void init(GlobalKey<NavigatorState> navKey) {
//     _overlayState = navKey.currentState!.overlay!;
//     _listenToCallTerminations();
//   }

//   void _listenToCallTerminations() {
//     _socketService.onCallTerminated((data) {
//       final terminatedCallId = data['callId'];
//       if (_activeCallId != null && _activeCallId == terminatedCallId) {
//         hide();
//         // Optionally: clean up any other state or notify
//       }
//     });
//   }

//   // ---------------- ringtone ----------------
//   final AudioPlayer _player = AudioPlayer();
//   bool _ringing = false;

//   Future<void> startRinging() async {
//     if (_ringing) return;
//     _ringing = true;
//     await _player.setReleaseMode(ReleaseMode.loop);
//     await _player.play(AssetSource('sounds/ringtone.mp3'));
//   }

//   Future<void> stopRinging() async {
//     if (!_ringing) return;
//     _ringing = false;
//     await _player.stop();
//   }

//   void show({
//     required String remoteName,
//     required VoidCallback onExpand,
//     required VoidCallback onHangup,
//     required String callId, // 👈 Add this to track active call
//   }) {
//     hide();
//     _activeCallId = callId;

//     _entry = OverlayEntry(
//       builder: (ctx) => Positioned(
//         top: 30,
//         left: 16,
//         right: 16,
//         child: GestureDetector(
//           onTap: onExpand,
//           child: Material(
//             color: Colors.transparent,
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//               decoration: BoxDecoration(
//                 color: Colors.black87,
//                 borderRadius: BorderRadius.circular(24),
//                 boxShadow: const [
//                   BoxShadow(color: Colors.black26, blurRadius: 6)
//                 ],
//               ),
//               child: Column(
//                 children: [
//                   Text(
//                     "Ongoing Call with $remoteName",
//                     style:
//                         AppTextStyles.black10_500.copyWith(color: Colors.white),
//                   ),
//                   Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       const Icon(Icons.call, size: 18, color: Colors.white),
//                       const SizedBox(width: 6),
//                       Consumer<CallTimerProvider>(
//                         builder: (_, t, __) => Text(
//                           t.formatted,
//                           style: const TextStyle(
//                               color: Colors.white, fontSize: 12),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );

//     _overlayState.insert(_entry!);
//   }

//   void hide() {
//     _entry?.remove();
//     _entry = null;
//     _activeCallId = null;
//     stopRinging();
//   }
// }
