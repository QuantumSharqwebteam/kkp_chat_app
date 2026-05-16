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
import 'package:kkpchatapp/presentation/marketing/screen/group_description.dart';
import 'package:permission_handler/permission_handler.dart';
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

class _InternalChatScreenState extends State<InternalChatScreen> with WidgetsBindingObserver {
  bool _isLoading = false;
  bool _isLoadingMore = false;
  final _chatController = TextEditingController();
  final SocketService _socketService = SocketService(navigatorKey);
  final ChatService _chatService = ChatService();
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
  String? _nextCursor;
  final Set<String> _loadedMessageIds = {};
  final Set<String> fetchedCursors = {};
  // bool _isEditing = false;
  // String _editingMessageId = '';
  final _editController = TextEditingController();
  int _currentPage = 1;
  final Set<int> _fetchedPages = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _socketService.setGroupChatPageState(true);
    _socketService.onGroupMessageReceived(_handleIncomingGroupMessage);
    _socketService.onGroupMessageDeleted(_handleGroupMessageDeleted);
    _socketService.onGroupMessageEdited(_handleGroupMessageEdited);
    _initializeRecorder();
    _loadInitialGroupMessages();
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

  // --- Load Initial Messages ---
  Future<void> _loadInitialGroupMessages() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch from API
      final result = await _chatService.fetchGroupMessages(limit: 20, groupId: widget.groupId!);
      final List<GroupMessageModel> fetchedMessages = result['messages'];
      _nextCursor = result['nextCursor'];

      // 2. Load from local storage
      final localMessages = await LocalDbHelper.getGroupMessages();

      // 3. Merge API and local messages
      final mergedMessages = _mergeMessages(localMessages, fetchedMessages);

      setState(() {
        messages = mergedMessages;
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _isLoading = false;
      });

      // 4. Save merged messages to local storage
      for (var msg in messages) {
        await LocalDbHelper.saveGroupMessage(msg);
      }
      _scrollToBottom();
    } catch (e) {
      debugPrint("Error loading messages: $e");
      // Fallback: Load from local storage if API fails
      final localMessages = await LocalDbHelper.getGroupMessages();
      if (localMessages.isNotEmpty) {
        setState(() {
          messages = _removeDuplicates(localMessages);
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          _isLoading = false;
        });
      }
    } finally {
      _scrollToBottom();
    }
  }

  // --- Merge Local and API Messages ---
  List<GroupMessageModel> _mergeMessages(
      List<GroupMessageModel> localMessages, List<GroupMessageModel> apiMessages) {
    final merged = [...localMessages];
    for (var apiMsg in apiMessages) {
      final index = merged.indexWhere((msg) => msg.messageId == apiMsg.messageId);
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
    if (_isLoadingMore || _nextCursor == null || _fetchedPages.contains(_currentPage)) return;
    _fetchedPages.add(_currentPage);
    setState(() => _isLoadingMore = true);

    try {
      final result = await _chatService.fetchGroupMessages(
        limit: 20,
        groupId: widget.groupId!,
        before: _nextCursor,
      );
      final List<GroupMessageModel> olderMessages = result['messages'];
      _nextCursor = result['nextCursor'];

      if (olderMessages.isNotEmpty) {
        final uniqueMessages = _removeDuplicates(olderMessages);
        setState(() {
          messages.insertAll(0, uniqueMessages);
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        });
        for (var msg in uniqueMessages) {
          await LocalDbHelper.saveGroupMessage(msg);
        }
      }
    } catch (e) {
      debugPrint("Error loading more messages: $e");
    } finally {
      setState(() => _isLoadingMore = false);
    }
  }

  // --- Remove Duplicates ---
  List<GroupMessageModel> _removeDuplicates(List<GroupMessageModel> messagesList) {
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
    debugPrint("Group message received: ${data.toString()}");
    final message = GroupMessageModel.fromApiJson(data);
    if (!_loadedMessageIds.contains(message.messageId)) {
      _loadedMessageIds.add(message.messageId);
      setState(() {
        messages.add(message);
      });
      LocalDbHelper.saveGroupMessage(message);
      _scrollToBottom();
    }
  }

// --- Handle Message Deletion ---
  void _handleGroupMessageDeleted(Map<String, dynamic> data) {
    debugPrint("🗑️ Group message deleted: ${data.toString()}");
    final messageId = data['messageId'];
    setState(() {
      final index = messages.indexWhere((msg) => msg.messageId == messageId);
      if (index != -1) {
        messages[index] = messages[index].copyWith(
          isDeleted: true,
          message: "This message was deleted",
        );
        // Save the updated message to local storage
        LocalDbHelper.updateGroupMessage(messages[index]);
      }
    });
  }

  // --- Delete Message ---
  void _deleteMessage(String messageId) {
    _socketService.deleteGroupMessage(
        messageId: messageId, senderId: widget.agentEmail, groupId: widget.groupId!);
    // Update the local message state to reflect deletion
    setState(() {
      final index = messages.indexWhere((msg) => msg.messageId == messageId);
      if (index != -1) {
        messages[index] = messages[index].copyWith(
          isDeleted: true,
          message: "This message was deleted",
        );
        // Save the updated message to local storage
        LocalDbHelper.updateGroupMessage(messages[index]);
      }
    });
    // Notify other users about the deletion
    _socketService.updateLastMessage(widget.agentEmail, "message deleted");
  }

// --- Handle Message Edit ---
  void _handleGroupMessageEdited(Map<String, dynamic> data) {
    debugPrint("✏️ Group message edited: ${data.toString()}");
    final messageId = data['messageId'];
    final newMessage = data['newMessage'];
    setState(() {
      final index = messages.indexWhere((msg) => msg.messageId == messageId);
      if (index != -1) {
        messages[index] = messages[index].copyWith(
          message: newMessage,
          isEdited: true,
        );
        // Save the updated message to local storage
        LocalDbHelper.updateGroupMessage(messages[index]);
      }
    });
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
    // Update the local message state to reflect the edit
    setState(() {
      final index = messages.indexWhere((msg) => msg.messageId == messageId);
      if (index != -1) {
        messages[index] = messages[index].copyWith(
          message: newMessage,
          isEdited: true,
        );
        // Save the updated message to local storage
        LocalDbHelper.updateGroupMessage(messages[index]);
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

  // --- Send Message ---
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
        groupId: widget.groupId ?? "");
    LocalDbHelper.saveGroupMessage(message);
    _chatController.clear();
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
        _sendGroupMessage(messageText: "image", type: 'media', mediaUrl: imageUrl);
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
        _sendGroupMessage(messageText: "document", type: 'document', mediaUrl: documentUrl);
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
      _currentPage++;
      _loadMoreGroupMessages();
    }
  }

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
        title: GestureDetector(
          onTap: () {
            if (widget.group != null) {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                return GroupDescriptionScreen(
                    groupId: widget.groupId ?? "Na", group: widget.group!);
              }));
            }
          },
          child: Text(
            widget.group?.groupName ?? "Group",
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
                                          timestamp: ChatUtils()
                                              .formatTimestamp(msg.timestamp.toIso8601String()),
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
                                          timestamp: ChatUtils()
                                              .formatTimestamp(msg.timestamp.toIso8601String()),
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
                                          timestamp: ChatUtils()
                                              .formatTimestamp(msg.timestamp.toIso8601String()),
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
                    showFormAndProduct: false,
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
