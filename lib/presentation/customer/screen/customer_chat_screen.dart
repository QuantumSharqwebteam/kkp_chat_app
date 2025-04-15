import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';
import 'package:kkp_chat_app/config/theme/image_constants.dart';
import 'package:kkp_chat_app/core/services/s3_upload_service.dart';
import 'package:kkp_chat_app/core/services/socket_service.dart';
import 'package:kkp_chat_app/presentation/common_widgets/chat/chat_input_field.dart';
import 'package:kkp_chat_app/presentation/common_widgets/chat/fill_form_button.dart';
import 'package:kkp_chat_app/presentation/common_widgets/chat/form_message_bubble.dart';
import 'package:kkp_chat_app/presentation/common_widgets/chat/image_message_bubble.dart';
import 'package:kkp_chat_app/presentation/common_widgets/chat/message_bubble.dart';
import 'package:kkp_chat_app/presentation/common_widgets/chat/no_chat_conversation.dart';
import 'package:permission_handler/permission_handler.dart';

class CustomerChatScreen extends StatefulWidget {
  final String? customerName;
  final String? customerImage;
  final String? agentName;
  final String? agentImage;
  final String? customerEmail;
  final String? agentEmail;

  const CustomerChatScreen({
    super.key,
    this.customerName = 'Varun',
    this.customerImage = ImageConstants.userImage,
    this.agentName = 'Agent',
    this.agentImage = 'assets/images/user4.png',
    this.customerEmail = 'prabhujivats@gmail.com',
    this.agentEmail = 'rayeenshoaib20786@gmail.com',
  });

  @override
  CustomerChatScreenState createState() => CustomerChatScreenState();
}

