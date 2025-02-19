import 'package:flutter/material.dart';

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
              "Mark as read",
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildNotificationList()),
          _buildFooter(),
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
                    if (notification['hasAction']) _buildActionButtons(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          _buildButton("Accept", Colors.black, Colors.white),
          SizedBox(width: 8),
          _buildButton("Decline", Colors.white, Colors.black),
        ],
      ),
    );
  }

  Widget _buildButton(String text, Color bgColor, Color textColor) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: Colors.black),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Text(
            "By using KKP chat application, You agree\nto the Terms and Privacy Policy",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
