import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:kkpchatapp/core/services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationSettings extends StatefulWidget {
  const NotificationSettings({super.key});

  @override
  State<NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings> {
  bool isNotificationPaused = false;
  bool isMessagePaused = false;
  bool isCallPaused = true;
  bool? isPushNotificationEnabled;

  @override
  void initState() {
    super.initState();
    _checkNotificationPermission();
  }

  Future<void> _checkNotificationPermission() async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    if (!mounted) return;
    setState(() {
      isPushNotificationEnabled =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;
    });
  }

  Future<void> _requestNotificationPermission() async {
    final granted = await NotificationService.requestPermission(context);
    if (!mounted) return;

    if (granted) {
      await NotificationService.checkAndUpdateFCMToken();
      setState(() => isPushNotificationEnabled = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Push notifications enabled.')),
        );
      }
    } else {
      setState(() => isPushNotificationEnabled = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permission denied. Please enable from settings.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: isPushNotificationEnabled == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Push Notifications for messages',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),

                // 🔔 Push Notification Permission Switch
                ListTile(
                  title: const Text('Enable Push Notifications'),
                  subtitle: !isPushNotificationEnabled!
                      ? const Text(
                          'Push notifications are disabled. Enable to receive alerts.',
                          style: TextStyle(color: Colors.red),
                        )
                      : null,
                  trailing: Switch(
                    value: isPushNotificationEnabled!,
                    onChanged: (value) async {
                      if (value) {
                        await _requestNotificationPermission();
                      } else {
                        final opened = await openAppSettings();
                        if (!opened && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Could not open app settings.'),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    isPushNotificationEnabled!
                        ? 'Notifications are enabled.'
                        : 'Notifications are disabled. You won’t receive messages notifications.',
                    style: TextStyle(
                      color: isPushNotificationEnabled!
                          ? Colors.green
                          : Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
