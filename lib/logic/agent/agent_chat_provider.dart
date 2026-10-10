import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hive/hive.dart';
import 'package:kkpchatapp/core/services/chat_storage_service.dart';
import 'package:kkpchatapp/core/services/connectivity_service.dart';
import 'package:kkpchatapp/core/services/socket_service.dart';
import 'package:kkpchatapp/core/utils/chat_utils.dart';
import 'package:kkpchatapp/data/models/chat_message_model.dart';
import 'package:kkpchatapp/data/models/message_model.dart';
import 'package:kkpchatapp/data/repositories/chat_reopsitory.dart';
import 'package:kkpchatapp/main.dart';

/// Owns all message state for the agent chat screen.
///
/// Messages are loaded cache-first from Hive for an instant first paint, then
/// synced from `GET /chat/getUserMessages/{customerEmail}` — the only network
/// source this provider uses. Older history is paged with that same endpoint's
/// `before` cursor.
///
/// Notifying listeners only when messages actually change means the ListView
/// rebuilds in isolation — scroll events and date-header visibility never
/// trigger a full-screen rebuild.
///
/// Call logs: the server writes a call as "missed" while it rings and only
/// later overwrites it with "answered" + duration. Every path that sees the
/// same callId twice (cache, API, socket, local CallProvider bubble) MERGES
/// into the one loaded bubble, and a status can only move up:
///   unknown < missed < not answered/declined < answered
class AgentChatProvider extends ChangeNotifier {
  final String agentEmail;
  final String customerEmail;

  static const int _pageSize = 20;

  /// Frames of unchanged scroll extent before a bottom-pin run is considered
  /// settled, and the absolute ceiling on one run (~2s at 60fps).
  static const int _bottomScrollSettleTicks = 8;
  static const int _bottomScrollMaxTicks = 120;

  /// While a recent call still shows the ringing placeholder, re-sync a few
  /// times so the caller's final "answered" write is picked up without the
  /// user leaving and re-opening the chat.
  static const Duration _callRecheckDelay = Duration(seconds: 3);
  static const int _maxCallRechecks = 5;
  static const Duration _recentCallWindow = Duration(minutes: 3);

  final ChatStorageService _storage = ChatStorageService();
  final ChatRepository _repo = ChatRepository();
  final SocketService _socket = SocketService(navigatorKey);
  final ScrollController scrollController = ScrollController();
  final ValueNotifier<bool> isAtBottom = ValueNotifier(true);

  /// Bumped on every message-list mutation. The ListView subtree listens to
  /// this alone, so pagination spinners and scroll state never rebuild it.
  final ValueNotifier<int> messageListVersion = ValueNotifier(0);

  /// Drives the pagination spinner without rebuilding the ListView.
  final ValueNotifier<bool> isLoadingMoreNotifier = ValueNotifier(false);

  List<ChatMessageModel> _messages = [];
  bool _isInitialized = false;
  bool _isLoadingMore = false;
  bool _hasScrolledToInitial = false;
  bool _keepPinnedToBottom = true;
  bool _disposed = false;
  bool _isRefreshing = false;

  /// False once the server reports no more history above [_oldestCursor].
  bool _hasMoreOlder = true;

  /// Strictly-decreasing pagination cursor. Deliberately NOT derived from
  /// `_messages.first` — a page that returns only duplicates must still advance
  /// it, or scrolling at the top re-issues the same request forever.
  DateTime? _oldestCursor;

  /// messageId -> message. O(1) reply lookup and O(1) delete.
  final Map<String, ChatMessageModel> _byId = {};

  /// callId -> the ONE call bubble shown for that call. API call logs carry no
  /// messageId, so without this index a repaired status could never be found.
  final Map<String, ChatMessageModel> _byCallId = {};

  final Set<String> _loadedMessageIds = {};
  final Set<String> _loadedCallIds = {};

  /// Loaded call bubbles upgraded by a merge that the caller hasn't persisted
  /// or announced yet. Drained with [_takeRepaired].
  final List<ChatMessageModel> _repaired = [];

  Timer? _callRecheckTimer;
  int _callRecheckCount = 0;

  StreamSubscription<bool>? _connectivitySub;

