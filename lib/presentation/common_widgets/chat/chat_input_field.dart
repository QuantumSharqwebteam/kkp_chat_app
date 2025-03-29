import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';
import 'package:kkp_chat_app/config/theme/image_constants.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_image.dart';

class ChatInputField extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onSendImage;
  final VoidCallback onSendForm;

  const ChatInputField({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onSendImage,
    required this.onSendForm,
  });

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attachment),
            onPressed: () {
              showAttachmentMenu(context, (selectedItem) {
                if (selectedItem == "Photos") {
                  widget.onSendImage();
                } else if (selectedItem == "Inquiry Form") {
                  widget.onSendForm();
                }
              });
            },
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.greyDBDDE1,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.emoji_emotions_outlined),
                    onPressed: () {},
                  ),
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
                    onPressed: widget.onSendImage,
                  ),
                  IconButton(
                    icon: const Icon(Icons.mic),
                    onPressed: () {},
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
    );
  }
}

// Move this list outside the class since it doesn’t depend on state
final List<Map<String, String>> attachmentItems = [
  {"image": ImageConstants.inquiry, "label": "Inquiry Form"},
  {"image": ImageConstants.rate, "label": "Rate"},
  {"image": ImageConstants.orderConfimm, "label": "Order Confirm"},
  {"image": ImageConstants.orderDecline, "label": "Order Decline"},
  {"image": ImageConstants.camera, "label": "Camera"},
  {"image": ImageConstants.photos, "label": "Photos"},
  {"image": ImageConstants.documents, "label": "Documents"},
  {"image": ImageConstants.video, "label": "Videos"},
];

void showAttachmentMenu(BuildContext context, Function(String) onItemSelected) {
  showModalBottomSheet(
    context: context,
    elevation: 10,
    backgroundColor: Colors.transparent, // Makes the corners visible
    isScrollControlled: true, // Ensures proper spacing
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
    ),
    builder: (context) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.0),
        ),
        margin: const EdgeInsets.only(bottom: 30, left: 10, right: 10),
        padding:
            const EdgeInsets.all(10.0), // Adds padding inside the bottom sheet
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, // 4 items per row
                crossAxisSpacing: 2,
                mainAxisSpacing: 0,
                childAspectRatio: 0.9, // Keeps square shape
              ),
              itemCount: attachmentItems.length,
              itemBuilder: (context, index) {
                final item = attachmentItems[index];
                return GestureDetector(
                  onTap: () {
                    onItemSelected(item['label']!);
                    Navigator.pop(context);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
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
          ],
        ),
      );
    },
  );
}
