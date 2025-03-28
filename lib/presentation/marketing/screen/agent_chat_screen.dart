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
    this.customerName = "Customer 2",
    this.customerImage = ImageConstants.userImage,
    this.agentName = "Agent N/A",
    this.agentImage = "assets/images/user4.png",
    this.customerEmail = "prabhujivats@gmail.com",
    this.agentEmail = "rayeenshoaib20786@gmail.com",
  });

  @override
  State<AgentChatScreen> createState() => _AgentChatScreenState();
}

class _AgentChatScreenState extends State<AgentChatScreen>
    with WidgetsBindingObserver {
  final _chatController = TextEditingController();
  final SocketService _socketService = SocketService();

  List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _socketService.toggleChatPageOpen(true);
    _socketService.onReceiveMessage(_handleIncomingMessage);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chatController.dispose();
    _socketService.toggleChatPageOpen(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _socketService.toggleChatPageOpen(false);
    } else if (state == AppLifecycleState.resumed) {
      _socketService.toggleChatPageOpen(true);
    }
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    setState(() {
      messages.add({
        "text": data["message"],
        "timeStamp": data["timestamp"],
        "isMe": data["senderId"] == widget.agentEmail,
      });
    });
  }

  void _sendMessage() {
    if (_chatController.text.trim().isEmpty) return;

    final messageText = _chatController.text.trim();
    final currentTime = DateTime.now().toIso8601String();
    setState(() {
      messages.add({
        "text": messageText,
        "timestamp": currentTime,
        "isMe": true,
      });
    });

    _socketService.sendMessage(
      widget.customerEmail!,
      messageText,
      widget.agentEmail!,
      widget.agentName!,
    );

    _chatController.clear();
  }

  String formatTimestamp(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return "";
    try {
      final dateTime = DateTime.parse(timestamp).toLocal();
      return DateFormat('hh:mm a').format(dateTime);
    } catch (e) {
      return "";
    }
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
              // transfer chat
            },
            icon: const Icon(Icons.swap_horizontal_circle_outlined,
                color: Colors.black),
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
                  // timestamp: formatTimestamp(msg['timestamp'] ?? ""),
                  image:
                      msg['isMe'] ? widget.agentImage! : widget.customerImage!,
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