  // Bottom-pin loop state.
  bool _bottomScrollScheduled = false;
  bool _bottomScrollAnimate = false;
  bool _pendingMarkInitial = false;
  int _bottomScrollStableTicks = 0;
  int _bottomScrollTotalTicks = 0;
  double? _lastBottomExtent;

  List<ChatMessageModel> get messages => _messages;
  bool get isInitialized => _isInitialized;
  bool get isLoadingMore => _isLoadingMore;

  String get _boxName => '$agentEmail$customerEmail';

  AgentChatProvider({required this.agentEmail, required this.customerEmail}) {
    _socket.onCallLogUpdated(_onSocketCallLogUpdated);
  }

  // ── Change notification ───────────────────────────────────────────────────

  /// Single funnel for every message-list mutation. Bumps the fine-grained
  /// notifier AND fires notifyListeners(), so a listener may use either.
  /// No message mutation may call notifyListeners() directly — read-status
  /// updates included, or read ticks would not repaint.
  void _notifyMessageListChanged() {
    if (_disposed) return;
    messageListVersion.value++;
    notifyListeners();
  }

  // ── Message index ─────────────────────────────────────────────────────────

  /// The message with [id], if it is still loaded in this chat.
  ChatMessageModel? messageById(String? id) =>
      (id == null || id.isEmpty) ? null : _byId[id];

  void _index(ChatMessageModel msg) {
    final id = msg.messageId;
    if (id != null && id.isNotEmpty) _byId[id] = msg;
    final callId = msg.callId;
    if (msg.type == 'call' && callId != null && callId.isNotEmpty) {
      _byCallId[callId] = msg;
    }
  }

  void _indexAll(Iterable<ChatMessageModel> msgs) {
    for (final msg in msgs) {
      _index(msg);
    }
  }

  // ── Call-log merging ──────────────────────────────────────────────────────

  static int _callRank(String? status) {
    switch (status) {
      case 'answered':
        return 3;
      case 'not answered':
      case 'declined':
        return 2;
      case 'missed':
        return 1;
      default:
        return 0; // null / "ringing" / unknown placeholder
    }
  }

  /// Copies call fields from [src] into [target] without ever downgrading.
  /// Returns true when [target] changed.
  bool _mergeCallFields(ChatMessageModel target, ChatMessageModel src) {
    var changed = false;
    final rt = _callRank(target.callStatus);
    final rs = _callRank(src.callStatus);

    if (src.callStatus != null && rs > rt) {
      target.callStatus = src.callStatus;
      changed = true;
    }
    if (rs >= rt) {
      final d = src.callDuration;
      if (d != null && d.isNotEmpty && d != target.callDuration) {
        target.callDuration = d;
        changed = true;
      }
    }
    if ((target.callerId == null || target.callerId!.isEmpty) &&
        src.callerId != null &&
        src.callerId!.isNotEmpty) {
      target.callerId = src.callerId;
      changed = true;
    }
    if (target.callId == null && src.callId != null) {
      target.callId = src.callId;
      changed = true;
    }
    if (target.messageId == null && src.messageId != null) {
      target.messageId = src.messageId;
      _index(target);
      changed = true;
    }
    return changed;
  }

  void _markRepaired(ChatMessageModel msg) {
    if (!_repaired.any((m) => identical(m, msg))) _repaired.add(msg);
  }

  List<ChatMessageModel> _takeRepaired() {
    final out = List<ChatMessageModel>.from(_repaired);
    _repaired.clear();
    return out;
  }

  /// Socket → a call's final status is known (from our own CallProvider via
  /// SocketService.patchCallLog, or from a server `callLogUpdated` event).
  void _onSocketCallLogUpdated(Map<String, dynamic> data) {
    if (_disposed) return;
    final peer = data['peerEmail']?.toString();
    if (peer != null &&
        peer.isNotEmpty &&
        peer.toLowerCase() != customerEmail.toLowerCase()) {
      return; // another conversation
    }
    applyCallLogUpdate(data);
  }

