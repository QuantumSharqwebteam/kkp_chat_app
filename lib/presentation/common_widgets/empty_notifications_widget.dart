import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class EmptyNotificationsWidget extends StatelessWidget {
  const EmptyNotificationsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/notification.svg',
            width: 300,
            height: 300,
          ),
          const SizedBox(height: 10),
          Text("No Notifications Yet!")
        ],
      ),
    );
  }
}
