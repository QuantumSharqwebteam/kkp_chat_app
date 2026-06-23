import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:kkpchatapp/core/services/chat_storage_service.dart';
import 'package:kkpchatapp/core/utils/chat_utils.dart';
import 'package:kkpchatapp/data/models/chat_message_model.dart';
import 'package:kkpchatapp/data/models/message_model.dart';
import 'package:kkpchatapp/data/repositories/chat_reopsitory.dart';

/// Owns all message state for the agent chat screen.
/// Notifying listeners only when messages actually change means the
/// ListView rebuilds in isolation — scroll events and date-header
/// visibility never trigger a full-screen rebuild.
class AgentChatProvider extends ChangeNotifier {
  final String agentEmail;
  final String customerEmail;

  final ChatStorageService _storage = ChatStorageService();
  final ChatRepository _repo = ChatRepository();
  final ScrollController scrollController = ScrollController();
  final ValueNotifier<bool> isAtBottom = ValueNotifier(true);

  List<ChatMessageModel> _messages = [];
  bool _isInitialized = false;
  bool _isLoadingMore = false;
  bool _hasScrolledToInitial = false;
  bool _keepPinnedToBottom = true;

  // Page tracking for Hive-based pagination
  int _currentPage = 1;
  final Set<int> _fetchedPages = {};

  final Set<String> _loadedMessageIds = {};
  final Set<String> _loadedCallIds = {};

  List<ChatMessageModel> get messages => _messages;
  bool get isInitialized => _isInitialized;
  bool get isLoadingMore => _isLoadingMore;

  String get _boxName => '$agentEmail$customerEmail';

  AgentChatProvider({required this.agentEmail, required this.customerEmail});

  // ── Initial load (cache-first → API sync → read-status) ─────────────────

  Future<void> load() async {
    // Step 1: Hive cache — instant, no network
    final bool boxExists = await Hive.boxExists(_boxName);
    if (boxExists) {
      final cached = await _storage.getMessages(_boxName, page: _currentPage);
      if (cached.isNotEmpty) {
        _messages = _removeDuplicates(cached)
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _isInitialized = true;
        notifyListeners();
        _jumpToBottom(markInitial: true);
      }
    }

    // Mark initialized even with empty cache so the screen shows
    // empty state (not shimmer) while the API call is in flight.
    if (!_isInitialized) {
      _isInitialized = true;
      notifyListeners();
    }

    // Step 2: Silent background API sync
    try {
      final fetched = await _repo.fetchCustomerMessages(
        customerEmail: customerEmail,
        limit: 20,
      );
      final chatMessages = fetched.map(_fromModel).toList();
      final newMessages = _removeDuplicates(chatMessages);

      if (!boxExists && chatMessages.isNotEmpty) {
        await _storage.saveMessages(chatMessages, _boxName);
      } else if (newMessages.isNotEmpty) {
        await _storage.saveMessages(newMessages, _boxName);
      }

      if (_isInitialized && newMessages.isEmpty) {
        return;
      }

      final shouldStayAtBottom = shouldAutoScrollForNewMessage;
      if (!_isInitialized) {
        _messages = chatMessages;
      } else {
        _messages.addAll(newMessages);
      }
      _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      _isInitialized = true;
      notifyListeners();
      if (!_hasScrolledToInitial) {
        _jumpToBottom(markInitial: true);
      } else if (newMessages.isNotEmpty && shouldStayAtBottom) {
        _jumpToBottom();
      }
    } catch (e) {
      debugPrint('[AgentChatProvider] API sync failed: $e');
    } finally {
      if (!_isInitialized) {
        _isInitialized = true;
        notifyListeners();
      }
    }

    // Step 3: Read-status sync
    if (_messages.isEmpty) return;
    try {
      final result = await _repo.fetchCustomerLastMessageTimestampForAgent(
        customerEmail: customerEmail,
        agentEmail: agentEmail,
      );
      final ts = result?['lastUserReadTimestamp'] as DateTime?;
      if (ts != null) _markReadUpTo(ts);
    } catch (e) {
      debugPrint('[AgentChatProvider] read-status sync failed: $e');
    }
  }

  // ── Pagination (load older messages) ─────────────────────────────────────

