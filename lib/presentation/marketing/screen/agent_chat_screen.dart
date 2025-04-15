import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';
import 'package:kkp_chat_app/config/theme/image_constants.dart';
import 'package:kkp_chat_app/core/services/s3_upload_service.dart';
import 'package:kkp_chat_app/core/services/socket_service.dart';
import 'package:kkp_chat_app/data/repositories/chat_reopsitory.dart';
import 'package:kkp_chat_app/presentation/common_widgets/chat/chat_input_field.dart';
import 'package:kkp_chat_app/presentation/common_widgets/chat/fill_form_button.dart';
import 'package:kkp_chat_app/presentation/common_widgets/chat/form_message_bubble.dart';
import 'package:kkp_chat_app/presentation/common_widgets/chat/image_message_bubble.dart';
import 'package:kkp_chat_app/presentation/common_widgets/chat/message_bubble.dart';
import 'package:kkp_chat_app/presentation/common_widgets/chat/no_chat_conversation.dart';
import 'package:permission_handler/permission_handler.dart';

class AgentChatScreen extends StatefulWidget {
  final String? customerName;
  final String? customerImage;
  final String? agentName;
  final String? agentImage;
  final String? customerEmail;
  final String? agentEmail;

  const AgentChatScreen({
    super.key,
    this.customerName = 'Customer 2',
    this.customerImage = ImageConstants.userImage,
    this.agentName = 'Agent N/A',
    this.agentImage = 'assets/images/user4.png',
    this.customerEmail = 'prabhujivats@gmail.com',
    this.agentEmail = 'agent@gmail.com',
  });

  @override
  AgentChatScreenState createState() => AgentChatScreenState();
}

class AgentChatScreenState extends State<AgentChatScreen>
    with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _isCallInProgress = false;
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final S3UploadService _s3uploadService = S3UploadService();
  final SocketService _callService = SocketService();
  final ChatRepository _chatRepository = ChatRepository();

  final TextEditingController qualityController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController weaveController = TextEditingController();
  final TextEditingController compositionController = TextEditingController();
  final TextEditingController rateController = TextEditingController();

  List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize unified service
    _callService.init(
      widget.agentName!,
      widget.agentEmail!,
      'agent',
    );
    _callService.toggleChatPageOpen(true);

    // Subscribe to events
    _callService.onReceiveMessage(_handleIncomingMessage);
    _callService.onIncomingCall((_) {});
    _callService.onCallAnswered((_) {
      setState(() => _isCallInProgress = true);
    });
    _callService.onCallTerminated((_) {
      setState(() => _isCallInProgress = false);
    });
    _callService.onSignalCandidate((_) {});

    _loadPreviousMessages();
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

  Future<void> _loadPreviousMessages() async {
    try {
      final fetched = await _chatRepository.fetchPreviousChats(
        widget.agentEmail!,
        widget.customerEmail!,
      );
      setState(() {
        messages = fetched.map((m) {
          Map<String, dynamic>? formData;
          if (m.type == 'form' && m.form != null && m.form!.isNotEmpty) {
            final f = m.form!.first;
            formData = {
              'quality': f['quality'],
              'quantity': f['quantity'],
              'weave': f['weave'],
              'composition': f['composition'],
              'rate': f['rate'],
            };
          }
          return {
            'text': m.message ?? '',
            'timestamp': m.timestamp ?? '',
            'isMe': m.isMe,
            'type': m.type ?? 'text',
            'mediaUrl': m.mediaUrl,
            'form': formData,
          };
        }).toList();
        _isLoading = false;
        _scrollToBottom();
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading chats: $e');
    }
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    setState(() {
      messages.add({
        'text': data['message'],
        'timestamp': DateTime.now().toIso8601String(),
        'isMe': data['senderId'] == widget.agentEmail,
        'type': data['type'] ?? 'text',
        'mediaUrl': data['mediaUrl'],
        'form': data['form'],
      });
      _scrollToBottom();
    });
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
      targetEmail: widget.customerEmail!,
      senderEmail: widget.agentEmail!,
      senderName: widget.agentName!,
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

  void _initiateAudioCall() async {
    if (await _requestCallPermissions()) {
      _callService.createOffer(widget.customerEmail!);
    }
  }

  Future<bool> _requestCallPermissions() async {
    // Check if microphone permission is already granted
    bool microphoneGranted = await Permission.microphone.isGranted;

    // Request microphone permission if not already granted
    if (!microphoneGranted) {
      microphoneGranted = await Permission.microphone.request().isGranted;

      // Handle permission denied
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

  void _endCall() {
    _callService.hangUp();
    setState(() => _isCallInProgress = false);
  }

  String _formatTimestamp(String? ts) {
    if (ts == null || ts.isEmpty) {
      return DateFormat('hh:mm a').format(DateTime.now());
    }
    final dt = DateTime.parse(ts).toLocal();
    return DateFormat('hh:mm a').format(dt);
  }

  void sendFormButton() {
    _sendMessage(messageText: 'Fill details');
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
        elevation: 4,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(backgroundImage: AssetImage(widget.customerImage!)),
            SizedBox(width: 8),
            Text(widget.customerName!, style: AppTextStyles.black14_400),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isCallInProgress ? Icons.call_end : Icons.call_outlined,
              color: Colors.black,
            ),
            onPressed: _isCallInProgress ? _endCall : _initiateAudioCall,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : messages.isEmpty
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
                            return FillFormButton(onSubmit: () {});
                          }
                          return MessageBubble(
                            text: msg['text'],
                            isMe: msg['isMe'],
                            timestamp: _formatTimestamp(msg['timestamp']),
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
            onSendForm: sendFormButton,
          ),
        ],
      ),
    );
  }
}
