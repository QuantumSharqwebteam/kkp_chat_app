import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';

class NotificationSettings extends StatefulWidget {
  const NotificationSettings({super.key});

  @override
  State<NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings> {
  bool isNotificationPaused = false;
  bool isMessagePaused = false;
  bool isCallPaused = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        title: Text(
          'Notification',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Push notification',
                style: AppTextStyles.black16_500,
              ),
            ),
            SizedBox(height: 8),
            ListTile(
              title: Text(
                'Pause all',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              trailing: Switch(
                thumbColor: WidgetStatePropertyAll(Colors.black),
                trackOutlineColor: WidgetStatePropertyAll(Colors.transparent),
                activeTrackColor: AppColors.blue,
                inactiveTrackColor: AppColors.greyD9D9D9,
                value: isNotificationPaused,
                onChanged: (newValue) {
                  setState(() {
                    isNotificationPaused = newValue;
                  });
                },
                activeColor: Colors.blue,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Temporarily pause notification',
                style: AppTextStyles.black12_400,
              ),
            ),
            Divider(
              color: Colors.black,
              thickness: 1,
            ),
            SizedBox(height: 8),
            ListTile(
              title: Text(
                'Message',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              trailing: Switch(
                thumbColor: WidgetStatePropertyAll(Colors.black),
                trackOutlineColor: WidgetStatePropertyAll(Colors.transparent),
                activeTrackColor: AppColors.blue,
                inactiveTrackColor: AppColors.greyD9D9D9,
                value: isMessagePaused,
                onChanged: (newValue) {
                  setState(() {
                    isMessagePaused = newValue;
                  });
                },
                activeColor: Colors.blue,
              ),
            ),
            SizedBox(height: 8),
            ListTile(
              title: Text(
                'Calls',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              trailing: Switch(
                thumbColor: WidgetStatePropertyAll(Colors.black),
                trackOutlineColor: WidgetStatePropertyAll(Colors.transparent),
                activeTrackColor: AppColors.blue,
                inactiveTrackColor: AppColors.greyD9D9D9,
                value: isCallPaused,
                onChanged: (newValue) {
                  setState(() {
                    isCallPaused = newValue;
                  });
                },
                activeColor: Colors.blue,
              ),
            ),
            Divider(
              color: Colors.black,
              thickness: 1,
            ),
          ],
        ),
      ),
    );
  }
}
