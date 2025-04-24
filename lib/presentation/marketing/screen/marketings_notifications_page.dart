import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> notifications = [
    {
      'name': 'Ramesh Mehra',
      'message': 'send final stocks',
      'time': '2hr ago',
      'image': 'assets/images/user1.png',
      'hasAction': false,
    },
    {
      'name': 'Rakesh R.S',
      'message': 'send final units and so out of stock',
      'time': '4hr ago',
      'image': 'assets/images/user2.png',
      'hasAction': false,
    },
    {
      'name': 'Ronita Jain',
      'message': 'to join this group',
      'time': '4hr ago',
      'image': 'assets/images/user3.png',
      'hasAction': true,
    },
    {
      'name': 'Ronit Moh',
      'message': 'send final units',
      'time': '4hr ago',
      'image': 'assets/images/user4.png',
      'hasAction': false,
    },
  ];

  NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Notifications",
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: Text(
              "Mark all read",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.blue,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.blue,
                decorationThickness: 3,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildNotificationList()),
          // _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    return ListView.separated(
      itemCount: notifications.length,
      physics: AlwaysScrollableScrollPhysics(),
      separatorBuilder: (context, index) =>
          Divider(thickness: 1, color: Colors.grey.shade300),
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: AssetImage(notification['image']),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        text: notification['name'],
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 14),
                        children: [
                          TextSpan(
                            text: " ${notification['message']}",
                            style: TextStyle(fontWeight: FontWeight.normal),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(notification['time'],
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget _buildFooter() {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 20),
  //     child: RichText(
  //       textAlign: TextAlign.center,
  //       text: TextSpan(
  //         style: AppTextStyles.black10_600
  //             .copyWith(color: Color(0xff121927), fontWeight: FontWeight.w500),
  //         children: [
  //           const TextSpan(text: "By using KKP chat application, you agree\n"),
  //           TextSpan(
  //               text: "to the Terms and Privacy Policy",
  //               style: AppTextStyles.black10_600
  //                   .copyWith(fontWeight: FontWeight.bold)),
  //         ],
  //       ),
  //     ),
  //   );
  // }
}