  /// Patches the loaded call bubble matching `callId` / `_id`.
  /// Returns false when that call isn't in this chat (yet).
  bool applyCallLogUpdate(Map<String, dynamic> data) {
    if (_disposed) return false;
    final callId = data['callId']?.toString();
    final logId = (data['_id'] ?? data['messageId'])?.toString();

    ChatMessageModel? target =
        (callId != null && callId.isNotEmpty) ? _byCallId[callId] : null;
    target ??= (logId != null && logId.isNotEmpty) ? _byId[logId] : null;
    if (target == null) {
      // Not loaded yet — pull it in.
      unawaited(refreshLatest(reason: 'call-log-update'));
      return false;
    }

    final src = ChatMessageModel(
      timestamp: target.timestamp,
      type: 'call',
      callStatus: data['callStatus']?.toString(),
      callDuration: data['callDuration']?.toString(),
      callId: callId,
      callerId: data['callerId']?.toString(),
    );
    if (!_mergeCallFields(target, src)) return true;

    debugPrint('[AgentChatProvider] call ${target.callId} → '
        '${target.callStatus} ${target.callDuration ?? ''}');
    _notifyMessageListChanged();
    unawaited(_storage.saveMessage(target, _boxName));
    return true;
  }

  bool _hasUnfinishedRecentCall() {
    final now = DateTime.now();
    return _messages.any((m) =>
        m.type == 'call' &&
        _callRank(m.callStatus) <= 1 &&
        now.difference(m.timestamp).abs() < _recentCallWindow);
  }

  void _scheduleCallRecheckIfNeeded() {
    if (_disposed) return;
    _callRecheckTimer?.cancel();
    if (!_hasUnfinishedRecentCall()) {
      _callRecheckCount = 0;
      return;
    }
    if (_callRecheckCount >= _maxCallRechecks) return;
    _callRecheckCount++;
    debugPrint('[AgentChatProvider] recent call still unfinished — recheck '
        '$_callRecheckCount/$_maxCallRechecks in ${_callRecheckDelay.inSeconds}s');
    _callRecheckTimer = Timer(_callRecheckDelay, () {
      if (!_disposed) unawaited(refreshLatest(reason: 'call-recheck'));
    });
  }

  // ── Initial load (cache-first → API sync → read-status) ─────────────────

  Future<void> load() async {
    // Step 1: Hive cache — instant, no network. Bounded to one page so opening
    // a long conversation does not decode the entire box before first frame.
    final bool boxExists = await Hive.boxExists(_boxName);
    if (_disposed) return;
    if (boxExists) {
      final cached =
          await _storage.getMessageWindow(_boxName, limit: _pageSize);
      if (_disposed) return;
      if (cached.isNotEmpty) {
        _messages = _removeDuplicates(cached)
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _indexAll(_messages);
        // Duplicate cache rows of one call were merged — persist the winner.
        final repaired = _takeRepaired();
        if (repaired.isNotEmpty) {
          unawaited(_storage.saveMessages(repaired, _boxName));
        }
        _isInitialized = true;
        _notifyMessageListChanged();
        _jumpToBottom(markInitial: true);
      }
    }

    // Mark initialized even with empty cache so the screen shows
    // empty state (not shimmer) while the API call is in flight.
    if (!_isInitialized) {
      _isInitialized = true;
      _notifyMessageListChanged();
    }

    // Step 2: Silent background API sync. Upsert (not skip) so cached rows —
    // especially call logs cached as "missed" while ringing — get repaired.
    try {
      final fetched = await _repo.fetchCustomerMessages(
        customerEmail: customerEmail,
        limit: _pageSize,
      );
      if (_disposed) return;
      final shouldStayAtBottom = shouldAutoScrollForNewMessage;
      final countBefore = _messages.length;

      final touched = _upsertFromApi(fetched.map(_fromModel).toList());
      if (touched.isNotEmpty) {
        await _storage.saveMessages(touched, _boxName);
        if (_disposed) return;

        _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _notifyMessageListChanged();
        final added = _messages.length > countBefore;
        if (!_hasScrolledToInitial) {
          _jumpToBottom(markInitial: true);
        } else if (added && shouldStayAtBottom) {
          _jumpToBottom();
        }
      }
    } catch (e) {
      debugPrint('[AgentChatProvider] API sync failed: $e');
    } finally {
      if (!_isInitialized) {
        _isInitialized = true;
        _notifyMessageListChanged();
      }
    }

    if (_disposed) return;
    _oldestCursor = _messages.isEmpty ? null : _messages.first.timestamp;
    _scheduleCallRecheckIfNeeded();

    // Step 3: Read-status sync
    if (_messages.isEmpty) return;
    try {
      final result = await _repo.fetchCustomerLastMessageTimestampForAgent(
        customerEmail: customerEmail,
        agentEmail: agentEmail,
      );
      if (_disposed) return;
      final ts = result?['lastUserReadTimestamp'] as DateTime?;
      if (ts != null) _markReadUpTo(ts);
    } catch (e) {
      debugPrint('[AgentChatProvider] read-status sync failed: $e');
    }
  }

