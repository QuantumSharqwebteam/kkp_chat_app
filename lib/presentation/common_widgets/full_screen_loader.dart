import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';

class FullScreenLoader extends StatelessWidget {
  const FullScreenLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Utils().height(context),
      width: Utils().width(context),
      color: Colors.white.withValues(alpha: 0.7), // Dim background
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.blue,
          strokeWidth: 6,
          semanticsLabel: "Uploading...",
          semanticsValue: "Uploading...",
        ),
      ),
    );
  }
}
