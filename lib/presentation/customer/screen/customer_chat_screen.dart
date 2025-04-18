import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';
import 'package:kkp_chat_app/config/theme/image_constants.dart';
import 'package:kkp_chat_app/core/services/chat_storage_service.dart';
import 'package:kkp_chat_app/core/services/s3_upload_service.dart';
import 'package:kkp_chat_app/core/services/socket_service.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';
import 'package:kkp_chat_app/data/models/chat_message_model.dart';

import 'package:kkp_chat_app/presentation/common/chat/agora_audio_call_screen.dart';
import 'package:kkp_chat_app/presentation/common_widgets/chat/fill_form_button.dart';
import 'package:kkp_chat_app/presentation/common_widgets/chat/form_message_bubble.dart';
import 'package:kkp_chat_app/presentation/common_widgets/chat/image_message_bubble.dart';
import 'package:kkp_chat_app/presentation/common_widgets/chat/message_bubble.dart';
import 'package:kkp_chat_app/presentation/common_widgets/chat/chat_input_field.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_button.dart';
import 'package:kkp_chat_app/presentation/common_widgets/chat/no_chat_conversation.dart';

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
    this.agentEmail = "agent@gmail.com",
  });

  @override
  State<CustomerChatScreen> createState() => _CustomerChatScreenState();
}

