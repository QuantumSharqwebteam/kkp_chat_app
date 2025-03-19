import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';
import 'package:kkp_chat_app/core/services/socket_service.dart';

class CustomerChatScreen extends StatefulWidget {
  const CustomerChatScreen({super.key});

  @override
  State<CustomerChatScreen> createState() => _CustomerChatScreenState();
}

class _CustomerChatScreenState extends State<CustomerChatScreen> {
  final SocketService _socketService = SocketService();
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> messages = [];
  late String customerSocketId; // Store the customer's socket ID

  @override
  void initState() {
    super.initState();
    _socketService.connect();

    // Set the customer's socket ID after connecting
    _socketService.socket?.on('1234567890', (data) {
      setState(() {
        customerSocketId = data;
      });
    });

    _socketService.onReceiveMessage = (data) {
      setState(() {
        messages.add({
          'message': data['message'],
          'senderName': data['senderName'],
          'isReceived': true,
        });
      });
    };
  }

  @override
  void dispose() {
    _socketService.disconnect();
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    String message = _messageController.text.trim();
    if (message.isNotEmpty) {
      String senderName = 'Customer'; // Replace with actual sender name
      _socketService.sendMessage('agentSocketId', message, senderName);

      setState(() {
        messages.add({
          'message': message,
          'senderName': senderName,
          'isReceived': false,
        });
        _messageController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Customer Support Chat', style: AppTextStyles.black18_600),
        backgroundColor: AppColors.background,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                Map<String, dynamic> message = messages[index];
                return _buildMessage(message);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    bool isReceived = message['isReceived'];
    return Align(
      alignment: isReceived ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isReceived ? Colors.grey[200] : AppColors.bluePrimary,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          message['message'],
          style: TextStyle(
            color: isReceived ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }
}
