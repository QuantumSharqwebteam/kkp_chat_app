import 'package:flutter/material.dart';
import 'package:flutter_initicon/flutter_initicon.dart';
import 'package:intl/intl.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart' show AppTextStyles;
import 'package:kkpchatapp/data/models/group_message_model.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/deleted_message_bubble.dart';

class GroupMessageBubble extends StatelessWidget {
  final GroupMessageModel message;
  final bool isMe;
  final VoidCallback? onLongPress;
  final GroupMessageModel? referencedMessage;

  const GroupMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onLongPress,
    this.referencedMessage,
  });

  @override
  Widget build(BuildContext context) {
    return message.isDeleted
        ? DeletedMessageBubble(
            isMe: isMe,
            timestamp: DateFormat('hh:mm a').format(message.timestamp),
          )
        : GestureDetector(
            onLongPress: onLongPress,
            child: Row(
              mainAxisAlignment:
                  isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Initicon(text: message.senderName, size: 25),
                  ),
                Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(
                          top: 10, bottom: 15, left: 10, right: 10),
                      padding: const EdgeInsets.only(
                          left: 10, right: 10, top: 10, bottom: 10),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isMe)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 5.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "~${message.senderName}",
                                    style: AppTextStyles.greyAAAAAA_10_400
                                        .copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    message.senderId,
                                    style: AppTextStyles.greyAAAAAA_10_400
                                        .copyWith(fontSize: 8),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          if (referencedMessage != null)
                            _GroupReplyStrip(
                              sender: referencedMessage!.senderName,
                              text: _previewText(referencedMessage!),
                              isMe: isMe,
                            ),
                          Text(
                            message.message,
                            style: TextStyle(
                              color: isMe
                                  ? Colors.white
                                  : Colors.black.withAlpha(153),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.start,
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: -1,
                      right: isMe ? 10 : null,
                      left: isMe ? null : 10,
                      child: Text(
                        DateFormat('hh:mm a').format(message.timestamp),
                        style:
                            AppTextStyles.greyAAAAAA_10_400.copyWith(fontSize: 8.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
  }

  String _previewText(GroupMessageModel m) {
    if (m.isDeleted) return 'This message was deleted';
    if (m.type == 'media') return '📷 Photo';
    if (m.type == 'voice') return '🎤 Voice message';
    if (m.type == 'document') return '📄 Document';
    return m.message;
  }
}

class _GroupReplyStrip extends StatelessWidget {
  final String sender;
  final String text;
  final bool isMe;

  const _GroupReplyStrip({
    required this.sender,
    required this.text,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isMe ? Colors.white.withOpacity(0.2) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(color: Color(0xFF6B7AED), width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            sender,
            style: const TextStyle(
              color: Color(0xFF6B7AED),
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: isMe ? Colors.white70 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
