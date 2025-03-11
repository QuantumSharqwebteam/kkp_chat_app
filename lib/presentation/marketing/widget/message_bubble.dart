import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String image;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isMe,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              margin: const EdgeInsets.all(8.0),
              padding: const EdgeInsets.only(
                  left: 20, right: 10, top: 10, bottom: 10),
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7),
              decoration: BoxDecoration(
                color: isMe ? AppColors.messageBubbleColor : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(3),
                  topRight: Radius.circular(35),
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(26),
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.74)
                      : Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              child: CircleAvatar(
                backgroundImage: AssetImage(image),
                radius: 12,
              ),
            )
          ],
        ),
        //if (isMe) CircleAvatar(backgroundImage: AssetImage(image)),
      ],
    );
  }
}
