import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_initicon/flutter_initicon.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/services/chat_storage_service.dart';
import 'package:kkpchatapp/core/services/s3_upload_service.dart';
import 'package:kkpchatapp/core/services/socket_service.dart';
import 'package:kkpchatapp/core/utils/chat_utils.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/models/chat_message_model.dart';
import 'package:kkpchatapp/data/models/message_model.dart';
import 'package:kkpchatapp/data/models/product_model.dart';
import 'package:kkpchatapp/data/repositories/chat_reopsitory.dart';
import 'package:kkpchatapp/data/repositories/product_repository.dart';
import 'package:kkpchatapp/logic/customer/customer_home_provider.dart';
import 'package:kkpchatapp/presentation/common/chat/call_provider.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/call_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/date_header.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/deleted_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/document_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/image_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/chat_input_field.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/product_bottom_sheet.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/product_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/shimmer_message_list.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/no_chat_conversation.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/voice_message_bubble.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:kkpchatapp/presentation/customer/screen/customer_product_description_page.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../l10n/generated/app_localizations.dart';

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

class _CustomerChatScreenState extends State<CustomerChatScreen> with WidgetsBindingObserver {
  final _chatController = TextEditingController();
  late final SocketService _socketService;
  final S3UploadService _s3uploadService = S3UploadService();
  final ScrollController _scrollController = ScrollController();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder(logLevel: Level.nothing);
  final ChatStorageService _chatStorageService = ChatStorageService();
  final ChatRepository _chatRepository = ChatRepository();
  bool _isInitialized = false;
  final _productRepository = ProductRepository();

  List<ChatMessageModel> messages = [];
  bool _isRecording = false;
  int _recordedSeconds = 0;
  Timer? _timer;
  String? userRole;
  final bool _isFetching = false;
  bool _isLoadingMore = false;
  bool _isAtBottom = true; // Track if the user is at the bottom of the list
  final Set<String> _loadedMessageIds = {};
  final Set<String> _loadedCallIds = {};
  Timer? _dateHeaderTimer;
  bool _showDateHeader = false;

  final ValueNotifier<String?> _currentTopDate = ValueNotifier(null);

  final Map<Key, GlobalKey> _messageKeys = {};

  Future<void> _loadPreviousMessages() async {
    final boxName = widget.customerEmail!;

    // ── Step 1: Cache-first — show instantly, no shimmer ──────────────────
    final bool boxExists = await Hive.boxExists(boxName);
    if (boxExists) {
      final cachedMessages = await _chatStorageService.getCustomerMessages(boxName);
      if (cachedMessages.isNotEmpty) {
        final deduped = _removeDuplicates(cachedMessages);
        if (mounted) {
          setState(() {
            messages = deduped;
            messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
            _isInitialized = true;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());
        }
      }
    }

    // No cache found — show empty state right away so no shimmer is visible
    // while the API is in flight. The API may later populate messages below.
    if (!_isInitialized && mounted) {
      setState(() => _isInitialized = true);
    }

    // ── Step 2: Silent background API sync ────────────────────────────────
    try {
      final List<MessageModel> fetchedMessages = await _chatRepository.fetchCustomerMessages(
        customerEmail: widget.customerEmail!,
        limit: 20,
      );
      final chatMessages = fetchedMessages.map(_chatMessageFromModel).toList();
      final newMessages = _removeDuplicates(chatMessages);

      if (!boxExists && chatMessages.isNotEmpty) {
        await _chatStorageService.saveMessages(chatMessages, boxName);
      } else if (newMessages.isNotEmpty) {
        await _chatStorageService.saveMessages(newMessages, boxName);
      }

      if (mounted) {
        final wasAtBottom = _isAtBottom;
        setState(() {
          if (!_isInitialized) {
            messages = chatMessages;
          } else {
            messages.addAll(newMessages);
          }
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          _isInitialized = true;
        });
        if (!boxExists || wasAtBottom) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());
        }
      }
    } catch (e) {
      debugPrint('[CustomerChat] Background API sync failed: $e');
    } finally {
      if (mounted && !_isInitialized) {
        setState(() => _isInitialized = true);
      }
    }

