import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_initicon/flutter_initicon.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:hive/hive.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/services/s3_upload_service.dart';
import 'package:kkpchatapp/core/services/socket_service.dart';
import 'package:kkpchatapp/core/utils/chat_utils.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/models/chat_message_model.dart';
import 'package:kkpchatapp/data/models/product_model.dart';
import 'package:kkpchatapp/data/repositories/chat_reopsitory.dart';
import 'package:kkpchatapp/logic/agent/agent_chat_provider.dart';
import 'package:kkpchatapp/data/repositories/product_repository.dart';
import 'package:kkpchatapp/logic/agent/chat_refresh_provider.dart';
import 'package:kkpchatapp/main.dart';
import 'package:kkpchatapp/presentation/common/chat/call_provider.dart';
import 'package:kkpchatapp/presentation/common/chat/transfer_agent_screen.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/call_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/chat_input_field.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/date_header.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/deleted_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/document_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/image_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/swipe_to_reply.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/no_chat_conversation.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/product_bottom_sheet.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/product_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/shimmer_message_list.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/voice_message_bubble.dart';
import 'package:kkpchatapp/presentation/customer/screen/customer_product_description_page.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:kkpchatapp/logic/agent/inquiry_provider.dart';
import 'package:kkpchatapp/presentation/marketing/screen/agent_inquiry_forms_screen.dart';

class AgentChatScreen extends StatefulWidget {
  final String? customerName;
  final String? agentName;
  final String customerEmail;
  final String? agentEmail;
  final bool? isAccountDeleted;
  final GlobalKey<NavigatorState> navigatorKey;

  /// false when this customer's agentId no longer matches the logged-in agent —
  /// i.e. the customer was transferred to another agent. Chat is read-only.
  final bool canMessage;

  const AgentChatScreen({
    super.key,
    this.customerName,
    this.agentName,
    required this.customerEmail,
    this.agentEmail,
    this.isAccountDeleted = false,
    required this.navigatorKey,
    this.canMessage = true,
  });

  @override
  State<AgentChatScreen> createState() => _AgentChatScreenState();
}

