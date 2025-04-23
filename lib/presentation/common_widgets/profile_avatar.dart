import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';

class ProfileAvatar extends StatelessWidget {
  final String image;
  final bool isActive;
  final double radius;

  const ProfileAvatar({
    super.key,
    required this.image,
    required this.isActive,
    this.radius = 30,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundImage: AssetImage(image),
        ),
        Positioned(
          bottom: 2,
          right: 2,
          child: Container(
            height: 10,
            width: 10,
            decoration: BoxDecoration(
              color: isActive ? AppColors.activeGreen : AppColors.inActiveRed,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  blurRadius: 4,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                  color: AppColors.shadowColor,
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}
