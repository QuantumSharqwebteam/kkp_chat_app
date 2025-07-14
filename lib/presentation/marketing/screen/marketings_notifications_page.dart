import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/data/models/notification_model.dart';
import 'package:kkpchatapp/logic/agent/notification_provider.dart';
import 'package:kkpchatapp/presentation/common_widgets/empty_notifications_widget.dart';
import 'package:kkpchatapp/presentation/common_widgets/full_screen_loader.dart';
import 'package:provider/provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late NotificationProvider _notificationProvider;

  @override
  void initState() {
    super.initState();
    // Fetch notifications when screen is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationProvider =
          Provider.of<NotificationProvider>(context, listen: false);
      _notificationProvider.fetchNotifications();
    });
  }

  Map<String, List<NotificationModel>> groupNotificationsByDate(
      List<NotificationModel> notifications) {
    Map<String, List<NotificationModel>> grouped = {
      'Today': [],
      'Yesterday': [],
      'Earlier': [],
    };
    final now = DateTime.now();
    for (final notif in notifications) {
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
    final provider = Provider.of<NotificationProvider>(context);
    final grouped = groupNotificationsByDate(provider.notifications);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        actions: [
          if (provider.notifications.isNotEmpty)
            TextButton(
              onPressed: () async {
                await provider.markAllRead();
              },
              child: const Text(
                "Mark all read",
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          // Add a refresh button
          // IconButton(
          //   icon: const Icon(Icons.refresh),
          //   onPressed: () => provider.refreshNotifications(),
          // ),
        ],
      ),
      body: Stack(
        children: [
          if (provider.isLoading)
            const FullScreenLoader()
          else if (provider.notifications.isEmpty)
            const EmptyNotificationsWidget()
          else
            ListView(
              children: grouped.entries
                  .where((e) => e.value.isNotEmpty)
                  .map((entry) => _buildGroup(context, entry.key, entry.value))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildGroup(
      BuildContext context, String label, List<NotificationModel> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.maxFinite,
          color: AppColors.blue00ABE9.withOpacity(0.07),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label,
            style: AppTextStyles.grey12_600.copyWith(fontSize: 14),
          ),
        ),
        ...list.map((n) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: _buildNotificationTile(context, n),
            )),
      ],
    );
  }

  Widget _buildNotificationTile(
      BuildContext context, NotificationModel notification) {
    final date = notification.timestamp ?? DateTime.now();
    final displayTime = getFormattedTime(date);
    final provider = Provider.of<NotificationProvider>(context, listen: false);

    // Format message body
    String bodyText;
    if (notification.type == 'product') {
      try {
        final decoded = jsonDecode(notification.body ?? '');
        if (decoded is Map<String, dynamic>) {
          bodyText = "shared a product with you";
        } else {
          bodyText = notification.body ?? '';
        }
      } catch (e) {
        bodyText = notification.body ?? '';
      }
    } else {
      bodyText = notification.body ?? '';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Clickable tick icon
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 8),
          child: GestureDetector(
            onTap: () async {
              if (!(notification.viewed ?? false)) {
                await provider.markAsRead(notification.id ?? '');
              }
            },
            child: CircleAvatar(
              backgroundColor: notification.viewed ?? false
                  ? Colors.green
                  : Colors.grey.shade300,
              radius: 16,
              child: Icon(
                Icons.check,
                color: notification.viewed ?? false
                    ? Colors.white
                    : Colors.grey.shade600,
                size: 18,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.senderName ?? '',
                  style: AppTextStyles.black14_600,
                ),
                const SizedBox(height: 4),
                Text(
                  bodyText,
                  style: AppTextStyles.black12_400,
                ),
              ],
            ),
          ),
        ),
        // ⏱ Time on the right
        Padding(
          padding: const EdgeInsets.only(right: 16, top: 8),
          child: Text(
            displayTime,
            style: AppTextStyles.grey12_600,
          ),
        ),
      ],
    );
  }
}
