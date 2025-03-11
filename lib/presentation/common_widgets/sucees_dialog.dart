import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';

class SuccessDialog extends StatelessWidget {
  final String message;

  const SuccessDialog({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[300], // Light grey background
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SizedBox(
        height: 176,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/icons/check_circle.png",
              height: 76,
              width: 76,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: AppTextStyles.black18_600,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }
}
