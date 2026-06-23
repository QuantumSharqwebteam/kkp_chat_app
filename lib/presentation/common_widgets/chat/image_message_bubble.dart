import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/models/chat_message_model.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/deleted_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/preview_image.dart';
import 'dart:io';

class ImageMessageBubble extends StatefulWidget {
  final String imageUrl;
  final bool isMe;
  final String timestamp;
  final bool uploading;
  final bool sent;
  final bool? read;

  final VoidCallback? onImageLoaded;
  final VoidCallback? onLongPress;
  final bool isDeleted;
  final ChatMessageModel? referencedMessage;
  final String? referencedSenderLabel;

  const ImageMessageBubble({
    super.key,
    required this.imageUrl,
    required this.isMe,
    required this.timestamp,
    this.uploading = false,
    this.sent = false,
    this.isDeleted = false,
    this.onImageLoaded,
    this.onLongPress,
    this.read = false,
    this.referencedMessage,
    this.referencedSenderLabel,
  });

  @override
  State<ImageMessageBubble> createState() => _ImageMessageBubbleState();
}

class _ImageMessageBubbleState extends State<ImageMessageBubble> {
  bool _notifiedImageLoaded = false;

  bool get isLocalFile =>
      widget.imageUrl.startsWith('/') || widget.imageUrl.startsWith('file://');

  void _notifyImageLoadedOnce() {
    if (_notifiedImageLoaded) return;
    _notifiedImageLoaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onImageLoaded?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = Utils().width(context) >= 600;
    final isRead = widget.read ?? false;
    return widget.isDeleted
        ? DeletedMessageBubble(isMe: widget.isMe, timestamp: widget.timestamp)
        : Align(
            alignment:
                widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isTablet
                    ? MediaQuery.of(context).size.width * 0.35
                    : MediaQuery.of(context).size.width * 0.7,
              ),
              child: Column(
                crossAxisAlignment: widget.isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (!widget.isDeleted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PreviewImage(imageUrl: widget.imageUrl),
                          ),
                        );
                      }
                    },
                    onLongPress: widget.onLongPress,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.greyE5E7EB),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.referencedMessage != null)
                            _ReplyPreviewStrip(
                              sender: widget.referencedSenderLabel ??
                                  widget.referencedMessage!.sender ??
                                  '',
                              text: _previewText(widget.referencedMessage!),
                              imageUrl:
                                  widget.referencedMessage!.type == 'media'
                                      ? widget.referencedMessage!.mediaUrl
                                      : null,
                              isMe: widget.isMe,
                            ),
                          SizedBox(
                            width: double.infinity,
                            height: 200,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: isLocalFile
                                  ? Image.file(
                                      File(widget.imageUrl
                                          .replaceFirst('file://', '')),
                                      fit: BoxFit.cover,
                                      frameBuilder: (
                                        context,
                                        child,
                                        frame,
                                        wasSynchronouslyLoaded,
                                      ) {
                                        if (wasSynchronouslyLoaded ||
                                            frame != null) {
                                          _notifyImageLoadedOnce();
                                        }
                                        return child;
                                      },
                                    )
                                  : CachedNetworkImage(
                                      imageUrl: widget.imageUrl,
                                      fit: BoxFit.cover,
                                      imageBuilder: (context, imageProvider) {
                                        _notifyImageLoadedOnce();
                                        return Image(
                                          image: imageProvider,
                                          fit: BoxFit.cover,
                                        );
                                      },
                                      placeholder: (context, url) => Container(
                                        color: AppColors.greyE5E7EB,
                                      ),
                                      errorWidget: (context, url, error) {
                                        _notifyImageLoadedOnce();
                                        return Container(
                                          color: AppColors.greyE5E7EB,
                                          child: const Icon(
                                            Icons.broken_image,
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.timestamp,
                        style: AppTextStyles.greyAAAAAA_10_400,
                      ),
                      const SizedBox(width: 4),
                      if (widget.isMe)
                        Icon(
                          Icons.check,
                          color: isRead ? Colors.blue : Colors.grey,
                          size: 16,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
  }

  String _previewText(ChatMessageModel m) {
    if (m.isDeleted) return 'This message was deleted';
    if (m.type == 'media') return 'Photo';
    if (m.type == 'voice') return 'Voice message';
    if (m.type == 'document') return 'Document';
    if (m.type == 'call') return 'Call';
    if (m.type == 'product') return 'Product';
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
      margin: const EdgeInsets.only(bottom: 8),
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
