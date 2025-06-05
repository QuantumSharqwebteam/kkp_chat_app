import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerMessageList extends StatelessWidget {
  final int itemCount;
  final Color baseShimmerColor;
  final Color highlightShimmerColor;

  const ShimmerMessageList({
    super.key,
    this.itemCount = 20,
    this.baseShimmerColor = const Color(0xFFE0E0E0),
    this.highlightShimmerColor = const Color(0xFFF5F5F5),
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseShimmerColor,
      highlightColor: highlightShimmerColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          bool isMe = index % 2 == 0;
          bool isImageBubble =
              index % 4 == 0; // Every 4th item is an image bubble

          return isImageBubble
              ? _buildShimmerImageBubble(context, isMe)
              : _buildShimmerMessageBubble(context, isMe);
        },
      ),
    );
  }

  Widget _buildShimmerMessageBubble(BuildContext context, bool isMe) {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isMe)
          CircleAvatar(
            radius: 15,
            backgroundColor: Colors.grey,
          ),
        Container(
          margin: const EdgeInsets.only(top: 5, bottom: 5, left: 10, right: 10),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          constraints: BoxConstraints(
            maxWidth: Utils().width(context) * 0.67,
          ),
          decoration: BoxDecoration(
            color: isMe
                ? AppColors.senderMessageBubbleColor
                : AppColors.recieverMessageBubble,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: isMe ? Radius.circular(16) : Radius.circular(0),
              bottomRight: isMe ? Radius.circular(0) : Radius.circular(16),
            ),
          ),
          child: Container(
            width: Utils().width(context) * 0.4,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        if (isMe)
          CircleAvatar(
            radius: 15,
            backgroundColor: Colors.grey,
          ),
      ],
    );
  }

  Widget _buildShimmerImageBubble(BuildContext context, bool isMe) {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isMe)
          CircleAvatar(
            radius: 15,
            backgroundColor: Colors.grey,
          ),
        Container(
          margin: const EdgeInsets.only(top: 5, bottom: 5, left: 10, right: 10),
          constraints: BoxConstraints(
            maxWidth: Utils().width(context) * 0.67,
          ),
          child: Container(
            width: Utils().width(context) * 0.5,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        if (isMe)
          CircleAvatar(
            radius: 15,
            backgroundColor: Colors.grey,
          ),
      ],
    );
  }
}
