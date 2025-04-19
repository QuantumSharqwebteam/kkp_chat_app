import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';

class MyVerticalDivider extends StatelessWidget {
  final double height;
  const MyVerticalDivider({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: 1,
      color: AppColors.greyAAAAAA,
    );
  }
}
