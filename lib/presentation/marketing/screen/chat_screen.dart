import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';
import 'package:kkp_chat_app/presentation/common_widgets/chat_input_field.dart';
import 'package:kkp_chat_app/presentation/marketing/widget/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String customerName;
  final String customerImage;
  final String agentName;
  final String agentImage;

  const ChatScreen({
    super.key,
    required this.customerName,
    required this.customerImage,
    required this.agentName,
    required this.agentImage,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatController = TextEditingController();

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> messages = [
    {"text": "Hi, sir", "isMe": false},
    {
      "text":
          "I am Shyam Mohan Jain and I want to buy 100 cotton tshirts and shirts.",
      "isMe": false
    },
    {
      "text": "Can you describe the price and availability of stocks or not.",
      "isMe": false
    },
    {"text": "Hello, Sir", "isMe": true},
    {
      "text":
          "Yes sir, it is available in stock and I give you the best price.",
      "isMe": true
    },
    {"text": "Hi, sir", "isMe": false},
    {
      "text":
          "I am Shyam Mohan Jain and I want to buy 100 cotton tshirts and shirts.",
      "isMe": false
    },
    {
      "text": "Can you describe the price and availability of stocks or not.",
      "isMe": false
    },
    {"text": "Hello, Sir", "isMe": true},
    {
      "text":
          "Yes sir, it is available in stock and I give you the best price.",
      "isMe": true
    },
    {"text": "Hi, sir", "isMe": false},
    {
      "text":
          "I am Shyam Mohan Jain and I want to buy 100 cotton tshirts and shirts.",
      "isMe": false
    },
    {
      "text": "Can you describe the price and availability of stocks or not.",
      "isMe": false
    },
    {"text": "Hello, Sir", "isMe": true},
    {
      "text":
          "Yes sir, it is available in stock and I give you the best price.",
      "isMe": true
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage(widget.agentImage),
            ),
            const SizedBox(width: 5),
            Text(widget.agentName, style: AppTextStyles.black14_600),
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
                  image: msg['isMe'] ? widget.agentImage : widget.customerImage,
                );
              },
            ),
          ),
          ChatInputField(
            controller: _chatController,
            onSend: () {},
          ),
        ],
      ),
    );
  }
}
