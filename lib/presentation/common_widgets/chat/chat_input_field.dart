import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/config/theme/image_constants.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_image.dart';

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
    required this.onSendImageByCamera, // Add this line
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
                } else if (selectedItem == "Camera") {
                  widget.onSendImageByCamera();
                } else if (selectedItem == "Documents") {
                  widget.onSendDocument();
                }
              });
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
                                color:
                                    AppColors.blue00ABE9.withValues(alpha: 0.5),
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
    );
  }
}

// Move this list outside the class since it doesn’t depend on state
final List<Map<String, String>> attachmentItems = [
  {"image": ImageConstants.inquiry, "label": "Inquiry Form"},
  {"image": ImageConstants.camera, "label": "Camera"},
  {"image": ImageConstants.photos, "label": "Photos"},
  {"image": ImageConstants.documents, "label": "Documents"},
];

final List<Map<String, String>> attachmentItemsforCustomer = [
  {"image": ImageConstants.camera, "label": "Camera"},
  {"image": ImageConstants.photos, "label": "Photos"},
  {"image": ImageConstants.documents, "label": "Documents"},
];

final String? currentUser = LocalDbHelper.getProfile()?.role;

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
              itemCount: currentUser == "User"
                  ? attachmentItemsforCustomer.length
                  : attachmentItems.length,
              itemBuilder: (context, index) {
                final item = currentUser == "User"
                    ? attachmentItemsforCustomer[index]
                    : attachmentItems[index];
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
