import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_initicon/flutter_initicon.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:hive/hive.dart';
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
import 'package:kkpchatapp/data/models/form_data_model.dart';
import 'package:kkpchatapp/data/repositories/chat_reopsitory.dart';
import 'package:kkpchatapp/data/repositories/product_repository.dart';
import 'package:kkpchatapp/l10n/generated/app_localizations.dart';
import 'package:kkpchatapp/logic/agent/chat_refresh_provider.dart';
import 'package:kkpchatapp/logic/agent/inquiry_provider.dart';
import 'package:kkpchatapp/main.dart';
import 'package:kkpchatapp/presentation/common/chat/call_provider.dart';
import 'package:kkpchatapp/presentation/common/chat/transfer_agent_screen.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/call_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/chat_input_field.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/date_header.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/deleted_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/document_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/fill_form_button.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/form_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/sent_product_form_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/image_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/message_bubble.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/no_chat_conversation.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/product_bottom_sheet.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/product_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/shimmer_message_list.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/voice_message_bubble.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_button.dart';
import 'package:kkpchatapp/presentation/common_widgets/full_screen_loader.dart';
import 'package:kkpchatapp/presentation/customer/screen/customer_product_description_page.dart';
import 'package:kkpchatapp/presentation/marketing/screen/extracted_data_viewer_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:kkpchatapp/core/services/product_data_extraction_service.dart';
import 'package:kkpchatapp/data/repositories/extracted_product_repository.dart';
import 'package:kkpchatapp/data/models/extracted_product_data.dart';
import 'package:kkpchatapp/core/services/logging_service.dart';

class AgentChatScreen extends StatefulWidget {
  final String? customerName;
  final String? agentName;
  final String customerEmail;
  final String? agentEmail;
  final bool? isAccountDeleted;
  final GlobalKey<NavigatorState> navigatorKey;

