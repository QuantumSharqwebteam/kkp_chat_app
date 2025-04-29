import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/config/theme/image_constants.dart';
import 'package:kkpchatapp/core/services/chat_storage_service.dart';
import 'package:kkpchatapp/core/services/s3_upload_service.dart';
import 'package:kkpchatapp/core/services/socket_service.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/models/chat_message_model.dart';
import 'package:kkpchatapp/presentation/common/chat/agora_audio_call_screen.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/document_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/fill_form_button.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/form_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/image_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/chat_input_field.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_button.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/no_chat_conversation.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/voice_message_bubble.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

class CustomerChatScreen extends StatefulWidget {
  final String? customerName;
  final String? customerImage;
  final String? agentName;
  final String? agentImage;
  final String? customerEmail;
  final String? agentEmail;
  final GlobalKey<NavigatorState> navigatorKey;

  const CustomerChatScreen({
    super.key,
    this.customerName,
    this.customerImage,
    this.agentName = "Agent",
    this.agentImage,
    this.customerEmail,
    this.agentEmail,
    required this.navigatorKey,
  });

  @override
  State<CustomerChatScreen> createState() => _CustomerChatScreenState();
}

class _CustomerChatScreenState extends State<CustomerChatScreen>
    with WidgetsBindingObserver {
  final _chatController = TextEditingController();
  late final SocketService _socketService;
  final S3UploadService _s3uploadService = S3UploadService();
  final ScrollController _scrollController = ScrollController();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final qualityController = TextEditingController();
  final quantityController = TextEditingController();
  final weaveController = TextEditingController();
  final compositionController = TextEditingController();
  final rateController = TextEditingController();
  final ChatStorageService _chatStorageService =
      ChatStorageService(); // Initialize the service

  List<ChatMessageModel> messages = [];
  bool _isRecording = false;
  int _recordedSeconds = 0; // Add this line
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _socketService = SocketService(widget.navigatorKey);
    WidgetsBinding.instance.addObserver(this);
    _socketService.toggleChatPageOpen(true);
    _socketService.onReceiveMessage(_handleIncomingMessage);
    _loadMessages();
    _initializeRecorder();
  }

  Future<void> _initializeRecorder() async {
    await _recorder.openRecorder();
    await Permission.microphone.request();
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
    _recorder.closeRecorder();
    _timer?.cancel();
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
    final emailFromHive = LocalDbHelper.getProfile()?.email;
    if (emailFromHive != null && emailFromHive == widget.customerEmail) {
      final loadedMessages =
          await _chatStorageService.getMessages(emailFromHive);
      setState(() {
        messages = loadedMessages;
        _scrollToBottom();
      });
    }
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
    _chatStorageService.saveMessage(message, widget.customerEmail!);
  }

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

    _chatStorageService.saveMessage(message, widget.customerEmail!);
    _chatController.clear();
  }

  Future<void> _startRecording() async {
    await _recorder.startRecorder(toFile: 'voice_message.aac');
    setState(() {
      _isRecording = true;
      _recordedSeconds = 0; // Reset recorded seconds
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          _recordedSeconds++;
        });
      });
    });
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stopRecorder();
    _timer?.cancel(); // Stop the timer
    if (path != null) {
      final File voiceFile = File(path);
      final voiceUrl =
          await _s3uploadService.uploadFile(voiceFile, isVoiceMessage: true);
      if (voiceUrl != null) {
        _sendMessage(messageText: "voice", type: 'voice', mediaUrl: voiceUrl);
      }
    }
    setState(() {
      _isRecording = false;
    });
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

  Future<void> _pickAndSendDocument() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
    );

    if (result != null) {
      final PlatformFile file = result.files.first;
      final File documentFile = File(file.path!);
      final documentUrl = await _s3uploadService.uploadDocument(documentFile);
      if (documentUrl != null) {
        _sendMessage(
            messageText: "document", type: 'document', mediaUrl: documentUrl);
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
                Text("Please fill in the form details",
                    style: AppTextStyles.black16_600),
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
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Row(
            children: [
              CircleAvatar(
                  backgroundImage: AssetImage(
                      widget.agentImage ?? ImageConstants.agentImage)),
              const SizedBox(width: 5),
              Text(
                widget.agentName ?? "Agent",
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
                  channelName: channelName,
                  callerId: widget.customerEmail!,
                  callerName: widget.customerName!,
                );

                // Navigate agent to call screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AgoraAudioCallScreen(
                      isCaller: true,
                      channelName: channelName,
                      uid: uid,
                      //  remoteUserId: widget.agentEmail!,
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
                        } else if (msg.type == 'document') {
                          return DocumentMessageBubble(
                            documentUrl: msg.mediaUrl!,
                            isMe: msg.sender == widget.customerEmail,
                            timestamp: formatTimestamp(msg.timestamp),
                          );
                        } else if (msg.type == 'voice') {
                          return VoiceMessageBubble(
                            // Add this line
                            voiceUrl: msg.mediaUrl!,
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
                              ? widget.customerImage ?? ImageConstants.userImage
                              : widget.agentImage ?? ImageConstants.agentImage,
                        );
                      },
                    ),
            ),
            ChatInputField(
              controller: _chatController,
              onSend: () => _sendMessage(messageText: _chatController.text),
              onSendImage: _pickAndSendImage,
              onSendForm: _showFormOverlay,
              onSendDocument: _pickAndSendDocument,
              onSendVoice: _isRecording
                  ? _stopRecording
                  : _startRecording, // Update this line
              isRecording: _isRecording,
              recordedSeconds: _recordedSeconds, // Update this line
            ),
          ],
        ),
      ),
    );
  }
}
