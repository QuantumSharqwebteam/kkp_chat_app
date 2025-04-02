import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';

import '../../../config/theme/image_constants.dart';

class NoChatConversation extends StatelessWidget {
  const NoChatConversation({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80, left: 20, right: 20),
      child: Column(
        children: [
          Image.asset(
            ImageConstants.noChat, // Replace with your asset path
            width: 300,
            height: 300,
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              "\"No conversations yet! Start a new chat to place your order or ask any questions. We're here to help!\"",
              style: AppTextStyles.black16_500.copyWith(
                color: AppColors.grey7B7B7B,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
