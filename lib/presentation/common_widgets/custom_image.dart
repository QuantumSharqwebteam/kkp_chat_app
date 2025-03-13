import 'package:flutter/material.dart';

class CustomImage extends StatelessWidget {
  final String imagePath;
  final double? height;
  final double? width;
  final VoidCallback? onTap;
  final Widget? child;
  final BoxFit fit;
  final Color? backgroundColor;
  final double borderRadius;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;

  const CustomImage({
    super.key,
    required this.imagePath,
    this.height,
    this.width,
    this.onTap,
    this.child,
    this.fit = BoxFit.contain,
    this.backgroundColor,
    this.borderRadius = 8.0,
    this.border,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
          border: border,
          boxShadow: boxShadow,
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: fit,
          ),
        ),
        child: child,
      ),
    );
  }
}
