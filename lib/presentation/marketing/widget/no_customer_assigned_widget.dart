import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/config/theme/image_constants.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_image.dart';

class NoCustomerAssignedWidget extends StatelessWidget {
  const NoCustomerAssignedWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Stack(
              children: [
                CustomImage(
                  imagePath: ImageConstants.noCustomerAssigned,
                  height: 400,
                  width: 300,
                ),
                Positioned(
                  top: 300,
                  left: 70,
                  child: Text(
                    "No Customer Assigned !!",
                    style: AppTextStyles.grey12_600,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
