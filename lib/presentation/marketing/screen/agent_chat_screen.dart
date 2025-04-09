import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/image_constants.dart';
import 'package:kkp_chat_app/core/services/s3_upload_service.dart';
import 'package:kkp_chat_app/core/services/socket_service.dart';
import 'package:kkp_chat_app/presentation/common/chat/audio_call_screen.dart';

import 'package:kkp_chat_app/presentation/common/chat/transfer_agent_screen.dart';
import 'package:kkp_chat_app/presentation/common_widgets/chat/chat_input_field.dart';
import 'package:kkp_chat_app/presentation/common_widgets/chat/fill_form_button.dart';
import 'package:kkp_chat_app/presentation/common_widgets/chat/form_message_bubble.dart';
import 'package:kkp_chat_app/presentation/common_widgets/chat/image_message_bubble.dart';
import 'package:kkp_chat_app/presentation/common_widgets/chat/message_bubble.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kkp_chat_app/presentation/common_widgets/chat/no_chat_conversation.dart';

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
    this.customerEmail = "customer@gmail.com",
    this.agentEmail = "agent@gmail.com",
  });

  @override
  State<AgentChatScreen> createState() => _AgentChatScreenState();
}

class _AgentChatScreenState extends State<AgentChatScreen>
    with WidgetsBindingObserver {
  final _chatController = TextEditingController();
  final SocketService _socketService = SocketService();
  final S3UploadService _s3uploadService = S3UploadService();
  final ScrollController _scrollController = ScrollController();
  final qualityController = TextEditingController();
  final quantityController = TextEditingController();
  final weaveController = TextEditingController();
  final compositionController = TextEditingController();
  final rateController = TextEditingController();

  List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _socketService.toggleChatPageOpen(true);
    _socketService.onReceiveMessage(_handleIncomingMessage);
    _socketService.listenForIncomingCall(_handleIncomingCall);
  }

  void _handleIncomingCall(dynamic data) {
    // Data structure from server 'incomingCall' event is expected to be:
    // { 'from': callerId, 'signal': offerMap, 'callerName': callerName }

    // Perform type checking for safety
    if (data is! Map<String, dynamic> ||
        !data.containsKey('from') ||
        !data.containsKey('signal') ||
        data['signal'] is! Map<String, dynamic>) {
      debugPrint("⚠️ Received incoming call signal with invalid format: $data");
      return;
    }

    final String callerId = data['from'];
    // Ensure 'signal' is correctly casted
    final Map<String, dynamic> offer =
        Map<String, dynamic>.from(data['signal']);
    final String callerName = data['callerName']?.toString() ??
        'Unknown Caller'; // Handle potential null callerName

    // Ensure context is still valid before navigating
    if (!mounted) return;

    debugPrint(
        "📞 Handling incoming call in ChatScreen from $callerId. Navigating to AudioCallScreen.");

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AudioCallScreen(
          // In an incoming call:
          selfId: widget.agentEmail!, // Agent's email is selfId here
          targetId: callerId, // The ID of the customer calling
          isCaller: false, // This user (Agent) is the CALLEE
          callerName: callerName, // Display name of the caller (Customer)
          // *** Pass the offer data to the AudioCallScreen constructor ***
          initialOffer: offer,
        ),
      ),
    ).then((_) {
      // Optional: Code to run after the call screen is popped
      debugPrint("Returned from AudioCallScreen");
      // Maybe refresh state if needed
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chatController.dispose();
    _scrollController.dispose();
    qualityController.dispose();
    quantityController.dispose();
    rateController.dispose();
    compositionController.dispose();
    weaveController.dispose();
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
    final currentTime = DateTime.now().toIso8601String();
    setState(() {
      messages.add({
        "text": data["message"],
        "timeStamp": currentTime,
        "isMe": data["senderId"] == widget.agentEmail,
        "type": data["type"] ?? "text", // Default to 'text' if not specified
        "mediaUrl": data["mediaUrl"],
        "form": data["form"],
      });
      _scrollToBottom();
    });
  }

  void _sendMessage({
    required String messageText,
    String? type = 'text',
    String? mediaUrl,
    Map<String, dynamic>? form,
  }) {
    if (messageText.trim().isEmpty && mediaUrl == null && form == null) return;

    final currentTime = DateTime.now().toIso8601String();

    setState(() {
      messages.add({
        "text": messageText,
        "timestamp": currentTime,
        "isMe": true,
        "type": type,
        "mediaUrl": mediaUrl,
        "form": form,
      });
      _scrollToBottom();
    });

    _socketService.sendMessage(
      targetEmail: widget.customerEmail!,
      message: messageText,
      senderEmail: widget.agentEmail!,
      senderName: widget.agentName!,
      type: type!,
      mediaUrl: mediaUrl,
      form: form,
    );

    _chatController.clear();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickAndSendImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Upload the image to AWS S3 and get the image URL
      final File imageFile = File(pickedFile.path);
      final imageUrl = await _s3uploadService.uploadFile(imageFile);
      if (imageUrl != null) {
        _sendMessage(messageText: "image", type: 'media', mediaUrl: imageUrl);
      }
    }
  }

  Future<void> _sendForm() async {
    _sendMessage(messageText: "Fill details");
  }

  String formatTimestamp(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) {
      // Return the current date and time in the desired format
      final currentTime = DateTime.now();
      return DateFormat('hh:mm a').format(currentTime);
    }
    try {
      final dateTime = DateTime.parse(timestamp).toLocal();
      return DateFormat('hh:mm a').format(dateTime);
    } catch (e) {
      // In case of an error, return the current date and time in the desired format
      final currentTime = DateTime.now();
      return DateFormat('hh:mm a').format(currentTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 10,
        shadowColor: AppColors.shadowColor,
        surfaceTintColor: Colors.white10,
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return TransferAgentScreen(
                      customerEmailId: widget.customerEmail!,
                    );
                  },
                ),
              );
            },
            icon: const Icon(Icons.swap_horizontal_circle_outlined,
                color: Colors.black),
          ),
          IconButton(
            onPressed: () {
              // Initiate an audio call
              final String selfEmail = widget.agentEmail!; // Agent is self
              final String targetEmail =
                  widget.customerEmail!; // Customer is target
              final String selfName = widget.agentName!;

              // Ensure target email is valid before navigating
              if (targetEmail.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content:
                        Text("Cannot initiate call: Target user invalid.")));
                return;
              }
              debugPrint("🚀 Initiating call from ChatScreen to $targetEmail.");
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AudioCallScreen(
                    selfId: selfEmail,
                    targetId: targetEmail,
                    isCaller: true, // Agent is the CALLER
                    callerName: selfName, // Agent's name
                    // initialOffer is null/not needed when isCaller is true
                  ),
                ),
              );
            },
            icon: const Icon(Icons.call_outlined, color: Colors.black),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20.0),
            bottomRight: Radius.circular(20.0),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? NoChatConversation()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(10),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      if (msg['type'] == 'media') {
                        return ImageMessageBubble(
                          imageUrl: msg['mediaUrl'],
                          isMe: msg['isMe'],
                          timestamp: formatTimestamp(msg['timestamp']),
                        );
                      } else if (msg['type'] == 'form') {
                        return FormMessageBubble(
                          formData: msg['form'],
                          isMe: msg['isMe'],
                          timestamp: formatTimestamp(msg['timestamp']),
                        );
                      } else if (msg['text'] == 'Fill details') {
                        return FillFormButton(
                          onSubmit: () {
                            //agent not allowedd to fill the form,
                          }, //_showFormOverlay,
                        );
                      }
                      return MessageBubble(
                        text: msg['text'],
                        isMe: msg['isMe'],
                        timestamp: formatTimestamp(msg['timestamp']),
                        image: msg['isMe']
                            ? widget.agentImage!
                            : widget.customerImage!,
                      );
                    },
                  ),
          ),
          ChatInputField(
            controller: _chatController,
            onSend: () => _sendMessage(messageText: _chatController.text),
            onSendImage: _pickAndSendImage,
            onSendForm: _sendForm,
          ),
        ],
      ),
    );
  }
}
