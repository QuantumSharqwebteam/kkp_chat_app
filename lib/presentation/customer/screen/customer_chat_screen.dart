import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';
import 'package:kkp_chat_app/config/theme/image_constants.dart';
import 'package:kkp_chat_app/core/services/s3_upload_service.dart';
import 'package:kkp_chat_app/core/services/socket_service.dart';
import 'package:kkp_chat_app/presentation/common_widgets/chat/fill_form_button.dart';
import 'package:kkp_chat_app/presentation/common_widgets/chat/form_message_bubble.dart';
import 'package:kkp_chat_app/presentation/common_widgets/chat/image_message_bubble.dart';
import 'package:kkp_chat_app/presentation/common_widgets/chat/message_bubble.dart';
import 'package:kkp_chat_app/presentation/common_widgets/chat/chat_input_field.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_button.dart';

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
  final S3UploadService s3UploadService = S3UploadService();
  final S3UploadService _s3uploadService = S3UploadService();
  final ScrollController _scrollController = ScrollController();

  //form controllers
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
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
        "timestamp": currentTime,
        "isMe": data["senderId"] == widget.customerEmail,
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
      targetEmail: widget.agentEmail!,
      message: messageText,
      senderEmail: widget.customerEmail!,
      senderName: widget.customerName!,
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
    // not allowed
    final formData = {
      "quality": "Premium",
      "quantity": "100 meters",
      "weave": "Twill",
      "composition": "Cotton 100%",
      "rate": "15 USD/meter"
    };
    _sendMessage(messageText: "form", type: 'form', form: formData);
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
            child: ListView.builder(
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
                    onSubmit: _showFormOverlay,
                  );
                }
                return MessageBubble(
                  text: msg['text'],
                  isMe: msg['isMe'],
                  timestamp: formatTimestamp(msg['timestamp']),
                  image:
                      msg['isMe'] ? widget.customerImage! : widget.agentImage!,
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

  void _showFormOverlay() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) {
        return Form(
          key: _formKey,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.0),
            ),
            margin: const EdgeInsets.only(bottom: 30, left: 10, right: 10),
            padding: const EdgeInsets.all(10.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                CustomButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Collect form data and send it back
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
}
