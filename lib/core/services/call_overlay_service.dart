import 'package:flutter/material.dart';

class CallOverlayService {
  static final CallOverlayService _instance = CallOverlayService._internal();
  factory CallOverlayService() => _instance;
  CallOverlayService._internal();

  late OverlayState _overlayState;
  OverlayEntry? _overlayEntry;
  bool _isShowing = false;

  void init(GlobalKey<NavigatorState> navigatorKey) {
    _overlayState = navigatorKey.currentState!.overlay!;
  }

  void showIncomingCall({
    required String callerName,
    required VoidCallback onAccept,
    required VoidCallback onReject,
  }) {
    if (_isShowing) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black26, blurRadius: 10),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$callerName is calling...',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        hideOverlay();
                        onReject();
                      },
                      icon: const Icon(Icons.call_end),
                      label: const Text('Reject'),
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        hideOverlay();
                        onAccept();
                      },
                      icon: const Icon(Icons.call),
                      label: const Text('Answer'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );

    _overlayState.insert(_overlayEntry!);
    _isShowing = true;
  }

  void hideOverlay() {
    if (!_isShowing) return;
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isShowing = false;
  }
}
