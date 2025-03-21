import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';
import 'package:kkp_chat_app/config/theme/image_constants.dart';
import 'package:kkp_chat_app/core/services/socket_service.dart';
import 'package:kkp_chat_app/presentation/common_widgets/chat_input_field.dart';
import 'package:kkp_chat_app/presentation/marketing/widget/message_bubble.dart';
import 'package:intl/intl.dart';

class AgentChatScreen extends StatefulWidget {
  final String? customerName;
  final String? customerImage;
  final String? agentName;
  final String? agentImage;

  const AgentChatScreen({
    super.key,
    this.customerName = "User",
    this.customerImage = ImageConstants.userImage,
    this.agentName = "Agent",
    this.agentImage = "assets/images/user4.png",
  });

  @override
  State<AgentChatScreen> createState() => _AgentChatScreenState();
}

class _AgentChatScreenState extends State<AgentChatScreen> {
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
          "isMe": data['senderId'] == _socketService.socketId,
          "timestamp":
              data['timestamp'] ?? DateTime.now().toUtc().toIso8601String(),
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
      final timestamp =
          DateTime.now().toUtc().toIso8601String(); // Generate timestamp

      setState(() {
        messages.add({
          "text": messageText,
          "isMe": true,
          "timestamp": timestamp, // Store locally
        });
      });

      _socketService.sendMessage(
        "ZR19xF3ymk2eburiAAAB",
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.videocam_outlined, color: Colors.black),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.call_outlined, color: Colors.black),
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
          ChatInputField(
            controller: _chatController,
            onSend: sendMessage,
          ),
        ],
      ),
    );
  }
}
