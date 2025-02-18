import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.width = double.infinity,
    this.height = 55,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    this.elevation = 2.0,
    this.borderColor,
    this.borderWidth = 0,
    this.image, // ✅ Accepts Widget instead of String
    this.imagePosition = ImagePosition.leading, // ✅ Image position
  });

  final String text;
  final VoidCallback? onPressed;
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Colors.blue, // Default color
          elevation: elevation,
          // padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: borderWidth > 0
                ? BorderSide(
                    color: borderColor ?? Colors.black, width: borderWidth)
                : BorderSide.none,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (image != null && imagePosition == ImagePosition.leading) ...[
              image!,
              const SizedBox(width: 8), // Space between image and text
            ],
            Text(
              text,
              style: TextStyle(
                color: textColor ?? Colors.white,
                fontSize: fontSize ?? 16.0,
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
