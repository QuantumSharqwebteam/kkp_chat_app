import 'package:flutter/material.dart';
import 'package:flutter_initicon/flutter_initicon.dart';
import 'package:intl/intl.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';

class GroupChatTile extends StatelessWidget {
  final String groupName;
  final String lastMessage;
  final DateTime? time;
  final int unreadCount;
  final VoidCallback onTap;

  const GroupChatTile({
    super.key,
    required this.groupName,
    required this.lastMessage,
    this.time,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Initicon(text: groupName),
      title: Text(groupName),
      subtitle: Text(lastMessage),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (time != null) Text(DateFormat('hh:mm a').format(time!)),
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.all(2),
              margin: const EdgeInsets.only(top: 4),
              decoration: const BoxDecoration(color: AppColors.activeGreen, shape: BoxShape.circle),
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}
