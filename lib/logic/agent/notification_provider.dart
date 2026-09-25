import 'package:flutter/material.dart';
import 'package:kkpchatapp/core/services/connectivity_service.dart';
import 'package:kkpchatapp/data/models/notification_model.dart';
import 'package:kkpchatapp/data/repositories/auth_repository.dart';

class NotificationProvider extends ChangeNotifier {
  final AuthRepository _authRepo = AuthRepository();
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  /// The request currently in flight, if any. Several screens can ask for
  /// notifications at once (home init, app resume, returning from the
  /// notification screen); without this each caller fired its own HTTP request.
  Future<void>? _inFlight;

  /// When the list was last successfully loaded — lets callers decide whether a
  /// refresh is worth making.
  DateTime? _lastFetchedAt;

  /// How long a loaded list is considered fresh enough to reuse without
  /// hitting the network again.
  static const Duration _freshFor = Duration(minutes: 2);

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  DateTime? get lastFetchedAt => _lastFetchedAt;

  /// True when nothing has been loaded yet, or the cached list has aged out.
  bool get isStale {
    final last = _lastFetchedAt;
    return last == null || DateTime.now().difference(last) > _freshFor;
  }

  /// Cache-first entry point for screens.
  ///
  /// Returns immediately when the cached list is still fresh, so reopening the
  /// notification screen renders instantly from the provider instead of
  /// refetching and flashing a loader over data we already have. Pass
  /// [force] for user-initiated refreshes (pull-to-refresh).
  Future<void> ensureLoaded({bool force = false}) {
    if (!force && !isStale) return Future<void>.value();
    return fetchNotifications();
  }

  /// Fetches the notification list, collapsing concurrent callers onto a single
  /// request.
  Future<void> fetchNotifications() {
    final existing = _inFlight;
    if (existing != null) return existing;

    final request = _fetchNotifications();
    _inFlight = request;
    return request.whenComplete(() {
      if (identical(_inFlight, request)) _inFlight = null;
    });
  }

  Future<void> _fetchNotifications() async {
    if (!ConnectivityService.instance.isOnline) {
      _isLoading = false;
      notifyListeners();
      return;
    }
    // Only advertise loading on a cold cache. A refresh over an existing list
    // stays silent, so the screen keeps showing the notifications it already
    // has instead of swapping them for a full-screen loader.
    final showLoading = _notifications.isEmpty;
    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }
    try {
      final notifications = await _authRepo.getParsedNotifications();
      notifications.sort((a, b) {
        final dateA = a.timestamp ?? DateTime.now();
        final dateB = b.timestamp ?? DateTime.now();
        return dateB.compareTo(dateA);
      });
      _notifications = notifications;
      _lastFetchedAt = DateTime.now();
    } catch (e) {
      debugPrint('Failed to load notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshNotifications() async {
    await fetchNotifications();
  }

  Future<void> markAsRead(String id) async {
    try {
      // Optimistic local update
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        final original = _notifications[index];
        _notifications[index] = NotificationModel(
          id: original.id,
          title: original.title,
          body: original.body,
          senderId: original.senderId,
          targetId: original.targetId,
          senderName: original.senderName,
          type: original.type,
          viewed: true,
          timestamp: original.timestamp,
          mediaUrl: original.mediaUrl,
          form: original.form,
          v: original.v,
        );
        notifyListeners();
      }

      // API call
      await _authRepo.updateNotificationRead(id);
    } catch (e) {
      debugPrint('Failed to mark notification as read: $e');
      await fetchNotifications();
    }
  }

  Future<void> markAllRead() async {
    final previousNotifications = List<NotificationModel>.from(_notifications);

    // 1. Get unread list BEFORE optimistic update
    final unreadIds = previousNotifications
        .where((n) => !(n.viewed ?? false))
        .map((n) => n.id ?? '')
        .where((id) => id.isNotEmpty)
        .toList();

    // 2. Optimistic update — mark all as read locally
    _notifications = _notifications.map((n) {
      return NotificationModel(
        id: n.id,
        title: n.title,
        body: n.body,
        senderId: n.senderId,
        targetId: n.targetId,
        senderName: n.senderName,
        type: n.type,
        viewed: true,
        timestamp: n.timestamp,
        mediaUrl: n.mediaUrl,
        form: n.form,
        v: n.v,
      );
    }).toList();
    notifyListeners();

    // 3. Parallel API calls — all at once, not one-by-one
    try {
      await Future.wait(
        unreadIds.map((id) => _authRepo.updateNotificationRead(id)),
      );
    } catch (e) {
      debugPrint('Failed to mark all notifications as read: $e');
      _notifications = previousNotifications;
      notifyListeners();
    }
  }

  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }
}
