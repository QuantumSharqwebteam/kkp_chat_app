import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_initicon/flutter_initicon.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/services/chat_storage_service.dart';
import 'package:kkpchatapp/core/services/s3_upload_service.dart';
import 'package:kkpchatapp/core/services/socket_service.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/models/chat_message_model.dart';
import 'package:kkpchatapp/data/models/message_model.dart';
import 'package:kkpchatapp/data/repositories/chat_reopsitory.dart';
import 'package:kkpchatapp/presentation/common/chat/agora_audio_call_screen.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/call_message_bubble.dart';
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
import 'package:kkpchatapp/presentation/common_widgets/full_screen_loader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

class CustomerChatScreen extends StatefulWidget {
  final String? customerName;
  final String? agentName;
  final String? customerEmail;
  final String? agentEmail;
  final GlobalKey<NavigatorState> navigatorKey;

  const CustomerChatScreen({
    super.key,
    this.customerName,
    this.agentName = "Agent",
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
  final rateController = TextEditingController();
  final qualityController = TextEditingController();
  final quantityController = TextEditingController();
  final weaveController = TextEditingController();
  final compositionController = TextEditingController();
  final sNoController = TextEditingController();
  final ChatStorageService _chatStorageService = ChatStorageService();
  final ChatRepository _chatRepository = ChatRepository();
  bool isFormUpdating = false;

  List<ChatMessageModel> messages = [];
  bool _isRecording = false;
  int _recordedSeconds = 0;
  Timer? _timer;
  String? userRole;
  bool _isFetching = false;
  bool _isLoadingMore = false;
  bool _isAtBottom = true; // Track if the user is at the bottom of the list
  final Set<String> _loadedMessageIds = {};

  Future<void> _loadPreviousMessages() async {
    final boxName = widget.customerEmail!;
    bool boxExists = await Hive.boxExists(boxName);

    if (!boxExists) {
      // Fetch messages from API
      await _fetchMessagesFromAPI(boxName);
    } else {
      // Load messages from Hive
      final loadedMessages =
          await _chatStorageService.getCustomerMessages(boxName);
      final newLoadedMessages = _removeDuplicates(loadedMessages);

      messages = newLoadedMessages;
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }

    // Scroll to bottom after loading messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  Future<void> _fetchMessagesFromAPI(String boxName) async {
    try {
      String? before;
      if (messages.isNotEmpty) {
        before = messages.first.timestamp.toIso8601String();
      }

      final List<MessageModel> fetchedMessages =
          await _chatRepository.fetchCustomerMessages(
        customerEmail: widget.customerEmail!,
        limit: 20,
        before: before,
      );

      if (fetchedMessages.isEmpty) {
        // No more messages to load
        return;
      }

      // Convert MessageModel to ChatMessageModel
      final chatMessages = fetchedMessages.map((messageJson) {
        return ChatMessageModel(
          message: messageJson.message ?? '',
          timestamp: DateTime.parse(
              messageJson.timestamp ?? DateTime.now().toIso8601String()),
          sender: messageJson.senderId!,
          type: messageJson.type,
          mediaUrl: messageJson.mediaUrl,
          form: messageJson.form != null && messageJson.form!.isNotEmpty
              ? Map<String, dynamic>.from(messageJson.form![0])
              : null,
        );
      }).toList();

      final newChatMessages = _removeDuplicates(chatMessages);
      if (newChatMessages.isNotEmpty) {
        // Save all messages at once
        await _chatStorageService.saveMessages(newChatMessages, boxName);
        setState(() {
          messages.insertAll(0, newChatMessages);
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        });
      }
    } catch (e) {
      // Handle errors properly
      debugPrint("Error fetching messages from API: $e");
      // You can show a snackbar or alert dialog to inform the user about the error
    }
  }

  List<ChatMessageModel> _removeDuplicates(List<ChatMessageModel> messages) {
    return messages.where((message) {
      final messageId =
          '${message.sender}_${message.timestamp.millisecondsSinceEpoch}_${message.message}';
      if (_loadedMessageIds.contains(messageId)) {
        return false;
      } else {
        _loadedMessageIds.add(messageId);
        return true;
      }
    }).toList();
  }

  void _handleScroll() {
    if (_scrollController.position.atEdge) {
      if (_scrollController.position.pixels == 0) {
        // User has scrolled to the top
        _loadMoreMessages();
      }
    }
  }

  void _checkIfAtBottom() {
    if (_scrollController.position.atEdge) {
      bool isBottom = _scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent;
      if (isBottom != _isAtBottom) {
        setState(() {
          _isAtBottom = isBottom;
        });
      }
    } else {
      if (_isAtBottom) {
        setState(() {
          _isAtBottom = false;
        });
      }
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isFetching || _isLoadingMore) return;
    _isLoadingMore = true;
    setState(() {});

    final boxName = widget.customerEmail!;
    await _fetchMessagesFromAPI(boxName);

    _isLoadingMore = false;
    setState(() {});
  }

  Future<void> _initializeRecorder() async {
    await _recorder.openRecorder();
    await Permission.microphone.request();
  }

  Future<void> _fetchUserRole() async {
    final role = await LocalDbHelper.getUserType();
    setState(() {
      userRole = role;
    });
  }

  @override
  void initState() {
    _fetchUserRole();
    super.initState();
    _socketService = SocketService(widget.navigatorKey);
    WidgetsBinding.instance.addObserver(this);
    _socketService.toggleChatPageOpen(true);
    _socketService.onReceiveMessage(_handleIncomingMessage);
    _loadPreviousMessages();
    _initializeRecorder();
    _scrollController.addListener(_handleScroll);
    _scrollController.addListener(_checkIfAtBottom);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chatController.dispose();
    _scrollController.dispose();
    qualityController.dispose();
    quantityController.dispose();
    sNoController.dispose();
    compositionController.dispose();
    _recorder.closeRecorder();
    _timer?.cancel();
    _scrollController.removeListener(_handleScroll);
    _scrollController.removeListener(_checkIfAtBottom);
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
    debugPrint("Received Message: ${data.toString()}");
    final currentTime = DateTime.now().toIso8601String();
    final message = ChatMessageModel(
      message: data["message"],
      timestamp: DateTime.parse(currentTime),
      sender: data["senderId"],
      type: data["type"] ?? "text",
      mediaUrl: data["mediaUrl"],
      form: data["form"],
    );

    final messageId =
        '${message.sender}_${message.timestamp.millisecondsSinceEpoch}_${message.message}';
    if (!_loadedMessageIds.contains(messageId)) {
      setState(() {
        messages.add(message);
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _scrollToBottom(); // Scroll to bottom only when a new message is received
      });

      // Save the message to Hive only if it's not already saved
      _chatStorageService.saveMessage(message, widget.customerEmail!);
      _loadedMessageIds.add(messageId);
    }
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

    final messageId =
        '${message.sender}_${message.timestamp.millisecondsSinceEpoch}_${message.message}';
    if (!_loadedMessageIds.contains(messageId)) {
      setState(() {
        messages.add(message);
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _scrollToBottom(); // Scroll to bottom only when a new message is sent
      });

      final String? name = LocalDbHelper.getProfile()?.name;

      _socketService.sendMessage(
        message: messageText,
        senderEmail: widget.customerEmail!,
        senderName: name!,
        type: type,
        mediaUrl: mediaUrl,
        form: form,
      );

      // Save the message to Hive only if it's not already saved
      _chatStorageService.saveMessage(message, widget.customerEmail!);
      _loadedMessageIds.add(messageId);
    }
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
                  decoration: InputDecoration(
                      labelText: "S.No",
                      hintText: "fill here '01' for first form",
                      hintStyle: AppTextStyles.grey12_600
                          .copyWith(color: AppColors.greyAAAAAA)),
                  controller: sNoController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'S.No';
                    }
                    return null;
                  },
                ),
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
                      return 'Please set Rate';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final formData = {
                        "S.No": sNoController.text,
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

  void _handleRateUpdated(Map<String, dynamic> updatedFormData) {
    _sendMessage(
      messageText: "Form rate updated",
      type: 'form',
      form: updatedFormData,
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
              Initicon(text: "Agent"),
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

                final callId = Uuid().v4();
                // Send call data over socket to notify customer
                _socketService.sendAgoraCall(
                  channelName: channelName,
                  callerId: widget.customerEmail!,
                  callerName: widget.customerName!,
                  callId: callId,
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
                      messageId: callId,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.call_outlined, color: Colors.black),
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
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
                                isMe: msg.sender == widget.agentEmail,
                                timestamp: formatTimestamp(
                                    msg.timestamp.toIso8601String()),
                                userRole: userRole!,
                                onRateUpdated: _handleRateUpdated,
                                onFormUpdateStart: () {
                                  setState(() {
                                    isFormUpdating = true;
                                  });
                                },
                                onFormUpdateEnd: () {
                                  setState(() {
                                    isFormUpdating = false;
                                  });
                                },
                              );
                            } else if (msg.type == 'document') {
                              return DocumentMessageBubble(
                                documentUrl: msg.mediaUrl!,
                                isMe: msg.sender == widget.customerEmail,
                                timestamp: formatTimestamp(msg.timestamp),
                              );
                            } else if (msg.type == 'voice') {
                              return VoiceMessageBubble(
                                voiceUrl: msg.mediaUrl!,
                                isMe: msg.sender == widget.customerEmail,
                                timestamp: formatTimestamp(msg.timestamp),
                              );
                            } else if (msg.type == 'call') {
                              return CallMessageBubble(
                                isMe: msg.sender == widget.agentEmail,
                                timestamp: formatTimestamp(
                                    msg.timestamp.toIso8601String()),
                                callStatus: msg.callStatus ?? "",
                                callDuration: msg.callDuration ?? '',
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
                                  ? widget.customerName ?? ""
                                  : "Agent",
                            );
                          },
                        ),
                ),
                if (_isLoadingMore)
                  Center(
                    child: CircularProgressIndicator(),
                  ),
                ChatInputField(
                  controller: _chatController,
                  onSend: () => _sendMessage(messageText: _chatController.text),
                  onSendImage: _pickAndSendImage,
                  onSendForm: _showFormOverlay,
                  onSendDocument: _pickAndSendDocument,
                  onSendVoice: _isRecording ? _stopRecording : _startRecording,
                  isRecording: _isRecording,
                  recordedSeconds: _recordedSeconds,
                ),
              ],
            ),
            if (isFormUpdating) FullScreenLoader(),
            if (!_isAtBottom)
              Positioned(
                bottom: 80, // Adjust the position as needed
                right: 16, // Adjust the position as needed
                child: FloatingActionButton(
                  onPressed: _scrollToBottom,
                  mini: true,
                  backgroundColor: AppColors.blue0056FB.withAlpha(50),
                  child: Icon(Icons.arrow_downward_rounded),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
