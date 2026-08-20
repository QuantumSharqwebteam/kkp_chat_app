import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/data/models/chat_message_model.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/deleted_message_bubble.dart';
import 'dart:io';

class MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;
  final VoidCallback? onLongPress;
  final bool? read;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onLongPress,
    this.read = false,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = read ?? false;
    return message.isDeleted
        ? DeletedMessageBubble(
            isMe: isMe,
            timestamp: DateFormat('hh:mm a').format(message.timestamp))
        : GestureDetector(
            onLongPress: onLongPress,
            child: Row(
              mainAxisAlignment:
                  isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(
                          top: 20, bottom: 15, left: 10, right: 10),
                      padding: const EdgeInsets.only(
                          left: 12, right: 10, top: 10, bottom: 10),
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7),
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (referencedMessage != null)
                            _ReplyPreviewStrip(
                              sender: referencedSenderLabel ??
                                  (referencedMessage!.sender ?? ''),
                              text: _previewText(referencedMessage!),
                              imageUrl: referencedMessage!.type == 'media'
                                  ? referencedMessage!.mediaUrl
                                  : null,
                              isMe: isMe,
                            ),
                          Text(
                            message.message ?? '',
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat('hh:mm a').format(message.timestamp),
                            style: AppTextStyles.greyAAAAAA_10_400
                                .copyWith(fontSize: 8.5),
                          ),
                          if (isMe)
                            Icon(
                              isRead ? Icons.done_all : Icons.done,
                              color: isRead ? Colors.blue : Colors.grey,
                              size: 14,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
  }

  String _previewText(ChatMessageModel m) {
    if (m.isDeleted) return 'This message was deleted';
    if (m.type == 'media') return '📷 Photo';
    if (m.type == 'voice') return '🎤 Voice message';
    if (m.type == 'document') return '📄 Document';
    if (m.type == 'call') return '📞 Call';
    if (m.type == 'product') return '🛍 Product';
    return m.message ?? '';
  }
}

class _ReplyPreviewStrip extends StatelessWidget {
  final String sender;
  final String text;
  final String? imageUrl;
  final bool isMe;

  const _ReplyPreviewStrip({
    required this.sender,
    required this.text,
    this.imageUrl,
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
          Row(
            children: [
              if (imageUrl != null) ...[
                _ReplyImageThumb(imageUrl: imageUrl!),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: isMe ? Colors.white70 : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReplyImageThumb extends StatelessWidget {
  final String imageUrl;

  const _ReplyImageThumb({required this.imageUrl});

  bool get _isLocalFile =>
      imageUrl.startsWith('/') || imageUrl.startsWith('file://');

  @override
  Widget build(BuildContext context) {
    final filePath = imageUrl.replaceFirst('file://', '');
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: 34,
        height: 34,
        child: _isLocalFile
            ? Image.file(File(filePath), fit: BoxFit.cover)
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.greyE5E7EB,
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.greyE5E7EB,
                  child: const Icon(Icons.broken_image, size: 16),
                ),
              ),
      ),
    );
  }
}
