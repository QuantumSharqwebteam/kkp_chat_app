import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_initicon/flutter_initicon.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
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
import 'package:kkpchatapp/main.dart';
import 'package:kkpchatapp/presentation/common/chat/agora_audio_call_screen.dart';
import 'package:kkpchatapp/presentation/common/chat/transfer_agent_screen.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/call_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/chat_input_field.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/document_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/fill_form_button.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/form_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/image_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/message_bubble.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/no_chat_conversation.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/voice_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/full_screen_loader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

class AgentChatScreen extends StatefulWidget {
  final String? customerName;
  final String? agentName;
  final String customerEmail;
  final String? agentEmail;
  final GlobalKey<NavigatorState> navigatorKey;

  const AgentChatScreen({
    super.key,
    this.customerName,
    this.agentName,
    required this.customerEmail,
    this.agentEmail,
    required this.navigatorKey,
  });

  @override
  State<AgentChatScreen> createState() => _AgentChatScreenState();
}

class _AgentChatScreenState extends State<AgentChatScreen>
    with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _isFormUpdating = false;
  final _chatController = TextEditingController();
  final ChatRepository _chatRepository = ChatRepository();
  final SocketService _socketService = SocketService(navigatorKey);
  final S3UploadService _s3uploadService = S3UploadService();
  final ScrollController _scrollController = ScrollController();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final ChatStorageService _chatStorageService = ChatStorageService();

  List<ChatMessageModel> messages = [];
  bool _isRecording = false;
  int _recordedSeconds = 0;
  Timer? _timer;
  String? userRole;
  int _currentPage = 1;
  bool _isFetching = false;
  Set<int> _fetchedPages = Set(); // Keep track of fetched pages
  bool _isLoadingMore = false; // Show loading indicator when loading more
  final Set<String> _loadedMessageIds = Set();
  bool _isAtBottom = true; // Track if the user is at the bottom of the list

  @override
  void initState() {
    _fetchUserRole();
    super.initState();
    _socketService.toggleChatPageOpen(true);
    _socketService.onReceiveMessage(_handleIncomingMessage);
    _initializeRecorder();
    _loadPreviousMessages(context);

    // Scroll to bottom when the chat page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    _scrollController.addListener(_handleScroll);
    _scrollController.addListener(_checkIfAtBottom);
    _resetMessageCount();
  }

  Future<void> _resetMessageCount() async {
    final boxNameWithCount = '${widget.agentEmail}${widget.customerEmail}count';
    final box = await Hive.openBox<int>(boxNameWithCount);
    await box.put('count', 0);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chatController.dispose();
    _scrollController.dispose();
    _recorder.closeRecorder();
    _timer?.cancel();
    _scrollController.removeListener(_handleScroll);
    _scrollController.removeListener(_checkIfAtBottom);
    _socketService.toggleChatPageOpen(false);
    super.dispose();
  }

  @override
  void deactivate() {
    _socketService.toggleChatPageOpen(false);
    super.deactivate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _socketService.toggleChatPageOpen(false);
    } else if (state == AppLifecycleState.resumed) {
      _socketService.toggleChatPageOpen(true);
      // Scroll to bottom when the app is resumed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  Future<void> _fetchUserRole() async {
    final role = await LocalDbHelper.getUserType();
    setState(() {
      userRole = role;
    });
  }

  Future<void> _initializeRecorder() async {
    await _recorder.openRecorder();
    await Permission.microphone.request();
  }

  Future<void> _loadPreviousMessages(context) async {
    final boxName = '${widget.agentEmail}${widget.customerEmail}';
    bool boxExists = await Hive.boxExists(boxName);

    if (!boxExists) {
      // Fetch messages from API
      await _fetchMessagesFromAPI(boxName, context);
    } else {
      // Load messages from Hive
      final loadedMessages =
          await _chatStorageService.getMessages(boxName, page: _currentPage);
      final newLoadedMessages = _removeDuplicates(loadedMessages);
      setState(() {
        messages = newLoadedMessages;
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchMessagesFromAPI(String boxName, context) async {
    try {
      String? before;
      if (messages.isNotEmpty) {
        before = messages.first.timestamp.toIso8601String();
      }

      final List<MessageModel> fetchedMessages =
          await _chatRepository.fetchAgentMessages(
        agentEmail: widget.agentEmail ?? LocalDbHelper.getProfile()!.email!,
        customerEmail: widget.customerEmail,
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
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching messages from API: $e");
    }
  }

  void _handleScroll() {
    if (_scrollController.position.atEdge) {
      if (_scrollController.position.pixels == 0) {
        // User has scrolled to the top
        _loadMoreMessages(context);
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

  Future<void> _loadMoreMessages(context) async {
    if (_isFetching || _isLoadingMore) return;
    _isLoadingMore = true;
    setState(() {});

    _currentPage++;
    final boxName = '${widget.agentEmail}${widget.customerEmail}';
    if (_fetchedPages.contains(_currentPage)) {
      // Page already fetched, do nothing
      _isLoadingMore = false;
      setState(() {});
      return;
    }

    final loadedMessages =
        await _chatStorageService.getMessages(boxName, page: _currentPage);

    if (loadedMessages.isEmpty) {
      // Fetch more messages from API
      await _fetchMessagesFromAPI(boxName, context);
      final newLoadedMessages =
          await _chatStorageService.getMessages(boxName, page: _currentPage);
      final uniqueMessages = _removeDuplicates(newLoadedMessages);
      setState(() {
        messages.insertAll(0, uniqueMessages);
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      });
      _fetchedPages.add(_currentPage);
    } else {
      final uniqueMessages = _removeDuplicates(loadedMessages);
      setState(() {
        messages.insertAll(0, uniqueMessages);
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      });
      _fetchedPages.add(_currentPage);
    }

    _isLoadingMore = false;
    setState(() {});
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

  void _handleIncomingMessage(Map<String, dynamic> data) {
    final currentTime = DateTime.now();
    final message = ChatMessageModel(
      message: data["message"],
      timestamp: currentTime,
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
        _scrollToBottom();
      });

      // Save the message to Hive only if it's not already saved
      _chatStorageService.saveMessage(
          message, '${widget.agentEmail}${widget.customerEmail}');
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

    final currentTime = DateTime.now();
    final message = ChatMessageModel(
      message: messageText,
      timestamp: currentTime,
      sender: widget.agentEmail!,
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
      });

      _socketService.sendMessage(
        targetEmail: widget.customerEmail,
        message: messageText,
        senderEmail: widget.agentEmail!,
        senderName: widget.agentName!,
        type: type,
        mediaUrl: mediaUrl,
        form: form,
      );

      // Save the message to Hive only if it's not already saved
      _chatStorageService.saveMessage(
          message, '${widget.agentEmail}${widget.customerEmail}');
      _loadedMessageIds.add(messageId);
    }
    _scrollToBottom();

    _chatController.clear();
    FocusScope.of(context)
        .unfocus(); // to close the opened keyboard after sending message
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 10),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startRecording() async {
    await _recorder.startRecorder(toFile: 'voice_message.aac');
    setState(() {
      _isRecording = true;
      _recordedSeconds = 0;
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          _recordedSeconds++;
        });
      });
    });
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stopRecorder();
    _timer?.cancel();
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
      _recordedSeconds = 0;
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

  void sendFormButton() {
    _sendMessage(messageText: "Fill details");
  }

  void sendFormToUpdateRate(Map<String, dynamic> formData) {
    _sendMessage(
      messageText: "Update form rate",
      form: formData,
    );
  }

  void _handleRateUpdated(Map<String, dynamic> updatedFormData) {
    _sendMessage(
      messageText: "Form rate updated",
      type: 'form',
      form: updatedFormData,
    );
  }

  void _handleStatusUpdated(String status, String id) {
    final messageText = status == 'Confirmed'
        ? "Your order is confirmed with form Id: $id"
        : "Your order is declined with form Id: $id";
    _sendMessage(
      messageText: messageText,
      type: 'text',
    );
  }

  String formatTimestamp(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) {
      final currentTime = DateTime.now();
      return DateFormat('hh:mm a').format(currentTime);
    }
    try {
      final dateTime = DateTime.parse(timestamp).toLocal();
      return DateFormat('hh:mm a').format(dateTime);
    } catch (e) {
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
            Initicon(text: widget.customerName ?? ""),
            const SizedBox(width: 5),
            Text(
              widget.customerName!,
              style: AppTextStyles.black12_700,
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return TransferAgentScreen(
                      customerEmailId: widget.customerEmail,
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
              final channelName =
                  sha256.convert(utf8.encode(widget.agentEmail!)).toString();

              final uid = Utils().generateIntUidFromEmail(widget.agentEmail!);
              debugPrint("Generated UID for agent (caller): $uid");

              final callId = Uuid().v4();

              _socketService.sendAgoraCall(
                targetId: widget.customerEmail,
                channelName: channelName,
                callerId: widget.agentEmail!,
                callerName: widget.agentName!,
                callId: callId,
              );

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AgoraAudioCallScreen(
                    isCaller: true,
                    channelName: channelName,
                    uid: uid,
                    remoteUserId: widget.customerEmail,
                    remoteUserName: widget.customerName!,
                    messageId: callId,
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
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : messages.isEmpty
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
                                  isMe: msg.sender == widget.agentEmail,
                                  timestamp: formatTimestamp(
                                      msg.timestamp.toIso8601String()),
                                );
                              } else if (msg.type == 'form') {
                                return FormMessageBubble(
                                  formData: msg.form!,
                                  isMe: msg.sender == widget.agentEmail,
                                  timestamp: formatTimestamp(
                                      msg.timestamp.toIso8601String()),
                                  userRole: userRole!,
                                  onRateUpdated: _handleRateUpdated,
                                  onStatusUpdated: _handleStatusUpdated,
                                  onFormUpdateStart: () {
                                    setState(() {
                                      _isFormUpdating = true;
                                    });
                                  },
                                  onFormUpdateEnd: () {
                                    setState(() {
                                      _isFormUpdating = false;
                                    });
                                  },
                                  onAskForRateUpdate: sendFormToUpdateRate,
                                );
                              } else if (msg.type == 'document') {
                                return DocumentMessageBubble(
                                  documentUrl: msg.mediaUrl!,
                                  isMe: msg.sender == widget.agentEmail,
                                  timestamp: formatTimestamp(
                                      msg.timestamp.toIso8601String()),
                                );
                              } else if (msg.type == 'voice') {
                                return VoiceMessageBubble(
                                  voiceUrl: msg.mediaUrl!,
                                  isMe: msg.sender == widget.agentEmail,
                                  timestamp: formatTimestamp(
                                      msg.timestamp.toIso8601String()),
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
                                  buttonText: "Fill product details",
                                  onSubmit: () {
                                    // Agent not allowed to fill the form
                                  },
                                );
                              } else if (msg.message == "Update form rate") {
                                return FillFormButton(
                                  buttonText: "Update Form",
                                  onSubmit: () {
                                    // only show the widget for history not to do anything agent side
                                  },
                                );
                              }
                              return MessageBubble(
                                text: msg.message,
                                isMe: msg.sender == widget.agentEmail,
                                timestamp: formatTimestamp(
                                    msg.timestamp.toIso8601String()),
                                image: msg.sender == widget.agentEmail
                                    ? widget.agentName ?? ""
                                    : widget.customerName ?? "",
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
                onSendForm: sendFormButton,
                onSendDocument: _pickAndSendDocument,
                onSendVoice: _isRecording ? _stopRecording : _startRecording,
                isRecording: _isRecording,
                recordedSeconds: _recordedSeconds,
              ),
            ],
          ),
          if (_isFormUpdating) FullScreenLoader(),
          if (!_isAtBottom)
            Positioned(
              bottom: 80, // Adjust the position as needed
              right: 16, // Adjust the position as needed
              child: FloatingActionButton(
                onPressed: _scrollToBottom,
                mini: true,
                child: Icon(Icons.arrow_downward_rounded),
              ),
            ),
        ],
      ),
    );
  }
}
