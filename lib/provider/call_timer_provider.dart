// lib/providers/call_timer_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';

class CallTimerProvider extends ChangeNotifier {
  Duration _duration = Duration.zero;
  Timer? _timer;
  bool _running = false;

  Duration get duration => _duration;
  String get formatted => '${_duration.inMinutes.toString().padLeft(2, '0')}:'
      '${(_duration.inSeconds % 60).toString().padLeft(2, '0')}';

  void start() {
    if (_running) return;
    _running = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _duration += const Duration(seconds: 1);
      notifyListeners();
    });
  }

  void stop() {
    _timer?.cancel();
    _running = false;
    notifyListeners();
  }

  void reset() {
    _duration = Duration.zero;
    notifyListeners();
  }
}
