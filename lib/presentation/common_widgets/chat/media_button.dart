import 'package:flutter/material.dart';

class MediaButton extends StatelessWidget {
  final Color backgroundColor;
  final Color iconColor;
  final void Function() onTap;
  final IconData iconData;
  const MediaButton(
      {super.key,
      required this.backgroundColor,
      required this.iconColor,
      required this.onTap,
      required this.iconData});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        width: 50,
        decoration:
            BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
        child: Icon(
          iconData,
          color: iconColor,
          size: 31,
        ),
      ),
    );
  }
}
