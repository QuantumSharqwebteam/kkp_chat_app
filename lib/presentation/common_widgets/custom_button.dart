import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.width = double.infinity,
    this.height = 45,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.borderRadius = 10,
    this.padding = const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    this.elevation = 0,
    this.borderColor = AppColors.blue,
    this.borderWidth = 1,
    this.image,
    this.imagePosition = ImagePosition.leading,
    this.isLoading = false,
    this.loaderColor,
    this.loaderStrokeWidth = 2.2,
  });

  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double elevation;
  final Color? borderColor;
  final double borderWidth;
  final Widget? image;
  final ImagePosition imagePosition;
  final bool isLoading;
  final Color? loaderColor;
  final double loaderStrokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.blue,
          elevation: elevation,
          // padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: borderWidth > 0
                ? BorderSide(
                    color: borderColor ?? AppColors.blue, width: borderWidth)
                : BorderSide.none,
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: (fontSize ?? 14) + 6,
                width: (fontSize ?? 14) + 6,
                child: CircularProgressIndicator(
                  strokeWidth: loaderStrokeWidth,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    loaderColor ?? textColor ?? Colors.white,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon,
                        color: textColor ?? Colors.white, size: fontSize ?? 20),
                    const SizedBox(width: 8),
                  ] else if (image != null &&
                      imagePosition == ImagePosition.leading) ...[
                    image!,
                    const SizedBox(width: 8), // Space between image and text
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      color: textColor ?? Colors.white,
                      fontSize: fontSize ?? 14.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (image != null && imagePosition == ImagePosition.trailing) ...[
                    const SizedBox(width: 8), // Space between text and image
                    image!,
                  ],
                ],
              ),
      ),
    );
  }
}

enum ImagePosition { leading, trailing }
