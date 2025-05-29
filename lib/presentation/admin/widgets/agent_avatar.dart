import 'package:flutter/material.dart';
import 'package:flutter_initicon/flutter_initicon.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';

class AgentAvatar extends StatelessWidget {
  final String name;
  final bool isOnline;

  const AgentAvatar({
    super.key,
    required this.name,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isOnline ? AppColors.activeGreen : AppColors.inActiveRed,
          width: 3,
        ),
      ),
      child: Initicon(
        text: name,
        size: 30,
      ),
    );
  }
}
