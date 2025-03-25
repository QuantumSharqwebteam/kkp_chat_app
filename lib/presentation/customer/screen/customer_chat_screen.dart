import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';
import 'package:kkp_chat_app/config/theme/image_constants.dart';
import 'package:kkp_chat_app/core/services/socket_service.dart';
import 'package:kkp_chat_app/presentation/marketing/widget/message_bubble.dart';
import 'package:kkp_chat_app/presentation/common_widgets/chat_input_field.dart';

class CustomerChatScreen extends StatefulWidget {
  final String? customerName;
  final String? customerImage;
  final String? agentName;
  final String? agentImage;
  final String? customerEmail;
  final String? agentEmail;

  const CustomerChatScreen({
    super.key,
    this.customerName = "Varun",
    this.customerImage = ImageConstants.userImage,
    this.agentName = "Agent",
    this.agentImage = "assets/images/user4.png",
    this.customerEmail = "prabhujivats@gmail.com",
    this.agentEmail = "rayeenshoaib20786@gmail.com",
  });

  @override
  State<CustomerChatScreen> createState() => _CustomerChatScreenState();
}

class _CustomerChatScreenState extends State<CustomerChatScreen>
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
        "timestamp": data["timestamp"], //added time Stamp code
        "isMe": data["senderId"] == widget.customerEmail,
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
        "timestamp": currentTime, // Store local timestamp
        "isMe": true,
      });
    });

    _socketService.sendMessage(
      widget.agentEmail!,
      messageText,
      widget.customerEmail!,
      widget.customerName!,
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
              style: AppTextStyles.black14_400,
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              _socketService.initiateCall(
                widget.agentEmail!,
                {},
                widget.customerEmail!,
                widget.customerName!,
              );
            },
            icon: Icon(Icons.videocam_outlined, color: Colors.black),
          ),
          IconButton(
            onPressed: () {
              _socketService.initiateCall(
                widget.agentEmail!,
                {},
                widget.customerEmail!,
                widget.customerName!,
              );
            },
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
                  timestamp: formatTimestamp(msg["timestamp"]),
                  image:
                      msg['isMe'] ? widget.customerImage! : widget.agentImage!,
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
