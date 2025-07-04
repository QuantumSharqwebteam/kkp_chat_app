import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';

class DeletedMessageBubble extends StatelessWidget {
  final bool isMe;
  final String timestamp;

  const DeletedMessageBubble({
    super.key,
    required this.isMe,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Stack(
          children: [
            Container(
              margin: const EdgeInsets.only(
                  top: 20, bottom: 15, left: 10, right: 10),
              padding: const EdgeInsets.only(
                  left: 20, right: 10, top: 10, bottom: 10),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              decoration: BoxDecoration(
                color: isMe
                    ? AppColors.senderMessageBubbleColor
                    : AppColors.recieverMessageBubble,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMe
                      ? const Radius.circular(16)
                      : const Radius.circular(0),
                  bottomRight: isMe
                      ? const Radius.circular(0)
                      : const Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.delete,
                    color: isMe ? Colors.white : Colors.black.withAlpha(153),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "This message is deleted",
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black.withAlpha(153),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: -1,
              right: isMe ? 10 : null,
              left: isMe ? null : 10,
              child: Text(
                timestamp,
                style: AppTextStyles.greyAAAAAA_10_400.copyWith(fontSize: 8.5),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
