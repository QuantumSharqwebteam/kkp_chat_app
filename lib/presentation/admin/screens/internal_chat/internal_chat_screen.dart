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
import 'package:kkpchatapp/data/models/group_model.dart';
import 'package:kkpchatapp/main.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/chat_input_field.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/date_header.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/document_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/group_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/image_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/no_chat_conversation.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/shimmer_message_list.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/voice_message_bubble.dart';
import 'package:kkpchatapp/logic/agent/group_provider.dart';
import 'package:kkpchatapp/presentation/marketing/screen/group_description.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

class InternalChatScreen extends StatefulWidget {
  final String agentName;
  final String agentEmail;
  final GlobalKey<NavigatorState> navigatorKey;
  final String? groupId;
  final GroupModel? group; // Add this line

  const InternalChatScreen({
    super.key,
    required this.agentName,
    required this.agentEmail,
    required this.navigatorKey,
    this.groupId,
    this.group, // Add this line
  });

  @override
  State<InternalChatScreen> createState() => _InternalChatScreenState();
}

class _InternalChatScreenState extends State<InternalChatScreen>
    with WidgetsBindingObserver {
  bool _isLoading = false;
  bool _isLoadingMore = false;
  final _chatController = TextEditingController();
  final SocketService _socketService = SocketService(navigatorKey);
  final ChatService _chatService = ChatService();
  final S3UploadService _s3uploadService = S3UploadService();
  final ScrollController _scrollController = ScrollController();
  final FlutterSoundRecorder _recorder =
      FlutterSoundRecorder(logLevel: Level.nothing);
  List<GroupMessageModel> messages = [];
  bool _isRecording = false;
  GroupMessageModel? _replyToMessage;
  GroupModel? _currentGroup;
  int _recordedSeconds = 0;
  Timer? _timer;
  final ValueNotifier<bool> _isAtBottom = ValueNotifier(true);
  final ValueNotifier<String?> currentTopDate = ValueNotifier(null);

  /// Keyed on the message instance. An Expando holds its keys weakly, so no
  /// pruning is needed — and unlike the old map it is not repopulated with a
  /// brand-new GlobalKey on every single build, which forced element
  /// reparenting for every visible row per frame.
  final Expando<GlobalKey> _messageKeys = Expando<GlobalKey>();
  String? _nextCursor;
  final Set<String> _loadedMessageIds = {};
  final Set<String> fetchedCursors = {};
  // bool _isEditing = false;
  // String _editingMessageId = '';
  final _editController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentGroup = widget.group;
    WidgetsBinding.instance.addObserver(this);
    _socketService.setGroupChatPageState(true);
    _socketService.onGroupMessageReceived(_handleIncomingGroupMessage);
    _socketService.onGroupMessageDeleted(_handleGroupMessageDeleted);
    _socketService.onGroupMessageEdited(_handleGroupMessageEdited);
    _initializeRecorder();
    if (widget.groupId != null) {
      // Clear storage count immediately; also update GroupProvider so the badge
      // in the drawer drops to zero without waiting for the user to go back.
      LocalDbHelper.clearGroupUnreadCount(widget.groupId!);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Provider.of<GroupProvider>(context, listen: false)
              .clearUnreadCount(widget.groupId!);
        }
      });
      _loadInitialGroupMessages();
    } else {
      debugPrint("⚠️ [InternalChat] groupId is null — skipping message load");
      setState(() => _isLoading = false);
    }
    _scrollController.addListener(_handleScroll);
    _scrollController.addListener(_checkIfAtBottom);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chatController.dispose();
    _editController.dispose();
    _scrollController.dispose();
    _recorder.closeRecorder();
    _timer?.cancel();
    _isAtBottom.dispose();
    currentTopDate.dispose();
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

  // --- Load Initial Messages ---
  Future<void> _loadInitialGroupMessages() async {
    final groupId = widget.groupId!;
    try {
      // 1. Load from local storage for an instant first paint.
      //    Display directly WITHOUT calling _removeDuplicates so _loadedMessageIds
      //    stays empty — poisoning it here is what caused the merge to return 0.
      final localMessages = await LocalDbHelper.getGroupMessages(groupId);
      debugPrint(
          "📦 [InternalChat] Local messages for group $groupId: ${localMessages.length}");
      if (!mounted) return;

      if (localMessages.isNotEmpty) {
        // Cache hit: paint it and sync in the background. The shimmer is only
        // for a genuinely cold cache — showing it on every open (which is what
        // an unconditional _isLoading = true did) hid content we already had.
        setState(() {
          messages = List.from(localMessages)
            ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
          _isLoading = false;
        });
        _scrollToBottom();
      } else {
        setState(() => _isLoading = true);
      }

      // 2. Fetch from API
      final result =
          await _chatService.fetchGroupMessages(limit: 20, groupId: groupId);
      final List<GroupMessageModel> fetchedMessages = result['messages'];
      _nextCursor = result['nextCursor'];
      debugPrint(
          "🌐 [InternalChat] API messages for group $groupId: ${fetchedMessages.length}");
      if (!mounted) return;

      // 3. Merge — reset the tracked-ID set first so _removeDuplicates inside
      //    _mergeMessages works on a clean slate.
      _loadedMessageIds.clear();
      final mergedMessages = _mergeMessages(localMessages, fetchedMessages);

      setState(() {
        messages = mergedMessages;
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _isLoading = false;
      });
      debugPrint(
          "✅ [InternalChat] Merged total: ${messages.length} for group $groupId");

      // 4. Persist only what the API actually added, in one batched write.
      //    Re-saving the entire merged list one message at a time on every open
      //    was the slowest part of entering a busy group.
      final localIds = localMessages.map((msg) => msg.messageId).toSet();
      final unsaved = mergedMessages
          .where((msg) => !localIds.contains(msg.messageId))
          .toList();
      if (unsaved.isNotEmpty) {
        await LocalDbHelper.saveGroupMessages(unsaved, groupId);
      }
      _scrollToBottom();
    } catch (e) {
      debugPrint(
          "❌ [InternalChat] Error loading messages for group $groupId: $e");
      // Fallback: show whatever is in local storage
      final localMessages = await LocalDbHelper.getGroupMessages(groupId);
      debugPrint(
          "📦 [InternalChat] Fallback local messages: ${localMessages.length}");
      if (!mounted) return;
      _loadedMessageIds.clear();
      setState(() {
        messages = _removeDuplicates(localMessages)
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _isLoading = false;
      });
    } finally {
      _scrollToBottom();
    }
  }

  // --- Merge Local and API Messages ---
  List<GroupMessageModel> _mergeMessages(List<GroupMessageModel> localMessages,
      List<GroupMessageModel> apiMessages) {
    final merged = [...localMessages];
    for (var apiMsg in apiMessages) {
      final index =
          merged.indexWhere((msg) => msg.messageId == apiMsg.messageId);
      if (index != -1) {
        // Replace local message with API message if API message is newer
        if (apiMsg.timestamp.isAfter(merged[index].timestamp)) {
          merged[index] = apiMsg;
        }
      } else {
        // Add new message from API
        merged.add(apiMsg);
      }
    }
    return _removeDuplicates(merged);
  }

  // --- Load More Messages ---
  Future<void> _loadMoreGroupMessages() async {
    final groupId = widget.groupId!;
    // _nextCursor is the whole pagination mechanism — a null cursor means the
    // server has no more history. The old page counter was never advanced past
    // 1, so its _fetchedPages guard permanently blocked every page after the
    // first.
    if (_isLoadingMore || _nextCursor == null) return;
    setState(() => _isLoadingMore = true);

    try {
      final result = await _chatService.fetchGroupMessages(
        limit: 20,
        groupId: groupId,
        before: _nextCursor,
      );
      final List<GroupMessageModel> olderMessages = result['messages'];
      _nextCursor = result['nextCursor'];
      debugPrint(
          "📜 [InternalChat] Loaded ${olderMessages.length} older messages for group $groupId");

      if (olderMessages.isNotEmpty) {
        final uniqueMessages = _removeDuplicates(olderMessages);
        if (!mounted) return;
        if (uniqueMessages.isNotEmpty) {
          setState(() {
            messages.insertAll(0, uniqueMessages);
            messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          });
          await LocalDbHelper.saveGroupMessages(uniqueMessages, groupId);
        }
      }
    } catch (e) {
      debugPrint("❌ [InternalChat] Error loading more messages: $e");
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  // --- Remove Duplicates ---
  List<GroupMessageModel> _removeDuplicates(
      List<GroupMessageModel> messagesList) {
    return messagesList.where((message) {
      if (_loadedMessageIds.contains(message.messageId)) {
        return false;
      } else {
        _loadedMessageIds.add(message.messageId);
        return true;
      }
    }).toList();
  }

  // --- Handle Incoming Messages ---
  void _handleIncomingGroupMessage(Map<String, dynamic> data) {
    debugPrint(
        "📨 [InternalChat] Group message received for group ${widget.groupId}: ${data.toString()}");

    // Server broadcasts targetId instead of groupId — persist the mapping so
    // background notifications can resolve the correct group badge.
    final targetId = data['targetId']?.toString();
    if (targetId != null && targetId.isNotEmpty && widget.groupId != null) {
      LocalDbHelper.saveGroupTargetMapping(targetId, widget.groupId!);
    }

    final message = GroupMessageModel.fromApiJson(data);
    if (!_loadedMessageIds.contains(message.messageId)) {
      _loadedMessageIds.add(message.messageId);
      setState(() {
        messages.add(message);
      });
      LocalDbHelper.saveGroupMessage(message, widget.groupId!);
      _saveLastMessagePreview(message.message, message.type, message.timestamp);
      _scrollToBottom();
    }
  }

  void _cancelReply() {
    if (_replyToMessage == null) return;
    setState(() {
      _replyToMessage = null;
    });
  }

  // --- Handle Message Deletion ---
  void _handleGroupMessageDeleted(Map<String, dynamic> data) {
    debugPrint("🗑️ [InternalChat] Group message deleted: ${data.toString()}");
    final messageId = data['messageId'];
    setState(() {
      final index = messages.indexWhere((msg) => msg.messageId == messageId);
      if (index != -1) {
        messages[index] = messages[index].copyWith(
          isDeleted: true,
          message: "This message was deleted",
        );
        LocalDbHelper.updateGroupMessage(messages[index], widget.groupId!);
      }
    });
  }

  // --- Delete Message ---
  void _deleteMessage(String messageId) {
    _socketService.deleteGroupMessage(
        messageId: messageId,
        senderId: widget.agentEmail,
        groupId: widget.groupId!);
    setState(() {
      final index = messages.indexWhere((msg) => msg.messageId == messageId);
      if (index != -1) {
        messages[index] = messages[index].copyWith(
          isDeleted: true,
          message: "This message was deleted",
        );
        LocalDbHelper.updateGroupMessage(messages[index], widget.groupId!);
      }
    });
  }

  // --- Handle Message Edit ---
  void _handleGroupMessageEdited(Map<String, dynamic> data) {
    debugPrint("✏️ [InternalChat] Group message edited: ${data.toString()}");
    final messageId = data['messageId'];
    final newMessage = data['newMessage'];
    setState(() {
      final index = messages.indexWhere((msg) => msg.messageId == messageId);
      if (index != -1) {
        messages[index] = messages[index].copyWith(
          message: newMessage,
          isEdited: true,
        );
        LocalDbHelper.updateGroupMessage(messages[index], widget.groupId!);
      }
    });
  }

  // --- Save last message preview for the group list tile ---
  void _saveLastMessagePreview(
      String messageText, String type, DateTime timestamp) {
    String preview;
    switch (type) {
      case 'media':
        preview = '[Photo]';
        break;
      case 'voice':
        preview = '[Voice]';
        break;
      case 'document':
        preview = '[Document]';
        break;
      default:
        preview = messageText.length > 60
            ? '${messageText.substring(0, 60)}...'
            : messageText;
    }
    LocalDbHelper.saveGroupLastMessage(widget.groupId!, preview, timestamp);
  }

  // // --- Edit Message ---
  // void _startEditingMessage(String messageId, String currentMessage) {
  //   setState(() {
  //     _isEditing = true;
  //     _editingMessageId = messageId;
  //     _editController.text = currentMessage;
  //   });
  // }

  // void _cancelEditing() {
  //   setState(() {
  //     _isEditing = false;
  //     _editingMessageId = '';
  //     _editController.clear();
  //   });
  // }

  // --- Show Edit Dialog ---
  void _showEditMessageDialog(String messageId, String currentMessage) {
    _editController.text = currentMessage;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Edit Message"),
          content: TextField(
            controller: _editController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: "Edit your message",
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
                _editController.clear();
              },
            ),
            TextButton(
              child: const Text("Save"),
              onPressed: () {
                _saveEditedMessage(messageId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // --- Save Edited Message ---
  void _saveEditedMessage(String messageId) {
    if (_editController.text.trim().isEmpty) return;
    final newMessage = _editController.text.trim();
    _socketService.editGroupMessage(
        messageId: messageId,
        senderId: widget.agentEmail,
        newMessage: newMessage,
        groupId: widget.groupId!);
    setState(() {
      final index = messages.indexWhere((msg) => msg.messageId == messageId);
      if (index != -1) {
        messages[index] = messages[index].copyWith(
          message: newMessage,
          isEdited: true,
        );
        LocalDbHelper.updateGroupMessage(messages[index], widget.groupId!);
      }
    });
    _editController.clear();
  }

  // --- Audio Recording ---
  Future<void> _initializeRecorder() async {
    try {
      await _recorder.openRecorder();
      await Permission.microphone.request();
    } catch (e) {
      debugPrint("Error initializing recorder: $e");
    }
  }

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

  Future<void> _stopRecording() async {
    _timer?.cancel();
    try {
      final path = await _recorder.stopRecorder();
      if (path != null) {
        final File voiceFile = File(path);
        final voiceUrl =
            await _s3uploadService.uploadFile(voiceFile, isVoiceMessage: true);
        if (voiceUrl != null) {
          _sendGroupMessage(
              messageText: "voice", type: 'voice', mediaUrl: voiceUrl);
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

  // --- Send Message ---
  void _sendGroupMessage({
    required String messageText,
    String type = 'text',
    String? mediaUrl,
  }) {
    if (messageText.trim().isEmpty && mediaUrl == null) return;
    final currentTime = DateTime.now();
    final groupId = widget.groupId ?? '';
    final messageId = const Uuid().v4();
    final message = GroupMessageModel(
      message: messageText,
      timestamp: currentTime,
      senderId: widget.agentEmail,
      senderName: widget.agentName,
      type: type,
      mediaUrl: mediaUrl,
      messageId: messageId,
      groupId: groupId,
      replyTo: _replyToMessage?.messageId,
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
        replyTo: _replyToMessage?.messageId,
        timestamp: currentTime.toIso8601String(),
        messageId: messageId,
        groupId: groupId);
    LocalDbHelper.saveGroupMessage(message, groupId);
    _saveLastMessagePreview(messageText, type, currentTime);
    _chatController.clear();
    _cancelReply();
    _scrollToBottom();
  }

  // --- Pick and Send Media ---
  Future<void> _pickAndSendImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      final File imageFile = File(pickedFile.path);
      final imageUrl = await _s3uploadService.uploadFile(imageFile);
      if (imageUrl != null) {
        _sendGroupMessage(
            messageText: "image", type: 'media', mediaUrl: imageUrl);
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
        _sendGroupMessage(
            messageText: "document", type: 'document', mediaUrl: documentUrl);
      }
    }
  }

  // --- Scroll Logic ---
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

  void _handleScroll() {
    if (_scrollController.position.atEdge &&
        _scrollController.position.pixels == 0 &&
        !_isLoadingMore) {
      unawaited(_loadMoreGroupMessages());
    }
  }

  void _checkIfAtBottom() {
    // ValueNotifier rather than setState: this fires on every scroll
    // notification and used to rebuild the whole screen on each crossing.
    if (_scrollController.position.atEdge) {
      _isAtBottom.value = _scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent;
    } else {
      _isAtBottom.value = false;
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
        title: GestureDetector(
          onTap: () async {
            if (_currentGroup != null) {
              final navigator = Navigator.of(context);
              final result = await navigator.push(
                MaterialPageRoute(
                    builder: (context) => GroupDescriptionScreen(
                          groupId: widget.groupId ?? "Na",
                          group: _currentGroup!,
                        )),
              );
              if (!mounted) return;
              if (result == true) {
                navigator.pop();
              } else if (result is GroupModel) {
                setState(() => _currentGroup = result);
              }
            }
          },
          child: Text(
            _currentGroup?.groupName ?? "Group",
            style: AppTextStyles.black16_600,
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(12.0),
            bottomRight: Radius.circular(12.0),
          ),
        ),
      ),
      body: SafeArea(
        bottom: Platform.isAndroid,
        child: Stack(
          children: [
            Column(
              children: [
                if (_isLoadingMore)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 15.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                // if (_isEditing)
                //   Container(
                //     color: Colors.grey[100],
                //     padding: const EdgeInsets.all(8.0),
                //     child: Row(
                //       children: [
                //         Expanded(
                //           child: TextField(
                //             controller: _editController,
                //             autofocus: true,
                //             decoration: InputDecoration(
                //               hintText: 'Edit your message',
                //               border: OutlineInputBorder(
                //                 borderRadius: BorderRadius.circular(20),
                //               ),
                //               contentPadding: const EdgeInsets.symmetric(
                //                 horizontal: 16,
                //                 vertical: 12,
                //               ),
                //             ),
                //           ),
                //         ),
                //         IconButton(
                //           icon: const Icon(Icons.close, color: Colors.red),
                //           onPressed: _cancelEditing,
                //         ),
                //         IconButton(
                //           icon: const Icon(Icons.check, color: Colors.green),
                //           onPressed: () => _saveEditedMessage,
                //         ),
                //       ],
                //     ),
                //   ),
                Expanded(
                  child: _isLoading
                      ? const ShimmerMessageList()
                      : messages.isEmpty
                          ? const NoChatConversation()
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(10),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final msg = messages[index];
                                final isAgent =
                                    msg.senderId == widget.agentEmail;
                                // Stable per message, not per build. Allocating
                                // a fresh GlobalKey here every frame forced the
                                // element tree to reparent every visible row.
                                final globalKey =
                                    _messageKeys[msg] ??= GlobalKey();
                                String? dateHeader;
                                if (index == 0 ||
                                    !ChatUtils().isSameDay(
                                        messages[index - 1].timestamp,
                                        msg.timestamp)) {
                                  dateHeader = ChatUtils()
                                      .formatDateHeader(msg.timestamp);
                                }
                                return Container(
                                  key: globalKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (dateHeader != null)
                                        DateHeader(date: dateHeader),
                                      if (msg.type == 'media')
                                        ImageMessageBubble(
                                          imageUrl: msg.mediaUrl!,
                                          isMe: isAgent,
                                          timestamp: ChatUtils()
                                              .formatTimestamp(msg.timestamp
                                                  .toIso8601String()),
                                          isDeleted: msg.isDeleted,
                                          onLongPress: isAgent
                                              ? () =>
                                                  _showMessageOptionsBottomSheet(
                                                      context, msg.messageId)
                                              : null,
                                        )
                                      else if (msg.type == 'document')
                                        DocumentMessageBubble(
                                          documentUrl: msg.mediaUrl!,
                                          isMe: isAgent,
                                          timestamp: ChatUtils()
                                              .formatTimestamp(msg.timestamp
                                                  .toIso8601String()),
                                          isDeleted: msg.isDeleted,
                                          onLongPress: isAgent
                                              ? () =>
                                                  _showMessageOptionsBottomSheet(
                                                      context, msg.messageId)
                                              : null,
                                        )
                                      else if (msg.type == 'voice')
                                        VoiceMessageBubble(
                                          voiceUrl: msg.mediaUrl!,
                                          isMe: isAgent,
                                          timestamp: ChatUtils()
                                              .formatTimestamp(msg.timestamp
                                                  .toIso8601String()),
                                          isDeleted: msg.isDeleted,
                                          onLongPress: isAgent
                                              ? () =>
                                                  _showMessageOptionsBottomSheet(
                                                      context, msg.messageId)
                                              : null,
                                        )
                                      else
                                        GroupMessageBubble(
                                          message: msg,
                                          isMe: isAgent,
                                          referencedMessage: msg.replyTo != null
                                              ? messages
                                                      .where((element) =>
                                                          element.messageId ==
                                                          msg.replyTo)
                                                      .isNotEmpty
                                                  ? messages.firstWhere(
                                                      (element) =>
                                                          element.messageId ==
                                                          msg.replyTo)
                                                  : null
                                              : null,
                                          onLongPress: isAgent
                                              ? () =>
                                                  _showMessageOptionsBottomSheet(
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
                    replyToSender: _replyToMessage?.senderName,
                    replyToText: _replyToMessage?.message,
                    onCancelReply: _cancelReply,
                    onSend: () =>
                        _sendGroupMessage(messageText: _chatController.text),
                    onSendImage: () => _pickAndSendImage(ImageSource.gallery),
                    onSendDocument: _pickAndSendDocument,
                    onSendImageByCamera: () =>
                        _pickAndSendImage(ImageSource.camera),
                    onSendVoice:
                        _isRecording ? _stopRecording : _startRecording,
                    isRecording: _isRecording,
                    recordedSeconds: _recordedSeconds,
                    onSendForm: () {},
                    onShareProduct: () {},
                    showFormAndProduct: false,
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _isAtBottom,
              builder: (context, atBottom, _) {
                if (atBottom) return const SizedBox.shrink();
                return Positioned(
                  bottom: 100,
                  right: 10,
                  child: FloatingActionButton(
                    onPressed: _scrollToBottom,
                    mini: true,
                    child: const Icon(Icons.arrow_downward_rounded),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- Show Message Options Bottom Sheet ---
  void _showMessageOptionsBottomSheet(BuildContext context, String messageId,
      {String? textToCopy, String? currentMessage}) {
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
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Message'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditMessageDialog(messageId, currentMessage ?? "");
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete Message'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(messageId);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
