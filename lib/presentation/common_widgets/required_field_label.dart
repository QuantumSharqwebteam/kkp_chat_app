import 'package:flutter/material.dart';

class RequiredFieldLabel extends StatelessWidget {
  const RequiredFieldLabel(
    this.text, {
    super.key,
    this.style,
    this.asteriskColor = Colors.red,
    this.showAsterisk = true,
  });

  final String text;
  final TextStyle? style;
  final Color asteriskColor;
  final bool showAsterisk;

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? const TextStyle(fontWeight: FontWeight.bold, color: Colors.black);

    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: text),
          if (showAsterisk)
            TextSpan(
              text: ' *',
              style: baseStyle.copyWith(color: asteriskColor),
            ),
        ],
      ),
    );
  }
}
