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
  final VoidCallback onTap;
  final VoidCallback? onPinTap;

  const RecentMessagesListCard({
    super.key,
    required this.name,
    required this.message,
    required this.time,
    required this.image,
    required this.isActive,
    this.isPinned = false,
    required this.onTap,
    this.onPinTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPressStart: (LongPressStartDetails details) {
        _showPinMenu(context, details.globalPosition);
      }, // Show menu on long press
      child: ListTile(
        contentPadding: EdgeInsets.zero,
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
            ? const Icon(Icons.push_pin, color: AppColors.redF11515, size: 16)
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
      ),
    );
  }

  void _showPinMenu(BuildContext context, Offset position) {
    showMenu(
      context: context,
      color: Colors.white,
      elevation: 10,
      surfaceTintColor: Colors.white,
      position: RelativeRect.fromLTRB(
        position.dx, // X position of tap
        position.dy, // Y position of tap
        position.dx + 40, // Avoids overflow
        position.dy + 40,
      ),
      items: [
        PopupMenuItem(
          child: Text(isPinned ? "Unpin Agent" : "Pin Agent"),
          onTap: () {
            Future.delayed(const Duration(milliseconds: 200), onPinTap);
          },
        ),
      ],
    );
  }
}
