import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';
import 'package:kkp_chat_app/presentation/common_widgets/profile_avatar.dart';

class RecentMessagesListCard extends StatelessWidget {
  final String name;
  final String message;
  final String time;
  final String image;
  final bool isActive;
  final bool isPinned;
  final void Function() onTap;

  const RecentMessagesListCard({
    super.key,
    required this.name,
    required this.message,
    required this.time,
    required this.image,
    required this.isActive,
    this.isPinned = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: ProfileAvatar(
        image: image,
        isActive: isActive,
      ),
      title: Text(
        name,
        style: AppTextStyles.black14_600,
      ),
      subtitle: Text(message, style: AppTextStyles.grey12_600),
      trailing: isPinned
          ? const Icon(Icons.push_pin,
              color: AppColors.redF11515, size: 16) // Pinned icon
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(time, style: AppTextStyles.black10_600),
                CircleAvatar(
                  radius: 3,
                  backgroundColor: AppColors.inActiveRed,
                ),
              ],
            ),
    );
  }
}
