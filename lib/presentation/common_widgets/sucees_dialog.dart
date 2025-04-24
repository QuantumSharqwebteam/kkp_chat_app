import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/config/theme/image_constants.dart';

class SuccessErrorDialog extends StatelessWidget {
  final String message;
  final bool success;
  const SuccessErrorDialog(
      {super.key, required this.message, required this.success});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SizedBox(
        height: 176,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (success)
              Image.asset(
                ImageConstants.checkCircle,
                height: 76,
                width: 76,
              ),
            if (!success)
              Icon(
                Icons.error_outline_outlined,
                size: 50,
                color: AppColors.blue,
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
