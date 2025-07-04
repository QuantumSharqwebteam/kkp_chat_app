import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/deleted_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/preview_image.dart';
import 'dart:io';

class ImageMessageBubble extends StatelessWidget {
  final String imageUrl;
  final bool isMe;
  final String timestamp;
  final bool uploading;
  final bool sent;

  final VoidCallback? onImageLoaded;
  final VoidCallback? onLongPress;
  final bool isDeleted;

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
  });

  bool get isLocalFile =>
      imageUrl.startsWith('/') || imageUrl.startsWith('file://');

  @override
  Widget build(BuildContext context) {
    return isDeleted
        ? DeletedMessageBubble(isMe: isMe, timestamp: timestamp)
        : Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (!isDeleted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PreviewImage(imageUrl: imageUrl),
                          ),
                        );
                      }
                    },
                    onLongPress: onLongPress,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.greyE5E7EB),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: isLocalFile
                          ? Image.file(
                              File(imageUrl),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 200,
                            )
                          : CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 200,
                              placeholder: (context, url) => Container(
                                height: 200,
                                color: AppColors.greyE5E7EB,
                              ),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.broken_image),
                            ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timestamp,
                        style: AppTextStyles.greyAAAAAA_10_400,
                      ),
                      const SizedBox(width: 4),
                      if (uploading)
                        const Icon(Icons.access_time,
                            size: 12, color: Colors.grey)
                      else if (sent)
                        const Icon(Icons.done_all,
                            size: 14, color: Colors.green),
                    ],
                  ),
                ],
              ),
            ),
          );
  }
}
