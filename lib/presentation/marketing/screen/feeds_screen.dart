import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/presentation/marketing/screen/customer_list_screen.dart';
import 'package:kkp_chat_app/presentation/marketing/widget/filter_button.dart';
import 'package:kkp_chat_app/presentation/marketing/widget/recent_messages_list_card.dart';

class FeedsScreen extends StatefulWidget {
  const FeedsScreen({super.key});

  @override
  State<FeedsScreen> createState() => _FeedsScreenState();
}

class _FeedsScreenState extends State<FeedsScreen> {
  List<Map<String, dynamic>> messages = [
    {
      "name": "Marketing Agent 1",
      "message": "Hi any update....",
      "time": "2m",
      "image": "assets/images/user1.png",
      "isActive": false // Inactive user
    },
    {
      "name": "Marketing Agent 2",
      "message": "Hi any update....",
      "time": "3m",
      "image": "assets/images/user4.png",
      "isActive": true // Active user
    },
    {
      "name": "Marketing Agent 3",
      "message": "Hi any update....",
      "time": "3m",
      "image": "assets/images/user1.png",
      "isActive": false
    },
    {
      "name": "Marketing Agent 3",
      "message": "Hi any update....",
      "time": "3m",
      "image": "assets/images/user2.png",
      "isActive": true // Active user
    },
    {
      "name": "Marketing Agent 4",
      "message": "Hi any update....",
      "time": "3m",
      "image": "assets/images/user3.png",
      "isActive": false
    },
    {
      "name": "Marketing Agent 5",
      "message": "Hi any update....",
      "time": "4m",
      "image": "assets/images/user4.png",
      "isActive": true // Active user
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildImageSection(),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
              ),
              child: Column(
                children: [
                  _buildFilterButtons(),
                  Expanded(child: _buildRecentMessages()),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Stack(
      children: [
        Container(
          padding: EdgeInsets.only(top: 50),
          width: double.maxFinite,
          height: 231,
          color: AppColors.background,
          child: Image.asset(
            "assets/images/feed.png",
            height: 200,
            width: 300,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 40,
          right: 20,
          child: Image.asset(
            "assets/icons/logo.png",
            height: 30,
            width: 30,
          ),
        )
      ],
    );
  }

  // Filter buttons section
  Widget _buildFilterButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        spacing: 5,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          FilterButton(icon: Icons.search_rounded),
          FilterButton(
            onTap: () {
              //Navigate to all chats page
            },
            text: "All Chats",
          ),
          FilterButton(
            onTap: () {
              //Navigate to all pinned messages page
            },
            text: "Pinned Messages",
          ),
        ],
      ),
    );
  }

  // Recent Messages List with Dividers
  Widget _buildRecentMessages() {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: messages.length,
      physics: AlwaysScrollableScrollPhysics(),
      separatorBuilder: (context, index) => Divider(
        thickness: 1,
        color: AppColors.dividerColor,
      ),
      itemBuilder: (context, index) {
        final message = messages[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: RecentMessagesListCard(
            name: message['name'],
            message: message['message'],
            time: message['time'],
            image: message['image'],
            isActive: message['isActive'],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CustomersListScreen(
                    agentName: message['name'],
                    agentImage: message['image'],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
