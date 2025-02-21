import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';

class ChatInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const ChatInputField({
    super.key,
    required this.controller,
    required this.onSend,
  });

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
                if (kDebugMode) {
                  print("Selected: $selectedItem");
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
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: "Type here...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.mic),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            onPressed: onSend,
          ),
        ],
      ),
    );
  }

  void showAttachmentMenu(
      BuildContext context, Function(String) onItemSelected) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAttachmentItem(
                  Icons.image, "Photos", onItemSelected, context),
              _buildAttachmentItem(
                  Icons.camera_alt, "Camera", onItemSelected, context),
              _buildAttachmentItem(Icons.insert_drive_file, "Documents",
                  onItemSelected, context),
              _buildAttachmentItem(
                  Icons.videocam, "Videos", onItemSelected, context),
              _buildAttachmentItem(
                  Icons.contacts, "Contacts", onItemSelected, context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachmentItem(
    IconData icon,
    String label,
    Function(String) onItemSelected,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () {
        onItemSelected(label); // First, call the function
        Navigator.pop(context); // Then, close the modal bottom sheet
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey[200],
            child: Icon(icon, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
