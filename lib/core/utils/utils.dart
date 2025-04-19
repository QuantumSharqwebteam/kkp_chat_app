import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/image_constants.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_button.dart';
import 'package:kkp_chat_app/presentation/common_widgets/sucees_dialog.dart';

class Utils {
  double width(context) {
    return MediaQuery.of(context).size.width;
  }

  double height(context) {
    return MediaQuery.of(context).size.height;
  }

  Orientation orientation(context) {
    return MediaQuery.of(context).orientation;
  }

  void showSuccessDialog(BuildContext context, String message, bool success) {
    showDialog(
      context: context,
      barrierDismissible: true, // Prevent manual dismissal
      builder: (context) => SuccessErrorDialog(
        message: message,
        success: success,
      ),
    );
  }

  void showDialogWithActions(
    BuildContext context,
    String title,
    String description,
    String actionButtonText,
    VoidCallback action, {
    IconData? icon,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Trash icon
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                child: icon != null
                    ? Icon(icon, size: 30, color: AppColors.inActiveRed)
                    : Image.asset(
                        ImageConstants.deleteProduct,
                        height: 30,
                        width: 30,
                      ),
              ),
              SizedBox(height: 16),

              // Title
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),

              // Message
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              SizedBox(height: 20),

              // Buttons (Remove & Cancel)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: CustomButton(
                        onPressed: action,
                        borderColor: AppColors.inActiveRed,
                        fontSize: 16,
                        backgroundColor: AppColors.inActiveRed,
                        text: actionButtonText),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: CustomButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        textColor: Colors.black,
                        borderColor: AppColors.greyE5E7EB,
                        fontSize: 16,
                        backgroundColor: AppColors.greyE5E7EB,
                        text: "Cancel"),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  int generateIntUidFromEmail(String email) {
    return email.hashCode & 0x7FFFFFFF;
  }
}
