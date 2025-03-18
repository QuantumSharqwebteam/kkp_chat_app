import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/routes/customer_routes.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';

class CustomAppBar extends StatefulWidget {
  const CustomAppBar({super.key, required this.name});
  final String name;
  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
      onTap: () {
        Navigator.pushNamed(context, CustomerRoutes.customerProfileSetup);
      },
      leading: CircleAvatar(
        radius: 26,
        backgroundImage: AssetImage("assets/images/profile.png"),
      ),
      title: Text(widget.name, style: AppTextStyles.black16_500),
      subtitle:
          Text("Let's find latest messages", style: AppTextStyles.black12_400),
      trailing: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: IconButton(
          onPressed: () {
            Navigator.pushNamed(context, CustomerRoutes.customerNotification);
          },
          icon: const Icon(
            Icons.notifications_active_outlined,
            color: Colors.black,
            size: 28,
          ),
        ),
      ),
    );
  }
}
