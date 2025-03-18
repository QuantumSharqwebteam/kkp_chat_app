import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_search_field.dart';

import 'package:kkp_chat_app/presentation/marketing/widget/recent_messages_list_card.dart';

class TrackInquries extends StatefulWidget {
  const TrackInquries({super.key});

  @override
  State<TrackInquries> createState() => _TrackInquriesState();
}

class _TrackInquriesState extends State<TrackInquries> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> messages = [
    {
      "name": "Ramesh Jain",
      "message": "Can you describe....",
      "time": "2m",
      "image": "assets/images/user1.png",
      "isActive": false // Inactive user
    },
    {
      "name": "Rumika Mehra",
      "message": "How much does.......",
      "time": "3m",
      "image": "assets/images/user4.png",
      "isActive": true // Active user
    },
    {
      "name": "Rumi",
      "message": "I'm interested in.......",
      "time": "3m",
      "image": "assets/images/user1.png",
      "isActive": false
    },
    {
      "name": "Riya",
      "message": "I'm interested in.......",
      "time": "3m",
      "image": "assets/images/user2.png",
      "isActive": true // Active user
    },
    {
      "name": "Radhika",
      "message": "Typing...",
      "time": "3m",
      "image": "assets/images/user3.png",
      "isActive": false
    },
    {
      "name": "Amit Kumar",
      "message": "Let's connect soon!",
      "time": "4m",
      "image": "assets/images/user4.png",
      "isActive": true // Active user
    },
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          "Track Inquries",
          style: AppTextStyles.black18_600,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(),
          Text("Recent Messages", style: AppTextStyles.black16_500),
          Expanded(
            child: _buildRecentMessages(),
          )
        ],
      ),
    );
  }

  // Search Bar
  Widget _buildSearchBar() {
    return CustomSearchBar(
      enable: true,
      controller: _searchController,
      hintText: "Search Inquries",
    );
  }

  // Recent Messages List
  Widget _buildRecentMessages() {
    return ListView.builder(
      itemCount: messages.length,
      physics: AlwaysScrollableScrollPhysics(),
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
            onTap: () {},
          ),
        );
      },
    );
  }
}