class _CustomerChatScreenState extends State<CustomerChatScreen>
    with WidgetsBindingObserver {
  final _chatController = TextEditingController();
  final SocketService _socketService = SocketService();
  final S3UploadService _s3uploadService = S3UploadService();
  final ScrollController _scrollController = ScrollController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final qualityController = TextEditingController();
  final quantityController = TextEditingController();
  final weaveController = TextEditingController();
  final compositionController = TextEditingController();
  final rateController = TextEditingController();
  // final _chatRepository = ChatRepository();
  final ChatStorageService _chatStorageService =
      ChatStorageService(); // Initialize the service

  List<ChatMessageModel> messages = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _socketService.toggleChatPageOpen(true);
    _socketService.onReceiveMessage(_handleIncomingMessage);
    _loadMessages();
    // _socketService.onIncomingCall(_handleIncomingCall);
    _socketService.onIncomingCall((callData) {
      final channelName = callData['channelName'];
      //  final token = callData['token'];
      final callerName = callData['callerName'];
      final callerId = callData['callerId'];
      final uid = Utils().generateIntUidFromEmail(widget.customerEmail!);

      showModalBottomSheet(
        context: context,
        isDismissible: false,
        enableDrag: false,
        builder: (context) {
          return Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$callerName is calling...',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.call_end, color: Colors.white),
                      label: const Text("Reject"),
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () {
                        Navigator.pop(context); // close bottom sheet
                        // Optionally emit reject event over socket
                      },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.call, color: Colors.white),
                      label: const Text("Answer"),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                      onPressed: () {
                        Navigator.pop(context); // close bottom sheet

                        // Navigate to the audio call screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AgoraAudioCallScreen(
                              isCaller: false,
                              // token: token,
                              channelName: channelName,
                              uid: uid,
                              remoteUserId: callerId,
                              remoteUserName: callerName,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chatController.dispose();
    _scrollController.dispose();
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

  Future<void> _loadMessages() async {
    final loadedMessages =
        await _chatStorageService.getMessages(widget.customerEmail!);
    setState(() {
      messages = loadedMessages;
      _scrollToBottom();
    });
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    final currentTime = DateTime.now().toIso8601String();
    final message = ChatMessageModel(
      message: data["message"],
      timestamp: DateTime.parse(currentTime),
      sender: data["senderId"],
      type: data["type"] ?? "text",
      mediaUrl: data["mediaUrl"],
      form: data["form"],
    );
    setState(() {
      messages.add(message);
      _scrollToBottom();
    });
    _chatStorageService.saveMessage(
        message, widget.customerEmail!); // Save to Hive
  }

  // void _handleIncomingCall(Map<String, dynamic> data) {
  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       return AlertDialog(
  //         title: Text('Incoming Call'),
  //         content: Text('Incoming call from ${data['name']}'),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.pop(context);
  //             },
  //             child: Text('Reject'),
  //           ),
  //           TextButton(
  //             onPressed: () {
  //               Navigator.pop(context);
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(
  //                   builder: (context) => AudioCallScreen(
  //                     args: AudioCallScreenArgs(
  //                       callDirection: CallDirection.receivingCall,
  //                       remoteUserFullName: data['name'],
  //                       remoteUserId: data['from'],
  //                       senderEmail: "",
  //                       senderName: "",
  //                       signalData: data["signal"],
  //                     ),
  //                   ),
  //                 ),
  //               );
  //             },
  //             child: Text('Answer'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  void _sendMessage({
    required String messageText,
    String? type = 'text',
    String? mediaUrl,
    Map<String, dynamic>? form,
  }) {
    if (messageText.trim().isEmpty && mediaUrl == null && form == null) return;

    final currentTime = DateTime.now().toIso8601String();
    final message = ChatMessageModel(
      message: messageText,
      timestamp: DateTime.parse(currentTime),
      sender: widget.customerEmail!,
      type: type!,
      mediaUrl: mediaUrl,
      form: form,
    );
    setState(() {
      messages.add(message);
      _scrollToBottom();
    });

    _socketService.sendMessage(
      message: messageText,
      senderEmail: widget.customerEmail!,
      senderName: widget.customerName!,
      type: type,
      mediaUrl: mediaUrl,
      form: form,
    );

    _chatStorageService.saveMessage(
        message, widget.customerEmail!); // Save to Hive
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
      final File imageFile = File(pickedFile.path);
      final imageUrl = await _s3uploadService.uploadFile(imageFile);
      if (imageUrl != null) {
        _sendMessage(messageText: "image", type: 'media', mediaUrl: imageUrl);
      }
    }
  }

  void _showFormOverlay() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Form(
          key: _formKey,
          child: Container(
            padding: EdgeInsets.all(16.0),
            height: Utils().height(context) * 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Pls Form details ", style: AppTextStyles.black16_600),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: InputDecoration(labelText: "Quality"),
                  controller: qualityController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter quality';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: "Quantity"),
                  controller: quantityController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter quantity';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: "Weave"),
                  controller: weaveController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter weave';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: "Composition"),
                  controller: compositionController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter composition';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: "Rate"),
                  controller: rateController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter rate';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final formData = {
                        "quality": qualityController.text,
                        "quantity": quantityController.text,
                        "weave": weaveController.text,
                        "composition": compositionController.text,
                        "rate": rateController.text,
                      };
                      _sendMessage(
                          messageText: "product", type: 'form', form: formData);
                      Navigator.pop(context);
                    }
                  },
                  textColor: Colors.white,
                  fontSize: 14,
                  backgroundColor: AppColors.blue,
                  text: "Submit",
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String formatTimestamp(dynamic timestamp) {
    if (timestamp == null) {
      return DateFormat('hh:mm a').format(DateTime.now());
    }

    try {
      final dateTime = timestamp is DateTime
          ? timestamp.toLocal()
          : DateTime.parse(timestamp.toString()).toLocal();
      return DateFormat('hh:mm a').format(dateTime);
    } catch (e) {
      return DateFormat('hh:mm a').format(DateTime.now());
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
            onPressed: () async {
              final channelName = "customerCall123";
              final uid =
                  Utils().generateIntUidFromEmail(widget.customerEmail!);
              debugPrint("Generated UID for agent (caller): $uid");
              // Send call data over socket to notify customer
              _socketService.sendAgoraCall(
                //  targetId: "mohdshoaibrayeen3@gmail.com",
                channelName: channelName,
                //token: token,
                callerId: widget.customerEmail!,
                callerName: widget.customerName!,
              );

              // Navigate agent to call screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AgoraAudioCallScreen(
                    isCaller: true,
                    //  token: token,
                    channelName: channelName,
                    uid: uid,
                    remoteUserId: widget.agentEmail!,
                    remoteUserName: widget.agentName!,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.call_outlined, color: Colors.black),
          ),
        ],
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
                      if (msg.type == 'media') {
                        return ImageMessageBubble(
                          imageUrl: msg.mediaUrl!,
                          isMe: msg.sender == widget.customerEmail,
                          timestamp: formatTimestamp(msg.timestamp),
                        );
                      } else if (msg.type == 'form') {
                        return FormMessageBubble(
                          formData: msg.form!,
                          isMe: msg.sender == widget.customerEmail,
                          timestamp: formatTimestamp(msg.timestamp),
                        );
                      } else if (msg.message == 'Fill details') {
                        return FillFormButton(
                          onSubmit: _showFormOverlay,
                        );
                      }
                      return MessageBubble(
                        text: msg.message,
                        isMe: msg.sender == widget.customerEmail,
                        timestamp: formatTimestamp(msg.timestamp),
                        image: msg.sender == widget.customerEmail
                            ? widget.customerImage!
                            : widget.agentImage!,
                      );
                    },
                  ),
          ),
          ChatInputField(
            controller: _chatController,
            onSend: () => _sendMessage(messageText: _chatController.text),
            onSendImage: _pickAndSendImage,
            onSendForm: _showFormOverlay,
          ),
        ],
      ),
    );
  }
}
