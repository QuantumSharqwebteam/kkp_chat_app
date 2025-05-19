import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_button.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_textfield.dart';

class FormUpdateAlertDialog extends StatelessWidget {
  final String formId;

  final String quality;
  final String quantity;
  final String weave;
  final String composition;
  final TextEditingController rateController;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  const FormUpdateAlertDialog({
    super.key,
    required this.quality,
    required this.quantity,
    required this.weave,
    required this.composition,
    required this.rateController,
    required this.onCancel,
    required this.onSubmit,
    required this.formId,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      title: Text("Review Product form :",
          style: AppTextStyles.black16_600.copyWith(color: AppColors.blue)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Form ID ',
                  style: AppTextStyles.black14_600,
                ),
                TextSpan(
                  text: formId,
                  style: AppTextStyles.grey12_600,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Quality: ',
                  style: AppTextStyles.black14_600,
                ),
                TextSpan(
                  text: quality,
                  style: AppTextStyles.grey12_600,
                ),
              ],
            ),
          ),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Quantity: ',
                  style: AppTextStyles.black14_600,
                ),
                TextSpan(
                  text: quantity,
                  style: AppTextStyles.grey12_600,
                ),
              ],
            ),
          ),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Weave: ',
                  style: AppTextStyles.black14_600,
                ),
                TextSpan(
                  text: weave,
                  style: AppTextStyles.grey12_600,
                ),
              ],
            ),
          ),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Composition: ',
                  style: AppTextStyles.black14_600,
                ),
                TextSpan(
                  text: composition,
                  style: AppTextStyles.grey12_600,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          CustomTextField(
            controller: rateController,
            keyboardType: TextInputType.number,
            hintText: "Enter final rate",
          ),
        ],
      ),
      actions: <Widget>[
        CustomButton(
          width: Utils().width(context) * 0.3,
          backgroundColor: Colors.white,
          borderColor: AppColors.blue,
          onPressed: onCancel,
          text: "Cancel",
          textColor: AppColors.blue,
        ),
        CustomButton(
          width: Utils().width(context) * 0.3,
          onPressed: onSubmit,
          text: "submit",
        ),
      ],
    );
  }
}