  const AgentChatScreen({
    super.key,
    this.customerName,
    this.agentName,
    required this.customerEmail,
    this.agentEmail,
    this.isAccountDeleted = false,
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
  final _productRepository = ProductRepository();
  final ProductDataExtractionService _extractionService = ProductDataExtractionService();
  final ExtractedProductRepository _extractedProductRepository = ExtractedProductRepository();
  final LoggingService _logger = LoggingService.instance;

  List<ChatMessageModel> messages = [];
  bool _isRecording = false;
  int _recordedSeconds = 0;
  Timer? _timer;
  String? userRole;
  int _currentPage = 1;
  final bool _isFetching = false;
  final Set<int> _fetchedPages = {}; // Keep track of fetched pages
  bool _isLoadingMore = false; // Show loading indicator when loading more
  final Set<String> _loadedMessageIds = {};
  final Set<String> _loadedCallIds = {};
  bool _isAtBottom = true; // Track if the user is at the bottom of the list
  //bool _isViewOnlyMode = false;
  Timer? _dateHeaderTimer;
  bool _showDateHeader = false;

  final ValueNotifier<String?> _currentTopDate = ValueNotifier(null);

  final Map<Key, GlobalKey> _messageKeys = {};

  bool _showFormNavigationButtons = false;
  int? _currentFormIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchUserRole();
    _socketService.setChatPageState(
        isOpen: true, customerId: widget.customerEmail);

    _socketService.onReceiveMessage(_handleIncomingMessage);
    _socketService.onMessageDeleted(_handleMessageDeleted);
    _socketService.onChatStatus(_handleChatStatus);
    _socketService.onMessagesReadUpTo(_handleMessagesReadUpTo);

    _initializeRecorder();
    _extractionService.initialize();
    _loadPreviousMessages(context);

    // Scroll to bottom when the chat page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _emitChatOpened();
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
    _scrollController.dispose();
    _recorder.closeRecorder();
    _timer?.cancel();
    _scrollController.removeListener(_handleScroll);
    _scrollController.removeListener(_checkIfAtBottom);

    _socketService.sendChatClosed(
      customerEmail: widget.customerEmail,
      agentEmail: widget.agentEmail,
      role: 'agent',
    );

    _socketService.setChatPageState(
      isOpen: false,
    );

    _dateHeaderTimer?.cancel();
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
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
    setState(() {
      // Update the read status of messages up to the lastMessageTimestamp
      for (var message in messages) {
        if (message.timestamp.isBefore(lastMessageTimestamp) ||
            message.timestamp == lastMessageTimestamp) {
          message.read = true;
        }
      }
    });

    // Save the updated messages to local storage
    final boxName = '${widget.agentEmail}${widget.customerEmail}';
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
        customerEmail: widget.customerEmail,
        agentEmail: widget.agentEmail,
        role: 'agent',
        lastMessageTimestamp: lastMessageTimestamp,
      );
      _socketService.sendMarkAsReadUpTo(
        customerEmail: widget.customerEmail,
        agentEmail: widget.agentEmail,
        role: 'agent',
        lastMessageTimestamp: DateTime.now().toIso8601String(),
      );
    } else {
      _socketService.sendChatOpened(
        customerEmail: widget.customerEmail,
        agentEmail: widget.agentEmail,
        role: 'agent',
        lastMessageTimestamp: DateTime.now().toIso8601String(),
      );
      _socketService.sendMarkAsReadUpTo(
        customerEmail: widget.customerEmail,
        agentEmail: widget.agentEmail,
        role: 'agent',
        lastMessageTimestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  void _handleChatStatus(Map<String, dynamic> data) {
    debugPrint("Chat status socket on chat page : ${data.toString()}");
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

    // Fetch the latest 20 messages from the API
    final List<MessageModel> fetchedMessages =
        await _chatRepository.fetchAgentMessages(
      agentEmail: widget.agentEmail ?? LocalDbHelper.getProfile()!.email!,
      customerEmail: widget.customerEmail,
      limit: 20,
    );

    // Convert MessageModel to ChatMessageModel
    final chatMessages = fetchedMessages.map(_chatMessageFromModel).toList();

    if (boxExists) {
      // Load messages from Hive
      final loadedMessages =
          await _chatStorageService.getMessages(boxName, page: _currentPage);
      final newLoadedMessages = _removeDuplicates(loadedMessages);

      // Replace local messages with fetched messages where the fetched message has an empty string
      final messagesToReplace = chatMessages
          .where((fetchedMessage) => fetchedMessage.message!.isEmpty)
          .toList();

      for (var fetchedMessage in messagesToReplace) {
        final index = newLoadedMessages.indexWhere((localMessage) =>
            localMessage.messageId == fetchedMessage.messageId);
        if (index != -1) {
          newLoadedMessages[index] = fetchedMessage;
        }
      }

      // Add any new messages that are not already in the local storage
      final uniqueFetchedMessages = _removeDuplicates(chatMessages);
      final messagesToAdd = uniqueFetchedMessages.where((fetchedMessage) {
        return !newLoadedMessages.any((loadedMessage) {
          if (fetchedMessage.type == 'call' && loadedMessage.type == 'call') {
            return loadedMessage.callId == fetchedMessage.callId;
          }
          return loadedMessage.messageId == fetchedMessage.messageId;
        });
      }).toList();

      // Add the messages that are not in the Hive database to the list of messages
      newLoadedMessages.addAll(messagesToAdd);

      setState(() {
        messages = newLoadedMessages;
        messages = _mergeFormMessagesById(messages);
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _isLoading = false;
      });
    } else {
      // Save the fetched messages to the Hive database
      await _chatStorageService.saveMessages(chatMessages, boxName);

      setState(() {
        messages = chatMessages;
        messages = _mergeFormMessagesById(messages);
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _isLoading = false;
      });
    }

    // Fetch the last message timestamp and message ID for the agent and customer
    final result =
        await _chatRepository.fetchCustomerLastMessageTimestampForAgent(
      customerEmail: widget.customerEmail,
      agentEmail: widget.agentEmail!,
    );

    if (result != null) {
      final DateTime? lastMessageTimestamp = result['lastUserReadTimestamp'];
      // final String? lastMessageId = result['messageId'];

      debugPrint(
          "✅ Fetched last message seen timestamp of agent for customer: $lastMessageTimestamp");

      // Update the read status of messages up to the lastMessageTimestamp
      if (lastMessageTimestamp != null) {
        _updateMessagesReadStatus(lastMessageTimestamp);
      }
    } else {
      debugPrint(
          "No read messages found or an error occurred while fetching the last message timestamp.");
    }
    _scrollToBottom();
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
      final chatMessages = fetchedMessages.map(_chatMessageFromModel).toList();

      final newChatMessages = _removeDuplicates(chatMessages);
      if (newChatMessages.isNotEmpty) {
        // Save all messages at once
        await _chatStorageService.saveMessages(newChatMessages, boxName);
        setState(() {
          messages.insertAll(0, newChatMessages);
          messages = _mergeFormMessagesById(messages);
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle errors properly
      if (kDebugMode) {
        debugPrint("Error fetching messages from API: $e");
      }
    }
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
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      _showFloatingDateHeader();
    }

    // Hide header when scrolling down (optional, but could improve UX)
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      _hideFloatingDateHeader();
    }
    // Check if at the top edge, then load more messages
    if (_scrollController.position.atEdge &&
        _scrollController.position.pixels == 0) {
      _loadMoreMessages(context);
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

    // // Emit markAsReadUpTo when user scrolls or reaches bottom
    // if (_scrollController.position.atEdge &&
    //     _scrollController.position.pixels != 0) {
    //   if (messages.isNotEmpty) {
    //     final lastVisibleMessageTimestamp =
    //         messages.last.timestamp.toIso8601String();
    //     _socketService.sendMarkAsReadUpTo(
    //       customerEmail: widget.customerEmail,
    //       agentEmail: widget.agentEmail,
    //       role: 'agent',
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

  List<ChatMessageModel> _removeDuplicates(
      List<ChatMessageModel> messagesList) {
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
        if (message.messageId == null ||
            _loadedMessageIds.contains(message.messageId)) {
          return false;
        } else {
          _loadedMessageIds.add(message.messageId!);
          return true;
        }
      }
    }).toList();
  }

  List<Map<String, dynamic>>? _normalizeFormData(dynamic raw) {
    if (raw == null) return null;
    if (raw is List) {
      final entries = raw
          .where((entry) => entry is Map)
          .map((entry) => Map<String, dynamic>.from(entry as Map))
          .toList();
      return entries.isNotEmpty ? entries : null;
    }
    if (raw is Map) {
      return [Map<String, dynamic>.from(raw)];
    }
    return null;
  }

  ChatMessageModel _chatMessageFromModel(MessageModel messageJson) {
    final normalizedForms = _normalizeFormData(messageJson.form);
    final primaryForm =
        normalizedForms?.isNotEmpty == true ? normalizedForms!.first : null;
    return ChatMessageModel(
      message: messageJson.message ?? '',
      timestamp: DateTime.parse(
        messageJson.timestamp ?? DateTime.now().toIso8601String(),
      ),
      sender: messageJson.senderId!,
      type: messageJson.type,
      mediaUrl: messageJson.mediaUrl,
      form: primaryForm,
      forms: normalizedForms,
      callDuration: messageJson.callDuration,
      callStatus: messageJson.callStatus,
      callId: messageJson.callId,
      messageId: messageJson.messageId,
      isDeleted: messageJson.isDeleted!,
      read: messageJson.read,
    );
  }

  List<Map<String, dynamic>> _cloneFormEntries(List<Map<String, dynamic>> entries) {
    return entries.map((entry) => Map<String, dynamic>.from(entry)).toList();
  }

  void _updateMessageFormEntry(ChatMessageModel message, Map<String, dynamic> entry) {
    final formId = entry['_id']?.toString();
    if (formId == null || formId.isEmpty) return;
    final entries = _cloneFormEntries(message.formEntries);
    final index = entries.indexWhere((item) => item['_id']?.toString() == formId);
    if (index != -1) {
      entries[index] = Map<String, dynamic>.from(entry);
    } else {
      entries.add(Map<String, dynamic>.from(entry));
    }
    message.forms = entries;
    message.form = entries.isNotEmpty ? entries.first : null;
  }

  num _parseRateValue(dynamic rateValue) {
    if (rateValue is num) return rateValue;
    if (rateValue is String) return num.tryParse(rateValue.trim()) ?? 0;
    return 0;
  }

  String? _extractFormId(ChatMessageModel message) {
    final form = message.primaryForm;
    if (form == null) return null;
    final formId = form['_id']?.toString();
    if (formId == null || formId.isEmpty) return null;
    return formId;
  }

  String? _extractFormOrderKey(ChatMessageModel message) {
    final form = message.primaryForm;
    if (form == null) return null;

    final orderId = form['orderId']?.toString();
    if (orderId != null && orderId.isNotEmpty) {
      return orderId;
    }

    return _extractFormId(message);
  }

  List<ChatMessageModel> _mergeFormMessagesById(List<ChatMessageModel> source) {
    final sorted = [...source]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final List<ChatMessageModel> merged = [];
    final Map<String, ChatMessageModel> firstFormMessageById = {};

    for (final message in sorted) {
      if (message.type != 'form') {
        merged.add(message);
        continue;
      }

      final formId = _extractFormId(message);
      if (formId == null) {
        merged.add(message);
        continue;
      }

      final primaryForm = message.primaryForm;
      if (primaryForm == null) {
        merged.add(message);
        continue;
      }

      final incomingForm = Map<String, dynamic>.from(primaryForm);
      final existing = firstFormMessageById[formId];

      if (existing == null) {
        incomingForm['_formOptionsUnlocked'] = _parseRateValue(incomingForm['rate']) > 0;
        message.form = incomingForm;
        firstFormMessageById[formId] = message;
        merged.add(message);
      } else {
        final existingForm =
            Map<String, dynamic>.from(existing.primaryForm ?? incomingForm);
        existingForm.addAll(incomingForm);
        existingForm['_formOptionsUnlocked'] = true;
        existing.form = existingForm;
        _updateMessageFormEntry(existing, existingForm);
      }
    }

    return merged;
  }

  ({String formId, num rate})? _extractRateUpdateInfo(String? messageText) {
    if (messageText == null || messageText.isEmpty) return null;

    final regex = RegExp(
      r'Rate\s+updated\s+as\s+([0-9]+(?:\.[0-9]+)?)\s+for\s+form\s+with\s+Id\s*:\s*([A-Za-z0-9]+)',
      caseSensitive: false,
    );
    final match = regex.firstMatch(messageText);
    if (match == null) return null;

    final parsedRate = num.tryParse(match.group(1) ?? '');
    final formId = match.group(2);
    if (parsedRate == null || formId == null || formId.isEmpty) return null;

    return (formId: formId, rate: parsedRate);
  }

  Future<void> _updateFormRateLocally({
    required String formId,
    required num rate,
  }) async {
    final normalizedRate = rate % 1 == 0 ? rate.toInt() : rate;
    final boxName = '${widget.agentEmail}${widget.customerEmail}';
    bool updated = false;

    for (int i = 0; i < messages.length; i++) {
      final msg = messages[i];
      final entryIndex = msg.formEntries
          .indexWhere((entry) => entry['_id']?.toString() == formId);
      if (entryIndex == -1) continue;

      final updatedEntry = Map<String, dynamic>.from(msg.formEntries[entryIndex]);
      updatedEntry['rate'] = normalizedRate;
      updatedEntry['_formOptionsUnlocked'] = true;
      _updateMessageFormEntry(msg, updatedEntry);
      await _chatStorageService.saveMessage(msg, boxName);
      updated = true;
    }

    if (updated && mounted) {
      setState(() {});
    }
  }

  Future<void> _updateLocalFormByOrderId({
    required String orderId,
    String? status,
    num? rate,
    String? quality,
    String? weave,
    String? quantity,
    String? composition,
    String? buyerName,
  }) async {
    final boxName = '${widget.agentEmail}${widget.customerEmail}';
    bool updated = false;

    for (int i = 0; i < messages.length; i++) {
      final msg = messages[i];
      final entries = msg.formEntries;
      for (final entry in entries) {
        if (entry['orderId']?.toString() != orderId) continue;

        final updatedEntry = Map<String, dynamic>.from(entry);
        if (status != null && status.isNotEmpty) {
          updatedEntry['status'] = status;
        }
        if (rate != null) {
          updatedEntry['rate'] = rate;
        }
        if (quality != null) {
          updatedEntry['quality'] = quality;
        }
        if (weave != null) {
          updatedEntry['weave'] = weave;
        }
        if (quantity != null) {
          updatedEntry['quantity'] = quantity;
        }
        if (composition != null) {
          updatedEntry['composition'] = composition;
        }
        if (buyerName != null && buyerName.isNotEmpty) {
          updatedEntry['buyerName'] = buyerName;
        }
        updatedEntry['_formOptionsUnlocked'] = true;
        updatedEntry['_highlightUpdated'] = true;
        _updateMessageFormEntry(msg, updatedEntry);
        await _chatStorageService.saveMessage(msg, boxName);
        updated = true;
      }
    }

    if (updated && mounted) {
      setState(() {});
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        bool changed = false;
        for (int i = 0; i < messages.length; i++) {
          final entries = messages[i].formEntries;
          for (final entry in entries) {
            if (entry['orderId']?.toString() != orderId) continue;
            if (entry['_highlightUpdated'] == true) {
              final updatedEntry = Map<String, dynamic>.from(entry);
              updatedEntry['_highlightUpdated'] = false;
              _updateMessageFormEntry(messages[i], updatedEntry);
              changed = true;
            }
          }
        }
        if (changed) setState(() {});
      });
    }
  }

  Future<bool> _upsertIncomingFormMessage(ChatMessageModel incomingMessage) async {
    if (incomingMessage.type != 'form') return false;

    final formId = _extractFormId(incomingMessage);
    if (formId == null) return false;

    final primaryForm = incomingMessage.primaryForm;
    if (primaryForm == null) return false;

    final incomingForm = Map<String, dynamic>.from(primaryForm);
    final boxName = '${widget.agentEmail}${widget.customerEmail}';
    final existingIndex = messages.indexWhere(
      (msg) => msg.type == 'form' && _extractFormId(msg) == formId,
    );

    if (existingIndex == -1) {
      incomingForm['_formOptionsUnlocked'] = _parseRateValue(incomingForm['rate']) > 0;
      _updateMessageFormEntry(incomingMessage, incomingForm);
      return false;
    }

    final existingMessage = messages[existingIndex];
    final mergedForm =
        Map<String, dynamic>.from(existingMessage.primaryForm ?? incomingForm);
    mergedForm.addAll(incomingForm);
    mergedForm['_formOptionsUnlocked'] = true;
    existingMessage.form = mergedForm;
    _updateMessageFormEntry(existingMessage, mergedForm);
    await _chatStorageService.saveMessage(existingMessage, boxName);

    if (mounted) {
      setState(() {});
    }
    return true;
  }

  // In _handleIncomingMessage method
  void _handleIncomingMessage(Map<String, dynamic> data) async {
    debugPrint("message received: ${data.toString()}");
    // saving last seen message
    if (data['type'] == "product") {
      _socketService.updateLastMessage(data["senderId"], "shared product");
    } else {
      _socketService.updateLastMessage(data['senderId'], data['message']);
    }
    //converting data in to message model
    final incomingForms = _normalizeFormData(data["form"]);
    final incomingPrimaryForm =
        incomingForms?.isNotEmpty == true ? incomingForms!.first : null;
    final message = ChatMessageModel(
      message: data["message"],
      timestamp: data["timestamp"] != null
          ? DateTime.parse(data["timestamp"])
          : DateTime.now(),
      sender: data["senderId"],
      type: data["type"] ?? "text",
      mediaUrl: data["mediaUrl"],
      form: incomingPrimaryForm,
      forms: incomingForms,
      messageId: data["messageId"], // Include the message ID
    );

    if (message.type == 'form') {
      final isMergedIntoExisting = await _upsertIncomingFormMessage(message);
      if (isMergedIntoExisting) {
        if (message.messageId != null) {
          _loadedMessageIds.add(message.messageId!);
        }
        _saveLastMessageTime();
        Provider.of<ChatRefreshProvider>(context, listen: false).markNeedsRefresh();
        return;
      }
    }

    final rateUpdate = _extractRateUpdateInfo(data["message"]?.toString());
    if (rateUpdate != null) {
      _updateFormRateLocally(
        formId: rateUpdate.formId,
        rate: rateUpdate.rate,
      );
    }

    // Extract product data from incoming messages
    if (data["type"] == "text" && data["message"]?.toString().isNotEmpty == true) {
      _extractAndSaveProductData(data["message"], data["messageId"] ?? "");
    }

    if (!_loadedMessageIds.contains(message.messageId)) {
      setState(() {
        messages.add(message); // Append to the end
        messages = _mergeFormMessagesById(messages);
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _scrollToBottom();
      });

      // Save the message to Hive only if it's not already saved
      _chatStorageService.saveMessage(
          message, '${widget.agentEmail}${widget.customerEmail}');
      _loadedMessageIds.add(message.messageId!);

      _saveLastMessageTime();
      Provider.of<ChatRefreshProvider>(context, listen: false)
          .markNeedsRefresh();
    }
  }

  void _handleMessageDeleted(String messageId) {
    if (mounted) {
      setState(() {
        final index =
            messages.indexWhere((message) => message.messageId == messageId);
        if (index != -1) {
          messages[index].isDeleted = true;
          messages[index].message = "This message is deleted";
        }
      });
    }

    // Save the updated message state to local storage
    final boxName = '${widget.agentEmail}${widget.customerEmail}';
    _chatStorageService.saveMessage(
        messages.firstWhere((message) => message.messageId == messageId),
        boxName);
    _socketService.updateLastMessage(widget.customerEmail, "message deleted");
  }

  void _sendMessage({
    required String messageText,
    String? type = 'text',
    String? mediaUrl,
    Map<String, dynamic>? form,
  }) {
    if (messageText.trim().isEmpty && mediaUrl == null && form == null) return;
    final currentTime = DateTime.now();
    // Generate a unique message ID
    final messageId = ChatUtils().generateMessageId();
    // Set the receiverIsOnChatPage to false when the app is paused or inactive
    final isReceiverOnChatPage = LocalDbHelper.getReceiverOnChatPageStatus();

    final messageType = form != null ? 'form' : type;

    final normalizedForms = form != null
        ? [Map<String, dynamic>.from(form)]
        : null;
    final message = ChatMessageModel(
      message: messageText,
      timestamp: currentTime,
      sender: widget.agentEmail!,
      type: messageType!,
      mediaUrl: mediaUrl,
      form: normalizedForms?.first,
      forms: normalizedForms,
      messageId: messageId,
      isDeleted: false,
      read: isReceiverOnChatPage,
    );

    if (!_loadedMessageIds.contains(messageId)) {
      setState(() {
        messages.add(message);
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      });

      // Always send text message event for non-form content
      if (form == null || type != 'form') {
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
        );
      }

      // Send form payload separately when form data exists
      if (form != null) {
        _socketService.sendForm(
          senderId: widget.agentEmail!,
          targetId: widget.customerEmail,
          senderName: widget.agentName ?? 'agent',
          form: form,
          timestamp: currentTime.toIso8601String(),
          messageId: messageId,
          orderId: form['orderId']?.toString(),
        );
      }

      // Save the message to Hive only if it's not already saved
      _chatStorageService.saveMessage(message, '${widget.agentEmail}${widget.customerEmail}');
      _loadedMessageIds.add(messageId);
    }
    _scrollToBottom();

    // Extract product data from sent messages
    if (type == 'text' && messageText.isNotEmpty) {
      _extractAndSaveProductData(messageText, messageId);
    }

    _chatController.clear();
    _saveLastMessageTime();
    Provider.of<ChatRefreshProvider>(context, listen: false).markNeedsRefresh();
  }

  String _generateOrderId() {
    return 'ORD-${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _extractAndSaveProductData(String messageText, String messageId) async {
    try {
      final extractedData = await _extractionService.extractProductData(messageText);
      if (extractedData != null) {
        final productData = ExtractedProductData(
          chatId: '${widget.agentEmail}${widget.customerEmail}',
          agentEmail: widget.agentEmail!,
          customerEmail: widget.customerEmail,
          customerName: widget.customerName,
          quality: extractedData['quality'],
          weave: extractedData['weave'],
          quantity: extractedData['quantity']?.toString(),
          composition: extractedData['composition'],
          rate: extractedData['rate'],
          extractedAt: DateTime.now(),
          confidence: extractedData['confidence'] ?? 0.0,
          extractionTimeMs: extractedData['extractionTimeMs'],
        );

        await _extractedProductRepository.insert(productData);
        _logger.logStorage('Product data extracted and saved: ${productData.toJson()}');
      }
    } catch (e) {
      _logger.logStorage('Error extracting product data: $e', level: LogLevel.error);
    }
  }

  void _addTemporaryMessage(String messageText) {
    final currentTime = DateTime.now();
    final temporaryMessage = ChatMessageModel(
      message: messageText,
      timestamp: currentTime,
      sender: widget.agentEmail!,
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

    // Update the local message state to reflect deletion
    setState(() {
      final index =
          messages.indexWhere((message) => message.messageId == messageId);
      if (index != -1) {
        messages[index].isDeleted = true;
        messages[index].message = "This message is deleted";
      }
    });

    // Save the updated message state to local storage
    final boxName = '${widget.agentEmail}${widget.customerEmail}';
    _chatStorageService.saveMessage(
        messages.firstWhere((message) => message.messageId == messageId),
        boxName);
    _socketService.updateLastMessage(widget.customerEmail, "message deleted");
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
          messages
              .removeWhere((message) => message.message == "Sending image...");
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
          messages.removeWhere(
              (message) => message.message == "Sending document...");
        });

        // Send the actual message
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
      type: 'text',
      form: updatedFormData,
    );

    // Trigger real-time update
    Provider.of<InquiryProvider>(context, listen: false).refreshInquiries();
  }

  void _handleStatusUpdated(String status, String id) {
    final messageText = status == 'Confirmed'
        ? "Your order is confirmed with form Id: $id"
        : "Your order is declined with form Id: $id";
    _sendMessage(
      messageText: messageText,
      type: 'text',
    );

    // Trigger real-time update after status change
    Provider.of<InquiryProvider>(context, listen: false).refreshInquiries();
  }

  Future<void> _showUpdateOrderByIdSheet(FormDataModel order) async {
    final rateController = TextEditingController(text: order.rate);
    final qualityController = TextEditingController(text: order.quality);
    final weaveController = TextEditingController(text: order.weave);
    final quantityController = TextEditingController(text: order.quantity);
    final compositionController = TextEditingController(text: order.composition);
    final buyerController = TextEditingController(text: order.buyerName);

    final customerDisplayName = order.customerName.isNotEmpty ? order.customerName : 'Not provided';
    final buyerDisplayName = order.buyerName.isNotEmpty ? order.buyerName : 'Not provided';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        /// ✅ Allowed statuses
        final allowedStatuses = ['Processed', 'Confirmed', 'Declined'];

        /// ✅ Default value from order (safe)
        String? selectedStatus = allowedStatuses.contains(order.status) ? order.status : null;

        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 14,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                padding: EdgeInsets.only(
                  left: 18,
                  right: 18,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 18,
                  top: 14,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Drag Handle
                      Center(
                        child: Container(
                          width: 42,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),

                      const Text(
                        'Update Order Details',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Order ID: ${order.orderId.isNotEmpty ? order.orderId : order.id}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),

                      const SizedBox(height: 12),

                      /// Customer / Buyer
                      Row(
                        children: [
                          Expanded(
                            child:
                                _buildPersonInfoChip('Customer', customerDisplayName, Colors.blue),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildPersonInfoChip('Buyer', buyerDisplayName, Colors.teal),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),
                      const Divider(height: 1, thickness: 1),
                      const SizedBox(height: 12),

                      Text(
                        'Update any fields below (leave blank to keep current value)',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),

                      const SizedBox(height: 12),

                      /// Buyer
                      TextField(
                        controller: buyerController,
                        decoration: InputDecoration(
                          labelText: 'Buyer name',
                          hintText: 'Add or update the buyer name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      /// ✅ STATUS DROPDOWN (with default value)
                      DropdownButtonFormField<String>(
                        value: selectedStatus,
                        hint: const Text('Select Status'),
                        decoration: InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Processed', child: Text('Processed')),
                          DropdownMenuItem(value: 'Confirmed', child: Text('Confirmed')),
                          DropdownMenuItem(value: 'Declined', child: Text('Declined')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedStatus = value;
                          });
                        },
                      ),

                      const SizedBox(height: 10),

                      /// Quality + Weave
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: qualityController,
                              decoration: InputDecoration(
                                labelText: 'Quality',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: weaveController,
                              decoration: InputDecoration(
                                labelText: 'Weave',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      /// Quantity + Composition
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: quantityController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Quantity',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: compositionController,
                              decoration: InputDecoration(
                                labelText: 'Composition',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      /// Rate
                      TextField(
                        controller: rateController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Rate',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// SAVE BUTTON
                      CustomButton(
                        text: "Save Order",
                        width: double.maxFinite,
                        onPressed: () async {
                          final statusValue = selectedStatus;
                          final rateText = rateController.text.trim();
                          final qualityValue = qualityController.text.trim();
                          final weaveValue = weaveController.text.trim();
                          final quantityValue = quantityController.text.trim();
                          final compositionValue = compositionController.text.trim();
                          final buyerValue = buyerController.text.trim();

                          final rateValue = rateText.isNotEmpty ? num.tryParse(rateText) : null;

                          if (statusValue == null &&
                              rateValue == null &&
                              qualityValue.isEmpty &&
                              weaveValue.isEmpty &&
                              quantityValue.isEmpty &&
                              compositionValue.isEmpty &&
                              buyerValue.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Enter at least one field to update')),
                            );
                            return;
                          }

                          try {
                            final updateOrderId =
                                order.orderId.isNotEmpty ? order.orderId : order.id;

                            await _chatRepository.updateFormByOrderId(
                              orderId: updateOrderId,
                              status: statusValue,
                              rate: rateValue,
                              quality: qualityValue.isNotEmpty ? qualityValue : null,
                              weave: weaveValue.isNotEmpty ? weaveValue : null,
                              quantity: quantityValue.isNotEmpty ? quantityValue : null,
                              composition: compositionValue.isNotEmpty ? compositionValue : null,
                              buyerName: buyerValue.isNotEmpty ? buyerValue : null,
                            );

                            await _updateLocalFormByOrderId(
                              orderId: updateOrderId,
                              status: statusValue,
                              rate: rateValue,
                              quality: qualityValue.isNotEmpty ? qualityValue : null,
                              weave: weaveValue.isNotEmpty ? weaveValue : null,
                              quantity: quantityValue.isNotEmpty ? quantityValue : null,
                              composition: compositionValue.isNotEmpty ? compositionValue : null,
                              buyerName: buyerValue.isNotEmpty ? buyerValue : null,
                            );

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Order updated successfully')),
                              );
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Update failed: $e')),
                              );
                            }
                          }
                        },
                      ),

                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showCheckOrdersBottomSheet() async {
    if (!mounted) return;
    bool isLoading = true;
    List<FormDataModel> orders = [];
    String? error;
    final customerFilter = widget.customerName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            if (isLoading) {
              Future.microtask(() async {
                try {
                  final fetchedOrders =
                      await _chatRepository.fetchFormDataForEnquiery(widget.agentEmail ?? '');
                  final filteredOrders = fetchedOrders.where((order) {
                    if (customerFilter == null || customerFilter.isEmpty) return true;
                    return order.customerName.trim().toLowerCase() ==
                        customerFilter.trim().toLowerCase();
                  }).toList();

                  if (mounted) {
                    setState(() {
                      orders = filteredOrders;
                      isLoading = false;
                    });
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() {
                      error = e.toString();
                      isLoading = false;
                    });
                  }
                }
              });
            }

            return SafeArea(
              child: Container(
                height: MediaQuery.of(context).size.height * 0.78,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Sent Orders',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade900,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : error != null
                              ? Center(child: Text('Failed to load orders: $error'))
                              : orders.isEmpty
                                  ? Center(
                                      child: Text(
                                        customerFilter != null && customerFilter.isNotEmpty
                                            ? 'No orders found for ${widget.customerName}'
                                            : 'No sent orders found.',
                                      ),
                                    )
                                  : ListView.separated(
                                      padding:
                                          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      itemCount: orders.length,
                                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                                      itemBuilder: (context, index) =>
                                          _buildCheckOrderCard(context, orders[index], index),
                                    ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCheckOrderCard(BuildContext sheetContext, FormDataModel order, int index) {
    final orderIdLabel = order.orderId.isNotEmpty ? order.orderId : order.id;
    final statusLabel = order.status.isNotEmpty ? order.status : 'Pending';
    final customerLabel =
        order.customerName.isNotEmpty ? order.customerName : 'Customer not provided';
    final buyerLabel = order.buyerName.isNotEmpty ? order.buyerName : 'Buyer not provided';
    final rateLabel = order.rate.isNotEmpty ? '₹${order.rate}' : '-';

    void openEditor() {
      Navigator.pop(sheetContext);
      _showUpdateOrderByIdSheet(order);
    }

    return InkWell(
      onTap: openEditor,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue.shade100,
                  child: Text('${index + 1}', style: TextStyle(color: Colors.blue.shade900)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order #${index + 1}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(orderIdLabel,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _orderStatusColor(statusLabel),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusLabel,
                    style: const TextStyle(fontSize: 11, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildPersonInfoChip('Customer', customerLabel, Colors.blue),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPersonInfoChip('Buyer', buyerLabel, Colors.teal),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (order.quality.isNotEmpty) _buildOrderDetailPill('Quality', order.quality),
                if (order.weave.isNotEmpty) _buildOrderDetailPill('Weave', order.weave),
                if (order.quantity.isNotEmpty) _buildOrderDetailPill('Qty', order.quantity),
                if (order.composition.isNotEmpty)
                  _buildOrderDetailPill('Composition', order.composition),
                _buildOrderDetailPill('Rate', rateLabel),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: openEditor,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue.shade700,
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _orderStatusColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('confirm')) return Colors.green;
    if (normalized.contains('decline')) return Colors.red;
    if (normalized.contains('pending')) return Colors.orange;
    return Colors.blueGrey;
  }

  Widget _buildOrderDetailPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
      ),
    );
  }

  Widget _buildPersonInfoChip(String label, String value, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: accentColor.withOpacity(0.9),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade900,
            ),
          ),
        ],
      ),
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

  List<int> _getFormMessageIndices() {
    List<int> formIndices = [];
    for (int i = 0; i < messages.length; i++) {
      final msg = messages[i];
      // Check if it's a form message sent by the customer (not the agent)
      if ((msg.type == 'form' || msg.form != null) &&
          msg.sender == widget.customerEmail) {
        formIndices.add(i);
      }
    }
    return formIndices;
  }

  Map<String, int> _buildFormSerialMap() {
    final Map<String, int> serialByFormId = {};
    int serial = 0;

    for (final msg in messages) {
      if (msg.type != 'form') continue;
      final formId = _extractFormId(msg);
      if (formId == null) continue;
      serialByFormId.putIfAbsent(formId, () => ++serial);
    }
    return serialByFormId;
  }

  Map<String, int> _buildSentOrderSerialMap() {
    final Map<String, int> serialByOrderKey = {};
    int serial = 0;

    final agentEmailLower = widget.agentEmail?.toLowerCase();
    for (final msg in messages) {
      if (msg.type != 'form') continue;
      if (agentEmailLower == null || msg.sender?.toLowerCase() != agentEmailLower) continue;

      final orderKey = _extractFormOrderKey(msg);
      if (orderKey == null) continue;
      serialByOrderKey.putIfAbsent(orderKey, () => ++serial);
    }
    return serialByOrderKey;
  }

  void _navigateToForm(int direction) {
    List<int> formIndices = _getFormMessageIndices();

    if (formIndices.isEmpty) {
      // Show a message that no forms are available
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No customer forms found to navigate to'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_currentFormIndex == null) {
      // If no current form is selected, start from the most recent form
      _currentFormIndex = formIndices.length - 1;
    } else {
      // Calculate new index based on direction (1 for next/down, -1 for previous/up)
      int newIndex = _currentFormIndex! + direction;

      // Handle wraparound or bounds
      if (newIndex < 0) {
        newIndex = formIndices.length - 1; // Wrap to last form
      } else if (newIndex >= formIndices.length) {
        newIndex = 0; // Wrap to first form
      }

      _currentFormIndex = newIndex;
    }

    // Scroll to the selected form message
    int messageIndex = formIndices[_currentFormIndex!];
    _scrollToMessage(messageIndex);

    // Optional: Show current form position
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Form ${_currentFormIndex! + 1} of ${formIndices.length}'),
        duration: Duration(milliseconds: 800),
      ),
    );
  }

  void _scrollToMessage(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && index < messages.length) {
        final key = ValueKey('chat-msg-$index');
        final globalKey = _messageKeys[key];

        if (globalKey?.currentContext != null) {
          final ctx = globalKey!.currentContext!;
          final box = ctx.findRenderObject() as RenderBox?;
          if (box != null) {
            try {
              // Get the position of the message
              final position = box.localToGlobal(Offset.zero);
              final scrollOffset = _scrollController.offset;
              final viewportHeight =
                  _scrollController.position.viewportDimension;

              // Calculate target scroll position to center the message
              final targetOffset =
                  scrollOffset + position.dy - (viewportHeight / 2);
              final clampedOffset = targetOffset.clamp(
                _scrollController.position.minScrollExtent,
                _scrollController.position.maxScrollExtent,
              );

              _scrollController.animateTo(
                clampedOffset,
                duration: Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            } catch (e) {
              debugPrint('Error scrolling to message: $e');
              // Fallback: scroll based on approximate item height
              final approximatePosition =
                  index * 100.0; // Adjust based on your average message height
              _scrollController.animateTo(
                approximatePosition,
                duration: Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            }
          }
        } else {
          // Fallback scrolling method
          final approximatePosition = index * 100.0;
          _scrollController.animateTo(
            approximatePosition,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  void _toggleFormNavigationButtons() {
    final formIndices = _getFormMessageIndices();
    debugPrint(
        'Found ${formIndices.length} customer form messages at indices: $formIndices');

    // Debug: Print details about each form message
    for (int i = 0; i < formIndices.length; i++) {
      final msgIndex = formIndices[i];
      final msg = messages[msgIndex];
      debugPrint(
          'Form $i: type=${msg.type}, sender=${msg.sender}, hasForm=${msg.form != null}');
    }

    setState(() {
      _showFormNavigationButtons = !_showFormNavigationButtons;
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final formSerialMap = _buildFormSerialMap();
    final sentOrderSerialMap = _buildSentOrderSerialMap();
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
            icon: const Icon(Icons.swap_horizontal_circle_outlined, color: Colors.black),
          ),
          IconButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExtractedDataViewerScreen(
                    agentEmail: widget.agentEmail!,
                  ),
                ),
              );

              if (result is Map<String, dynamic> && result['success'] == true) {
                final formData = result['formData'] as Map<String, dynamic>?;
                final customerEmail = result['customerEmail'] as String?;
                if (formData != null && customerEmail != null) {
                  final orderId = formData['orderId'] ?? _generateOrderId();
                  formData['orderId'] = orderId;
                  _sendMessage(
                    messageText: 'Product inquiry',
                    type: 'text',
                    form: formData,
                  );
                  // ScaffoldMessenger.of(context).showSnackBar(
                  //   SnackBar(
                  //     content: Text('Sent validated form to $customerEmail'),
                  //     backgroundColor: Colors.green,
                  //   ),
                  // );
                }
              }
            },
            icon: const Icon(Icons.inventory, color: Colors.black),
            tooltip: 'View Extracted Product Data',
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
              );

              // 3. ⏳ Wait for call to complete and message to be returned
              // This is done via callProvider.callDetailsMessage after call ends
              void handleCallMessage(ChatMessageModel message) async {
                // Save to storage
                await _chatStorageService.saveMessage(
                    message, '${widget.agentEmail}${widget.customerEmail}');

                if (!mounted) return;
                setState(() {
                  messages.add(message);
                  messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
                });

                _scrollToBottom();
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
                              final isAgent = msg.sender == widget.agentEmail;
                              final orderKey = _extractFormOrderKey(msg);
                              final agentFormSerial =
                                  orderKey != null ? sentOrderSerialMap[orderKey] : null;
                              final valueKey = ValueKey('chat-msg-$index');
                              final globalKey = GlobalKey();
                              _messageKeys[valueKey] = globalKey;
                              String? dateHeader;

                              if (index == 0 ||
                                  !ChatUtils().isSameDay(
                                      messages[index - 1].timestamp,
                                      msg.timestamp)) {
                                dateHeader =
                                    ChatUtils().formatDateHeader(msg.timestamp);
                              }

                              return Container(
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
                                          msg.timestamp.toIso8601String(),
                                        ),
                                        isDeleted: msg.isDeleted,
                                        onLongPress: isAgent
                                            ? () =>
                                                _showMessageOptionsBottomSheet(
                                                    context, msg.messageId!)
                                            : null,
                                      )
                                    else if (msg.type == 'form')
                                      (msg.sender?.toLowerCase() ==
                                              widget.agentEmail?.toLowerCase())
                                          ? SentProductFormBubble(
                                              formData: msg.form ?? {},
                                              isMe: true,
                                              timestamp: ChatUtils()
                                                  .formatTimestamp(msg.timestamp.toIso8601String()),
                                              serialNumber: agentFormSerial,
                                              onStatusUpdate: (status) {
                                                setState(() {
                                                  msg.form?['status'] = status;
                                                });
                                              },
                                              onRateUpdate: (newRate) {
                                                setState(() {
                                                  msg.form?['rate'] = newRate;
                                                });
                                              },
                                            )
                                      : FormMessageBubble(
                                          forms: msg.formEntries,
                                          serialNumber: msg.form?['_id'] != null
                                              ? formSerialMap[msg.form!['_id'].toString()]
                                              : null,
                                          isMe: false,
                                          timestamp: ChatUtils()
                                              .formatTimestamp(msg.timestamp.toIso8601String()),
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
                                    else if (msg.message == 'Fill details')
                                      FillFormButton(
                                        buttonText: locale.fillProductDetails,
                                        onSubmit: () {
                                          // Agent not allowed to fill the form
                                        },
                                      )
                                    else if (msg.message == "Update form rate")
                                      FillFormButton(
                                        buttonText: locale.updateForm,
                                        onSubmit: () {
                                          // Only show the widget for history, not to do anything on the agent side
                                        },
                                      )
                                    else if (msg.type == 'product')
                                      (msg.message != null &&
                                              msg.message!.isNotEmpty)
                                          ? ProductMessageBubble(
                                              productJson: msg.message!,
                                              isMe: msg.sender ==
                                                  widget.agentEmail,
                                              timestamp:
                                                  ChatUtils().formatTimestamp(
                                                msg.timestamp.toIso8601String(),
                                              ),
                                              isDeleted: msg.isDeleted,
                                              onLongPress: isAgent
                                                  ? () =>
                                                      _showMessageOptionsBottomSheet(
                                                        context,
                                                        msg.messageId!,
                                                      )
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
                                                      product: product,
                                                    ),
                                                  ),
                                                );
                                              },
                                            )
                                          : DeletedMessageBubble(
                                              isMe: msg.sender ==
                                                  widget.agentEmail,
                                              timestamp:
                                                  ChatUtils().formatTimestamp(
                                                msg.timestamp.toIso8601String(),
                                              ),
                                            )
                                    else
                                      MessageBubble(
                                        message: msg,
                                        isMe: msg.sender == widget.agentEmail,
                                        onLongPress: isAgent
                                            ? () =>
                                                _showMessageOptionsBottomSheet(
                                                    context, msg.messageId!,
                                                    textToCopy: msg.message!)
                                            : null,
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
              if (widget.isAccountDeleted == false)
                SafeArea(
                  minimum: const EdgeInsets.only(bottom: 1),
                  child: ChatInputField(
                    controller: _chatController,
                    onSend: () =>
                        _sendMessage(messageText: _chatController.text),
                    onSendImage: () {
                      _pickAndSendImage(ImageSource.gallery);
                    },
                    onSendForm: sendFormButton,
                    onSendDocument: _pickAndSendDocument,
                    onSendImageByCamera: () {
                      _pickAndSendImage(ImageSource.camera);
                    },
                    onShareProduct: () => _showProductsBottomSheet(context),
                    onCheckOrders:
                        (userRole == '2' || userRole == '3') ? _showCheckOrdersBottomSheet : null,
                    showCheckOrders: userRole == '2' || userRole == '3',
                    onSendVoice: _isRecording ? _stopRecording : _startRecording,
                    isRecording: _isRecording,
                    recordedSeconds: _recordedSeconds,
                  ),
                ),
              const SizedBox(height: 10),
            ],
          ),
          if (_isFormUpdating) FullScreenLoader(),
          if (!_isAtBottom)
            Positioned(
              bottom: 80,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_showFormNavigationButtons) ...[
                    IconButton(
                      onPressed: () => _navigateToForm(-1),
                      icon: Icon(Icons.arrow_upward),
                    ),
                    IconButton(
                      onPressed: () => _navigateToForm(1),
                      icon: Icon(Icons.arrow_downward),
                    ),
                  ],
                  IconButton(
                    onPressed: _toggleFormNavigationButtons,
                    icon: Icon(Icons.push_pin),
                  ),
                  FloatingActionButton(
                    onPressed: _scrollToBottom,
                    mini: true,
                    child: Icon(Icons.arrow_downward_rounded),
                  ),
                ],
              ),
            ),
          //  Floating day/date header
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: ValueListenableBuilder<String?>(
              valueListenable: _currentTopDate,
              builder: (context, date, _) {
                if (date == null || !_showDateHeader) return SizedBox.shrink();
                return Center(
                  child: DateHeader(date: date),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
