import 'dart:async';

import 'package:flutter/material.dart';

/// Signals that the agent's conversation list is stale.
///
/// Its only listener responds by refetching the full assigned-customer list
/// (an HTTP call plus a Hive box open per customer), and the chat screen marks
/// it on every single message sent or received — so the signal is coalesced
/// over a short window rather than firing per message.
class ChatRefreshProvider extends ChangeNotifier {
  static const Duration _debounce = Duration(milliseconds: 800);

  bool _shouldRefresh = false;
  Timer? _debounceTimer;
  bool _disposed = false;

  bool get shouldRefresh => _shouldRefresh;

  void markNeedsRefresh() {
    if (_disposed) return;
    _shouldRefresh = true;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () {
      if (_disposed || !_shouldRefresh) return;
      notifyListeners();
    });
  }

  void reset() {
    _shouldRefresh = false;
  }

  @override
  void dispose() {
    _disposed = true;
    _debounceTimer?.cancel();
    super.dispose();
  }
}
