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
        if (!isMe) CircleAvatar(backgroundImage: AssetImage(image)),
        Container(
          margin: const EdgeInsets.all(8.0),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          constraints:
              BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
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
              color: isMe ? Colors.white : Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (isMe) CircleAvatar(backgroundImage: AssetImage(image)),
      ],
    );
  }
}
