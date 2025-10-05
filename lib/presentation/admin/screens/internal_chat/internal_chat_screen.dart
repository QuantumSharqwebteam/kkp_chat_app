import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/services/s3_upload_service.dart';
import 'package:kkpchatapp/core/services/socket_service.dart';
import 'package:kkpchatapp/core/utils/chat_utils.dart';
import 'package:kkpchatapp/data/api/chat_service.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/models/group_message_model.dart';
import 'package:kkpchatapp/main.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/chat_input_field.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/date_header.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/document_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/group_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/image_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/no_chat_conversation.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/shimmer_message_list.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/voice_message_bubble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

class InternalChatScreen extends StatefulWidget {
  final String agentName;
  final String agentEmail;
  final GlobalKey<NavigatorState> navigatorKey;

  const InternalChatScreen({
    super.key,
    required this.agentName,
    required this.agentEmail,
    required this.navigatorKey,
  });

  @override
  State<InternalChatScreen> createState() => _InternalChatScreenState();
}

class _InternalChatScreenState extends State<InternalChatScreen> with WidgetsBindingObserver {
  bool _isLoading = false;
  bool _isLoadingMore = false;
  final _chatController = TextEditingController();
  final SocketService _socketService = SocketService(navigatorKey);
  final ChatService _chatService = ChatService(); // Add ChatService
  final S3UploadService _s3uploadService = S3UploadService();
  final ScrollController _scrollController = ScrollController();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  List<GroupMessageModel> messages = [];
  bool _isRecording = false;
  int _recordedSeconds = 0;
  Timer? _timer;
  bool _isAtBottom = true;
  final ValueNotifier<String?> currentTopDate = ValueNotifier(null);
  final Map<Key, GlobalKey> _messageKeys = {};
  String? _nextCursor; // Track the cursor for pagination
  final Set<String> _loadedMessageIds = {}; // Track loaded message IDs to avoid duplicates

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _socketService.setGroupChatPageState(true);
    _socketService.onGroupMessageReceived(_handleIncomingGroupMessage);
    _initializeRecorder();
    _loadInitialGroupMessages(); // Load from API first
    _scrollController.addListener(_handleScroll);
    _scrollController.addListener(_checkIfAtBottom);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chatController.dispose();
    _scrollController.dispose();
    _recorder.closeRecorder();
    _timer?.cancel();
    _socketService.setGroupChatPageState(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _socketService.setGroupChatPageState(false);
    } else if (state == AppLifecycleState.resumed) {
      _socketService.setGroupChatPageState(true);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  /// Load initial 20 messages from API
  Future<void> _loadInitialGroupMessages() async {
    setState(() => _isLoading = true);
    try {
      // First try to fetch from API
      final result = await _chatService.fetchGroupMessages(limit: 20);
      final List<GroupMessageModel> fetchedMessages = result['messages'];
      _nextCursor = result['nextCursor'];

      if (fetchedMessages.isNotEmpty) {
        // Remove duplicates and add to messages
        final uniqueMessages = _removeDuplicates(fetchedMessages);

        setState(() {
          messages = uniqueMessages;
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        });

        // Save to local storage
        for (var msg in uniqueMessages) {
          await LocalDbHelper.saveGroupMessage(msg);
        }
        _scrollToBottom();
      } else {
        // If API returns no messages, load from local storage
        await _loadLocalGroupMessages();
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint("Error fetching initial group messages: $e");
      // Fallback to local storage if API fails
      await _loadLocalGroupMessages();
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  /// Load messages from local storage (fallback)
  Future<void> _loadLocalGroupMessages() async {
    try {
      final localMessages = await LocalDbHelper.getGroupMessages();
      if (localMessages.isNotEmpty) {
        // Remove duplicates and add to messages
        final uniqueMessages = _removeDuplicates(localMessages);

        setState(() {
          messages = uniqueMessages;
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          if (messages.isNotEmpty) {
            _nextCursor = messages.last.timestamp.toIso8601String();
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading local group messages: $e");
    }
  }

  /// Remove duplicate messages based on messageId
  List<GroupMessageModel> _removeDuplicates(List<GroupMessageModel> newMessages) {
    return newMessages.where((message) {
      // Check if we've already loaded this message
      if (_loadedMessageIds.contains(message.messageId)) {
        return false; // Skip duplicates
      } else {
        _loadedMessageIds.add(message.messageId);
        return true; // Keep unique messages
      }
    }).toList();
  }

  /// Load more older messages
  Future<void> _loadMoreGroupMessages() async {
    if (_isLoadingMore || _nextCursor == null) return;

    setState(() => _isLoadingMore = true);
    try {
      // Fetch older messages using the nextCursor
      final result = await _chatService.fetchGroupMessages(
        limit: 20,
        before: _nextCursor,
      );

      final List<GroupMessageModel> olderMessages = result['messages'];
      _nextCursor = result['nextCursor'];

      if (olderMessages.isNotEmpty) {
        // Remove duplicates and add to messages
        final uniqueMessages = _removeDuplicates(olderMessages);

        setState(() {
          messages.insertAll(0, uniqueMessages);
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        });

        // Save to local storage
        for (var msg in uniqueMessages) {
          await LocalDbHelper.saveGroupMessage(msg);
        }
      }
    } catch (e) {
      debugPrint("Error loading more group messages: $e");
    } finally {
      setState(() => _isLoadingMore = false);
    }
  }

  /// Handle incoming real-time messages
  void _handleIncomingGroupMessage(Map<String, dynamic> data) {
    debugPrint("Group message received: ${data.toString()}");
    final message = GroupMessageModel.fromApiJson(data);

    // Check if this is a new message (not already loaded)
    if (!_loadedMessageIds.contains(message.messageId)) {
      _loadedMessageIds.add(message.messageId);

      setState(() {
        messages.add(message);
      });
      LocalDbHelper.saveGroupMessage(message);
      _scrollToBottom();
    }
  }

  /// Initialize the audio recorder
  Future<void> _initializeRecorder() async {
    try {
      await _recorder.openRecorder();
      await Permission.microphone.request();
    } catch (e) {
      debugPrint("Error initializing recorder: $e");
    }
  }

  /// Start recording voice message
  Future<void> _startRecording() async {
    try {
      await _recorder.startRecorder(toFile: 'voice_message.aac');
      setState(() {
        _isRecording = true;
        _recordedSeconds = 0;
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() => _recordedSeconds++);
        });
      });
    } catch (e) {
      debugPrint("Error starting recording: $e");
    }
  }

  /// Stop recording and send voice message
  Future<void> _stopRecording() async {
    _timer?.cancel();
    try {
      final path = await _recorder.stopRecorder();
      if (path != null) {
        final File voiceFile = File(path);
        final voiceUrl = await _s3uploadService.uploadFile(voiceFile, isVoiceMessage: true);
        if (voiceUrl != null) {
          _sendGroupMessage(messageText: "voice", type: 'voice', mediaUrl: voiceUrl);
        }
      }
    } catch (e) {
      debugPrint("Error stopping recording: $e");
    } finally {
      setState(() {
        _isRecording = false;
        _recordedSeconds = 0;
      });
    }
  }

  /// Send a group message
  void _sendGroupMessage({
    required String messageText,
    String type = 'text',
    String? mediaUrl,
  }) {
    if (messageText.trim().isEmpty && mediaUrl == null) return;

    final currentTime = DateTime.now();
    final messageId = const Uuid().v4();
    final message = GroupMessageModel(
      message: messageText,
      timestamp: currentTime,
      senderId: widget.agentEmail,
      senderName: widget.agentName,
      type: type,
      mediaUrl: mediaUrl,
      messageId: messageId,
    );

    setState(() {
      messages.add(message);
    });

    _socketService.sendGroupMessage(
      message: messageText,
      senderId: widget.agentEmail,
      senderName: widget.agentName,
      type: type,
      mediaUrl: mediaUrl,
      timestamp: currentTime.toIso8601String(),
      messageId: messageId,
    );

    LocalDbHelper.saveGroupMessage(message);
    _chatController.clear();
    _scrollToBottom();
  }

  /// Pick and send an image
  Future<void> _pickAndSendImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      final File imageFile = File(pickedFile.path);
      final imageUrl = await _s3uploadService.uploadFile(imageFile);
      if (imageUrl != null) {
        _sendGroupMessage(messageText: "image", type: 'media', mediaUrl: imageUrl);
      }
    }
  }

  /// Pick and send a document
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
        _sendGroupMessage(messageText: "document", type: 'document', mediaUrl: documentUrl);
      }
    }
  }

