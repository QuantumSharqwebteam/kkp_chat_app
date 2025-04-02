import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/image_constants.dart';
import 'package:kkp_chat_app/core/services/s3_upload_service.dart';
import 'package:kkp_chat_app/core/services/socket_service.dart';
import 'package:kkp_chat_app/presentation/common_widgets/chat/chat_input_field.dart';
import 'package:kkp_chat_app/presentation/common_widgets/chat/fill_form_button.dart';
import 'package:kkp_chat_app/presentation/common_widgets/chat/form_message_bubble.dart';
import 'package:kkp_chat_app/presentation/common_widgets/chat/image_message_bubble.dart';
import 'package:kkp_chat_app/presentation/common_widgets/chat/message_bubble.dart';
import 'package:image_picker/image_picker.dart';

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
  final S3UploadService _s3uploadService = S3UploadService();
  final ScrollController _scrollController = ScrollController();
  // final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
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
        "text": messageText, // Set message as mediaUrl if it's a media type
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
      message: messageText, // Send media URL as message if type is 'media'
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
                    onSubmit: () {
                      //agent not allowedd to fill the form,
                    }, //_showFormOverlay,
                  );
                }
                return MessageBubble(
                  text: msg['text'],
                  isMe: msg['isMe'],
                  timestamp: formatTimestamp(msg['timestamp']),
                  image:
                      msg['isMe'] ? widget.agentImage! : widget.customerImage!,
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

  // void _showFormOverlay() {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     elevation: 10,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
  //     ),
  //     builder: (context) {
  //       return Form(
  //         key: _formKey,
  //         child: Container(
  //           decoration: BoxDecoration(
  //             color: Colors.white,
  //             borderRadius: BorderRadius.circular(20.0),
  //           ),
  //           margin: const EdgeInsets.only(bottom: 30, left: 10, right: 10),
  //           padding: const EdgeInsets.all(10.0),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               TextFormField(
  //                 decoration: InputDecoration(labelText: "Quality"),
  //                 controller: qualityController,
  //                 validator: (value) {
  //                   if (value == null || value.isEmpty) {
  //                     return 'Please enter quality';
  //                   }
  //                   return null;
  //                 },
  //               ),
  //               TextFormField(
  //                 decoration: InputDecoration(labelText: "Quantity"),
  //                 controller: quantityController,
  //                 validator: (value) {
  //                   if (value == null || value.isEmpty) {
  //                     return 'Please enter quantity';
  //                   }
  //                   return null;
  //                 },
  //               ),
  //               TextFormField(
  //                 decoration: InputDecoration(labelText: "Weave"),
  //                 controller: weaveController,
  //                 validator: (value) {
  //                   if (value == null || value.isEmpty) {
  //                     return 'Please enter weave';
  //                   }
  //                   return null;
  //                 },
  //               ),
  //               TextFormField(
  //                 decoration: InputDecoration(labelText: "Composition"),
  //                 controller: compositionController,
  //                 validator: (value) {
  //                   if (value == null || value.isEmpty) {
  //                     return 'Please enter composition';
  //                   }
  //                   return null;
  //                 },
  //               ),
  //               TextFormField(
  //                 decoration: InputDecoration(labelText: "Rate"),
  //                 controller: rateController,
  //                 validator: (value) {
  //                   if (value == null || value.isEmpty) {
  //                     return 'Please enter rate';
  //                   }
  //                   return null;
  //                 },
  //               ),
  //               const SizedBox(height: 10),
  //               CustomButton(
  //                 onPressed: () {
  //                   if (_formKey.currentState!.validate()) {
  //                     // Collect form data and send it back
  //                     final formData = {
  //                       "quality": qualityController.text,
  //                       "quantity": quantityController.text,
  //                       "weave": weaveController.text,
  //                       "composition": compositionController.text,
  //                       "rate": rateController.text,
  //                     };
  //                     _sendMessage(
  //                         messageText: "product", type: 'form', form: formData);
  //                     Navigator.pop(context);
  //                   }
  //                 },
  //                 textColor: Colors.white,
  //                 fontSize: 14,
  //                 backgroundColor: AppColors.blue,
  //                 text: "Submit",
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }
}