class _AgentChatScreenState extends State<AgentChatScreen>
    with WidgetsBindingObserver {
  final _chatController = TextEditingController();
  final SocketService _socketService = SocketService(navigatorKey);
  final S3UploadService _s3uploadService = S3UploadService();
  final FlutterSoundRecorder _recorder =
      FlutterSoundRecorder(logLevel: Level.nothing);
  final _productRepository = ProductRepository();

  // All message state lives in the provider.
  late final AgentChatProvider _provider;
  ChatMessageModel? _replyToMessage;

  bool _isRecording = false;
  int _recordedSeconds = 0;
  Timer? _timer;
  String? userRole;

  // ValueNotifiers so scroll / date-header changes never rebuild the ListView.
  final ValueNotifier<bool> _showDateHeader = ValueNotifier(false);
  final ValueNotifier<String?> _currentTopDate = ValueNotifier(null);

  Timer? _dateHeaderTimer;

  final Map<String, GlobalKey> _globalKeys = {};

  ScrollController get _scrollController => _provider.scrollController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchUserRole();

    _provider = AgentChatProvider(
      agentEmail: widget.agentEmail!,
      customerEmail: widget.customerEmail,
    );

    _socketService.setChatPageState(
        isOpen: true, customerId: widget.customerEmail);

    _socketService.onReceiveMessage(_handleIncomingMessage);
    _socketService.onMessageDeleted(_handleMessageDeleted);
    _socketService.onChatStatus(_handleChatStatus);
    _socketService.onMessagesReadUpTo(_handleMessagesReadUpTo);

    _initializeRecorder();

    unawaited(_loadMessages());

    WidgetsBinding.instance.addPostFrameCallback((_) => _emitChatOpened());

    _scrollController.addListener(_handleScroll);
    _scrollController.addListener(_checkIfAtBottom);
    _resetMessageCount();
  }

  Future<void> _resetMessageCount() async {
    final boxNameWithCount = '${widget.agentEmail}${widget.customerEmail}count';
    final box = await Hive.openBox<int>(boxNameWithCount);
    await box.put('count', 0);
  }

  Future<void> _loadMessages() async {
    await _provider.load();
    if (!mounted) return;
    _provider.jumpToBottom();
  }

  Future<void> _saveLastMessageTime() async {
    if (widget.agentEmail == null) return;
    final timeBox = await Hive.openBox<String>(
        '${widget.agentEmail}${widget.customerEmail}lastMessageTime');
    await timeBox.put('lastMessageTime', DateTime.now().toIso8601String());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chatController.dispose();
    _scrollController.removeListener(_handleScroll);
    _scrollController.removeListener(_checkIfAtBottom);
    _recorder.closeRecorder();
    _timer?.cancel();
    _dateHeaderTimer?.cancel();
    _showDateHeader.dispose();
    _currentTopDate.dispose();
    _provider.dispose();
    _socketService.sendChatClosed(
      customerEmail: widget.customerEmail,
      agentEmail: widget.agentEmail,
      role: 'agent',
    );
    _socketService.setChatPageState(isOpen: false);
    super.dispose();
  }

  @override
  void deactivate() {
    // _socketService.sendChatClosed(
    //   customerEmail: widget.customerEmail,
    //   agentEmail: widget.agentEmail,
    //   role: 'agent',
    // );
    _socketService.setChatPageState(isOpen: false);
    super.deactivate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _socketService.setChatPageState(isOpen: false);
      _socketService.sendChatClosed(
          agentEmail: widget.agentEmail,
          customerEmail: widget.customerEmail,
          role: "agent");
    } else if (state == AppLifecycleState.resumed) {
      // _socketService.toggleChatPageOpen(true);
      _socketService.setChatPageState(
        isOpen: true,
        customerId: widget.customerEmail,
      );
      // Scroll to bottom when the app is resumed
      _provider.scrollToBottom();
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
      _provider.scrollToBottom();
    }
  }

  void _emitChatOpened() {
    final msgs = _provider.messages;
    final lastTs = msgs.isNotEmpty
        ? msgs.last.timestamp.toIso8601String()
        : DateTime.now().toIso8601String();
    _socketService.sendChatOpened(
      customerEmail: widget.customerEmail,
      agentEmail: widget.agentEmail,
      role: 'agent',
      lastMessageTimestamp: lastTs,
    );
    _socketService.sendMarkAsReadUpTo(
      customerEmail: widget.customerEmail,
      agentEmail: widget.agentEmail,
      role: 'agent',
      lastMessageTimestamp: DateTime.now().toIso8601String(),
    );
  }

  void _handleChatStatus(Map<String, dynamic> data) {
    final status = data['status'];
    final lastMessageTimestampStr = data['lastMessageTimestamp'];
    if (status == 'opened' && lastMessageTimestampStr != null) {
      final ts = DateTime.tryParse(lastMessageTimestampStr);
      if (ts != null) {
        LocalDbHelper.saveReceiverOnChatPageStatus(true);
        _provider.markReadUpToTimestamp(ts);
      }
    } else if (status == 'closed') {
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

  void _showFloatingDateHeader() {
    _showDateHeader.value = true;
    _dateHeaderTimer?.cancel();
    _dateHeaderTimer = Timer(const Duration(seconds: 1), () {
      _showDateHeader.value = false;
    });
  }

  void _hideFloatingDateHeader() {
    _dateHeaderTimer?.cancel();
    _showDateHeader.value = false;
  }

  void _handleScroll() {
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      _showFloatingDateHeader();
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      _hideFloatingDateHeader();
    }

    if (_scrollController.position.atEdge &&
        _scrollController.position.pixels == 0) {
      _provider.loadMore();
    }

    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      final firstVisibleIndex = _getFirstVisibleIndex();
      final msgs = _provider.messages;
      if (firstVisibleIndex != null && firstVisibleIndex < msgs.length) {
        final newDate =
            ChatUtils().formatDateHeader(msgs[firstVisibleIndex].timestamp);
        if (_currentTopDate.value != newDate) _currentTopDate.value = newDate;
      }
    }
  }

  int? _getFirstVisibleIndex() {
    final msgs = _provider.messages;
    for (int i = 0; i < msgs.length; i++) {
      final msg = msgs[i];
      final msgKey =
          msg.messageId ?? 'ts:${msg.timestamp.millisecondsSinceEpoch}';
      final ctx = _globalKeys[msgKey]?.currentContext;
      if (ctx != null) {
        final box = ctx.findRenderObject() as RenderBox?;
        if (box != null) {
          final pos = box.localToGlobal(Offset.zero);
          if (pos.dy >= 0) return i;
        }
      }
    }
    return null;
  }

  void _checkIfAtBottom() {
    _provider.updateScrollPosition();
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    if (data['type'] == "product") {
      _socketService.updateLastMessage(data["senderId"], "shared product");
    } else {
      _socketService.updateLastMessage(data['senderId'], data['message']);
    }
    _provider.addIncoming(data);
    _saveLastMessageTime();
  }

  void _setReplyToMessage(ChatMessageModel message) {
    setState(() {
      _replyToMessage = message;
    });
  }

  void _cancelReply() {
    if (_replyToMessage == null) return;
    setState(() {
      _replyToMessage = null;
    });
  }

  void _handleMessageDeleted(String messageId) {
    _provider.markDeleted(messageId);
    _socketService.updateLastMessage(widget.customerEmail, "message deleted");
  }

  void _sendMessage({
    required String messageText,
    String? type = 'text',
    String? mediaUrl,
  }) {
    if (messageText.trim().isEmpty && mediaUrl == null) return;
    final currentTime = DateTime.now();
    // Generate a unique message ID
    final messageId = ChatUtils().generateMessageId();
    // Set the receiverIsOnChatPage to false when the app is paused or inactive
    final isReceiverOnChatPage = LocalDbHelper.getReceiverOnChatPageStatus();
    final message = ChatMessageModel(
      message: messageText,
      timestamp: currentTime,
      sender: widget.agentEmail!,
      type: type,
      mediaUrl: mediaUrl,
      messageId: messageId,
      isDeleted: false,
      read: isReceiverOnChatPage,
      referenceId: _replyToMessage?.messageId,
    );

    _provider.addSent(message);
    _provider.persistMessage(message);

    _socketService.sendMessage(
      targetEmail: widget.customerEmail,
      message: messageText,
      senderEmail: widget.agentEmail!,
      senderName: widget.agentName ?? "agent",
      type: type ?? 'text',
      mediaUrl: mediaUrl,
      form: null,
      timestamp: currentTime.toIso8601String(),
      messageId: messageId,
      read: isReceiverOnChatPage ?? false,
      referenceId: _replyToMessage?.messageId,
    );

    _chatController.clear();
    _cancelReply();
    _saveLastMessageTime();
    Provider.of<ChatRefreshProvider>(context, listen: false).markNeedsRefresh();
  }

  void _addTemporaryMessage(String messageText) {
    _provider.addOptimistic(messageText, widget.agentEmail!);
  }

  void _sendProductMessage(Product product) {
    // Convert the product object to a JSON string
    final productJson = jsonEncode(product.toCreateJson());

    _sendMessage(
      messageText: productJson,
      type: 'product',
    );
  }

  void _showMessageOptionsBottomSheet(BuildContext context, String messageId,
      {String? textToCopy, bool isMedia = false}) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Choose what to do :",
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
              if (textToCopy !=
                  null) // Only show the copy option if textToCopy is not null
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
                title: const Text(
                  'Unsend Message',
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
    _socketService.deleteMessage(
        messageId, widget.agentEmail!, widget.customerEmail);
    _provider.markDeleted(messageId);
    _socketService.updateLastMessage(widget.customerEmail, "message deleted");
  }

  // Instant jump — used when opening the chat so there is no visible scroll
  // animation. The user simply sees the bottom of the conversation.
  // Smooth animated scroll — used only for new incoming/sent messages so the
  // user sees where the new message appeared.
  void _scrollToBottom() {
    _provider.scrollToBottom();
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

  Future<void> _pickAndSendImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      // Add a temporary message
      _addTemporaryMessage("Sending image...");

      final File imageFile = File(pickedFile.path);
      final imageUrl = await _s3uploadService.uploadFile(imageFile);

      if (imageUrl != null) {
        _provider.removeOptimistic("Sending image...");
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
        _provider.removeOptimistic("Sending document...");
        _sendMessage(
            messageText: "document", type: 'document', mediaUrl: documentUrl);
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

  String _replyPreviewText(ChatMessageModel? message) {
    if (message == null) return '';
    if (message.isDeleted) return 'This message was deleted';
    if (message.type == 'media') return 'Photo';
    if (message.type == 'voice') return 'Voice message';
    if (message.type == 'document') return 'Document';
    if (message.type == 'call') return 'Call';
    if (message.type == 'product') return 'Product';
    return message.message ?? '';
  }

  String? _replyPreviewImageUrl(ChatMessageModel? message) {
    if (message?.type != 'media') return null;
    return message?.mediaUrl;
  }

  void _handleImageLoaded() {
    if (_provider.shouldAutoScrollForNewMessage) {
      _provider.scrollToBottom();
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
            Expanded(
              child: Text(
                widget.customerName ?? '',
                style: AppTextStyles.black12_700,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
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
            onPressed: () async {
              final callProvider = context.read<CallProvider>();

              final channelName =
                  sha256.convert(utf8.encode(widget.agentEmail!)).toString();
              final uid = Utils().generateIntUidFromEmail(widget.agentEmail!);
              final callId = Uuid().v4();
              final timestamp = DateTime.now();

              debugPrint("📞 Generated UID for agent (caller): $uid");

              // 1. 🔁 Send outgoing call signal
              _socketService.sendAgoraCall(
                targetId: widget.customerEmail,
                channelName: channelName,
                callerId: widget.agentEmail!,
                callerName: widget.agentName!,
                callId: callId,
                timestamp: timestamp.toIso8601String(),
              );

              // 2. 🚀 Start call via Provider
              await callProvider.startNewCall(
                channelName: channelName,
                remoteUserName: widget.customerName!,
                uid: uid,
                callId: callId,
                isCaller: true,
                targetUserId: widget.customerEmail,
              );

              // 3. ⏳ Wait for call to complete and message to be returned
              // This is done via callProvider.callDetailsMessage after call ends
              void handleCallMessage(ChatMessageModel message) {
                if (!mounted) {
                  return;
                }
                _provider.addSent(message);
                _provider.persistMessage(message);
              }

              // 4. ✅ Listen once for callDetailsMessage change
              late final VoidCallback subscription;
              subscription = () {
                final message = callProvider.callDetailsMessage;
                if (message != null) {
                  handleCallMessage(message);
                  callProvider
                      .removeListener(subscription); // Remove after first call
                }
              };

              callProvider.addListener(subscription);
            },
            icon: const Icon(Icons.call_outlined, color: Colors.black),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider(
                    create: (_) => InquiryProvider(ChatRepository()),
                    child: AgentInquiryFormsScreen(
                      customerEmail: widget.customerEmail,
                      customerName: widget.customerName ?? 'Customer',
                    ),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.assignment_outlined, color: Colors.black),
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
                child: ListenableBuilder(
                  listenable: _provider,
                  builder: (context, _) {
                    if (!_provider.isInitialized) return ShimmerMessageList();
                    final messages = _provider.messages;
                    if (messages.isEmpty) return NoChatConversation();
                    return Column(
                      children: [
                        if (_provider.isLoadingMore)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: CircularProgressIndicator(),
                          ),
                        Expanded(
                            child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(10),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            final isAgent = msg.sender == widget.agentEmail;
                            final msgKey = msg.messageId ??
                                'ts:${msg.timestamp.millisecondsSinceEpoch}';
                            final globalKey = _globalKeys.putIfAbsent(
                                msgKey, () => GlobalKey());
                            final referencedMatches = msg.referenceId != null
                                ? messages.where((element) =>
                                    element.messageId == msg.referenceId)
                                : const Iterable<ChatMessageModel>.empty();
                            final ChatMessageModel? referencedMessage =
                                referencedMatches.isNotEmpty
                                    ? referencedMatches.first
                                    : null;
                            String? dateHeader;
                            if (index == 0 ||
                                !ChatUtils().isSameDay(
                                    messages[index - 1].timestamp,
                                    msg.timestamp)) {
                              dateHeader =
                                  ChatUtils().formatDateHeader(msg.timestamp);
                            }
                            return SwipeToReply(
                              onReply: () => _setReplyToMessage(msg),
                              child: Container(
                                key: globalKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (dateHeader != null)
                                      DateHeader(date: dateHeader),
                                    if (msg.type == 'media')
                                      ImageMessageBubble(
                                        read: msg.read,
                                        imageUrl: msg.mediaUrl!,
                                        isMe: msg.sender == widget.agentEmail,
                                        timestamp: ChatUtils().formatTimestamp(
                                            msg.timestamp.toIso8601String()),
                                        isDeleted: msg.isDeleted,
                                        referencedMessage: referencedMessage,
                                        referencedSenderLabel:
                                            referencedMessage?.sender,
                                        onImageLoaded: _handleImageLoaded,
                                        onLongPress: isAgent
                                            ? () =>
                                                _showMessageOptionsBottomSheet(
                                                    context, msg.messageId!)
                                            : null,
                                      )
                                    else if (msg.type == 'document')
                                      DocumentMessageBubble(
                                        documentUrl: msg.mediaUrl!,
                                        isMe: msg.sender == widget.agentEmail,
                                        timestamp: ChatUtils().formatTimestamp(
                                            msg.timestamp.toIso8601String()),
                                        isDeleted: msg.isDeleted,
                                        onLongPress: isAgent
                                            ? () =>
                                                _showMessageOptionsBottomSheet(
                                                    context, msg.messageId!)
                                            : null,
                                      )
                                    else if (msg.type == 'voice')
                                      VoiceMessageBubble(
                                        voiceUrl: msg.mediaUrl!,
                                        isMe: msg.sender == widget.agentEmail,
                                        timestamp: ChatUtils().formatTimestamp(
                                            msg.timestamp.toIso8601String()),
                                        isDeleted: msg.isDeleted,
                                        onLongPress: isAgent
                                            ? () =>
                                                _showMessageOptionsBottomSheet(
                                                    context, msg.messageId!)
                                            : null,
                                      )
                                    else if (msg.type == 'call')
                                      CallMessageBubble(
                                        isMe: msg.sender == widget.agentEmail,
                                        timestamp: ChatUtils().formatTimestamp(
                                            msg.timestamp.toIso8601String()),
                                        callStatus: msg.callStatus ?? "",
                                        callDuration: msg.callDuration ?? '',
                                      )
                                    else if (msg.type == 'product')
                                      (msg.message != null &&
                                              msg.message!.isNotEmpty)
                                          ? ProductMessageBubble(
                                              productJson: msg.message!,
                                              isMe: msg.sender ==
                                                  widget.agentEmail,
                                              timestamp: ChatUtils()
                                                  .formatTimestamp(msg.timestamp
                                                      .toIso8601String()),
                                              isDeleted: msg.isDeleted,
                                              onLongPress: isAgent
                                                  ? () =>
                                                      _showMessageOptionsBottomSheet(
                                                          context,
                                                          msg.messageId!)
                                                  : null,
                                              onTap: () {
                                                final productMap =
                                                    jsonDecode(msg.message!);
                                                final product =
                                                    Product.fromJson(
                                                        productMap);
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          CustomerProductDescriptionPage(
                                                              product: product),
                                                    ));
                                              },
                                            )
                                          : DeletedMessageBubble(
                                              isMe: msg.sender ==
                                                  widget.agentEmail,
                                              timestamp: ChatUtils()
                                                  .formatTimestamp(msg.timestamp
                                                      .toIso8601String()),
                                            )
                                    else
                                      MessageBubble(
                                        message: msg,
                                        isMe: msg.sender == widget.agentEmail,
                                        referencedMessage: referencedMessage,
                                        referencedSenderLabel:
                                            referencedMessage?.sender,
                                        onLongPress: isAgent
                                            ? () =>
                                                _showMessageOptionsBottomSheet(
                                                    context, msg.messageId!,
                                                    textToCopy: msg.message!)
                                            : null,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        )), // Expanded + ListView.builder
                      ],
                    ); // Column
                  },
                ),
              ),
              if (widget.isAccountDeleted == false && widget.canMessage)
                SafeArea(
                  minimum: const EdgeInsets.only(bottom: 1),
                  child: ChatInputField(
                    controller: _chatController,
                    showInquiryForm: false,
                    replyToSender: _replyToMessage?.sender,
                    replyToText: _replyPreviewText(_replyToMessage),
                    replyPreviewImageUrl:
                        _replyPreviewImageUrl(_replyToMessage),
                    onCancelReply: _cancelReply,
                    onSend: () =>
                        _sendMessage(messageText: _chatController.text),
                    onSendImage: () {
                      _pickAndSendImage(ImageSource.gallery);
                    },
                    onSendForm: () {},
                    onSendDocument: _pickAndSendDocument,
                    onSendImageByCamera: () {
                      _pickAndSendImage(ImageSource.camera);
                    },
                    onShareProduct: () => _showProductsBottomSheet(context),
                    onSendVoice:
                        _isRecording ? _stopRecording : _startRecording,
                    isRecording: _isRecording,
                    recordedSeconds: _recordedSeconds,
                  ),
                ),
              if (!widget.canMessage)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  color: const Color(0xFFF0F4FF),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.swap_horiz_rounded,
                          size: 16, color: Color(0xFF6B7AED)),
                      const SizedBox(width: 6),
                      Text(
                        'This conversation has been transferred',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
            ],
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _provider.isAtBottom,
            builder: (context, atBottom, _) {
              if (atBottom) return const SizedBox.shrink();
              return Positioned(
                bottom: 80,
                right: 16,
                child: FloatingActionButton(
                  onPressed: _scrollToBottom,
                  mini: true,
                  child: const Icon(Icons.arrow_downward_rounded),
                ),
              );
            },
          ),
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: ListenableBuilder(
              listenable: Listenable.merge([_currentTopDate, _showDateHeader]),
              builder: (context, _) {
                final date = _currentTopDate.value;
                if (date == null || !_showDateHeader.value) {
                  return const SizedBox.shrink();
                }
                return Center(child: DateHeader(date: date));
              },
            ),
          ),
        ],
      ),
    );
  }
}