    // ── Step 3: Read-status sync — skip when no messages exist ───────────
    if (messages.isEmpty || !mounted) return;
    try {
      final DateTime? lastMessageTimestamp =
          await _chatRepository.fetchUserLastTimestamp(widget.customerEmail!);
      if (lastMessageTimestamp != null && mounted) {
        _updateMessagesReadStatus(lastMessageTimestamp);
      }
    } catch (e) {
      debugPrint('[CustomerChat] Read-status sync failed: $e');
    }
  }

  Future<void> _fetchMessagesFromAPI(String boxName) async {
    try {
      String? before;
      if (messages.isNotEmpty) {
        before = messages.first.timestamp.toIso8601String();
      }

      final List<MessageModel> fetchedMessages = await _chatRepository.fetchCustomerMessages(
        customerEmail: widget.customerEmail!,
        limit: 20,
        before: before,
      );

      if (fetchedMessages.isEmpty) {
        // No more messages to load
        return;
      }

      // Convert MessageModel to ChatMessageModel
      final chatMessages = fetchedMessages.map(_chatMessageFromModel).toList();

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

  List<ChatMessageModel> _removeDuplicates(List<ChatMessageModel> messagesList) {
    return messagesList.where((message) {
      if (message.type == 'call') {
        // Use callId for call messages
        if (message.callId == null || _loadedCallIds.contains(message.callId)) {
          return false;
        } else {
          _loadedCallIds.add(message.callId!);
          return true;
        }
      } else {
        // Use messageId for all other messages
        if (message.messageId == null || _loadedMessageIds.contains(message.messageId)) {
          return false;
        } else {
          _loadedMessageIds.add(message.messageId!);
          return true;
        }
      }
    }).toList();
  }

  ChatMessageModel _chatMessageFromModel(MessageModel messageJson) {
    return ChatMessageModel(
      message: messageJson.message ?? '',
      timestamp: DateTime.parse(
        messageJson.timestamp ?? DateTime.now().toIso8601String(),
      ),
      sender: messageJson.senderId!,
      type: messageJson.type,
      mediaUrl: messageJson.mediaUrl,
      callDuration: messageJson.callDuration,
      callStatus: messageJson.callStatus,
      callId: messageJson.callId,
      messageId: messageJson.messageId,
      isDeleted: messageJson.isDeleted ?? false,
      read: messageJson.read,
    );
  }

  void _showFloatingDateHeader() {
    setState(() {
      _showDateHeader = true;
    });

    // Cancel existing timer if user is still scrolling
    _dateHeaderTimer?.cancel();

    // Start new timer to hide after 1 second
    _dateHeaderTimer = Timer(Duration(seconds: 1), () {
      setState(() {
        _showDateHeader = false;
      });
    });
  }

  void _hideFloatingDateHeader() {
    // Optionally hide immediately when scrolling down
    setState(() {
      _showDateHeader = false;
    });

    // Cancel the timer to avoid it interfering
    _dateHeaderTimer?.cancel();
  }

  void _handleScroll() {
    if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      _showFloatingDateHeader();
    }

    // Hide header when scrolling down (optional, but could improve UX)
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      _hideFloatingDateHeader();
    }

    // Check if at the top edge, then load more messages
    if (_scrollController.position.atEdge && _scrollController.position.pixels == 0) {
      _loadMoreMessages();
    }

    // Find index of first visible message and update date
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      final firstVisibleIndex = _getFirstVisibleIndex();
      if (firstVisibleIndex != null && firstVisibleIndex < messages.length) {
        final message = messages[firstVisibleIndex];
        final newDate = ChatUtils().formatDateHeader(message.timestamp);
        if (_currentTopDate.value != newDate) {
          _currentTopDate.value = newDate;
        }
      }
    }

    // Emit markAsReadUpTo when user scrolls or reaches bottom
    // if (_scrollController.position.atEdge &&
    //     _scrollController.position.pixels != 0) {
    //   if (messages.isNotEmpty) {
    //     final lastVisibleMessageTimestamp =
    //         messages.last.timestamp.toIso8601String();
    //     _socketService.sendMarkAsReadUpTo(
    //       customerEmail: widget.customerEmail!,
    //       role: 'user',
    //       lastMessageTimestamp: lastVisibleMessageTimestamp,
    //     );
    //   }
    // }
  }

  int? _getFirstVisibleIndex() {
    for (int i = 0; i < messages.length; i++) {
      final key = ValueKey('chat-msg-$i');
      final context = _messageKeys[key]?.currentContext;
      if (context != null) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          final pos = box.localToGlobal(Offset.zero);
          if (pos.dy >= 0) {
            return i;
          }
        }
      }
    }
    return null;
  }

  void _checkIfAtBottom() {
    if (_scrollController.position.atEdge) {
      bool isBottom =
          _scrollController.position.pixels == _scrollController.position.maxScrollExtent;
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

    _socketService.setChatPageState(
      isOpen: true,
      customerId: widget.customerEmail,
    );

    _socketService.onReceiveMessage(_handleIncomingMessage);
    _socketService.onMessageDeleted(_handleMessageDeleted);
    _socketService.onChatStatus(_handleChatStatus);
    _socketService.onMessagesReadUpTo(_handleMessagesReadUpTo);
    _loadPreviousMessages();
    _initializeRecorder();
    _scrollController.addListener(_handleScroll);
    _scrollController.addListener(_checkIfAtBottom);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _emitChatOpened();
    });

    _resetMessageCount();
  }

  Future<void> _resetMessageCount() async {
    final boxNameWithCount = '${widget.customerEmail}count';
    final box = await Hive.openBox<int>(boxNameWithCount);
    await box.put('count', 0);
    if (mounted) {
      context.read<CustomerHomeProvider>().fetchNotificationCount();
    }
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
    _socketService.sendChatClosed(
      customerEmail: widget.customerEmail!,
      role: 'user',
    );
    _socketService.toggleChatPageOpen(false);
    _dateHeaderTimer?.cancel();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _socketService.sendChatClosed(
        customerEmail: widget.customerEmail!,
        role: 'user',
      );
      _socketService.setChatPageState(isOpen: false);
    } else if (state == AppLifecycleState.resumed) {
      _socketService.setChatPageState(
        isOpen: true,
        customerId: widget.customerEmail, // This is targetId in incoming message
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _emitChatOpened();
      });
    }
  }

  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    final newValue = bottomInset > 0.0;

    if (newValue) {
      // Keyboard is opened
      _scrollToBottom();
    }
  }

  void _updateMessagesReadStatus(DateTime lastMessageTimestamp) {
    if (!mounted) return;
    setState(() {
      for (var message in messages) {
        if (message.timestamp.isBefore(lastMessageTimestamp) ||
            message.timestamp == lastMessageTimestamp) {
          message.read = true;
        }
      }
    });

    // Save the updated messages to local storage
    final boxName = widget.customerEmail!;
    for (var message in messages) {
      if (message.timestamp.isBefore(lastMessageTimestamp) ||
          message.timestamp == lastMessageTimestamp) {
        _chatStorageService.saveMessage(message, boxName);
      }
    }
  }

  void _emitChatOpened() {
    if (messages.isNotEmpty) {
      final lastMessageTimestamp = messages.last.timestamp.toIso8601String();
      _socketService.sendChatOpened(
        customerEmail: widget.customerEmail!,
        role: 'user',
        lastMessageTimestamp: lastMessageTimestamp,
      );
      _socketService.sendMarkAsReadUpTo(
        customerEmail: widget.customerEmail!,
        role: 'user',
        lastMessageTimestamp: DateTime.now().toIso8601String(),
      );
    } else {
      _socketService.sendChatOpened(
        customerEmail: widget.customerEmail!,
        role: 'user',
        lastMessageTimestamp: DateTime.now().toIso8601String(),
      );
      _socketService.sendMarkAsReadUpTo(
        customerEmail: widget.customerEmail!,
        role: 'user',
        lastMessageTimestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  void _handleChatStatus(Map<String, dynamic> data) {
    final status = data['status'];
    final lastMessageTimestampStr = data['lastMessageTimestamp'];
    debugPrint("Chat Status Updated: $status");

    if (status == 'opened' && lastMessageTimestampStr != null) {
      final lastMessageTimestamp = DateTime.tryParse(lastMessageTimestampStr);
      if (lastMessageTimestamp != null) {
        // Set the receiver as on the chat page
        LocalDbHelper.saveReceiverOnChatPageStatus(true);
        // Update the read status of messages
        _updateMessagesReadStatus(lastMessageTimestamp);
      }
    } else if (status == 'closed') {
      // Set the receiver as not on the chat page
      LocalDbHelper.saveReceiverOnChatPageStatus(false);
    }
  }

  void _handleMessagesReadUpTo(Map<String, dynamic> data) {
    // final customerEmail = data['customerEmail'];
    // final lastMessageTimestampStr = data['lastMessageTimestamp'];
    // if (customerEmail == widget.customerEmail &&
    //     lastMessageTimestampStr != null) {
    //   final lastMessageTimestamp = DateTime.tryParse(lastMessageTimestampStr);
    //   if (lastMessageTimestamp != null) {
    //     setState(() {
    //       messages.forEach((message) {
    //         if (message.sender == widget.agentEmail &&
    //             (message.timestamp.isBefore(lastMessageTimestamp) ||
    //                 message.timestamp == lastMessageTimestamp)) {
    //           message.read = true;
    //         }
    //       });
    //     });
    //     // Save updated messages to local database
    //     _saveMessagesToLocalDatabase();
    //   }
    // }
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    debugPrint("Received Message: ${data.toString()}");

    DateTime timestamp;
    try {
      timestamp = DateTime.parse(data["timestamp"]);
    } catch (_) {
      timestamp = DateTime.now();
    }

    final messageId = data['messageId'] as String?;
    final message = ChatMessageModel(
      message: data["message"],
      timestamp: timestamp,
      sender: data["senderId"],
      type: data["type"] ?? "text",
      mediaUrl: data["mediaUrl"],
      callStatus: data["callStatus"],
      callDuration: data["callDuration"],
      callId: data["callId"],
      messageId: messageId,
      isDeleted: data['isDeleted'] ?? false,
      read: data['read'],
    );

    if (!_loadedMessageIds.contains(messageId)) {
      final wasAtBottom = _isAtBottom;
      setState(() {
        messages.add(message);
      });
      if (wasAtBottom) _scrollToBottom();

      _chatStorageService.saveMessage(message, widget.customerEmail!);
      if (messageId != null) {
        _loadedMessageIds.add(messageId);
      }
    }
  }

  void _handleMessageDeleted(String messageId) {
    if (mounted) {
      // Check if the widget is currently mounted
      setState(() {
        final index = messages.indexWhere((message) => message.messageId == messageId);
        if (index != -1) {
          messages[index].isDeleted = true;
          messages[index].message = "This message is deleted";
        }
      });
    }

    // Save the updated message state to local storage

    final boxName = widget.customerEmail!;
    _chatStorageService.saveMessage(
        messages.firstWhere((message) => message.messageId == messageId), boxName);
  }

  void _sendMessage({
    required String messageText,
    String type = 'text',
    String? mediaUrl,
  }) {
    if (messageText.trim().isEmpty && mediaUrl == null) return;

    final currentTime = DateTime.now();
    final messageId = ChatUtils().generateMessageId();
    // Set the receiverIsOnChatPage to false when the app is paused or inactive
    final isReceiverOnChatPage = LocalDbHelper.getReceiverOnChatPageStatus();
    final message = ChatMessageModel(
      message: messageText,
      timestamp: currentTime,
      sender: widget.customerEmail!,
      type: type,
      mediaUrl: mediaUrl,
      messageId: messageId,
      isDeleted: false,
      read: isReceiverOnChatPage,
    );

    if (!_loadedMessageIds.contains(messageId)) {
      setState(() {
        messages.add(message);
        // messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _scrollToBottom();
      });

      final String name = LocalDbHelper.getProfile()?.name ?? '';

      _socketService.sendMessage(
        message: messageText,
        senderEmail: widget.customerEmail!,
        senderName: name,
        type: type,
        mediaUrl: mediaUrl,
        timestamp: currentTime.toIso8601String(), // ✅ Send timestamp
        messageId: messageId,
        read: isReceiverOnChatPage ?? false,
      );

      _chatStorageService.saveMessage(message, widget.customerEmail!);
      _loadedMessageIds.add(messageId);
    }
    _chatController.clear();
  }

  void _showMessageOptionBottomSheet(BuildContext context, String messageId,
      {String? textToCopy, bool isMedia = false}) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.chooseWhatToDo,
                      style: AppTextStyles.grey12_600.copyWith(fontSize: 16),
                    ),
                    IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: Icon(Icons.clear_rounded))
                  ],
                ),
              ),
              if (textToCopy != null) // Only show the copy option if textToCopy is not null
                ListTile(
                  leading: const Icon(Icons.content_copy),
                  title: Text(
                    isMedia ? 'Copy Media URL' : 'Copy Message',
                    style: AppTextStyles.black15_500,
                  ),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: textToCopy));
                    Navigator.pop(context);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: Text(
                  AppLocalizations.of(context)!.unsendMessage,
                  // 'Unsend Message',
                  style: AppTextStyles.black15_500,
                ),
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

  void _deleteMessage(String messageId) {
    _socketService.deleteMessage(messageId, widget.customerEmail!);

    // Update the local message state to reflect deletion
    setState(() {
      final index = messages.indexWhere((message) => message.messageId == messageId);
      if (index != -1) {
        messages[index].isDeleted = true;
        messages[index].message = "This message is deleted";
      }
    });

    // Save the updated message state to local storage

    final boxName = widget.customerEmail!;
    _chatStorageService.saveMessage(
        messages.firstWhere((message) => message.messageId == messageId), boxName);
  }

  void _jumpToBottom() {
    if (_scrollController.hasClients &&
        _scrollController.position.hasContentDimensions) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients &&
          _scrollController.position.hasContentDimensions) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
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
      final voiceUrl = await _s3uploadService.uploadFile(voiceFile, isVoiceMessage: true);
      if (voiceUrl != null) {
        _sendMessage(messageText: "voice", type: 'voice', mediaUrl: voiceUrl);
      }
    }
    setState(() {
      _isRecording = false;
    });
  }

  void _addTemporaryMessage(String messageText) {
    final currentTime = DateTime.now();
    final temporaryMessage = ChatMessageModel(
      message: messageText,
      timestamp: currentTime,
      sender: "",
    );

    setState(() {
      messages.add(temporaryMessage);
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    });

    _scrollToBottom();
  }

  void _sendProductMessage(Product product) {
    // Convert the product object to a JSON string
    final productJson = jsonEncode(product.toCreateJson());

    _sendMessage(
      messageText: productJson,
      type: 'product',
    );
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      // Add a temporary message
      _addTemporaryMessage("Sending image...");

      final File imageFile = File(pickedFile.path);
      final imageUrl = await _s3uploadService.uploadFile(imageFile);
      if (imageUrl != null) {
        // Remove the temporary message
        setState(() {
          messages.removeWhere((message) => message.message == "Sending image...");
        });

        // Send the actual message
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
      // Add a temporary message
      _addTemporaryMessage(
        "Sending document...",
      );

      final PlatformFile file = result.files.first;
      final File documentFile = File(file.path!);
      final documentUrl = await _s3uploadService.uploadDocument(documentFile);
      if (documentUrl != null) {
        // Remove the temporary message
        setState(() {
          messages.removeWhere((message) => message.message == "Sending document...");
        });

        // Send the actual message
        _sendMessage(messageText: "document", type: 'document', mediaUrl: documentUrl);
      }
    }
  }

  void _showProductsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return ProductsBottomSheet(
          productsFuture: _productRepository.getProducts(),
          onProductTap: _sendProductMessage,
        );
      },
    );
  }

  String formatTimestamp(dynamic timestamp) {
    if (timestamp == null) {
      return DateFormat('hh:mm a').format(DateTime.now());
    }

    try {
      final dateTime = timestamp is DateTime ? timestamp : DateTime.parse(timestamp.toString());
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
              Initicon(text: AppLocalizations.of(context)!.agent),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  widget.agentName ?? AppLocalizations.of(context)!.agent,
                  style: AppTextStyles.black14_400,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () async {
                final callProvider = context.read<CallProvider>();

                final uid = Utils().generateIntUidFromEmail(widget.customerEmail!);
                final timestamp = DateTime.now();
                final callId = Uuid().v4();

                // Unique channel name per call
                final rawChannel = '${widget.customerEmail}_$callId';
                final channelName = sha256.convert(utf8.encode(rawChannel)).toString();

                debugPrint("📞 Customer (caller) UID: $uid");
                debugPrint("📞 Generated Channel: $channelName");

                // 1. 🔁 Send outgoing call request
                _socketService.sendAgoraCall(
                  channelName: channelName,
                  callerId: widget.customerEmail!,
                  callerName: widget.customerName!,
                  callId: callId,
                  timestamp: timestamp.toIso8601String(),
                );

                // 2. 🚀 Start call via provider
                await callProvider.startNewCall(
                  channelName: channelName,
                  remoteUserName: widget.agentName!,
                  uid: uid,
                  callId: callId,
                  isCaller: true,
                  targetUserId: widget.agentEmail,
                );

                // 3. ⏳ Wait for call message to be available
                void handleCallMessage(ChatMessageModel message) async {
                  await _chatStorageService.saveMessage(message, widget.customerEmail!);

                  if (!mounted) return;
                  setState(() {
                    messages.add(message);
                    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
                  });

                  _scrollToBottom();
                }

                // 4. ✅ Listen once to callDetailsMessage
                late final VoidCallback subscription;
                subscription = () {
                  final message = callProvider.callDetailsMessage;
                  if (message != null) {
                    handleCallMessage(message);
                    callProvider.removeListener(subscription); // Only once
                  }
                };

                callProvider.addListener(subscription);
              },
              icon: const Icon(Icons.call_outlined, color: Colors.black),
            ),
          ],
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
                  child: !_isInitialized
                      ? ShimmerMessageList()
                      : messages.isEmpty
                          ? NoChatConversation()
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(10),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final msg = messages[index];
                                final isCustomer = msg.sender == widget.customerEmail;
                                final valueKey = ValueKey('chat-msg-$index');
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
                                          read: msg.read,
                                          imageUrl: msg.mediaUrl!,
                                          isMe: msg.sender == widget.customerEmail,
                                          timestamp: formatTimestamp(msg.timestamp),
                                          isDeleted: msg.isDeleted,
                                          onLongPress: isCustomer
                                              ? () => _showMessageOptionBottomSheet(
                                                    context,
                                                    msg.messageId!,
                                                  )
                                              : null,
                                        )
                                      else if (msg.type == 'document')
                                        DocumentMessageBubble(
                                          documentUrl: msg.mediaUrl!,
                                          isMe: msg.sender == widget.customerEmail,
                                          timestamp: formatTimestamp(msg.timestamp),
                                          isDeleted: msg.isDeleted,
                                          onLongPress: isCustomer
                                              ? () => _showMessageOptionBottomSheet(
                                                    context,
                                                    msg.messageId!,
                                                  )
                                              : null,
                                        )
                                      else if (msg.type == 'voice')
                                        VoiceMessageBubble(
                                          voiceUrl: msg.mediaUrl!,
                                          isMe: msg.sender == widget.customerEmail,
                                          timestamp: formatTimestamp(msg.timestamp),
                                          isDeleted: msg.isDeleted,
                                          onLongPress: isCustomer
                                              ? () => _showMessageOptionBottomSheet(
                                                    context,
                                                    msg.messageId!,
                                                  )
                                              : null,
                                        )
                                      else if (msg.type == 'call')
                                        CallMessageBubble(
                                          isMe: msg.sender == widget.agentEmail,
                                          timestamp:
                                              formatTimestamp(msg.timestamp.toIso8601String()),
                                          callStatus: msg.callStatus ?? "",
                                          callDuration: msg.callDuration ?? '',
                                        )
                                      else if (msg.type == 'product')
                                        (msg.message != null && msg.message!.isNotEmpty)
                                            ? ProductMessageBubble(
                                                productJson: msg.message!,
                                                isMe: msg.sender == widget.customerEmail,
                                                timestamp: ChatUtils().formatTimestamp(
                                                  msg.timestamp.toIso8601String(),
                                                ),
                                                onTap: () {
                                                  final productMap = jsonDecode(msg.message!);
                                                  final product = Product.fromJson(productMap);

                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          CustomerProductDescriptionPage(
                                                        product: product,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                isDeleted: msg.isDeleted,
                                                onLongPress: isCustomer
                                                    ? () => _showMessageOptionBottomSheet(
                                                          context,
                                                          msg.messageId!,
                                                        )
                                                    : null,
                                              )
                                            : DeletedMessageBubble(
                                                isMe: msg.sender == widget.customerEmail,
                                                timestamp: ChatUtils().formatTimestamp(
                                                  msg.timestamp.toIso8601String(),
                                                ),
                                              )
                                      else
                                        MessageBubble(
                                          message: msg,
                                          isMe: msg.sender == widget.customerEmail,
                                          onLongPress: isCustomer
                                              ? () => _showMessageOptionBottomSheet(
                                                    context,
                                                    msg.messageId!,
                                                    textToCopy: msg.message,
                                                  )
                                              : null,
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),
                SafeArea(
                  minimum: const EdgeInsets.only(bottom: 5),
                  child: ChatInputField(
                    controller: _chatController,
                    showInquiryForm: false,
                    onSend: () => _sendMessage(messageText: _chatController.text),
                    onSendImage: () {
                      _pickAndSendImage(ImageSource.gallery);
                    },
                    onSendImageByCamera: () {
                      _pickAndSendImage(ImageSource.camera);
                    },
                    onSendForm: () {},
                    onSendDocument: _pickAndSendDocument,
                    onShareProduct: () => _showProductsBottomSheet(context),
                    onSendVoice: _isRecording ? _stopRecording : _startRecording,
                    isRecording: _isRecording,
                    recordedSeconds: _recordedSeconds,
                  ),
                ),
              ],
            ),
            if (!_isAtBottom)
              Positioned(
                bottom: 120, // Adjust the position as needed
                right: 16, // Adjust the position as needed
                child: FloatingActionButton(
                  onPressed: _scrollToBottom,
                  mini: true,
                  backgroundColor: AppColors.blue0056FB.withAlpha(50),
                  child: Icon(Icons.arrow_downward_rounded),
                ),
              ),
            Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: ValueListenableBuilder<String?>(
                valueListenable: _currentTopDate,
                builder: (context, date, _) {
                  if (date == null || !_showDateHeader) {
                    return SizedBox.shrink();
                  }
                  return Center(
                    child: DateHeader(date: date),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
