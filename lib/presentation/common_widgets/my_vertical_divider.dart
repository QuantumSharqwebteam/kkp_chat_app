import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';

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
