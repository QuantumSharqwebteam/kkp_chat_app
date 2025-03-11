import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';

class AgentAvatar extends StatelessWidget {
  final String image;
  final String status;

  const AgentAvatar({
    super.key,
    required this.image,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
