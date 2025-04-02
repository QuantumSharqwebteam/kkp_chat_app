import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';
import 'package:kkp_chat_app/presentation/common_widgets/chat/preview_image.dart';

class ImageMessageBubble extends StatelessWidget {
  final String imageUrl;
  final bool isMe;
  final String timestamp;

  const ImageMessageBubble({
    super.key,
    required this.imageUrl,
    required this.isMe,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PreviewImage(imageUrl: imageUrl),
                  ),
                );
              },
              child: Container(
                margin: EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                    //  color: isMe ? Colors.blue : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.greyE5E7EB)),
                padding: const EdgeInsets.all(10),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 200,
                  placeholder: (context, url) => Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(Icons.broken_image),
                  ),
                  memCacheHeight: 200,
                  memCacheWidth: 400,
                  maxHeightDiskCache: 200,
                  maxWidthDiskCache: 400,
                ),
              ),
            ),
            Text(
              timestamp,
              style: AppTextStyles.greyAAAAAA_10_400,
            ),
          ],
        ),
      ),
    );
  }
}
