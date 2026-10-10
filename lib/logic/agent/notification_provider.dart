import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kkpchatapp/core/services/connectivity_service.dart';
import 'package:kkpchatapp/core/services/socket_service.dart';
import 'package:kkpchatapp/data/models/notification_model.dart';
import 'package:kkpchatapp/data/repositories/auth_repository.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider() {
    // Realtime: any socket event that can create a server-side notification
    // (incoming call, call ended / missed, new message) invalidates the cache
    // and triggers a silent refetch, so the list updates without a manual
    // pull-to-refresh.
    _socketSub = SocketService.notificationEvents.listen(_onRealtimeEvent);
  }

  final AuthRepository _authRepo = AuthRepository();
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  bool _disposed = false;

  /// The request currently in flight, if any. Several screens can ask for
  /// notifications at once (home init, app resume, returning from the
  /// notification screen); without this each caller fired its own HTTP request.
  Future<void>? _inFlight;

  /// Set when a realtime event arrives while a fetch is already running. That
  /// fetch may have started before the server saved the new notification, so
  /// one more fetch is run as soon as it finishes.
  bool _refetchQueued = false;

  StreamSubscription<String>? _socketSub;
  Timer? _eventDebounce;

  /// Gives the backend a moment to persist the notification record after it
  /// emits the socket event, and collapses bursts (call → callTerminated →
  /// call log) into a single request.
  static const Duration _eventDelay = Duration(milliseconds: 1200);

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

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _onRealtimeEvent(String reason) {
    if (_disposed) return;
    debugPrint('🔔 [NotificationProvider] realtime event: $reason');

    // The cached list is no longer trustworthy — the next ensureLoaded()
    // (e.g. opening the notification screen) must hit the network.
    _lastFetchedAt = null;
    if (_inFlight != null) _refetchQueued = true;

    _eventDebounce?.cancel();
    _eventDebounce = Timer(_eventDelay, () {
      if (_disposed) return;
      // Only refetch right away when something is showing the list/badge.
      // Otherwise the stale flag above makes the next screen open fetch.
      if (hasListeners) fetchNotifications();
    });
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
      if (_refetchQueued && !_disposed) {
        _refetchQueued = false;
        fetchNotifications();
      }
    });
  }

  Future<void> _fetchNotifications() async {
    if (!ConnectivityService.instance.isOnline) {
      _isLoading = false;
      _notify();
      return;
    }
    // Only advertise loading on a cold cache. A refresh over an existing list
    // stays silent, so the screen keeps showing the notifications it already
    // has instead of swapping them for a full-screen loader.
    final showLoading = _notifications.isEmpty;
    if (showLoading) {
      _isLoading = true;
      _notify();
    }
    try {
      final notifications = await _authRepo.getParsedNotifications();
      notifications.sort((a, b) {
        final dateA = a.timestamp ?? DateTime.now();
        final dateB = b.timestamp ?? DateTime.now();
        return dateB.compareTo(dateA);
      });
      _notifications = notifications;
      // If an event arrived mid-request, leave the cache stale so the queued
      // refetch (and any screen open) still goes to the network.
      if (!_refetchQueued) _lastFetchedAt = DateTime.now();
    } catch (e) {
      debugPrint('Failed to load notifications: $e');
    } finally {
      _isLoading = false;
      _notify();
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
        _notify();
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
    _notify();

    // 3. Parallel API calls — all at once, not one-by-one
    try {
      await Future.wait(
        unreadIds.map((id) => _authRepo.updateNotificationRead(id)),
      );
    } catch (e) {
      debugPrint('Failed to mark all notifications as read: $e');
      _notifications = previousNotifications;
      _notify();
    }
  }

  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _eventDebounce?.cancel();
    _socketSub?.cancel();
    super.dispose();
  }
}
