import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/deleted_message_bubble.dart';

class ProductMessageBubble extends StatelessWidget {
  final String productJson;
  final bool isMe;
  final String timestamp;
  final VoidCallback onTap;
  final bool isDeleted;
  final VoidCallback? onLongPress;

  const ProductMessageBubble({
    super.key,
    required this.productJson,
    required this.isMe,
    required this.timestamp,
    required this.onTap,
    this.isDeleted = false,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    // Parse the product JSON string to get the product details
    final productMap = jsonDecode(productJson);
    final productName = productMap['productName'];
    final productImageUrl = productMap['imageUrl'];

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
                    onTap: onTap,
                    onLongPress: onLongPress,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.greyE5E7EB),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Display the product image
                          CachedNetworkImage(
                            imageUrl: productImageUrl,
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
                          const SizedBox(height: 8),
                          // Display the product name
                          Text(
                            productName,
                            style: AppTextStyles.black14_600
                                .copyWith(color: Colors.black),
                          ),
                        ],
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
                    ],
                  ),
                ],
              ),
            ),
          );
  }
}
