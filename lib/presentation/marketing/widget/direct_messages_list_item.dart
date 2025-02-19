import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';

class DirectMessagesListItem extends StatelessWidget {
  final String name;
  final String image;
  final String status;
  final int unread;
  final bool typing;

  const DirectMessagesListItem({
    super.key,
    required this.name,
    required this.image,
    required this.status,
    required this.unread,
    required this.typing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: status == 'active'
                      ? AppColors.activeGreen
                      : AppColors.inActiveRed,
                  width: 3,
                ),
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundImage: AssetImage(image),
              ),
            ),
            if (unread > 0)
              Positioned(
                top: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.activeGreen,
                  child: Text(
                    unread.toString(),
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            if (typing)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.activeGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Typing....",
                    style: AppTextStyles.white8_600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        Text(name, style: AppTextStyles.black12_700),
      ],
    );
  }
}