class CustomerChatScreenState extends State<CustomerChatScreen>
    with WidgetsBindingObserver {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final S3UploadService _s3uploadService = S3UploadService();
  final SocketService _callService = SocketService();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController qualityController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController weaveController = TextEditingController();
  final TextEditingController compositionController = TextEditingController();
  final TextEditingController rateController = TextEditingController();

  List<Map<String, dynamic>> messages = [];
  bool _isCallInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _callService.init(
      widget.customerName!,
      widget.customerEmail!,
      'customer',
    );
    _callService.toggleChatPageOpen(true);

    _callService.onReceiveMessage(_handleIncomingMessage);
    _callService.onIncomingCall(_handleIncomingCall);
    _callService.onCallAnswered(_handleCallAnswered);
    _callService.onCallTerminated(_handleCallTerminated);
    _callService.onSignalCandidate((_) {});
  }

  void _handleCallAnswered(Map<String, dynamic> data) {
    setState(() {
      _isCallInProgress = true;
    });
    _showCallOverlay();
  }

  void _handleCallTerminated(Map<String, dynamic> data) {
    setState(() {
      _isCallInProgress = false;
    });
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chatController.dispose();
    _scrollController.dispose();
    _callService.toggleChatPageOpen(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _callService.toggleChatPageOpen(state == AppLifecycleState.resumed);
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    setState(() {
      messages.add({
        'text': data['message'],
        'timestamp': DateTime.now().toIso8601String(),
        'isMe': data['senderId'] == widget.customerEmail,
        'type': data['type'] ?? 'text',
        'mediaUrl': data['mediaUrl'],
        'form': data['form'],
      });
      _scrollToBottom();
    });
  }

  void _handleIncomingCall(Map<String, dynamic> data) async {
    if (await _requestCallPermissions()) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Incoming Call'),
            content: Text('Call from ${data['name']}'),
            actions: [
              TextButton(
                onPressed: () {
                  _callService.handleOffer(data);
                  Navigator.pop(context);
                },
                child: Text('Answer'),
              ),
              TextButton(
                onPressed: () {
                  _callService.hangUp();
                  Navigator.pop(context);
                },
                child: Text('Reject'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<bool> _requestCallPermissions() async {
    bool microphoneGranted = await Permission.microphone.isGranted;

    if (!microphoneGranted) {
      microphoneGranted = await Permission.microphone.request().isGranted;

      if (!microphoneGranted) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text('Permission Required'),
              content:
                  Text('Microphone permission is required for audio calls.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK'),
                ),
              ],
            ),
          );
        }
        return false;
      }
    }

    return true;
  }

  void _showCallOverlay() {
    if (!_isCallInProgress) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text('Call in Progress'),
        content: Text('Tap "End Call" to hang up.'),
        actions: [
          TextButton(
            onPressed: () {
              _callService.hangUp();
              setState(() {
                _isCallInProgress = false;
              });
              Navigator.pop(context);
            },
            child: Text('End Call'),
          ),
          TextButton(
            onPressed: _toggleSpeakerphone,
            child: Text('Speaker'),
          ),
        ],
      ),
    );
  }

  void _toggleSpeakerphone() {
    // Implement speakerphone toggle logic here
  }

  void _sendMessage({
    required String messageText,
    String type = 'text',
    String? mediaUrl,
    Map<String, dynamic>? form,
  }) {
    if (messageText.trim().isEmpty && mediaUrl == null && form == null) return;

    setState(() {
      messages.add({
        'text': messageText,
        'timestamp': DateTime.now().toIso8601String(),
        'isMe': true,
        'type': type,
        'mediaUrl': mediaUrl,
        'form': form,
      });
      _scrollToBottom();
    });

    _callService.sendMessage(
      senderEmail: widget.customerEmail!,
      senderName: widget.customerName!,
      message: messageText,
      type: type,
      mediaUrl: mediaUrl,
      form: form,
    );

    _chatController.clear();
  }

  Future<void> _pickAndSendImage() async {
    final XFile? picked =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final File file = File(picked.path);
      final String? url = await _s3uploadService.uploadFile(file);
      if (url != null) {
        _sendMessage(messageText: 'image', type: 'media', mediaUrl: url);
      }
    }
  }

  void _showFormOverlay() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: qualityController,
                decoration: InputDecoration(labelText: 'Quality'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: quantityController,
                decoration: InputDecoration(labelText: 'Quantity'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: weaveController,
                decoration: InputDecoration(labelText: 'Weave'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: compositionController,
                decoration: InputDecoration(labelText: 'Composition'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: rateController,
                decoration: InputDecoration(labelText: 'Rate'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final formData = {
                      'quality': qualityController.text,
                      'quantity': quantityController.text,
                      'weave': weaveController.text,
                      'composition': compositionController.text,
                      'rate': rateController.text,
                    };
                    _sendMessage(
                        messageText: 'product', type: 'form', form: formData);
                    Navigator.pop(context);
                  }
                },
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(String? ts) {
    if (ts == null || ts.isEmpty) {
      return DateFormat('hh:mm a').format(DateTime.now());
    }
    final dt = DateTime.parse(ts).toLocal();
    return DateFormat('hh:mm a').format(dt);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(backgroundImage: AssetImage(widget.agentImage!)),
            SizedBox(width: 8),
            Text(widget.agentName!, style: AppTextStyles.black14_400),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? NoChatConversation()
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(10),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      if (msg['type'] == 'media') {
                        return ImageMessageBubble(
                          imageUrl: msg['mediaUrl'],
                          isMe: msg['isMe'],
                          timestamp: _formatTimestamp(msg['timestamp']),
                        );
                      } else if (msg['type'] == 'form') {
                        return FormMessageBubble(
                          formData: msg['form'],
                          isMe: msg['isMe'],
                          timestamp: _formatTimestamp(msg['timestamp']),
                        );
                      } else if (msg['text'] == 'Fill details') {
                        return FillFormButton(onSubmit: _showFormOverlay);
                      }
                      return MessageBubble(
                        text: msg['text'],
                        isMe: msg['isMe'],
                        timestamp: _formatTimestamp(msg['timestamp']),
                        image: msg['isMe']
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
