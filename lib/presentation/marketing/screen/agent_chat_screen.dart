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
  Timer? _dateHeaderTimer;
  bool _keyboardVisible = false;

  // ValueNotifiers: updates to these never trigger a full-screen rebuild.
  final ValueNotifier<bool> _showDateHeader = ValueNotifier(false);
  final ValueNotifier<String?> _currentTopDate = ValueNotifier(null);

  // Keyed by message identity so Flutter reuses render objects across rebuilds.
  // An Expando holds its keys weakly, so entries for messages that fall out of
  // the list are collected automatically — a Map here grew for the life of the
  // screen and had to be walked on every scroll notification.
  final Expando<GlobalKey> _itemKeys = Expando<GlobalKey>();

  /// Last known first-visible row, used to bound the visible-index scan.
  int _lastVisibleIndex = 0;

  ScrollController get _scrollController => _provider.scrollController;

  // ← FIX: any non-customer sender = agent side (agent head, assigned agent, etc.)
  bool _isFromAgentSide(String? sender) {
    return sender != null && sender != widget.customerEmail;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _provider = AgentChatProvider(
      agentEmail: widget.agentEmail!,
      customerEmail: widget.customerEmail,
    );

    _socketService.setChatPageState(
        isOpen: true, customerId: widget.customerEmail);

    _attachSocketHandlers();
    _provider.attachConnectivity();

    unawaited(_loadMessages());

    _initializeRecorder();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _emitChatOpened());

    // One listener: two listeners meant every scroll notification ran the
    // handler chain twice.
    _scrollController.addListener(_onScroll);
    unawaited(_resetMessageCount());
  }

  void _attachSocketHandlers() {
    _socketService.onReceiveMessage(_handleIncomingMessage);
    _socketService.onMessageDeleted(_handleMessageDeleted);
    _socketService.onChatStatus(_handleChatStatus);
    _socketService.onMessagesReadUpTo(_handleMessagesReadUpTo);
  }

  Future<void> _resetMessageCount() async {
    final boxNameWithCount = '${widget.agentEmail}${widget.customerEmail}count';
    final box = await Hive.openBox<int>(boxNameWithCount);
    await box.put('count', 0);
    // The legacy box above is never incremented; the socket increments
    // unreadCountsBox_<agentEmail>. Clearing only the former left the badge
    // stuck whenever the chat was entered by auto-navigation.
    await LocalDbHelper.clearUnreadCount(
        widget.agentEmail!, widget.customerEmail);
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
    _scrollController.removeListener(_onScroll);
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
      _socketService.setChatPageState(
        isOpen: true,
        customerId: widget.customerEmail,
      );
      unawaited(_handleResumed());
    }
  }

  /// While the chat page was flagged closed the socket wrote incoming messages
  /// straight to Hive without telling anyone. Merge them back in before
  /// reporting our last-seen timestamp, or we report a stale one.
  Future<void> _handleResumed() async {
    await _provider.handleAppResumed();
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToBottom();
      _emitChatOpened();
    });
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;
    final bottomInset = View.of(context).viewInsets.bottom;
    final visible = bottomInset > 0.0;
    if (visible == _keyboardVisible) return;
    _keyboardVisible = visible;
    // Only on the hidden -> visible transition. This used to fire on every
    // keyboard animation frame, each scheduling its own retry chain.
    if (visible) _scrollToBottom();
  }

  void _updateMessagesReadStatus(DateTime lastMessageTimestamp) {
    _provider.markReadUpToTimestamp(lastMessageTimestamp);
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

  /// The socket dispatches chatStatus / messagesReadUpTo on "a chat page is
  /// open" alone, without matching the customer — so events belonging to a
  /// different conversation arrive here. Fails open when the payload omits
  /// customerEmail, preserving the previous behaviour.
  bool _isForThisConversation(Map<String, dynamic> data) {
    final email = data['customerEmail']?.toString();
    return email == null || email == widget.customerEmail;
  }

  void _handleChatStatus(Map<String, dynamic> data) {
    if (!mounted || !_isForThisConversation(data)) return;
    final status = data['status'];
    final lastMessageTimestampStr = data['lastMessageTimestamp'];
    if (status == 'opened' && lastMessageTimestampStr != null) {
      final lastMessageTimestamp = DateTime.tryParse(lastMessageTimestampStr);
      if (lastMessageTimestamp != null) {
        LocalDbHelper.saveReceiverOnChatPageStatus(true);
        _updateMessagesReadStatus(lastMessageTimestamp);
      }
    } else if (status == 'closed') {
      LocalDbHelper.saveReceiverOnChatPageStatus(false);
    }
  }

  void _handleMessagesReadUpTo(Map<String, dynamic> data) {
    if (!mounted || !_isForThisConversation(data)) return;
    final raw = data['lastMessageTimestamp'] ?? data['timestamp'];
    if (raw == null) return;
    final ts = DateTime.tryParse(raw.toString());
    if (ts != null) _updateMessagesReadStatus(ts);
  }

  Future<void> _initializeRecorder() async {
    await _recorder.openRecorder();
    await Permission.microphone.request();
  }

  void _showFloatingDateHeader() {
    if (!_showDateHeader.value) {
      _showDateHeader.value = true;
      // The header just appeared — make sure it carries the right date rather
      // than whatever was last computed.
      _updateTopDate();
    }
    _dateHeaderTimer?.cancel();
    _dateHeaderTimer = Timer(const Duration(seconds: 1), () {
      _showDateHeader.value = false;
    });
  }

  void _hideFloatingDateHeader() {
    _dateHeaderTimer?.cancel();
    _showDateHeader.value = false;
  }

  void _onScroll() {
    _provider.updateScrollPosition();

    final direction = _scrollController.position.userScrollDirection;
    if (direction == ScrollDirection.forward) {
      _showFloatingDateHeader();
    } else if (direction == ScrollDirection.reverse) {
      _hideFloatingDateHeader();
    }

    if (_scrollController.position.atEdge &&
        _scrollController.position.pixels == 0) {
      unawaited(_provider.loadMore());
    }

    // Skip the visible-index scan entirely while the header is hidden — that is
    // the whole downward-fling case, which used to do this work per frame.
    if (_showDateHeader.value) _updateTopDate();
  }

  void _updateTopDate() {
    final messages = _provider.messages;
    final index = _getFirstVisibleIndex();
    if (index == null || index >= messages.length) return;
    final newDate = ChatUtils().formatDateHeader(messages[index].timestamp);
    if (_currentTopDate.value != newDate) {
      _currentTopDate.value = newDate;
    }
  }

  /// Index of the first row whose top edge is on screen.
  ///
  /// Scans a window around the previous answer first — only a handful of rows
  /// are mounted at a time, so walking the whole list (as this used to) was
  /// O(messages) per scroll notification. Falls back to the exact full scan on
  /// a miss, so the result is identical to the unbounded version.
  int? _getFirstVisibleIndex() {
    final msgs = _provider.messages;
    if (msgs.isEmpty) return null;

    const window = 40;
    final start = (_lastVisibleIndex - window).clamp(0, msgs.length);
    final end = (_lastVisibleIndex + window).clamp(0, msgs.length);

    final windowed = _firstVisibleInRange(msgs, start, end);
    if (windowed != null) {
      _lastVisibleIndex = windowed;
      return windowed;
    }

    final full = _firstVisibleInRange(msgs, 0, msgs.length);
    if (full != null) _lastVisibleIndex = full;
    return full;
  }

  int? _firstVisibleInRange(List<ChatMessageModel> msgs, int start, int end) {
    for (int i = start; i < end; i++) {
      final ctx = _itemKeys[msgs[i]]?.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) continue;
      if (box.localToGlobal(Offset.zero).dy >= 0) return i;
    }
    return null;
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    if (!mounted) return;
    debugPrint("message received: ${data.toString()}");
    if (data['type'] == "product") {
      _socketService.updateLastMessage(data["senderId"], "shared product");
    } else {
      _socketService.updateLastMessage(data['senderId'], data['message']);
    }

    _provider.addIncoming(data);

    unawaited(_saveLastMessageTime());
    Provider.of<ChatRefreshProvider>(context, listen: false).markNeedsRefresh();
  }

  void _handleMessageDeleted(String messageId) {
    if (!mounted) return;
    // messageDeleted is not filtered by customer, so gate the chat-list preview
    // rewrite on the message actually belonging to this conversation.
    if (!_provider.markDeleted(messageId)) return;
    _socketService.updateLastMessage(widget.customerEmail, "message deleted");
  }

  void _sendMessage({
    required String messageText,
    String? type = 'text',
    String? mediaUrl,
  }) {
    if (messageText.trim().isEmpty && mediaUrl == null) return;
    final currentTime = DateTime.now();
    final messageId = ChatUtils().generateMessageId();
    final isReceiverOnChatPage = LocalDbHelper.getReceiverOnChatPageStatus();
    final referenceId = _replyToMessage?.messageId;
    final message = ChatMessageModel(
      message: messageText,
      timestamp: currentTime,
      sender: widget.agentEmail!,
      type: type,
      mediaUrl: mediaUrl,
      messageId: messageId,
      isDeleted: false,
      read: isReceiverOnChatPage,
      referenceId: referenceId,
    );

    _provider.addSent(message);

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
      referenceId: referenceId,
    );

    _provider.persistMessage(message);

    _chatController.clear();
    _cancelReply();
    _saveLastMessageTime();
    Provider.of<ChatRefreshProvider>(context, listen: false).markNeedsRefresh();
  }

  void _sendProductMessage(Product product) {
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
              if (textToCopy != null)
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

    if (!_provider.markDeleted(messageId)) return;
    _socketService.updateLastMessage(widget.customerEmail, "message deleted");
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

    if (pickedFile == null) return;

    final placeholder =
        _provider.addOptimistic("Sending image...", widget.agentEmail!);
    String? imageUrl;
    try {
      imageUrl = await _s3uploadService.uploadFile(File(pickedFile.path));
    } catch (e) {
      debugPrint('[AgentChat] image upload failed: $e');
    } finally {
      // Always clear the placeholder — a failed upload used to leave
      // "Sending image..." in the list forever.
      _provider.removePlaceholder(placeholder);
    }

    if (!mounted || imageUrl == null) return;
    _sendMessage(messageText: "image", type: 'media', mediaUrl: imageUrl);
  }

  Future<void> _pickAndSendDocument() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
    );

    if (result == null) return;

    final placeholder =
        _provider.addOptimistic("Sending document...", widget.agentEmail!);
    String? documentUrl;
    try {
      final PlatformFile file = result.files.first;
      documentUrl = await _s3uploadService.uploadDocument(File(file.path!));
    } catch (e) {
      debugPrint('[AgentChat] document upload failed: $e');
    } finally {
      _provider.removePlaceholder(placeholder);
    }

    if (!mounted || documentUrl == null) return;
    _sendMessage(
        messageText: "document", type: 'document', mediaUrl: documentUrl);
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

  /// Label shown on top of a reply preview strip.
  String? _senderLabel(ChatMessageModel? message) {
    if (message == null) return null;
    return _isFromAgentSide(message.sender)
        ? 'You'
        : (widget.customerName ?? message.sender ?? '');
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

              _socketService.sendAgoraCall(
                targetId: widget.customerEmail,
                channelName: channelName,
                callerId: widget.agentEmail!,
                callerName: widget.agentName!,
                callId: callId,
                timestamp: timestamp.toIso8601String(),
              );

              await callProvider.startNewCall(
                channelName: channelName,
                remoteUserName: widget.customerName!,
                uid: uid,
                callId: callId,
                isCaller: true,
                targetUserId: widget.customerEmail,
              );

              void handleCallMessage(ChatMessageModel message) {
                if (!mounted) return;
                // callId dedup lives in the provider now, alongside the same
                // set used when deduplicating cached and fetched call rows.
                _provider.addCallMessage(message);
              }

              final existingMessage = callProvider.callDetailsMessage;
              if (existingMessage != null) {
                handleCallMessage(existingMessage);
              } else {
                late final VoidCallback subscription;
                subscription = () {
                  final message = callProvider.callDetailsMessage;
                  if (message != null) {
                    handleCallMessage(message);
                    callProvider.removeListener(subscription);
                  }
                };
                callProvider.addListener(subscription);
              }
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
        shape: const RoundedRectangleBorder(
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
              // The pagination spinner is its own listenable so showing it
              // does not rebuild the entire message list.
              ValueListenableBuilder<bool>(
                valueListenable: _provider.isLoadingMoreNotifier,
                builder: (context, loadingMore, _) {
                  if (!loadingMore) return const SizedBox.shrink();
                  return const Padding(
                    padding: EdgeInsets.only(top: 15.0),
                    child: CircularProgressIndicator(),
                  );
                },
              ),
              Expanded(
                // Listens to the message-list version rather than the whole
                // provider, so unrelated provider notifications are free.
                child: ListenableBuilder(
                  listenable: _provider.messageListVersion,
                  builder: (context, _) {
                    if (!_provider.isInitialized) {
                      return const ShimmerMessageList();
                    }
                    final messages = _provider.messages;
                    if (messages.isEmpty) return const NoChatConversation();
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(10),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        // ← FIX: for display — any agent's message on right side
                        final isMe = _isFromAgentSide(msg.sender);
                        // ← FIX: for actions — only THIS agent can delete their own messages
                        final isMyMessage = msg.sender == widget.agentEmail;
                        final globalKey = _itemKeys[msg] ??= GlobalKey();
                        final referencedMessage =
                            _provider.messageById(msg.referenceId);
                        String? dateHeader;

                        if (index == 0 ||
                            !ChatUtils().isSameDay(
                                messages[index - 1].timestamp, msg.timestamp)) {
                          dateHeader =
                              ChatUtils().formatDateHeader(msg.timestamp);
                        }

                        final Widget content = Container(
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
                                  isMe: isMe,
                                  timestamp: ChatUtils.timeLabel(msg.timestamp),
                                  isDeleted: msg.isDeleted,
                                  onImageLoaded: _handleImageLoaded,
                                  referencedMessage: referencedMessage,
                                  referencedSenderLabel:
                                      _senderLabel(referencedMessage),
                                  onLongPress: isMyMessage
                                      ? () => _showMessageOptionsBottomSheet(
                                          context, msg.messageId!)
                                      : null,
                                )
                              else if (msg.type == 'document')
                                DocumentMessageBubble(
                                  documentUrl: msg.mediaUrl!,
                                  read: msg.read,
                                  isMe: isMe,
                                  timestamp: ChatUtils.timeLabel(msg.timestamp),
                                  isDeleted: msg.isDeleted,
                                  onLongPress: isMyMessage
                                      ? () => _showMessageOptionsBottomSheet(
                                          context, msg.messageId!)
                                      : null,
                                )
                              else if (msg.type == 'voice')
                                VoiceMessageBubble(
                                  voiceUrl: msg.mediaUrl!,
                                  read: msg.read,
                                  isMe: isMe,
                                  timestamp: ChatUtils.timeLabel(msg.timestamp),
                                  isDeleted: msg.isDeleted,
                                  onLongPress: isMyMessage
                                      ? () => _showMessageOptionsBottomSheet(
                                          context, msg.messageId!)
                                      : null,
                                )
                              else if (msg.type == 'call')
                                CallMessageBubble(
                                  isMe: isMe,
                                  timestamp: ChatUtils.timeLabel(msg.timestamp),
                                  callStatus: msg.callStatus ?? "",
                                  callDuration: msg.callDuration ?? '',
                                )
                              else if (msg.type == 'product')
                                (msg.message != null && msg.message!.isNotEmpty)
                                    ? ProductMessageBubble(
                                        productJson: msg.message!,
                                        isMe: isMe,
                                        read: msg.read,
                                        timestamp:
                                            ChatUtils.timeLabel(msg.timestamp),
                                        isDeleted: msg.isDeleted,
                                        onLongPress: isMyMessage
                                            ? () =>
                                                _showMessageOptionsBottomSheet(
                                                    context, msg.messageId!)
                                            : null,
                                        onTap: () {
                                          final productMap =
                                              jsonDecode(msg.message!);
                                          final product =
                                              Product.fromJson(productMap);
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
                                        isMe: isMe,
                                        timestamp:
                                            ChatUtils.timeLabel(msg.timestamp),
                                      )
                              else
                                MessageBubble(
                                  message: msg,
                                  isMe: isMe,
                                  read: msg.read,
                                  referencedMessage: referencedMessage,
                                  referencedSenderLabel:
                                      _senderLabel(referencedMessage),
                                  onLongPress: isMyMessage
                                      ? () => _showMessageOptionsBottomSheet(
                                          context, msg.messageId!,
                                          textToCopy: msg.message!)
                                      : null,
                                ),
                            ],
                          ),
                        );

                        if (!widget.canMessage) return content;
                        return SwipeToReply(
                          onReply: () => _setReplyToMessage(msg),
                          child: content,
                        );
                      },
                    );
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
          // Driven by the provider's notifier instead of setState — crossing
          // the at-bottom threshold used to rebuild the whole screen.
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
