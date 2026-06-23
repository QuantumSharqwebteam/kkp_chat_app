import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:kkpchatapp/core/services/chat_storage_service.dart';
import 'package:kkpchatapp/core/utils/chat_utils.dart';
import 'package:kkpchatapp/data/models/chat_message_model.dart';
import 'package:kkpchatapp/data/models/message_model.dart';
import 'package:kkpchatapp/data/repositories/chat_reopsitory.dart';

/// Owns all message state for the customer chat screen.
/// Using a ChangeNotifier means the ListView rebuilds only when this provider
/// notifies — not on every scroll event, date-header toggle, or keyboard open.
class CustomerChatProvider extends ChangeNotifier {
  final String customerEmail;
  final String agentEmail;

  final ChatStorageService _storage = ChatStorageService();
  final ChatRepository _repo = ChatRepository();
  final ScrollController scrollController = ScrollController();
  final ValueNotifier<bool> isAtBottom = ValueNotifier(true);
  final ValueNotifier<int> messageListVersion = ValueNotifier(0);

  List<ChatMessageModel> _messages = [];
  bool _isInitialized = false;
  bool _isLoadingMore = false;
  bool _hasScrolledToInitial = false;
  bool _keepPinnedToBottom = true;

  final Set<String> _loadedMessageIds = {};
  final Set<String> _loadedCallIds = {};

  List<ChatMessageModel> get messages => _messages;
  bool get isInitialized => _isInitialized;
  bool get isLoadingMore => _isLoadingMore;

  CustomerChatProvider({required this.customerEmail, required this.agentEmail});

  void _log(String message) {
    debugPrint(
      '🧭 [CustomerChatTrace][Provider][$customerEmail] $message',
    );
  }

  void _notifyMessageListChanged(String reason) {
    messageListVersion.value++;
    _log(
      'messageListVersion=${messageListVersion.value} reason=$reason '
      'messages=${_messages.length} initialized=$_isInitialized '
      'loadingMore=$_isLoadingMore hasInitialScroll=$_hasScrolledToInitial',
    );
  }

  Future<void> resetUnreadCount() async {
    _log('resetUnreadCount:start');
    final box = await Hive.openBox<int>('${customerEmail}count');
    await box.put('count', 0);
    _log('resetUnreadCount:done');
  }

  // ── Load (cache-first → API sync → read-status) ─────────────────────────

  Future<void> load() async {
    final boxName = customerEmail;
    _log('load:start box=$boxName');
    // Customer cache can lag the API even when unread count is already reset.
    // Defer first render until cache + API are merged to avoid cache->API flicker.
    const deferInitialNotify = true;
    var hasDeferredInitialMessages = false;
    _log('load:deferInitialNotify=$deferInitialNotify');

    // Step 1: cache
    final bool boxExists = await Hive.boxExists(boxName);
    _log('load:cacheBoxExists=$boxExists');
    if (boxExists) {
      final cached = await _storage.getCustomerMessages(boxName);
      _log(
        'load:cacheFetched count=${cached.length} '
        'last=${cached.isNotEmpty ? cached.last.messageId : null}',
      );
      if (cached.isNotEmpty) {
        _messages = _removeDuplicates(cached)
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _isInitialized = true;
        hasDeferredInitialMessages = true;
        _log('load:cache deferred until API sync');
      }
    }

    if (!_isInitialized) {
      _log('load:empty state deferred until API sync');
    }

    // Step 2: API sync
    try {
      _log('load:apiFetch:start');
      final fetched = await _repo.fetchCustomerMessages(
        customerEmail: customerEmail,
        limit: 20,
      );
      final chatMessages = fetched.map(_fromModel).toList();
      final newMessages = _removeDuplicates(chatMessages);
      _log(
        'load:apiFetch:done fetched=${fetched.length} '
        'new=${newMessages.length} current=${_messages.length}',
      );

      if (!boxExists && chatMessages.isNotEmpty) {
        await _storage.saveMessages(chatMessages, boxName);
        _log('load:apiSaved all=${chatMessages.length}');
      } else if (newMessages.isNotEmpty) {
        await _storage.saveMessages(newMessages, boxName);
        _log('load:apiSaved new=${newMessages.length}');
      }

      if (_isInitialized && newMessages.isEmpty) {
        // Cache was already in sync — no rebuild needed.
        if (hasDeferredInitialMessages) {
          _notifyMessageListChanged('load.deferred-cache-api-no-new');
          _jumpToBottom(markInitial: true);
        }
        _log('load:apiNoNewMessages:return-no-rebuild');
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
      _notifyMessageListChanged(
        hasDeferredInitialMessages
            ? 'load.deferred-cache-api-new-messages'
            : 'load.api-new-messages',
      );
      if (!_hasScrolledToInitial) {
        _jumpToBottom(markInitial: true);
      } else if (newMessages.isNotEmpty && shouldStayAtBottom) {
        _jumpToBottom();
      }
    } catch (e) {
      debugPrint('[CustomerChatProvider] API sync failed: $e');
    } finally {
      if (!_isInitialized) {
        _isInitialized = true;
        _notifyMessageListChanged('load.finally-initialized');
      } else if (hasDeferredInitialMessages && messageListVersion.value == 0) {
        _notifyMessageListChanged('load.deferred-cache-fallback');
        _jumpToBottom(markInitial: true);
      }
    }

    // Step 3: read-status
    if (_messages.isEmpty) return;
    try {
      _log('load:readStatus:start');
      final lastTs = await _repo.fetchUserLastTimestamp(customerEmail);
      _log('load:readStatus:done ts=$lastTs');
      if (lastTs != null) _markReadUpTo(lastTs, notify: false);
    } catch (e) {
      debugPrint('[CustomerChatProvider] read-status sync failed: $e');
    }
  }

  // ── Pagination ───────────────────────────────────────────────────────────

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasScrolledToInitial) {
      _log(
        'loadMore:skip loadingMore=$_isLoadingMore '
        'hasInitialScroll=$_hasScrolledToInitial',
      );
      return;
    }
    _isLoadingMore = true;
    final oldMaxScrollExtent = _currentMaxScrollExtent;
    final oldPixels = _currentPixels;
    var messagesChanged = false;
    _log('loadMore:start current=${_messages.length}');

