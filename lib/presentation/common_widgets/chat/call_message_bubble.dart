import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';

class CallMessageBubble extends StatelessWidget {
  final bool isMe;
  final String timestamp;
  final String callStatus;
  final String callDuration;

  const CallMessageBubble({
    super.key,
    required this.isMe,
    required this.timestamp,
    required this.callStatus,
    required this.callDuration,
  });

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    Color iconColor;
    String statusText;

    switch (callStatus) {
      case 'answered':
        iconData = Icons.call;
        iconColor = Colors.green;
        statusText = 'Call ended';
        break;
      case 'not answered':
        iconData = Icons.call_end;
        iconColor = Colors.orange;
        statusText = 'Not answered';
        break;
      case 'missed':
      default:
        iconData = Icons.call_missed;
        iconColor = Colors.red;
        statusText = 'Call missed';
        break;
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: IntrinsicWidth(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMe
                ? AppColors.senderMessageBubbleColor
                : AppColors.recieverMessageBubble,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft:
                  isMe ? const Radius.circular(16) : const Radius.circular(0),
              bottomRight:
                  isMe ? const Radius.circular(0) : const Radius.circular(16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(iconData, color: iconColor, size: 20),
                  const SizedBox(width: 8),
                  Text(statusText,
                      style: AppTextStyles.black14_600.copyWith(
                        color: isMe ? Colors.white : Colors.black,
                      )),
                ],
              ),
              if (callStatus == 'answered') ...[
                const SizedBox(height: 4),
                Text(callDuration,
                    style: AppTextStyles.grey5C5C5C_18_700.copyWith(
                      color: isMe ? Colors.white70 : null,
                    )),
              ],
              const SizedBox(height: 4),
              Text(
                timestamp,
                style: AppTextStyles.greyAAAAAA_10_400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
