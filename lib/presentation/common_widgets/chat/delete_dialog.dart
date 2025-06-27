import 'package:flutter/material.dart';

// Define a separate DeleteDialog widget
class DeleteDialog extends StatelessWidget {
  final String messageId;
  final Function(String) onDelete;

  const DeleteDialog({
    super.key,
    required this.messageId,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Unsend Message"),
      content: const Text("Are you sure you want to unsend this message?"),
      actions: <Widget>[
        TextButton(
          child: const Text("Cancel"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text("Unsend Message"),
          onPressed: () {
            Navigator.of(context).pop();
            onDelete(messageId);
          },
        ),
      ],
    );
  }
}