  // ── Pagination (load older messages) ─────────────────────────────────────

  Future<void> loadMore() async {
    if (_disposed ||
        _isLoadingMore ||
        !_hasScrolledToInitial ||
        !_hasMoreOlder) {
      return;
    }
    _isLoadingMore = true;
    isLoadingMoreNotifier.value = true;

    final oldMaxScrollExtent = _currentMaxScrollExtent;
    final oldPixels = _currentPixels;
    var messagesChanged = false;

    try {
      final cursor = _oldestCursor;
      List<ChatMessageModel> older;

      if (ConnectivityService.instance.isOnline) {
        final fetched = await _repo.fetchCustomerMessages(
          customerEmail: customerEmail,
          limit: _pageSize,
          before: cursor?.toIso8601String(),
        );
        if (_disposed) return;

        if (fetched.isEmpty) {
          // Genuinely the start of history. Never infer this from a short page.
          _hasMoreOlder = false;
          return;
        }
        older = fetched.map(_fromModel).toList();
      } else {
        // Offline: serve older history from cache, but never conclude that the
        // server has nothing more — it may simply not be cached yet.
        older = await _storage.getMessageWindow(
          _boxName,
          limit: _pageSize,
          before: cursor,
        );
        if (_disposed) return;
        if (older.isEmpty) return;
      }

      // Advance the cursor even when every row turns out to be a duplicate,
      // otherwise the next top-edge scroll re-issues the identical request.
      DateTime? oldest;
      for (final msg in older) {
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

      final unique = _removeDuplicates(older);
      final repaired = _takeRepaired();
      if (unique.isNotEmpty || repaired.isNotEmpty) {
        await _storage.saveMessages([...unique, ...repaired], _boxName);
        if (_disposed) return;
        if (unique.isNotEmpty) {
          _messages.insertAll(0, unique);
          _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          _indexAll(unique);
        }
        messagesChanged = true;
      }
    } catch (e) {
      debugPrint('[AgentChatProvider] loadMore failed: $e');
    } finally {
      _isLoadingMore = false;
      if (!_disposed) {
        isLoadingMoreNotifier.value = false;
        if (messagesChanged) {
          _notifyMessageListChanged();
          _preserveScrollOffsetAfterPrepend(
            oldMaxScrollExtent: oldMaxScrollExtent,
            oldPixels: oldPixels,
          );
        }
      }
    }
  }

  // ── Catch-up sync (resume / reconnect / route return) ─────────────────────

  /// Merges everything that arrived while this chat was backgrounded, offline,
  /// or covered by another route: the newest cached window (written by
  /// SocketService's background handler) plus one `getUserMessages?limit=20`.
  /// Never moves the pagination cursor, and only scrolls when the user is
  /// already pinned to the bottom.
  Future<void> refreshLatest({String reason = 'manual'}) async {
    if (_disposed || _isRefreshing || !_isInitialized) return;
    _isRefreshing = true;
    debugPrint('[AgentChatProvider] refreshLatest($reason)');

    try {
      final shouldStayAtBottom = shouldAutoScrollForNewMessage;
      var changed = false;

      // 1. Cache — surfaces messages the socket wrote while the chat page was
      //    flagged closed, and call statuses patched by SocketService.
      try {
        final cached =
            await _storage.getMessageWindow(_boxName, limit: _pageSize);
        if (_disposed) return;
        final fresh = _removeDuplicates(cached);
        if (fresh.isNotEmpty) {
          _messages.addAll(fresh);
          _indexAll(fresh);
          changed = true;
        }
        if (_takeRepaired().isNotEmpty) changed = true;
      } catch (e) {
        debugPrint('[AgentChatProvider] refreshLatest cache read failed: $e');
      }

      // 2. API — authoritative, and repairs fields the background writer drops.
      try {
        final fetched = await _repo.fetchCustomerMessages(
          customerEmail: customerEmail,
          limit: _pageSize,
        );
        if (_disposed) return;
        final incoming = fetched.map(_fromModel).toList();
        final touched = _upsertFromApi(incoming);
        if (touched.isNotEmpty) {
          changed = true;
          await _storage.saveMessages(touched, _boxName);
          if (_disposed) return;
        }
      } catch (e) {
        debugPrint('[AgentChatProvider] refreshLatest API sync failed: $e');
      }

      if (changed) {
        _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _notifyMessageListChanged();
        if (shouldStayAtBottom) _jumpToBottom();
      }

      // 3. Read status may also have moved while we were away.
      if (_messages.isEmpty) return;
      try {
        final result = await _repo.fetchCustomerLastMessageTimestampForAgent(
          customerEmail: customerEmail,
          agentEmail: agentEmail,
        );
        if (_disposed) return;
        final ts = result?['lastUserReadTimestamp'] as DateTime?;
        if (ts != null) _markReadUpTo(ts);
      } catch (e) {
        debugPrint('[AgentChatProvider] refreshLatest read-status failed: $e');
      }
    } finally {
      _isRefreshing = false;
      _scheduleCallRecheckIfNeeded();
    }
  }

  Future<void> handleAppResumed() => refreshLatest(reason: 'app-resumed');

  /// Idempotent. Re-syncs when the device comes back online.
  void attachConnectivity() {
    if (_disposed) return;
    _connectivitySub ??=
        ConnectivityService.instance.onConnectivityChanged.listen((online) {
      if (_disposed || !online) return;
      unawaited(refreshLatest(reason: 'connectivity-restored'));
    });
  }

  /// Merges a fresh API window into the in-memory list. Rows already present
  /// are REPAIRED in place rather than discarded, because the background socket
  /// writer drops referenceId / callId / callStatus / callDuration / form.
  /// Every rule is monotonic, so a refresh can never regress state.
  /// Returns the rows that actually changed, for one batched Hive write.
  List<ChatMessageModel> _upsertFromApi(List<ChatMessageModel> incoming) {
    final touched = <ChatMessageModel>[];

    for (final msg in incoming) {
      // Call logs from the API have no messageId — match them by callId.
      ChatMessageModel? existing;
      final callId = msg.callId;
      if (msg.type == 'call' && callId != null && callId.isNotEmpty) {
        existing = _byCallId[callId];
      }
      final id = msg.messageId;
      existing ??= (id != null && id.isNotEmpty) ? _byId[id] : null;

      if (existing == null) {
        final fresh = _removeDuplicates([msg]);
        if (fresh.isNotEmpty) {
          _messages.addAll(fresh);
          _indexAll(fresh);
          touched.addAll(fresh);
        }
        continue;
      }

      var changed = false;

      if (msg.read == true && existing.read != true) {
        existing.read = true;
        changed = true;
      }
      if (msg.isDeleted && !existing.isDeleted) {
        existing.isDeleted = true;
        existing.message = 'This message is deleted';
        changed = true;
      }

      if (existing.referenceId == null && msg.referenceId != null) {
        existing.referenceId = msg.referenceId;
        changed = true;
      }
      if (existing.mediaUrl == null && msg.mediaUrl != null) {
        existing.mediaUrl = msg.mediaUrl;
        changed = true;
      }

      // Call fields: upgrade-only (missed → answered), never the reverse.
      if (msg.type == 'call' || existing.type == 'call') {
        if (_mergeCallFields(existing, msg)) changed = true;
      }

      if (existing.form == null && msg.form != null) {
        existing.form = msg.form;
        changed = true;
      }
      if (existing.forms == null && msg.forms != null) {
        existing.forms = msg.forms;
        changed = true;
      }

      // A deleted message keeps its tombstone text and type.
      if (!existing.isDeleted) {
        if (msg.type != null && existing.type != msg.type) {
          existing.type = msg.type;
          changed = true;
        }
        if (msg.message != null && existing.message != msg.message) {
          existing.message = msg.message;
          changed = true;
        }
      }

      if (changed) touched.add(existing);
    }

    for (final r in _takeRepaired()) {
      if (!touched.any((t) => identical(t, r))) touched.add(r);
    }
    return touched;
  }

  // ── Incoming socket message ───────────────────────────────────────────────

  void addIncoming(Map<String, dynamic> data) {
    if (_disposed) return;
    final shouldStayAtBottom = shouldAutoScrollForNewMessage;
    final tsRaw = data['timestamp'];
    final timestamp = tsRaw != null
        ? DateTime.tryParse(tsRaw.toString()) ?? DateTime.now()
        : DateTime.now();

    // The server returns '_id' on some paths; the background writer already
    // hedges the same way, so honour it here or the two disagree and duplicate.
    final messageId = (data['messageId'] ?? data['_id'])?.toString();
    final type = data['type']?.toString() ?? 'text';
    final callId = data['callId']?.toString();

    // A call log for a call we already show is an UPDATE, not a new bubble.
    if (type == 'call' &&
        callId != null &&
        callId.isNotEmpty &&
        (_byCallId.containsKey(callId) || _loadedCallIds.contains(callId))) {
      applyCallLogUpdate(data);
      return;
    }

    final tsKey = 'ts:${timestamp.millisecondsSinceEpoch}';

    if ((messageId != null && _loadedMessageIds.contains(messageId)) ||
        _loadedMessageIds.contains(tsKey)) {
      return;
    }

    final callerId = data['callerId']?.toString();
    final msg = ChatMessageModel(
      message: data['message']?.toString() ?? '',
      timestamp: timestamp,
      sender: (data['senderId'] ?? callerId)?.toString() ?? '',
      callerId: type == 'call'
          ? (callerId ?? data['senderId']?.toString())
          : callerId,
      type: type,
      mediaUrl: data['mediaUrl']?.toString(),
      callStatus: data['callStatus']?.toString(),
      callDuration: data['callDuration']?.toString(),
      callId: callId,
      messageId: messageId,
      isDeleted: data['isDeleted'] as bool? ?? false,
      read: data['read'] as bool?,
      referenceId: data['referenceId']?.toString(),
    );

    _messages.add(msg);
    _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (messageId != null) _loadedMessageIds.add(messageId);
    if (type == 'call' && callId != null && callId.isNotEmpty) {
      _loadedCallIds.add(callId);
    }
    _loadedMessageIds.add(tsKey);
    _index(msg);
    _notifyMessageListChanged();
    if (shouldStayAtBottom) scrollToBottom();

    unawaited(_storage.saveMessage(msg, _boxName));
    if (type == 'call') _scheduleCallRecheckIfNeeded();
  }

  // ── Sent message (optimistic add) ────────────────────────────────────────

  void addSent(ChatMessageModel msg) {
    if (_disposed) return;
    _messages.add(msg);
    _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (msg.messageId != null) _loadedMessageIds.add(msg.messageId!);
    _loadedMessageIds.add('ts:${msg.timestamp.millisecondsSinceEpoch}');
    _index(msg);
    _notifyMessageListChanged();
    scrollToBottom();
  }

  /// Adds a call bubble, or — when this callId is already shown (e.g. the
  /// server's "missed" placeholder) — upgrades that bubble in place.
  /// Returns false when this call was already recorded.
  bool addCallMessage(ChatMessageModel msg) {
    if (_disposed) return false;
    final callId = msg.callId;
    if (callId != null) {
      final existing = _byCallId[callId];
      if (existing != null) {
        if (_mergeCallFields(existing, msg)) {
          _notifyMessageListChanged();
          persistMessage(existing);
        }
        return false;
      }
      if (_loadedCallIds.contains(callId)) return false;
      _loadedCallIds.add(callId);
    }
    addSent(msg);
    persistMessage(msg);
    return true;
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  /// Returns true only when [messageId] belongs to THIS conversation.
  ///
  /// The socket's `messageDeleted` dispatch is gated on the chat page being
  /// open but is NOT filtered by customer, so events for another conversation
  /// reach this provider. Callers must gate their side effects (chat-list
  /// preview rewrite) on the return value.
  bool markDeleted(String messageId) {
    if (_disposed) return false;
    final msg = _byId[messageId];
    if (msg == null) return false;
    if (msg.isDeleted) return true;
    msg.isDeleted = true;
    msg.message = 'This message is deleted';
    _notifyMessageListChanged();
    unawaited(_storage.saveMessage(msg, _boxName));
    return true;
  }

  // ── Read status ───────────────────────────────────────────────────────────

  void markReadUpToTimestamp(DateTime ts) => _markReadUpTo(ts);

  void _markReadUpTo(DateTime ts) {
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
    _notifyMessageListChanged();
    // One batched write of only what changed, not N writes of every read row.
    unawaited(_storage.saveMessages(changed, _boxName));
  }

  // ── Optimistic placeholder ────────────────────────────────────────────────

  ChatMessageModel addOptimistic(String text, String sender) {
    final msg = ChatMessageModel(
      message: text,
      timestamp: DateTime.now(),
      sender: sender,
    );
    if (_disposed) return msg;
    _messages.add(msg);
    _notifyMessageListChanged();
    scrollToBottom();
    return msg;
  }

  /// Removes the exact placeholder instance returned by [addOptimistic].
  /// Prefer this over [removeOptimistic], which matches on message text and
  /// would also delete a real message whose body happens to read
  /// "Sending image...".
  void removePlaceholder(ChatMessageModel placeholder) {
    if (_disposed) return;
    final before = _messages.length;
    _messages.removeWhere((m) => identical(m, placeholder));
    if (_messages.length == before) return;
    _notifyMessageListChanged();
  }

  void removeOptimistic(String messageText) {
    if (_disposed) return;
    _messages.removeWhere((m) => m.message == messageText);
    _notifyMessageListChanged();
  }

  void persistMessage(ChatMessageModel msg) =>
      unawaited(_storage.saveMessage(msg, _boxName));

  String generateMessageId() => ChatUtils().generateMessageId();

  // ── Deduplication ─────────────────────────────────────────────────────────

  /// Filters out rows already shown. A repeated CALL is not simply dropped:
  /// its status/duration is merged into the bubble already kept (and queued
  /// in [_repaired]), so whichever copy is newest-and-best wins.
  List<ChatMessageModel> _removeDuplicates(List<ChatMessageModel> list) {
    final kept = <ChatMessageModel>[];
    final batchCalls = <String, ChatMessageModel>{};

    for (final msg in list) {
      if (msg.type == 'call') {
        final callId = msg.callId;
        if (callId == null || callId.isEmpty) continue;

        final prior = batchCalls[callId] ?? _byCallId[callId];
        if (prior != null) {
          if (_mergeCallFields(prior, msg) && !batchCalls.containsKey(callId)) {
            _markRepaired(prior); // an already-loaded bubble changed
          }
          continue;
        }
        if (_loadedCallIds.contains(callId)) continue;

        _loadedCallIds.add(callId);
        batchCalls[callId] = msg;
        kept.add(msg);
        continue;
      }

      final id = msg.messageId;
      final tsKey = 'ts:${msg.timestamp.millisecondsSinceEpoch}';
      if ((id != null && _loadedMessageIds.contains(id)) ||
          _loadedMessageIds.contains(tsKey)) {
        continue;
      }
      if (id != null) _loadedMessageIds.add(id);
      _loadedMessageIds.add(tsKey);
      kept.add(msg);
    }
    return kept;
  }

  // ── Model conversion ──────────────────────────────────────────────────────

  ChatMessageModel _fromModel(MessageModel m) => ChatMessageModel(
        message: m.message ?? '',
        timestamp: DateTime.tryParse(m.timestamp ?? '') ?? DateTime.now(),
        sender: m.senderId ?? '',
        callerId: m.callerId, // keeps call direction on reload
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
      // The screen may have popped between scheduling and this frame — the
      // controller is disposed by then.
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
    _socket.offCallLogUpdated(_onSocketCallLogUpdated);
    _callRecheckTimer?.cancel();
    unawaited(_connectivitySub?.cancel());
    _connectivitySub = null;
    scrollController.dispose();
    isAtBottom.dispose();
    messageListVersion.dispose();
    isLoadingMoreNotifier.dispose();
    super.dispose();
  }
}