  Future<void> loadMore() async {
    if (_isLoadingMore) return;
    _isLoadingMore = true;
    notifyListeners();
    final oldMaxScrollExtent = _currentMaxScrollExtent;
    final oldPixels = _currentPixels;

    _currentPage++;

    try {
      if (_fetchedPages.contains(_currentPage)) {
        return;
      }

      // Try loading from Hive first
      var older = await _storage.getMessages(_boxName, page: _currentPage);

      if (older.isEmpty) {
        // Not in cache — fetch from API
        final before = _messages.isNotEmpty
            ? _messages.first.timestamp.toIso8601String()
            : null;
        final fetched = await _repo.fetchCustomerMessages(
          customerEmail: customerEmail,
          limit: 20,
          before: before,
        );
        if (fetched.isNotEmpty) {
          final chatMessages = fetched.map(_fromModel).toList();
          final newChatMessages = _removeDuplicates(chatMessages);
          if (newChatMessages.isNotEmpty) {
            await _storage.saveMessages(newChatMessages, _boxName);
          }
          older = await _storage.getMessages(_boxName, page: _currentPage);
        }
      }

      if (older.isNotEmpty) {
        final unique = _removeDuplicates(older);
        if (unique.isNotEmpty) {
          _messages.insertAll(0, unique);
          _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          notifyListeners();
          _preserveScrollOffsetAfterPrepend(
            oldMaxScrollExtent: oldMaxScrollExtent,
            oldPixels: oldPixels,
          );
        }
      }
      _fetchedPages.add(_currentPage);
    } catch (e) {
      _currentPage--; // Roll back page on failure
      debugPrint('[AgentChatProvider] loadMore failed: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // ── Incoming socket message ───────────────────────────────────────────────

  void addIncoming(Map<String, dynamic> data) {
    final shouldStayAtBottom = shouldAutoScrollForNewMessage;
    final tsRaw = data['timestamp'];
    final timestamp = tsRaw != null
        ? DateTime.tryParse(tsRaw.toString()) ?? DateTime.now()
        : DateTime.now();

    final messageId = data['messageId'] as String?;
    final tsKey = 'ts:${timestamp.millisecondsSinceEpoch}';

    if ((messageId != null && _loadedMessageIds.contains(messageId)) ||
        _loadedMessageIds.contains(tsKey)) {
      return;
    }

    final msg = ChatMessageModel(
      message: data['message'] as String? ?? '',
      timestamp: timestamp,
      sender: data['senderId'] as String? ?? '',
      type: data['type'] as String? ?? 'text',
      mediaUrl: data['mediaUrl'] as String?,
      callStatus: data['callStatus'] as String?,
      callDuration: data['callDuration'] as String?,
      callId: data['callId'] as String?,
      messageId: messageId,
      isDeleted: data['isDeleted'] as bool? ?? false,
      read: data['read'] as bool?,
      referenceId: data['referenceId'] as String?,
    );

    _messages.add(msg);
    _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (messageId != null) _loadedMessageIds.add(messageId);
    _loadedMessageIds.add(tsKey);
    notifyListeners();
    if (shouldStayAtBottom) scrollToBottom();

    _storage.saveMessage(msg, _boxName);
  }

  // ── Sent message (optimistic add) ────────────────────────────────────────

  void addSent(ChatMessageModel msg) {
    _messages.add(msg);
    _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (msg.messageId != null) _loadedMessageIds.add(msg.messageId!);
    _loadedMessageIds.add('ts:${msg.timestamp.millisecondsSinceEpoch}');
    notifyListeners();
    scrollToBottom();
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  void markDeleted(String messageId) {
    final idx = _messages.indexWhere((m) => m.messageId == messageId);
    if (idx == -1) return;
    _messages[idx].isDeleted = true;
    _messages[idx].message = 'This message is deleted';
    notifyListeners();
    _storage.saveMessage(_messages[idx], _boxName);
  }

  // ── Read status ───────────────────────────────────────────────────────────

  void markReadUpToTimestamp(DateTime ts) => _markReadUpTo(ts);

  void _markReadUpTo(DateTime ts) {
    bool changed = false;
    for (final msg in _messages) {
      if (msg.read != true &&
          (msg.timestamp.isBefore(ts) || msg.timestamp == ts)) {
        msg.read = true;
        changed = true;
      }
    }
    if (!changed) return;
    notifyListeners();
    for (final msg in _messages) {
      if (msg.read == true) _storage.saveMessage(msg, _boxName);
    }
  }

  // ── Optimistic placeholder ────────────────────────────────────────────────

  ChatMessageModel addOptimistic(String text, String sender) {
    final msg = ChatMessageModel(
      message: text,
      timestamp: DateTime.now(),
      sender: sender,
    );
    _messages.add(msg);
    notifyListeners();
    scrollToBottom();
    return msg;
  }

  void removeOptimistic(String messageText) {
    _messages.removeWhere((m) => m.message == messageText);
    notifyListeners();
  }

  void persistMessage(ChatMessageModel msg) =>
      _storage.saveMessage(msg, _boxName);

  String generateMessageId() => ChatUtils().generateMessageId();

  // ── Deduplication ─────────────────────────────────────────────────────────

  List<ChatMessageModel> _removeDuplicates(List<ChatMessageModel> list) {
    return list.where((msg) {
      if (msg.type == 'call') {
        if (msg.callId == null || _loadedCallIds.contains(msg.callId)) {
          return false;
        }
        _loadedCallIds.add(msg.callId!);
        return true;
      }
      final id = msg.messageId;
      final tsKey = 'ts:${msg.timestamp.millisecondsSinceEpoch}';
      if ((id != null && _loadedMessageIds.contains(id)) ||
          _loadedMessageIds.contains(tsKey)) {
        return false;
      }
      if (id != null) _loadedMessageIds.add(id);
      _loadedMessageIds.add(tsKey);
      return true;
    }).toList();
  }

  // ── Model conversion ──────────────────────────────────────────────────────

  ChatMessageModel _fromModel(MessageModel m) => ChatMessageModel(
        message: m.message ?? '',
        timestamp:
            DateTime.parse(m.timestamp ?? DateTime.now().toIso8601String()),
        sender: m.senderId ?? '',
        type: m.type ?? 'text',
        messageId: m.messageId,
        mediaUrl: m.mediaUrl,
        read: m.read,
        isDeleted: m.isDeleted ?? false,
        callStatus: m.callStatus,
        callDuration: m.callDuration,
        callId: m.callId,
        referenceId: m.referenceId,
      );

  bool get shouldAutoScrollForNewMessage =>
      !_hasScrolledToInitial || _keepPinnedToBottom || isAtBottom.value;

  void updateScrollPosition() {
    if (!scrollController.hasClients ||
        !scrollController.position.hasContentDimensions) {
      return;
    }
    final distanceFromBottom = scrollController.position.maxScrollExtent -
        scrollController.position.pixels;
    final atBottom = distanceFromBottom <= 48;
    if (isAtBottom.value != atBottom) isAtBottom.value = atBottom;
    _keepPinnedToBottom = atBottom;
  }

  void jumpToBottom() => _jumpToBottom();

  void scrollToBottom() {
    _scheduleBottomScroll(animate: true);
  }

  void _jumpToBottom({bool markInitial = false}) {
    _scheduleBottomScroll(animate: false, markInitial: markInitial);
  }

  void _scheduleBottomScroll({
    required bool animate,
    bool markInitial = false,
    int attemptsLeft = 6,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients ||
          !scrollController.position.hasContentDimensions) {
        if (attemptsLeft > 0) {
          _scheduleBottomScroll(
            animate: animate,
            markInitial: markInitial,
            attemptsLeft: attemptsLeft - 1,
          );
        }
        return;
      }
      final target = scrollController.position.maxScrollExtent;
      if (animate) {
        scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      } else {
        scrollController.jumpTo(target);
      }
      if (markInitial) _hasScrolledToInitial = true;
      isAtBottom.value = true;
      _keepPinnedToBottom = true;

      if (attemptsLeft > 0) {
        _scheduleBottomScroll(
          animate: false,
          markInitial: markInitial,
          attemptsLeft: attemptsLeft - 1,
        );
      }
    });
  }

  double? get _currentMaxScrollExtent {
    if (!scrollController.hasClients ||
        !scrollController.position.hasContentDimensions) {
      return null;
    }
    return scrollController.position.maxScrollExtent;
  }

  double? get _currentPixels {
    if (!scrollController.hasClients ||
        !scrollController.position.hasContentDimensions) {
      return null;
    }
    return scrollController.position.pixels;
  }

  void _preserveScrollOffsetAfterPrepend({
    required double? oldMaxScrollExtent,
    required double? oldPixels,
  }) {
    if (oldMaxScrollExtent == null || oldPixels == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients ||
          !scrollController.position.hasContentDimensions) {
        return;
      }
      final delta =
          scrollController.position.maxScrollExtent - oldMaxScrollExtent;
      scrollController.jumpTo(oldPixels + delta);
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    isAtBottom.dispose();
    super.dispose();
  }
}
