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
      // Sort notifications by timestamp (newest first)
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
      // Find the notification and create a new one with viewed = true
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        final original = _notifications[index];
        final updatedNotification = NotificationModel(
          id: original.id,
          title: original.title,
          body: original.body,
          senderId: original.senderId,
          targetId: original.targetId,
          senderName: original.senderName,
          type: original.type,
          viewed: true,  // Mark as read
          timestamp: original.timestamp,
          mediaUrl: original.mediaUrl,
          form: original.form,
          v: original.v,
        );

        // Update in our list
        _notifications[index] = updatedNotification;
        notifyListeners();
      }

      // Make API call
      await _authRepo.updateNotificationRead(id);
    } catch (e) {
      debugPrint('Failed to mark notification as read: $e');
      // Revert if API call fails by refreshing notifications
      await fetchNotifications();
    }
  }

  Future<void> markAllRead() async {
    // Create a copy of the current notifications list
    final previousNotifications = List<NotificationModel>.from(_notifications);

    // Optimistically update all notifications locally
    _notifications = _notifications.map((n) {
      return NotificationModel(
        id: n.id,
        title: n.title,
        body: n.body,
        senderId: n.senderId,
        targetId: n.targetId,
        senderName: n.senderName,
        type: n.type,
        viewed: true,  // Mark all as read
        timestamp: n.timestamp,
        mediaUrl: n.mediaUrl,
        form: n.form,
        v: n.v,
      );
    }).toList();
    notifyListeners();

    try {
      // Get list of unread notifications
      final unreadNotifications = previousNotifications.where((n) => !(n.viewed ?? false)).toList();

      // Mark each unread notification as read via API
      for (var n in unreadNotifications) {
        await _authRepo.updateNotificationRead(n.id ?? '');
      }
      // Refresh notifications after marking all as read to get any new ones
      await fetchNotifications();
    } catch (e) {
      debugPrint('Failed to mark all notifications as read: $e');
      // Revert changes if API call fails
      _notifications = previousNotifications;
      notifyListeners();
    }
  }

  // Add a method to add/prepend a new notification
  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }
}
