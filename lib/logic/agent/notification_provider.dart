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
      _notifications = notifications;
    } catch (e) {
      debugPrint('Failed to load notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authRepo.updateNotificationRead(id);
      await fetchNotifications();
    } catch (e) {
      debugPrint('Failed to mark notification as read: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    _isLoading = true;
    notifyListeners();

    try {
      for (var n in _notifications.where((n) => !(n.viewed ?? false))) {
        await markAsRead(n.id ?? '');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
