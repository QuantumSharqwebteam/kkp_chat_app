import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';

class CustomerNotificationPage extends StatefulWidget {
  const CustomerNotificationPage({super.key});

  @override
  State<CustomerNotificationPage> createState() =>
      _CustomerNotificationPageState();
}

class _CustomerNotificationPageState extends State<CustomerNotificationPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        title: Text(
          'Notifications',
          style: AppTextStyles.black18_600,
        ),
        leadingWidth: 25,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: InkWell(
              onTap: () {},
              child: Text(
                'Mark all read',
                style: AppTextStyles.black16_500.copyWith(
                  color: AppColors.blue,
                  decoration: TextDecoration.underline,
                  decorationStyle: TextDecorationStyle.solid,
                  decorationColor: AppColors.blue,
                  decorationThickness: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _notificationTile(),
            _notificationTile(),
            _notificationTile(),
            _notificationTile(),
            _notificationTile(),
            _notificationTile(),
          ],
        ),
      ),
    );
  }

  Widget _notificationTile() {
    bool selected = false;
    return ListTile(
      onTap: () {
        setState(() {
          selected = !selected;
        });
      },
      selectedTileColor: Colors.grey.shade400,
      selectedColor: Colors.black,
      selected: selected,
      leading: CircleAvatar(
        radius: 25,
        backgroundImage: AssetImage('assets/images/user5.png'),
      ),
      title: Text(
        'Sam is Online you can message now',
        maxLines: 2,
        style: TextStyle(
            fontSize: 12, color: Colors.black), // Adjust style as needed
      ),
      subtitle: Text(
        DateTime.now().toString(),
        style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500),
      ),
    );
  }
}
