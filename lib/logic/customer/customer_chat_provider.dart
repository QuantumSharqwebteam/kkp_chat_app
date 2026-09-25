import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

  /// Frames of unchanged scroll extent before a bottom-pin run is considered
  /// settled, and the absolute ceiling on one run (~2s at 60fps).
  static const int _bottomScrollSettleTicks = 8;
  static const int _bottomScrollMaxTicks = 120;

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
  bool _disposed = false;

  /// False once the server reports no more history above [_oldestCursor].
  bool _hasMoreOlder = true;

  /// Strictly-decreasing pagination cursor.
  DateTime? _oldestCursor;

  // Bottom-pin loop state.
  bool _bottomScrollScheduled = false;
  bool _bottomScrollAnimate = false;
  bool _pendingMarkInitial = false;
  int _bottomScrollStableTicks = 0;
  int _bottomScrollTotalTicks = 0;
  double? _lastBottomExtent;

  final Set<String> _loadedMessageIds = {};
  final Set<String> _loadedCallIds = {};

  /// messageId -> message. O(1) reply lookup; the screen used to scan the whole
  /// list per row, which is O(messages²) for one full list rebuild.
  final Map<String, ChatMessageModel> _byId = {};

  List<ChatMessageModel> get messages => _messages;
  bool get isInitialized => _isInitialized;
  bool get isLoadingMore => _isLoadingMore;

  CustomerChatProvider({required this.customerEmail, required this.agentEmail});

  /// Verbose load/scroll tracing. Compiled out of release builds — debugPrint
  /// is not, and these fire on hot paths.
  void _log(String message) {
    if (!kDebugMode) return;
    debugPrint(
      '🧭 [CustomerChatTrace][Provider][$customerEmail] $message',
    );
  }

  /// Single funnel for every message-list mutation. The ListView listens to
  /// messageListVersion, so a mutation that only calls notifyListeners() would
  /// not repaint — which is why read ticks used to stay grey until something
  /// else happened to bump the version.
  void _notifyMessageListChanged(String reason) {
    if (_disposed) return;
    messageListVersion.value++;
    notifyListeners();
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
    if (_disposed) return;
    _log('load:cacheBoxExists=$boxExists');
    if (boxExists) {
      final cached = await _storage.getCustomerMessages(boxName);
      if (_disposed) return;
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
      if (_disposed) return;
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
        // Cache was already in sync — no rebuild needed, but fall through to
        // the read-status sync below (this used to return and skip it, so read
        // ticks never synced on the common path).
        if (hasDeferredInitialMessages) {
          _notifyMessageListChanged('load.deferred-cache-api-no-new');
          _jumpToBottom(markInitial: true);
        }
        _log('load:apiNoNewMessages:no-rebuild');
      } else {
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

    if (_disposed) return;
    _oldestCursor = _messages.isEmpty ? null : _messages.first.timestamp;

    // Step 3: read-status
    if (_messages.isEmpty) return;
    try {
      _log('load:readStatus:start');
      final lastTs = await _repo.fetchUserLastTimestamp(customerEmail);
      if (_disposed) return;
      _log('load:readStatus:done ts=$lastTs');
      // Notify: this lands after the list has already rendered, so without it
      // the ticks stay grey until some unrelated change repaints them.
      if (lastTs != null) _markReadUpTo(lastTs);
    } catch (e) {
      debugPrint('[CustomerChatProvider] read-status sync failed: $e');
    }
  }

  // ── Pagination ───────────────────────────────────────────────────────────

  Future<void> loadMore() async {
    if (_disposed ||
        _isLoadingMore ||
        !_hasScrolledToInitial ||
        !_hasMoreOlder) {
      _log(
        'loadMore:skip loadingMore=$_isLoadingMore '
        'hasInitialScroll=$_hasScrolledToInitial hasMore=$_hasMoreOlder',
      );
      return;
    }
    _isLoadingMore = true;
    final oldMaxScrollExtent = _currentMaxScrollExtent;
    final oldPixels = _currentPixels;
    var messagesChanged = false;
    _log('loadMore:start current=${_messages.length}');

    try {
      // Explicit cursor rather than _messages.first: a page that comes back as
      // pure duplicates must still advance it, or every scroll at the top
      // re-issues the identical request forever.
      final cursor = _oldestCursor ??
          (_messages.isEmpty ? null : _messages.first.timestamp);

      final fetched = await _repo.fetchCustomerMessages(
        customerEmail: customerEmail,
        limit: 20,
        before: cursor?.toIso8601String(),
      );
      if (_disposed) return;

      if (fetched.isEmpty) {
        // Genuinely the start of history. Never infer this from a short page.
        _hasMoreOlder = false;
        _log('loadMore:fetched-empty return-no-rebuild');
        return;
      }

      final chatMessages = fetched.map(_fromModel).toList();

      DateTime? oldest;
      for (final msg in chatMessages) {
        if (oldest == null || msg.timestamp.isBefore(oldest)) {
          oldest = msg.timestamp;
        }
      }
      if (oldest != null) {
        if (cursor != null && !oldest.isBefore(cursor)) {
          _hasMoreOlder = false;
        } else {
          _oldestCursor = oldest;
        }
      }

      final newMessages = _removeDuplicates(chatMessages);
      _log(
        'loadMore:fetched=${fetched.length} new=${newMessages.length} '
        'before=$cursor',
      );
      if (newMessages.isNotEmpty) {
        await _storage.saveMessages(newMessages, customerEmail);
        if (_disposed) return;
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
    if (_disposed) return;
    final shouldStayAtBottom = shouldAutoScrollForNewMessage;
    DateTime timestamp;
    try {
      timestamp = DateTime.parse(data['timestamp'] as String);
    } catch (_) {
      timestamp = DateTime.now();
    }

    // The server returns '_id' on some paths; the background writer already
    // hedges the same way, so honour it here or the two disagree and duplicate.
    final messageId = (data['messageId'] ?? data['_id'])?.toString();
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
    _index(msg);
    _notifyMessageListChanged('socket.addIncoming messageId=$messageId');
    if (shouldStayAtBottom) scrollToBottom();

    unawaited(_storage.saveMessage(msg, customerEmail));
  }

  // ── Sent message (optimistic add) ────────────────────────────────────────

  void addSent(ChatMessageModel msg) {
    if (_disposed) return;
    _messages.add(msg);
    _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (msg.messageId != null) _loadedMessageIds.add(msg.messageId!);
    _loadedMessageIds.add('ts:${msg.timestamp.millisecondsSinceEpoch}');
    _index(msg);
    _notifyMessageListChanged('send.addSent messageId=${msg.messageId}');
    scrollToBottom();
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  /// Returns true only when [messageId] belongs to THIS conversation.
  /// The socket's messageDeleted dispatch is not filtered by customer, so
  /// callers must gate their side effects on the return value.
  bool markDeleted(String messageId) {
    if (_disposed) return false;
    final msg = _byId[messageId];
    if (msg == null) return false;
    if (msg.isDeleted) return true;
    msg.isDeleted = true;
    msg.message = 'This message is deleted';
    _notifyMessageListChanged('delete.markDeleted messageId=$messageId');
    unawaited(_storage.saveMessage(msg, customerEmail));
    return true;
  }

  // ── Read status ───────────────────────────────────────────────────────────

  void markReadUpToTimestamp(DateTime ts) => _markReadUpTo(ts);

  void _markReadUpTo(DateTime ts, {bool notify = true}) {
    if (_disposed) return;
    // `!isAfter` rather than `isBefore || ==`: DateTime.== also compares the
    // isUtc flag, so with API timestamps parsed as UTC and socket ones as local
    // the boundary message would never be marked read.
    final changed = <ChatMessageModel>[];
    for (final msg in _messages) {
      if (msg.read != true && !msg.timestamp.isAfter(ts)) {
        msg.read = true;
        changed.add(msg);
      }
    }
    if (changed.isEmpty) return;
    _log('markReadUpTo changed=${changed.length} notify=$notify ts=$ts');
    // Must go through the version funnel — the ListView listens to
    // messageListVersion, so a bare notifyListeners() left ticks stale.
    if (notify) _notifyMessageListChanged('markReadUpTo');
    // One batched write of only what changed, not N writes of every read row.
    unawaited(_storage.saveMessages(changed, customerEmail));
  }

  // ── Deduplication ─────────────────────────────────────────────────────────

  List<ChatMessageModel> _removeDuplicates(List<ChatMessageModel> list) {
    return list.where((msg) {
      if (msg.type == 'call') {
        if (msg.callId == null || _loadedCallIds.contains(msg.callId)) {
          return false;
        }
        _loadedCallIds.add(msg.callId!);
        _index(msg);
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
      _index(msg);
      return true;
    }).toList();
  }

  // ── Message index ─────────────────────────────────────────────────────────

  /// The message with [id], if it is still loaded in this chat.
  ChatMessageModel? messageById(String? id) =>
      (id == null || id.isEmpty) ? null : _byId[id];

  void _index(ChatMessageModel msg) {
    final id = msg.messageId;
    if (id != null && id.isNotEmpty) _byId[id] = msg;
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
    if (_disposed ||
        !scrollController.hasClients ||
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
  }) {
    if (_disposed) return;
    if (markInitial) _pendingMarkInitial = true;
    if (animate) _bottomScrollAnimate = true;
    // Restart the settle window; an in-flight loop picks the new target up.
    _bottomScrollStableTicks = 0;
    _bottomScrollTotalTicks = 0;
    _lastBottomExtent = null;
    if (_bottomScrollScheduled) return;
    _bottomScrollScheduled = true;
    _tickBottomScroll();
  }

  /// Keeps re-pinning to the bottom until the scroll extent stops growing.
  ///
  /// A ListView.builder only *estimates* maxScrollExtent until its children are
  /// laid out, and image bubbles resize again when their bitmaps arrive. A
  /// fixed handful of retries (what this used to do) lands short of the real
  /// bottom on a busy chat, and — worse — the short landing then clears
  /// _keepPinnedToBottom, so later messages stop auto-scrolling too.
  void _tickBottomScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed) {
        _bottomScrollScheduled = false;
        return;
      }

      if (!scrollController.hasClients ||
          !scrollController.position.hasContentDimensions) {
        _continueOrStopBottomScroll(extentChanged: false);
        return;
      }

      final position = scrollController.position;

      // Never fight the user: if they have started dragging, stop pinning.
      if (position.userScrollDirection != ScrollDirection.idle) {
        _bottomScrollScheduled = false;
        _pendingMarkInitial = false;
        _bottomScrollAnimate = false;
        return;
      }

      final target = position.maxScrollExtent;
      if ((target - position.pixels).abs() > 1.0) {
        if (_bottomScrollAnimate) {
          scrollController.animateTo(
            target,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
          );
        } else {
          scrollController.jumpTo(target);
        }
      }
      // Only the first hop of a run animates; the settle hops are instant.
      _bottomScrollAnimate = false;

      if (_pendingMarkInitial) {
        _hasScrolledToInitial = true;
        _pendingMarkInitial = false;
      }
      isAtBottom.value = true;
      _keepPinnedToBottom = true;

      final extentChanged = _lastBottomExtent == null ||
          (target - _lastBottomExtent!).abs() > 0.5;
      _lastBottomExtent = target;
      _continueOrStopBottomScroll(extentChanged: extentChanged);
    });
  }

  void _continueOrStopBottomScroll({required bool extentChanged}) {
    // Every time the content grows, give it a fresh settle window.
    if (extentChanged) _bottomScrollStableTicks = 0;
    _bottomScrollStableTicks++;
    _bottomScrollTotalTicks++;

    if (_bottomScrollStableTicks >= _bottomScrollSettleTicks ||
        _bottomScrollTotalTicks >= _bottomScrollMaxTicks) {
      _bottomScrollScheduled = false;
      _pendingMarkInitial = false;
      _lastBottomExtent = null;
      return;
    }
    _tickBottomScroll();
  }

  double? get _currentMaxScrollExtent {
    if (_disposed ||
        !scrollController.hasClients ||
        !scrollController.position.hasContentDimensions) {
      return null;
    }
    return scrollController.position.maxScrollExtent;
  }

  double? get _currentPixels {
    if (_disposed ||
        !scrollController.hasClients ||
        !scrollController.position.hasContentDimensions) {
      return null;
    }
    return scrollController.position.pixels;
  }

  void _preserveScrollOffsetAfterPrepend({
    required double? oldMaxScrollExtent,
    required double? oldPixels,
  }) {
    if (_disposed || oldMaxScrollExtent == null || oldPixels == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed) return;
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
    _disposed = true;
    scrollController.dispose();
    isAtBottom.dispose();
    messageListVersion.dispose();
    super.dispose();
  }
}
