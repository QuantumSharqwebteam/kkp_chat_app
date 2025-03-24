import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String image;
  final String? timestamp;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isMe,
    required this.image,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isMe) CircleAvatar(backgroundImage: AssetImage(image)),
        Stack(
          children: [
            Container(
              margin: const EdgeInsets.only(
                  top: 20, bottom: 15, left: 10, right: 10),
              padding: const EdgeInsets.only(
                  left: 20, right: 10, top: 10, bottom: 10),
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7),
              decoration: BoxDecoration(
                color: isMe ? AppColors.blue00ABE9 : Color(0xffF2F2F2),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: isMe ? Radius.circular(16) : Radius.circular(0),
                  bottomRight: isMe ? Radius.circular(0) : Radius.circular(16),
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color:
                      isMe ? Colors.white : Colors.black.withValues(alpha: .6),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.start,
              ),
            ),
            // Positioned(
            //   top: 0,
            //   left: 0,
            //   child: CircleAvatar(
            //     backgroundImage: AssetImage(image),
            //     radius: 12,
            //   ),
            // ),
            Positioned(
              bottom: -1,
              right: 10,
              child: Text(
                timestamp ?? "",
                style: AppTextStyles.greyAAAAAA_10_400,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
