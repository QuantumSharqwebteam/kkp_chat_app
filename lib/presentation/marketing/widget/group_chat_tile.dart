import 'package:flutter/material.dart';
import 'package:flutter_initicon/flutter_initicon.dart';
import 'package:intl/intl.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';

class GroupChatTile extends StatelessWidget {
  final String groupName;
  final String lastMessage;
  final int memberCount;
  final DateTime? time;
  final int unreadCount;
  final VoidCallback onTap;

  const GroupChatTile({
    super.key,
    required this.groupName,
    required this.lastMessage,
    this.memberCount = 0,
    this.time,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Initicon(text: groupName),
      title: Text(groupName, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: _buildSubtitle(),  // null → single-line tile (no cached message)
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (time != null)
            Text(
              DateFormat('hh:mm a').format(time!),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            )
          else if (memberCount > 0)
            Text(
              '$memberCount members',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(top: 4),
              decoration: const BoxDecoration(
                  color: AppColors.activeGreen, shape: BoxShape.circle),
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

  Widget? _buildSubtitle() {
    if (lastMessage.isEmpty) return null;

    IconData? icon;
    String displayText = lastMessage;

    if (lastMessage == '[Photo]') {
      icon = Icons.photo_outlined;
      displayText = 'Photo';
    } else if (lastMessage == '[Voice]') {
      icon = Icons.mic_none_rounded;
      displayText = 'Voice message';
    } else if (lastMessage == '[Document]') {
      icon = Icons.description_outlined;
      displayText = 'Document';
    }

    if (icon != null) {
      return Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Text(displayText,
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ],
      );
    }

    return Text(
      lastMessage,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: Colors.grey[700], fontSize: 13),
    );
  }
}
