import 'package:flutter/material.dart';

class ChatRefreshProvider extends ChangeNotifier {
  bool _shouldRefresh = false;

  bool get shouldRefresh => _shouldRefresh;

  void markNeedsRefresh() {
    _shouldRefresh = true;
    notifyListeners();
  }

  void reset() {
    _shouldRefresh = false;
  }
}
