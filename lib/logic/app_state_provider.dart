import 'package:flutter/material.dart';

class AppStateProvider with ChangeNotifier {
  bool _isAppReady = false;

  bool get isAppReady => _isAppReady;

  void setAppReady(bool ready) {
    _isAppReady = ready;
    notifyListeners();
  }
}
