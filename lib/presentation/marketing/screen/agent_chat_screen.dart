import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kkp_chat_app/config/theme/image_constants.dart';
import 'package:kkp_chat_app/core/services/socket_service.dart';
import 'package:kkp_chat_app/presentation/common_widgets/chat_input_field.dart';
import 'package:kkp_chat_app/presentation/marketing/widget/message_bubble.dart';

class AgentChatScreen extends StatefulWidget {
  final String? customerName;
  final String? customerImage;
  final String? agentName;
  final String? agentImage;
  final String? customerEmail;
  final String? agentEmail;

  const AgentChatScreen({
    super.key,
    this.customerName = "Varun",
    this.customerImage = ImageConstants.userImage,
    this.agentName = "Shoaib",
    this.agentImage = "assets/images/user4.png",
    this.customerEmail = "prabhujivats@gmail.com",
    this.agentEmail = "mohdshoaibrayeen3@gmail.com",
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
    _socketService.onReceiveMessage(_handleIncomingMessage);
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    setState(() {
      messages.add({
        "text": data["message"],
        "isMe": data["senderId"] == widget.agentEmail,
      });
    });
  }

  void _sendMessage() {
    if (_chatController.text.trim().isEmpty) return;

    final messageText = _chatController.text.trim();
    setState(() {
      messages.add({"text": messageText, "isMe": true});
    });

    _socketService.sendMessage(
      widget.customerEmail!,
      messageText,
      widget.agentEmail!,
      widget.agentName!,
    );

    _chatController.clear();
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
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
            onPressed: () {
              // Initiate a video call
            },
            icon: const Icon(Icons.videocam_outlined, color: Colors.black),
          ),
          IconButton(
            onPressed: () {
              // Initiate an audio call
            },
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
                  //timestamp: formatTimestamp(msg['timestamp']),
                );
              },
            ),
          ),
          ChatInputField(
            controller: _chatController,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}
