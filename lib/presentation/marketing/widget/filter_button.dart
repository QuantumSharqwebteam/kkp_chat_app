import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';

class FilterButton extends StatelessWidget {
  final IconData? icon;
  final String? text;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color textColor;
  final Color iconColor;

  const FilterButton({
    super.key,
    this.icon,
    this.text,
    this.onTap,
    this.backgroundColor = AppColors.background, // Light background
    this.textColor = Colors.black,
    this.iconColor = Colors.black,
  }) : assert((icon != null) ^ (text != null),
            'Provide either icon or text, not both');

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, size: 20, color: iconColor)
              : Text(
                  text!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
        ),
      ),
    );
  }
}
