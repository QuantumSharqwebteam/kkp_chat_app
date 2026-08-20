import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_initicon/flutter_initicon.dart';
import 'package:intl/intl.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/services/s3_upload_service.dart';
import 'package:kkpchatapp/core/services/socket_service.dart';
import 'package:kkpchatapp/core/utils/chat_utils.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/models/chat_message_model.dart';
import 'package:kkpchatapp/data/models/product_model.dart';
import 'package:kkpchatapp/data/repositories/product_repository.dart';
import 'package:kkpchatapp/logic/customer/customer_chat_provider.dart';
import 'package:kkpchatapp/presentation/common/chat/call_provider.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/call_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/date_header.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/deleted_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/document_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/image_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/chat_input_field.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/swipe_to_reply.dart';
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

class _CustomerChatScreenState extends State<CustomerChatScreen>
    with WidgetsBindingObserver {
  final _chatController = TextEditingController();
  late final SocketService _socketService;
  final S3UploadService _s3uploadService = S3UploadService();
  final FlutterSoundRecorder _recorder =
      FlutterSoundRecorder(logLevel: Level.nothing);
  final _productRepository = ProductRepository();

  // Message state lives in the provider — screen only owns UI state.
  late final CustomerChatProvider _provider;

  bool _isRecording = false;
  int _recordedSeconds = 0;
  Timer? _timer;
  String? userRole;

  // ValueNotifiers: updates to these never trigger a full-screen rebuild.
  final ValueNotifier<bool> _showDateHeader = ValueNotifier(false);
  final ValueNotifier<String?> _currentTopDate = ValueNotifier(null);

  Timer? _dateHeaderTimer;

  // Keyed by message identity so Flutter reuses render objects across rebuilds.
  final Map<String, GlobalKey> _globalKeys = {};
  ChatMessageModel? _replyToMessage;

  ScrollController get _scrollController => _provider.scrollController;

  void _log(String message) {
    debugPrint(
      '🧭 [CustomerChatTrace][Screen][${widget.customerEmail}] $message',
    );
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
    final dir = _scrollController.position.userScrollDirection;
    if (dir == ScrollDirection.forward) _showFloatingDateHeader();
    if (dir == ScrollDirection.reverse) _hideFloatingDateHeader();

    if (_scrollController.position.atEdge &&
        _scrollController.position.pixels == 0) {
      _loadMoreMessages();
    }

    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      final idx = _getFirstVisibleIndex();
      if (idx != null && idx < _provider.messages.length) {
        final newDate =
            ChatUtils().formatDateHeader(_provider.messages[idx].timestamp);
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
        if (box != null && box.localToGlobal(Offset.zero).dy >= 0) return i;
      }
    }
    return null;
  }

  void _checkIfAtBottom() {
    _provider.updateScrollPosition();
  }

  Future<void> _loadMoreMessages() async {
    if (_provider.isLoadingMore) return;
    await _provider.loadMore();
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
    super.initState();
    _log('initState:start agent=${widget.agentEmail}');
    _fetchUserRole();

    _provider = CustomerChatProvider(
      customerEmail: widget.customerEmail!,
      agentEmail: widget.agentEmail ?? '',
    );

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

    unawaited(_loadMessages());

    _initializeRecorder();
    _scrollController.addListener(_handleScroll);
    _scrollController.addListener(_checkIfAtBottom);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _emitChatOpened();
    });

    _log('initState:done');
  }

  Future<void> _loadMessages() async {
    _log('loadMessages:start');
    await _provider.load();
    if (!mounted) return;
    _provider.jumpToBottom();
    unawaited(_provider.resetUnreadCount());
    _log('loadMessages:done');
  }

  @override
  void dispose() {
    _log('dispose:start');
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
      customerEmail: widget.customerEmail!,
      role: 'user',
    );
    _socketService.toggleChatPageOpen(false);
    _log('dispose:done');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _socketService.sendChatClosed(
        customerEmail: widget.customerEmail!,
        role: 'user',
      );
      _socketService.setChatPageState(isOpen: false);
    } else if (state == AppLifecycleState.resumed) {
      _socketService.setChatPageState(
        isOpen: true,
        customerId:
            widget.customerEmail, // This is targetId in incoming message
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
      _provider.scrollToBottom();
    }
  }

  void _emitChatOpened() {
    final msgs = _provider.messages;
    final lastTs = msgs.isNotEmpty
        ? msgs.last.timestamp.toIso8601String()
        : DateTime.now().toIso8601String();
    _log('emitChatOpened messages=${msgs.length} lastTs=$lastTs');
    _socketService.sendChatOpened(
      customerEmail: widget.customerEmail!,
      role: 'user',
      lastMessageTimestamp: lastTs,
    );
    _socketService.sendMarkAsReadUpTo(
      customerEmail: widget.customerEmail!,
      role: 'user',
      lastMessageTimestamp: DateTime.now().toIso8601String(),
    );
  }

  void _handleChatStatus(Map<String, dynamic> data) {
    _log('handleChatStatus data=$data');
    final status = data['status'];
    final lastMessageTimestampStr = data['lastMessageTimestamp'] as String?;
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

  void _handleMessagesReadUpTo(Map<String, dynamic> data) {}

  void _handleIncomingMessage(Map<String, dynamic> data) {
    _log('handleIncomingMessage data=$data');
    _provider.addIncoming(data);
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
      referenceId: _replyToMessage?.messageId,
    );

    _provider.addSent(message);

    final String name = LocalDbHelper.getProfile()?.name ?? '';
    _socketService.sendMessage(
      message: messageText,
      senderEmail: widget.customerEmail!,
      senderName: name,
      type: type,
      mediaUrl: mediaUrl,
      timestamp: currentTime.toIso8601String(),
      messageId: messageId,
      read: isReceiverOnChatPage ?? false,
      referenceId: _replyToMessage?.messageId,
    );
    _provider.persistMessage(message);
    _chatController.clear();
    _cancelReply();
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8),
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
    _provider.markDeleted(messageId);
    final msg = _provider.messages.firstWhere(
      (m) => m.messageId == messageId,
      orElse: () =>
          ChatMessageModel(message: '', timestamp: DateTime.now(), sender: ''),
    );
    if (msg.messageId != null) _provider.persistMessage(msg);
  }

  void _scrollToBottom() {
    _provider.scrollToBottom();
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

  void _addTemporaryMessage(String messageText) {
    _provider.addOptimistic(messageText, widget.customerEmail ?? '');
  }

  void _sendProductMessage(Product product) {
    // Convert the product object to a JSON string
    final productJson = jsonEncode(product.toCreateJson());

    _sendMessage(
      messageText: productJson,
      type: 'product',
    );
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
          messageText: "document",
          type: 'document',
          mediaUrl: documentUrl,
        );
      }
    }
  }

  String formatTimestamp(dynamic timestamp) {
    if (timestamp == null) {
      return DateFormat('hh:mm a').format(DateTime.now());
    }

    try {
      final dateTime = timestamp is DateTime
          ? timestamp
          : DateTime.parse(timestamp.toString());
      return DateFormat('hh:mm a').format(dateTime);
    } catch (e) {
      return DateFormat('hh:mm a').format(DateTime.now());
    }
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

                final uid =
                    Utils().generateIntUidFromEmail(widget.customerEmail!);
                final timestamp = DateTime.now();
                final callId = Uuid().v4();

                // Unique channel name per call
                final rawChannel = '${widget.customerEmail}_$callId';
                final channelName =
                    sha256.convert(utf8.encode(rawChannel)).toString();

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
                  await _chatStorageService.saveMessage(
                      message, widget.customerEmail!);

                  if (!mounted) return;
                  setState(() {
                    messages.add(message);
                    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
                  });

                  _scrollToBottom();
                }

                // 4. Check if call details are already available (fast call end)
                final existingMessage = callProvider.callDetailsMessage;
                if (existingMessage != null) {
                  handleCallMessage(existingMessage);
                } else {
                  // Listen for it
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
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: ListenableBuilder(
                    listenable: _provider.messageListVersion,
                    builder: (context, _) {
                      _log(
                        'messageBuilder rebuild version='
                        '${_provider.messageListVersion.value} '
                        'initialized=${_provider.isInitialized} '
                        'messages=${_provider.messages.length} '
                        'loadingMore=${_provider.isLoadingMore}',
                      );
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
                                final isCustomer =
                                    msg.sender == widget.customerEmail;
                                final msgKey = msg.messageId ??
                                    'ts:${msg.timestamp.millisecondsSinceEpoch}';
                                final globalKey = _globalKeys.putIfAbsent(
                                    msgKey, () => GlobalKey());
                                final referencedMatches = msg.referenceId !=
                                        null
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
                                          read: msg.read,
                                          imageUrl: msg.mediaUrl!,
                                          isMe: msg.sender ==
                                              widget.customerEmail,
                                          timestamp:
                                              formatTimestamp(msg.timestamp),
                                          isDeleted: msg.isDeleted,
                                          onLongPress: isCustomer
                                              ? () =>
                                                  _showMessageOptionBottomSheet(
                                                    context,
                                                    msg.messageId!,
                                                  )
                                              : null,
                                        )
                                      else if (msg.type == 'document')
                                        DocumentMessageBubble(
                                          documentUrl: msg.mediaUrl!,
                                          isMe: msg.sender ==
                                              widget.customerEmail,
                                          timestamp:
                                              formatTimestamp(msg.timestamp),
                                          isDeleted: msg.isDeleted,
                                          onLongPress: isCustomer
                                              ? () =>
                                                  _showMessageOptionBottomSheet(
                                                    context,
                                                    msg.messageId!,
                                                  )
                                              : null,
                                        )
                                      else if (msg.type == 'voice')
                                        VoiceMessageBubble(
                                          voiceUrl: msg.mediaUrl!,
                                          isMe: msg.sender ==
                                              widget.customerEmail,
                                          timestamp:
                                              formatTimestamp(msg.timestamp),
                                          isDeleted: msg.isDeleted,
                                          onLongPress: isCustomer
                                              ? () =>
                                                  _showMessageOptionBottomSheet(
                                                    context,
                                                    msg.messageId!,
                                                  )
                                              : null,
                                        )
                                      else if (msg.type == 'call')
                                        CallMessageBubble(
                                          isMe: msg.sender == widget.agentEmail,
                                          timestamp: formatTimestamp(
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
                                                    widget.customerEmail,
                                                timestamp:
                                                    ChatUtils().formatTimestamp(
                                                  msg.timestamp
                                                      .toIso8601String(),
                                                ),
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
                                                        product: product,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                isDeleted: msg.isDeleted,
                                                onLongPress: isCustomer
                                                    ? () =>
                                                        _showMessageOptionBottomSheet(
                                                          context,
                                                          msg.messageId!,
                                                        )
                                                    : null,
                                              )
                                            : DeletedMessageBubble(
                                                isMe: msg.sender ==
                                                    widget.customerEmail,
                                                timestamp:
                                                    ChatUtils().formatTimestamp(
                                                  msg.timestamp
                                                      .toIso8601String(),
                                                ),
                                              )
                                      else
                                        MessageBubble(
                                          message: msg,
                                          isMe: msg.sender ==
                                              widget.customerEmail,
                                          onLongPress: isCustomer
                                              ? () =>
                                                  _showMessageOptionBottomSheet(
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
                        ],
                      );
                    },
                  ),
                ),
                SafeArea(
                  minimum: const EdgeInsets.only(bottom: 5),
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
                    onSendImageByCamera: () {
                      _pickAndSendImage(ImageSource.camera);
                    },
                    onSendForm: () {},
                    onSendDocument: _pickAndSendDocument,
                    onShareProduct: () => _showProductsBottomSheet(context),
                    onSendVoice:
                        _isRecording ? _stopRecording : _startRecording,
                    isRecording: _isRecording,
                    recordedSeconds: _recordedSeconds,
                  ),
                ),
              ],
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _provider.isAtBottom,
              builder: (context, atBottom, _) {
                if (atBottom) return const SizedBox.shrink();
                return Positioned(
                  bottom: 120,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: _scrollToBottom,
                    mini: true,
                    backgroundColor: AppColors.blue0056FB.withAlpha(50),
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
                listenable:
                    Listenable.merge([_currentTopDate, _showDateHeader]),
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
      ),
    );
  }
}
