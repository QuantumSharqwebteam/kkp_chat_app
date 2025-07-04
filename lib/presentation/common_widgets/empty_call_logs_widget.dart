import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/utils/utils.dart';

class EmptyCallLogsWidget extends StatelessWidget {
  const EmptyCallLogsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: Utils().height(context) * 0.2,
        ),
        CircleAvatar(
          radius: 55,
          backgroundColor: AppColors.greyE5E7EB,
          child: Icon(
            Icons.call,
            size: 55,
            color: AppColors.grey474747,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "No Call History !",
          style: AppTextStyles.black16_500,
        ),
        Text(
          "Your call logs will apppear here once you started making or recieving calls",
          style: AppTextStyles.grey12_600,
          textAlign: TextAlign.center,
        )
      ],
    );
  }
}