    try {
      final before = _messages.isNotEmpty
          ? _messages.first.timestamp.toIso8601String()
          : null;

      final fetched = await _repo.fetchCustomerMessages(
        customerEmail: customerEmail,
        limit: 20,
        before: before,
      );

      if (fetched.isEmpty) {
        _log('loadMore:fetched-empty return-no-rebuild');
        return;
      }

      final chatMessages = fetched.map(_fromModel).toList();
      final newMessages = _removeDuplicates(chatMessages);
      _log(
        'loadMore:fetched=${fetched.length} new=${newMessages.length} '
        'before=$before',
      );
      if (newMessages.isNotEmpty) {
        await _storage.saveMessages(newMessages, customerEmail);
        _messages.insertAll(0, newMessages);
        _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        messagesChanged = true;
      }
    } catch (e) {
      debugPrint('[CustomerChatProvider] loadMore failed: $e');
    } finally {
      _isLoadingMore = false;
      if (messagesChanged) {
        _notifyMessageListChanged('loadMore.new-messages');
        _preserveScrollOffsetAfterPrepend(
          oldMaxScrollExtent: oldMaxScrollExtent,
          oldPixels: oldPixels,
        );
      } else {
        _log('loadMore:done no-message-change');
      }
    }
  }

  // ── Incoming socket message ───────────────────────────────────────────────

  void addIncoming(Map<String, dynamic> data) {
    final shouldStayAtBottom = shouldAutoScrollForNewMessage;
    DateTime timestamp;
    try {
      timestamp = DateTime.parse(data['timestamp'] as String);
    } catch (_) {
      timestamp = DateTime.now();
    }

    final messageId = data['messageId'] as String?;
    final tsKey = 'ts:${timestamp.millisecondsSinceEpoch}';

    if ((messageId != null && _loadedMessageIds.contains(messageId)) ||
        _loadedMessageIds.contains(tsKey)) {
      _log('addIncoming:duplicate messageId=$messageId tsKey=$tsKey');
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
    _notifyMessageListChanged('socket.addIncoming messageId=$messageId');
    if (shouldStayAtBottom) scrollToBottom();

    _storage.saveMessage(msg, customerEmail);
  }

  // ── Sent message (optimistic add) ────────────────────────────────────────

  void addSent(ChatMessageModel msg) {
    _messages.add(msg);
    _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (msg.messageId != null) _loadedMessageIds.add(msg.messageId!);
    _loadedMessageIds.add('ts:${msg.timestamp.millisecondsSinceEpoch}');
    _notifyMessageListChanged('send.addSent messageId=${msg.messageId}');
    scrollToBottom();
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  void markDeleted(String messageId) {
    final idx = _messages.indexWhere((m) => m.messageId == messageId);
    if (idx == -1) return;
    _messages[idx].isDeleted = true;
    _messages[idx].message = 'This message is deleted';
    _notifyMessageListChanged('delete.markDeleted messageId=$messageId');
  }

  // ── Read status ───────────────────────────────────────────────────────────

  void markReadUpToTimestamp(DateTime ts) => _markReadUpTo(ts);

  void _markReadUpTo(DateTime ts, {bool notify = true}) {
    bool changed = false;
    for (final msg in _messages) {
      if (msg.read != true &&
          (msg.timestamp.isBefore(ts) || msg.timestamp == ts)) {
        msg.read = true;
        changed = true;
      }
    }
    if (!changed) return;
    _log('markReadUpTo changed notify=$notify ts=$ts');
    if (notify) notifyListeners();
    for (final msg in _messages) {
      if (msg.read == true) _storage.saveMessage(msg, customerEmail);
    }
  }

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

  // ── Temp/utility ─────────────────────────────────────────────────────────

  /// Adds a placeholder message (e.g. "Sending document…") while an upload
  /// is in progress. Returns the placeholder so the caller can remove it later.
  ChatMessageModel addOptimistic(String text, String sender) {
    final msg = ChatMessageModel(
      message: text,
      timestamp: DateTime.now(),
      sender: sender,
    );
    _messages.add(msg);
    _notifyMessageListChanged('optimistic.add text=$text');
    scrollToBottom();
    return msg;
  }

  void removeOptimistic(String messageText) {
    _messages.removeWhere((m) => m.message == messageText);
    _notifyMessageListChanged('optimistic.remove text=$messageText');
  }

  /// Saves a message to Hive after a delete-soft-undo path.
  void persistMessage(ChatMessageModel msg) {
    _storage.saveMessage(msg, customerEmail);
  }

  String generateMessageId() => ChatUtils().generateMessageId();

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
      _log(
        'scrollToBottom applied animate=$animate markInitial=$markInitial '
        'target=$target attemptsLeft=$attemptsLeft',
      );

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
    messageListVersion.dispose();
    super.dispose();
  }
}
