import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/data/models/notification_model.dart';
import 'package:kkpchatapp/l10n/generated/app_localizations.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Cache-first: the provider outlives this screen, so a freshly-loaded
      // list is reused as-is. Reopening the screen no longer refetches and no
      // longer flashes a loader over notifications we already have.
      unawaited(
        context.read<NotificationProvider>().ensureLoaded(),
      );
    });
  }

  Map<String, List<NotificationModel>> groupNotificationsByDate(
      List<NotificationModel> notifications) {
    Map<String, List<NotificationModel>> grouped = {
      'Today': [],
      'Yesterday': [],
      'Earlier': [],
    };

    final today = DateUtils.dateOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));

    for (final notif in notifications) {
      final date = DateUtils.dateOnly(notif.timestamp ?? DateTime.now());
      if (date == today) {
        grouped['Today']!.add(notif);
      } else if (date == yesterday) {
        grouped['Yesterday']!.add(notif);
      } else {
        grouped['Earlier']!.add(notif);
      }
    }
    return grouped;
  }

  String getFormattedTime(DateTime date) {
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateUtils.dateOnly(date);

    if (dateOnly == today) {
      return DateFormat('hh:mm a').format(date);
    } else if (dateOnly == yesterday) {
      return 'Yesterday, ${DateFormat('hh:mm a').format(date)}';
    } else {
      return DateFormat('dd MMM, hh:mm a').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final provider = Provider.of<NotificationProvider>(context);
    final grouped = groupNotificationsByDate(provider.notifications);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          locale.notifications,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        actions: [
          if (provider.notifications.isNotEmpty)
            TextButton(
              // ← FIX: mark all read then refresh to keep notifications visible
              onPressed: () async {
                await provider.markAllRead();
              },
              child: Text(
                locale.markAllRead,
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Loader only on a cold cache — a background refresh must not hide
          // the list that is already on screen.
          if (provider.isLoading && provider.notifications.isEmpty)
            const FullScreenLoader()
          else if (provider.notifications.isEmpty)
            const EmptyNotificationsWidget()
          else
            RefreshIndicator(
              // ← FIX: pull to refresh support
              // User-initiated: always hits the network.
              onRefresh: () => provider.ensureLoaded(force: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: grouped.entries
                    .where((e) => e.value.isNotEmpty)
                    .map(
                        (entry) => _buildGroup(context, entry.key, entry.value))
                    .toList(),
              ),
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
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 8),
          child: GestureDetector(
            // ← FIX: mark as read then refresh so notification stays visible with green tick
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
