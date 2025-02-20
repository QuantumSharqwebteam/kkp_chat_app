import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';

class RecentMessagesListCard extends StatelessWidget {
  final String name;
  final String message;
  final String time;
  final String image;
  final bool isActive;

  const RecentMessagesListCard({
    super.key,
    required this.name,
    required this.message,
    required this.time,
    required this.image,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: AssetImage(image),
          ),
          // Green dot for active users
          if (isActive)
            Positioned(
              bottom: 2,
              right: 2,
              child: _buildStatusIndicator(color: AppColors.activeGreen),
            ),
          // Red dot for inactive users
          if (!isActive)
            Positioned(
              bottom: 2,
              right: 2,
              child: _buildStatusIndicator(color: AppColors.inActiveRed),
            ),
        ],
      ),
      title: Text(
        name,
        style: AppTextStyles.black14_600,
      ),
      subtitle: Text(message, style: AppTextStyles.grey12_600),
      trailing: Column(
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

  Widget _buildStatusIndicator({required Color color}) {
    return Container(
      height: 10,
      width: 10,
      decoration:
          BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [
        BoxShadow(
          blurRadius: 4,
          spreadRadius: 0,
          offset: const Offset(0, 4),
          color: AppColors.shadowColor,
        )
      ]),
    );
  }
}
