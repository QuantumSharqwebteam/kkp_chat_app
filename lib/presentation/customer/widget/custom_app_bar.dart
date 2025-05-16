import 'package:flutter/material.dart';
import 'package:flutter_initicon/flutter_initicon.dart';
import 'package:kkpchatapp/config/routes/customer_routes.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/presentation/common/chat/call_history_screen.dart';

class CustomAppBar extends StatefulWidget {
  const CustomAppBar({
    super.key,
    this.name,
  });
  final String? name;

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
      onTap: () {
        // Navigator.pushNamed(context, CustomerRoutes.customerProfileSetup);
      },
      leading: ClipRRect(
          borderRadius: BorderRadius.circular(70),
          child: Initicon(
            text: widget.name ?? "",
            size: 40,
          )),
      title: Text(widget.name ?? "", style: AppTextStyles.black16_500),
      subtitle:
          Text("Let's find latest messages", style: AppTextStyles.black12_400),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, CustomerRoutes.customerNotification);
            },
            icon: const Icon(
              Icons.notifications_active_outlined,
              color: Colors.black,
              size: 28,
            ),
          ),
          IconButton(
            onPressed: () {
              // Navigate to the CallHistoryPage or perform an action related to call logs
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CallHistoryScreen()),
              );
            },
            icon: Icon(
              Icons
                  .call_outlined, // You can choose a different icon if preferred
              color: Colors.black,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}
