import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_button.dart';

class FillFormButton extends StatelessWidget {
  final void Function()? onSubmit;
  const FillFormButton({super.key, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 15, left: 10, right: 30),
      padding: const EdgeInsets.only(left: 20, right: 30, top: 10, bottom: 10),
      constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.5),
      decoration: BoxDecoration(
        color: Color(0xffF2F2F2),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        spacing: 10,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Click the button below to open the form:",
            style: AppTextStyles.black14_400.copyWith(
              color: AppColors.black60opac,
            ),
          ),
          Center(
            child: CustomButton(
              onPressed: onSubmit,
              image: Icon(Icons.edit_document, color: Colors.white, size: 16),
              backgroundColor: AppColors.blue,
              textColor: Colors.white,
              padding: EdgeInsets.all(6),
              fontSize: 14,
              text: "Fill product Details",
            ),
          ),
        ],
      ),
    );
  }
}
