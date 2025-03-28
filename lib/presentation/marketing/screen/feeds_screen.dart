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
      "isActive": false,
      "isPinned": true,
      "email": "agent1@example.com" // Add email for identification
    },
    {
      "name": "Marketing Agent 2",
      "message": "Hi any update....",
      "time": "3m",
      "image": "assets/images/user4.png",
      "isActive": true,
      "isPinned": true,
      "email": "agent2@example.com"
    },
    {
      "name": "Marketing Agent 3",
      "message": "Hi any update....",
      "time": "2hr",
      "image": "assets/images/user1.png",
      "isActive": false,
      "isPinned": false,
      "email": "agent3@example.com"
    },
    {
      "name": "Marketing Agent 4",
      "message": "Hi any update....",
      "time": "3hr",
      "image": "assets/images/user3.png",
      "isActive": false,
      "isPinned": true,
      "email": "agent4@example.com"
    },
    {
      "name": "Marketing Agent 5",
      "message": "Hi any update....",
      "time": "4m",
      "image": "assets/images/user4.png",
      "isActive": true,
      "isPinned": false,
      "email": "agent5@example.com"
    },
  ];

  bool showPinned = false;
  void togglePinnedMessages() {
    setState(() {
      showPinned = !showPinned;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildImageSection(),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: const BoxDecoration(color: Colors.white),
              child: Column(
                children: [
                  _buildFilterButtons(),
                  Expanded(child: _buildRecentMessages()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.only(top: 50),
          width: double.infinity,
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
        ),
      ],
    );
  }

  // Filter buttons section
  Widget _buildFilterButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          FilterButton(icon: Icons.search_rounded),
          // FilterButton(
          //   onTap: () {
          //     setState(() {
          //       showPinned = false; // Show all messages
          //     });
          //   },
          //   text: "All Chats",
          // ),
          FilterButton(
            onTap: togglePinnedMessages,
            text: "Pinned Messages",
          ),
        ],
      ),
    );
  }

  // Recent Messages List with Dividers
  Widget _buildRecentMessages() {
    List<Map<String, dynamic>> filteredMessages = showPinned
        ? messages.where((msg) => msg['isPinned'] == true).toList()
        : messages;

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      itemCount: filteredMessages.length,
      physics: const AlwaysScrollableScrollPhysics(),
      separatorBuilder: (context, index) => Divider(
        thickness: 1,
        color: AppColors.dividerColor,
      ),
      itemBuilder: (context, index) {
        final message = filteredMessages[index];
        return RecentMessagesListCard(
          name: message['name'],
          message: message['message'],
          time: message['time'],
          image: message['image'],
          isActive: message['isActive'],
          isPinned: message['isPinned']!,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CustomersListScreen(
                  agentName: message['name'],
                  agentImage: message['image'],
                  agentEmail: message['email'], // Pass the agent's email
                ),
              ),
            );
          },
        );
      },
    );
  }
}
