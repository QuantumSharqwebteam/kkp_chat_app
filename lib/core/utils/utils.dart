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

  void showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => SuccessDialog(message: message),
    );
  }

  void showRemoveProductDialog(BuildContext context, VoidCallback onRemove) {
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
                child: Image.asset(
                  ImageConstants.deleteProduct,
                  height: 30,
                  width: 30,
                ),
              ),
              SizedBox(height: 16),

              // Title
              Text(
                "Remove Product",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),

              // Message
              Text(
                "Are you sure you want to remove this product?",
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
                        onPressed: onRemove,
                        borderColor: AppColors.inActiveRed,
                        fontSize: 16,
                        backgroundColor: AppColors.inActiveRed,
                        text: "Remove"),
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
}
