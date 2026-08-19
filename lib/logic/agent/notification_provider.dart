import 'package:flutter/material.dart';
import 'package:kkpchatapp/data/models/notification_model.dart';
import 'package:kkpchatapp/data/repositories/auth_repository.dart';

class NotificationProvider extends ChangeNotifier {
  final AuthRepository _authRepo = AuthRepository();
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();
    try {
      final notifications = await _authRepo.getParsedNotifications();
      notifications.sort((a, b) {
        final dateA = a.timestamp ?? DateTime.now();
        final dateB = b.timestamp ?? DateTime.now();
        return dateB.compareTo(dateA);
      });
      _notifications = notifications;
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
