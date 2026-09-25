import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/config/theme/image_constants.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_image.dart';
import 'dart:io';

class ChatInputField extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onSendImage;
  final VoidCallback onSendImageByCamera;
  final VoidCallback onSendForm;
  final VoidCallback onSendDocument;
  final VoidCallback onSendVoice;
  final bool isRecording;
  final int recordedSeconds; // Add this line
  final VoidCallback onShareProduct;
  final VoidCallback? onCheckOrders;
  final bool showFormAndProduct;
  final bool showCheckOrders;
  final bool showInquiryForm;
  final String? replyToSender;
  final String? replyToText;
  final String? replyPreviewImageUrl;
  final VoidCallback? onCancelReply;

  const ChatInputField({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onSendImage,
    required this.onSendForm,
    required this.onSendDocument,
    required this.onSendVoice,
    required this.isRecording,
    required this.recordedSeconds,
    required this.onSendImageByCamera,
    required this.onShareProduct,
    this.onCheckOrders,
    this.showFormAndProduct = true,
    this.showCheckOrders = false,
    this.showInquiryForm = true,
    this.replyToSender,
    this.replyToText,
    this.replyPreviewImageUrl,
    this.onCancelReply,
  });

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation =
        Tween<double>(begin: 1.0, end: 1.5).animate(_animationController)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _animationController.reverse();
            } else if (status == AnimationStatus.dismissed) {
              _animationController.forward();
            }
          });

    if (widget.isRecording) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant ChatInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording) {
      _animationController.forward();
    } else {
      _animationController.stop();
      _animationController.value = 0.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.replyToSender != null)
          Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B7AED),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.replyToSender!,
                        style: const TextStyle(
                          color: Color(0xFF6B7AED),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Row(
                        children: [
                          if (widget.replyPreviewImageUrl != null) ...[
                            _ReplyImageThumb(
                              imageUrl: widget.replyPreviewImageUrl!,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Text(
                              widget.replyToText ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                  onPressed: widget.onCancelReply,
                ),
              ],
            ),
          ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.attachment),
                onPressed: () {
                  showAttachmentMenu(
                    context,
                    (selectedItem) {
                      if (selectedItem == "Photos") {
                        widget.onSendImage();
                      } else if (selectedItem == "Inquiry Form") {
                        widget.onSendForm();
                      } else if (selectedItem == "Camera") {
                        widget.onSendImageByCamera();
                      } else if (selectedItem == "Documents") {
                        widget.onSendDocument();
                      } else if (selectedItem == "Share Product") {
                        widget.onShareProduct();
                      } else if (selectedItem == "Check Orders") {
                        widget.onCheckOrders?.call();
                      }
                    },
                    showFormAndProduct: widget.showFormAndProduct,
                    showCheckOrders: widget.showCheckOrders,
                    showInquiryForm: widget.showInquiryForm,
                  );
                },
              ),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.greyDBDDE1,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      // IconButton(
                      //   icon: const Icon(Icons.emoji_emotions_outlined),
                      //   onPressed: () {},
                      // ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: TextField(
                          controller: widget.controller,
                          decoration: const InputDecoration(
                            hintText: "Type here...",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                          icon: const Icon(Icons.camera_alt),
                          onPressed: widget.onSendImageByCamera),
                      const SizedBox(
                        width: 10,
                      ),
                      if (widget.isRecording)
                        Text(
                          '${widget.recordedSeconds}s',
                          style: TextStyle(color: AppColors.grey474747),
                        ),
                      GestureDetector(
                        onLongPressStart: (_) async {
                          widget.onSendVoice();
                        },
                        onLongPressEnd: (_) async {
                          widget.onSendVoice();
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (widget.isRecording)
                              ScaleTransition(
                                scale: _animation,
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.blue00ABE9
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            Icon(
                              widget.isRecording ? Icons.stop : Icons.mic,
                              size: widget.isRecording ? 30 : 24,
                            ),
                            if (widget.isRecording)
                              Positioned(
                                top: 2,
                                child: Text(
                                  '${widget.recordedSeconds}s',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Send button
              InkWell(
                onTap: widget.onSend,
                child: CustomImage(
                  imagePath: ImageConstants.send,
                  height: 30,
                  width: 30,
                ),
              )
            ],
          ),
        ), // closes inner Container
      ],
    ); // closes outer Column
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
        width: 32,
        height: 32,
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

// Move this list outside the class since it doesn’t depend on state
final List<Map<String, String>> attachmentItems = [
  {"image": ImageConstants.inquiry, "label": "Inquiry Form"},
  {"image": ImageConstants.camera, "label": "Camera"},
  {"image": ImageConstants.photos, "label": "Photos"},
  {"image": ImageConstants.documents, "label": "Documents"},
  {"image": ImageConstants.shareProduct, "label": "Share Product"},
];

final List<Map<String, String>> attachmentItemsforCustomer = [
  {"image": ImageConstants.camera, "label": "Camera"},
  {"image": ImageConstants.photos, "label": "Photos"},
  {"image": ImageConstants.documents, "label": "Documents"},
  {"image": ImageConstants.shareProduct, "label": "Share Product"},
];

final List<Map<String, String>> attachmentItemsforInternalChat = [
  {"image": ImageConstants.camera, "label": "Camera"},
  {"image": ImageConstants.photos, "label": "Photos"},
  {"image": ImageConstants.documents, "label": "Documents"},
];

final String? currentUser = LocalDbHelper.getProfile()?.role;

void showAttachmentMenu(BuildContext context, Function(String) onItemSelected,
    {bool showFormAndProduct = true,
    bool showCheckOrders = false,
    bool showInquiryForm = true}) {
  showModalBottomSheet(
      context: context,
      elevation: 10,
      backgroundColor: Colors.transparent, // Makes the corners visible
      isScrollControlled: true, // Ensures proper spacing
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) {
        // Determine which items to show
        List<Map<String, String>> itemsToShow;
        if (!showFormAndProduct) {
          // For internal chat - only camera, photos, documents
          itemsToShow = attachmentItemsforInternalChat;
        } else if (currentUser == "User") {
          // For customers - camera, photos, documents, share product
          itemsToShow = attachmentItemsforCustomer;
        } else {
          // For agents - all items
          itemsToShow = List<Map<String, String>>.from(attachmentItems);
          if (showCheckOrders) {
            itemsToShow.insert(0,
                {"image": ImageConstants.checkCircle, "label": "Check Orders"});
          }
        }

        if (!showInquiryForm) {
          itemsToShow = itemsToShow
              .where((item) => item['label'] != 'Inquiry Form')
              .toList();
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.0),
          ),
          margin: EdgeInsets.only(
              bottom: Utils().height(context) * 0.1, left: 10, right: 10),
          padding: const EdgeInsets.all(10.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🛑 Fix: Add SizedBox or ConstrainedBox
                SizedBox(
                  height:
                      200, // Adjust height as needed (e.g., 2 rows of GridView)
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 0,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: itemsToShow.length,
                    itemBuilder: (context, index) {
                      final item = itemsToShow[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            onItemSelected(item['label']!);
                          });
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Image.asset(
                                item['image']!,
                                height: 30,
                                width: 30,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item['label']!,
                              style: AppTextStyles.black10_500,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      });
}
