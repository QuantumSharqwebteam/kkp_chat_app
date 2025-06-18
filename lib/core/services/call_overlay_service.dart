// lib/core/services/call_overlay_service.dart
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/provider/call_timer_provider.dart';
import 'package:provider/provider.dart';

class CallOverlayService {
  // ---------------- singleton boilerplate ----------------
  static final CallOverlayService _i = CallOverlayService._internal();
  factory CallOverlayService() => _i;
  CallOverlayService._internal();

  // ---------------- overlay ----------------
  late OverlayState _overlayState;
  OverlayEntry? _entry;

  void init(GlobalKey<NavigatorState> navKey) =>
      _overlayState = navKey.currentState!.overlay!;

  // ---------------- ringtone ----------------
  final AudioPlayer _player = AudioPlayer();
  bool _ringing = false;

  Future<void> startRinging() async {
    if (_ringing) return;
    _ringing = true;
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(AssetSource('sounds/ringtone.mp3'));
  }

  Future<void> stopRinging() async {
    if (!_ringing) return;
    _ringing = false;
    await _player.stop();
  }

  void show({
    required String remoteName,
    required VoidCallback onExpand,
    required VoidCallback onHangup,
  }) {
    hide();

    _entry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: 30,
        left: 16,
        right: 16,
        child: GestureDetector(
          onTap: onExpand,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 6)
                ],
              ),
              child: Column(
                children: [
                  Text(
                    "Ongoing Call with $remoteName",
                    style:
                        AppTextStyles.black10_500.copyWith(color: Colors.white),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.call, size: 18, color: Colors.white),
                      const SizedBox(width: 6),
                      // 👇 live timer
                      Consumer<CallTimerProvider>(
                        builder: (_, t, __) => Text(
                          t.formatted,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ),
                      // IconButton(
                      //   icon: const Icon(Icons.call_end, size: 20, color: Colors.red),
                      //   onPressed: () {
                      //     onHangup();
                      //     hide();
                      //   },
                      // ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    _overlayState.insert(_entry!);
  }

  void hide() {
    _entry?.remove();
    _entry = null;
    stopRinging(); // also silence ring if still playing
  }
}
