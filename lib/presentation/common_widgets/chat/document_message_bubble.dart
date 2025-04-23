import 'package:flutter/material.dart';
import 'package:kkp_chat_app/presentation/common_widgets/chat/doucment_viewer.dart';

class DocumentMessageBubble extends StatelessWidget {
  final String documentUrl;
  final bool isMe;
  final String timestamp;

  const DocumentMessageBubble({
    super.key,
    required this.documentUrl,
    required this.isMe,
    required this.timestamp,
  });

  void _openDocument(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentViewer(documentUrl: documentUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => _openDocument(context),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isMe ? Colors.blue : Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.description, size: 40),
              const SizedBox(height: 5),
              Text(
                'Document',
                style: TextStyle(
                    fontSize: 16, color: isMe ? Colors.white : Colors.black),
              ),
              const SizedBox(height: 5),
              Text(
                timestamp,
                style: TextStyle(
                    fontSize: 12,
                    color: isMe ? Colors.white70 : Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
