import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';
import 'package:kkp_chat_app/config/theme/image_constants.dart';
import 'package:kkp_chat_app/core/services/socket_service.dart';
import 'package:kkp_chat_app/presentation/marketing/widget/message_bubble.dart';

class CustomerChatScreen extends StatefulWidget {
  final String? customerName;
  final String? customerImage;
  final String? agentName;
  final String? agentImage;

  const CustomerChatScreen({
    super.key,
    this.customerName = "User",
    this.customerImage = ImageConstants.userImage,
    this.agentName = "Agent",
    this.agentImage = "assets/images/user4.png",
  });

  @override
  State<CustomerChatScreen> createState() => _CustomerChatScreenState();
}

class _CustomerChatScreenState extends State<CustomerChatScreen> {
  final _chatController = TextEditingController();
  final SocketService _socketService = SocketService();

  List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();

    // Listen for new messages
    _socketService.onReceiveMessage = (data) {
      setState(() {
        messages.add({
          "text": data['message'],
          "isMe": data['senderId'] == _socketService.socketId
        });
      });
    };
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  void sendMessage() {
    if (_chatController.text.isNotEmpty) {
      final messageText = _chatController.text.trim();
      final timestamp = DateTime.now().toUtc().toIso8601String();
      setState(() {
        messages.add({"text": messageText, "isMe": true});
      });

      _socketService.sendMessage(
        "0VhypeA6SrUBrEjbAAAE",
        messageText,
        widget.agentName!,
        timestamp, // Send timestamp
      );
      _chatController.clear();
    }
  }

  String formatTimestamp(String timestamp) {
    final dateTime = DateTime.parse(timestamp).toLocal();
    return DateFormat('hh:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(backgroundImage: AssetImage(widget.agentImage!)),
            const SizedBox(width: 5),
            Text(
              widget.agentName!,
              style: AppTextStyles.black14_400,
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.videocam_outlined, color: Colors.black),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.call_outlined, color: Colors.black),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return MessageBubble(
                  text: msg['text'],
                  isMe: msg['isMe'],
                  image:
                      msg['isMe'] ? widget.agentImage! : widget.customerImage!,
                  timestamp: formatTimestamp(msg['timestamp']),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    decoration: InputDecoration(hintText: "Type a message..."),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blue),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