  /// Scroll to bottom of the chat
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Handle scroll events for pagination
  void _handleScroll() {
    if (_scrollController.position.atEdge &&
        _scrollController.position.pixels == 0 &&
        !_isLoadingMore) {
      _loadMoreGroupMessages();
    }
  }

  /// Check if user is at the bottom of the chat
  void _checkIfAtBottom() {
    if (_scrollController.position.atEdge) {
      bool isBottom =
          _scrollController.position.pixels == _scrollController.position.maxScrollExtent;
      if (isBottom != _isAtBottom) {
        setState(() => _isAtBottom = isBottom);
      }
    } else if (_isAtBottom) {
      setState(() => _isAtBottom = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 5,
        surfaceTintColor: Colors.white,
        shadowColor: AppColors.greyDBDDE1,
        title: const Text(
          "Internal Chat",
          style: AppTextStyles.black16_600,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(12.0),
            bottomRight: Radius.circular(12.0),
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (_isLoadingMore)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 15.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              Expanded(
                child: _isLoading
                    ? ShimmerMessageList()
                    : messages.isEmpty
                        ? NoChatConversation()
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(10),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final msg = messages[index];
                              final isAgent = msg.senderId == widget.agentEmail;
                              final valueKey = ValueKey('group-msg-$index');
                              final globalKey = GlobalKey();
                              _messageKeys[valueKey] = globalKey;
                              String? dateHeader;
                              if (index == 0 ||
                                  !ChatUtils()
                                      .isSameDay(messages[index - 1].timestamp, msg.timestamp)) {
                                dateHeader = ChatUtils().formatDateHeader(msg.timestamp);
                              }
                              return Container(
                                key: globalKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (dateHeader != null) DateHeader(date: dateHeader),
                                    if (msg.type == 'media')
                                      ImageMessageBubble(
                                        imageUrl: msg.mediaUrl!,
                                        isMe: isAgent,
                                        timestamp: ChatUtils().formatTimestamp(
                                          msg.timestamp.toIso8601String(),
                                        ),
                                        isDeleted: msg.isDeleted,
                                        onLongPress: isAgent
                                            ? () => _showMessageOptionsBottomSheet(
                                                context, msg.messageId)
                                            : null,
                                      )
                                    else if (msg.type == 'document')
                                      DocumentMessageBubble(
                                        documentUrl: msg.mediaUrl!,
                                        isMe: isAgent,
                                        timestamp: ChatUtils().formatTimestamp(
                                          msg.timestamp.toIso8601String(),
                                        ),
                                        isDeleted: msg.isDeleted,
                                        onLongPress: isAgent
                                            ? () => _showMessageOptionsBottomSheet(
                                                context, msg.messageId)
                                            : null,
                                      )
                                    else if (msg.type == 'voice')
                                      VoiceMessageBubble(
                                        voiceUrl: msg.mediaUrl!,
                                        isMe: isAgent,
                                        timestamp: ChatUtils().formatTimestamp(
                                          msg.timestamp.toIso8601String(),
                                        ),
                                        isDeleted: msg.isDeleted,
                                        onLongPress: isAgent
                                            ? () => _showMessageOptionsBottomSheet(
                                                context, msg.messageId)
                                            : null,
                                      )
                                    else
                                      GroupMessageBubble(
                                        message: msg,
                                        isMe: isAgent,
                                        onLongPress: isAgent
                                            ? () => _showMessageOptionsBottomSheet(
                                                context, msg.messageId,
                                                textToCopy: msg.message)
                                            : null,
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
              SafeArea(
                minimum: const EdgeInsets.only(bottom: 1),
                child: ChatInputField(
                  controller: _chatController,
                  onSend: () => _sendGroupMessage(messageText: _chatController.text),
                  onSendImage: () => _pickAndSendImage(ImageSource.gallery),
                  onSendDocument: _pickAndSendDocument,
                  onSendImageByCamera: () => _pickAndSendImage(ImageSource.camera),
                  onSendVoice: _isRecording ? _stopRecording : _startRecording,
                  isRecording: _isRecording,
                  recordedSeconds: _recordedSeconds,
                  onSendForm: () {},
                  onShareProduct: () {},
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
          if (!_isAtBottom)
            Positioned(
              bottom: 100,
              right: 10,
              child: FloatingActionButton(
                onPressed: _scrollToBottom,
                mini: true,
                child: const Icon(Icons.arrow_downward_rounded),
              ),
            ),
        ],
      ),
    );
  }

  void _showMessageOptionsBottomSheet(BuildContext context, String messageId,
      {String? textToCopy}) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (textToCopy != null)
                ListTile(
                  leading: const Icon(Icons.content_copy),
                  title: const Text('Copy Message'),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: textToCopy));
                    Navigator.pop(context);
                  },
                ),
              // ListTile( // Commented out delete option
              //   leading: const Icon(Icons.delete),
              //   title: const Text('Delete Message'),
              //   onTap: () {
              //     Navigator.pop(context);
              //     _socketService.deleteGroupMessage(messageId);
              //   },
              // ),
            ],
          ),
        );
      },
    );
  }
}
