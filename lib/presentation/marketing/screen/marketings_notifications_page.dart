import 'package:flutter/material.dart';
import 'package:flutter_initicon/flutter_initicon.dart';
import 'package:intl/intl.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';

import 'package:kkpchatapp/data/models/notification_model.dart';
import 'package:kkpchatapp/data/repositories/auth_repository.dart';
import 'package:kkpchatapp/presentation/common_widgets/full_screen_loader.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _notifications = [];
  final AuthRepository _authRepo = AuthRepository();
  bool _isLoading = false; // Loading flag to track API progress

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    setState(() {
      _isLoading = true; // Start loading when API is hit
    });

    try {
      final notifications = await _authRepo.getParsedNotifications();
      setState(() {
        _notifications = notifications;
      });
    } catch (e) {
      debugPrint('Failed to load notifications: $e');
    } finally {
      setState(() {
        _isLoading = false; // Stop loading once the API call is complete
      });
    }
  }

  Future<void> markAsRead(String id) async {
    setState(() {
      _isLoading = true; // Start loading when API is hit
    });

    try {
      await _authRepo.updateNotificationRead(id);
      fetchNotifications(); // Refresh the notification list
    } catch (e) {
      debugPrint('Failed to mark notification as read: $e');
    } finally {
      setState(() {
        _isLoading = false; // Stop loading once the API call is complete
      });
    }
  }

  Map<String, List<NotificationModel>> groupNotificationsByDate() {
    Map<String, List<NotificationModel>> grouped = {
      'Today': [],
      'Yesterday': [],
      'Earlier': [],
    };
    final now = DateTime.now();

    for (final notif in _notifications) {
      final date = notif.timestamp ?? DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0 && now.day == date.day) {
        grouped['Today']!.add(notif);
      } else if (diff.inDays == 1 ||
          (diff.inHours < 48 && now.day - date.day == 1)) {
        grouped['Yesterday']!.add(notif);
      } else {
        grouped['Earlier']!.add(notif);
      }
    }

    return grouped;
  }

  String getFormattedTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins';
    } else if (difference.inHours < 24 && now.day == date.day) {
      return DateFormat('hh:mm a').format(date);
    } else {
      return 'Yesterday at ${DateFormat('HH:mm').format(date)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = groupNotificationsByDate();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          TextButton(
            onPressed: () async {
              setState(() {
                _isLoading = true; // Start loading for all notifications
              });
              for (var n in _notifications.where((n) => !(n.viewed ?? false))) {
                await markAsRead(n.id ?? '');
              }
              setState(() {
                _isLoading =
                    false; // Stop loading once all notifications are marked
              });
            },
            child: const Text(
              "Mark all read",
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          _notifications.isEmpty
              ? const Center(child: Text(""))
              : ListView(
                  children: grouped.entries
                      .where((e) => e.value.isNotEmpty)
                      .map((entry) => _buildGroup(entry.key, entry.value))
                      .toList(),
                ),
          if (_isLoading) const FullScreenLoader(),
        ],
      ),
    );
  }

  Widget _buildGroup(String label, List<NotificationModel> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.maxFinite,
          color: AppColors.blue00ABE9.withValues(alpha: 0.07),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          margin: EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label,
            style: AppTextStyles.grey12_600.copyWith(fontSize: 14),
          ),
        ),
        ...list.map((n) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
              child: _buildNotificationTile(n),
            )),
      ],
    );
  }

  Widget _buildNotificationTile(NotificationModel n) {
    final date = n.timestamp ?? DateTime.now();
    final displayTime = getFormattedTime(date);

    return ListTile(
      onTap: () {
        markAsRead(n.id ?? '');
      },
      leading: Initicon(
        text: n.senderName ?? '',
        size: 40,
        backgroundColor: Colors.grey.shade300,
      ),
      title: RichText(
        text: TextSpan(
          text: n.senderName ?? '',
          style: AppTextStyles.black14_600,
          children: [
            TextSpan(
              text: ' ${n.body}',
              style: AppTextStyles.black12_400,
            ),
          ],
        ),
      ),
      subtitle: Text(
        displayTime,
        style: AppTextStyles.grey12_600,
      ),
      trailing: !(n.viewed ?? false)
          ? const Text(
              "Mark as read",
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            )
          : null,
    );
  }
}
