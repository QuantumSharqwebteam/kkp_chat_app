import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:kkpchatapp/core/services/chat_storage_service.dart';
import 'package:kkpchatapp/data/models/chat_message_model.dart';
import 'package:kkpchatapp/core/services/handle_notification_clicks.dart';
import 'package:kkpchatapp/core/services/notification_service.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/main.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'dart:async';

class SocketService with WidgetsBindingObserver {
  static final SocketService _instance = SocketService._internal();
  factory SocketService(GlobalKey<NavigatorState> navigatorKey) {
    return _instance;
  }

  static const _backgroundChannel =
      MethodChannel('com.kkpchatapp/background_task');
  String? _currentUserName;
  String? _currentUserEmail;
  String? _currentRole;
  String? _currentToken;
  bool _pendingRejoin = false;
  bool _observerRegistered = false;

  final NotificationService notiService = NotificationService();

  late io.Socket _socket;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  /// Logged-in user's email. Used by CallProvider as a fallback caller ID so
  /// call logs are always saved with the correct sender.
  String? get currentUserEmail => _currentUserEmail;

  final String serverUrl = dotenv.env["SOCKET_IO_URL"]!;
  final ChatStorageService _chatStorageService = ChatStorageService();
  Function(Map<String, dynamic>)? _onMessageReceived;
  Function(String)? _onMessageDeleted;
  Function(Map<String, dynamic>)? _onIncomingCall;
  final List<Function(Map<String, dynamic>)> _onCallTerminatedListeners = [];
  Function? _onConnect;
  Function(Map<String, dynamic>)? _onChatStatus;
  Function(Map<String, dynamic>)? _onMessagesReadUpTo;

  /// Fired when a call log's final status/duration becomes known (either from
  /// the server or from the local CallProvider). The open chat page should
  /// patch its in-memory message with the same callId / _id.
  final List<Function(Map<String, dynamic>)> _callLogListeners = [];

  Function(Map<String, dynamic>)? _onProductAdd;
  Function(Map<String, dynamic>)? _onProductUpdate;
  Function(String)? _onProductDelete;

  // Group chat callbacks
  Function(Map<String, dynamic>)? _onGroupMessageReceived;
  Function(Map<String, dynamic>)? _onGroupMessageDeleted;
  Function(Map<String, dynamic>)? _onGroupMessageEdited;
  // Called when a group message arrives in the background (chat page not open).
  // Passes groupId, preview message, and timestamp so the provider can update
  // in-memory counts directly without a Hive round-trip.
  Function(String groupId, String message, DateTime timestamp)?
      _onGroupListUpdateCallback;

  bool isChatPageOpen = false;
  String? activeCustomerId;

  bool isGroupChatPageOpen = false;

  Function? onMessageReceivedCallback;

  List<String> _roomMembers = [];
  StreamController<List<String>> _statusController =
      StreamController<List<String>>.broadcast();

  Stream<List<String>> get statusStream => _statusController.stream;

  List<String> get onlineUsers => List.from(_roomMembers);

  // ── Notification-list refresh signal ──────────────────────────────────────

  /// Tells NotificationProvider that the server-side notification list may
  /// have changed (incoming call, call ended/missed, new message, app resumed).
  /// Static and never closed: it lives as long as the app, like the singleton,
  /// and survives socket dispose/re-init on logout/login.
  static final StreamController<String> _notificationEvents =
      StreamController<String>.broadcast();

  static Stream<String> get notificationEvents => _notificationEvents.stream;

  static void _pingNotifications(String reason) {
    if (!_notificationEvents.isClosed) _notificationEvents.add(reason);
  }

  SocketService._internal();

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String? _str(dynamic v) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  /// Sender of a socket payload. For call logs the caller is the sender,
  /// and some servers send it only as `callerId`.
  static String? _payloadSender(Map data) {
    if (_str(data['type']) == 'call') {
      return _str(data['callerId']) ?? _str(data['senderId']);
    }
    return _str(data['senderId']) ?? _str(data['callerId']);
  }

  static String _callPreview(dynamic status) {
    switch (_str(status)) {
      case 'answered':
        return 'Call ended';
      case 'not answered':
        return 'Not answered';
      case 'missed':
        return 'Missed call';
      default:
        return 'Call';
    }
  }

  /// Final statuses outrank the placeholder the server writes while ringing.
  /// Used so a stale "missed" never overwrites an "answered" log.
  static int _callStatusRank(String? status) {
    switch (status) {
      case 'answered':
        return 3;
      case 'not answered':
      case 'declined':
        return 2;
      case 'missed':
        return 1;
      default:
        return 0;
    }
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

  Future<void> _applyFormRateUpdateInBackground(
      Map<String, dynamic> data) async {
    String? targetFormId;
    final Map<String, dynamic> formPatch = {};

    if (data['type'] == 'form' && data['form'] is Map) {
      final incomingForm = Map<String, dynamic>.from(data['form'] as Map);
      final formId = incomingForm['_id']?.toString();
      if (formId != null && formId.isNotEmpty) {
        targetFormId = formId;
        formPatch.addAll(incomingForm);
        formPatch['_formOptionsUnlocked'] = true;
      }
    }

    final rateUpdate = _extractRateUpdateInfo(data['message']?.toString());
    if (targetFormId == null && rateUpdate != null) {
      final normalizedRate =
          rateUpdate.rate % 1 == 0 ? rateUpdate.rate.toInt() : rateUpdate.rate;
      targetFormId = rateUpdate.formId;
      formPatch['rate'] = normalizedRate;
      formPatch['_formOptionsUnlocked'] = true;
    }

    if (targetFormId == null) return;

    final senderId = data['senderId']?.toString();
    final targetId = data['targetId']?.toString();
    if (senderId == null ||
        senderId.isEmpty ||
        targetId == null ||
        targetId.isEmpty) {
      return;
    }

    final userType = await LocalDbHelper.getUserType();
    final boxName = userType == "0" ? targetId : '$targetId$senderId';

    final storage = ChatStorageService();
    final cachedMessages =
        await storage.getMessages(boxName, page: 1, limit: 100000);
    bool updated = false;

    for (final msg in cachedMessages) {
      final form = msg.form;
      if (form == null) continue;
      if (form['_id']?.toString() != targetFormId) continue;

      final updatedForm = Map<String, dynamic>.from(form);
      updatedForm.addAll(formPatch);
      msg.form = updatedForm;
      await storage.saveMessage(msg, boxName);
      updated = true;
    }

    if (updated) {
      debugPrint(
        "✅ Updated cached form options for formId: $targetFormId in box: $boxName",
      );
      if (onMessageReceivedCallback != null) {
        onMessageReceivedCallback!();
      }
    }
  }

  // ── Call log status sync ──────────────────────────────────────────────────

  /// Patch a cached call log with its final status/duration.
  ///
  /// Call this from CallProvider when a call ends on THIS device (agent or
  /// customer), passing the other party's email as [peerEmail]. It is also
  /// invoked automatically for server `callLogUpdated` / `callTerminated`
  /// events that carry a `callStatus`.
  ///
  /// A lower-ranked status never overwrites a higher one, so the server's
  /// ringing-time "missed" placeholder can't clobber "answered".
  Future<void> patchCallLog({
    required String callId,
    required String peerEmail,
    required String callStatus,
    String? callDuration,
    String? logId,
  }) async {
    final me = _currentUserEmail;
    if (me == null || me.isEmpty || peerEmail.isEmpty) return;

    try {
      final userType = await LocalDbHelper.getUserType();
      // Same box naming as _chatNotification:
      //   customer → own email, agent → agentEmail + customerEmail
      final boxName = userType == "0" ? me : '$me$peerEmail';

      final cached = await _chatStorageService.getMessages(boxName,
          page: 1, limit: 100000);
      bool updated = false;

      for (final msg in cached) {
        final sameCall = msg.callId != null && msg.callId == callId;
        final sameLog = logId != null && msg.messageId == logId;
        if (!sameCall && !sameLog) continue;

        if (_callStatusRank(msg.callStatus) > _callStatusRank(callStatus)) {
          continue; // never downgrade answered → missed
        }

        msg.callStatus = callStatus;
        if (callDuration != null && callDuration.isNotEmpty) {
          msg.callDuration = callDuration;
        }
        msg.callId ??= callId;
        await _chatStorageService.saveMessage(msg, boxName);
        updated = true;
      }

      debugPrint('📞 [CallLog] patch callId=$callId status=$callStatus '
          'duration=$callDuration box=$boxName updated=$updated');

      if (updated && userType != "0") {
        updateLastMessage(peerEmail, _callPreview(callStatus));
      }

      // Let the open chat page update its in-memory list too.
      final update = <String, dynamic>{
        'callId': callId,
        if (logId != null) '_id': logId,
        'callStatus': callStatus,
        if (callDuration != null) 'callDuration': callDuration,
        'peerEmail': peerEmail,
      };
      for (final l
          in List<Function(Map<String, dynamic>)>.from(_callLogListeners)) {
        l(update);
      }
      if (updated) onMessageReceivedCallback?.call();
    } catch (e) {
      debugPrint('❌ [CallLog] patch failed: $e');
    }
  }

  /// Backup "caller cancelled" signal. If a call log for [data]'s callId
  /// arrives with a final NOT-answered status, the call is over — so a still
  /// ringing incoming-call UI on this device must be dismissed, even if the
  /// `callTerminated` event itself was missed (socket reconnecting, etc.).
  /// "missed" is deliberately excluded: the server writes it as a placeholder
  /// while the call is still ringing.
  void _forwardCancelFromCallLog(Map<String, dynamic> data) {
    if (_str(data['type']) != null && _str(data['type']) != 'call') return;
    final callId = _str(data['callId']);
    final status = _str(data['callStatus']);
    if (callId == null) return;
    if (status != 'not answered' && status != 'declined') return;

    final payload = <String, dynamic>{
      'callId': callId,
      if (_str(data['channelName']) != null)
        'channelName': _str(data['channelName']),
      'source': 'callLog',
    };
    for (final listener in List<Function(Map<String, dynamic>)>.from(
        _onCallTerminatedListeners)) {
      listener(payload);
    }
  }

  void _handleServerCallLogUpdate(Map<String, dynamic> data) {
    final callId = _str(data['callId']);
    final status = _str(data['callStatus']);
    final me = _currentUserEmail;
    if (callId == null || status == null || me == null) return;

    final caller = _str(data['callerId']) ?? _str(data['senderId']);
    final target = _str(data['targetId']);
    final peer = caller == me ? target : caller;
    if (peer == null) return;

    patchCallLog(
      callId: callId,
      peerEmail: peer,
      callStatus: status,
      callDuration: _str(data['callDuration']),
      logId: _str(data['_id']) ?? _str(data['messageId']),
    );
  }

  /// Several screens can listen at once (chat page + history screen).
  /// Always pair with [offCallLogUpdated] in dispose().
  void onCallLogUpdated(Function(Map<String, dynamic>) callback) {
    if (!_callLogListeners.contains(callback)) _callLogListeners.add(callback);
  }

  void offCallLogUpdated(Function(Map<String, dynamic>) callback) {
    _callLogListeners.remove(callback);
  }

  void onMessageReceived(Function(Map<String, dynamic>) callback,
      {Function? refreshCallback}) {
    _onMessageReceived = callback;
    onMessageReceivedCallback = refreshCallback;
  }

  void initSocket(String userName, String userEmail, String role,
      {String? token}) {
    // Prevent duplicate socket creation
    if (_isConnected) {
      debugPrint('⚠️ Socket already connected, skipping init');
      return;
    }
    _currentUserName = userName;
    _currentUserEmail = userEmail;
    _currentRole = role;
    _currentToken = token;
    if (!_observerRegistered) {
      WidgetsBinding.instance.addObserver(this);
      _observerRegistered = true;
    }
    _statusController.close();
    _statusController = StreamController<List<String>>.broadcast();
    _socket = io.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'reconnection': true,
      'reconnectionAttempts': 10,
      'reconnectionDelay': 2000,
      'reconnectionDelayMax': 10000,
      'timeout': 20000,
    });

    _socket.onConnect((_) {
      _isConnected = true;
      NotificationService.socketIsConnected = true;
      debugPrint('✅ Connected to socket server');
      _socket.emit('join', {
        'user': userName,
        'userId': userEmail,
        "role": role,
        "token": token,
      });
      _onConnect?.call();
      // Events may have been missed while disconnected — resync the list.
      _pingNotifications('socketConnected');
    });

    _socket.on('socketId', (socketId) {
      debugPrint('📌 Assigned Socket ID: $socketId');
    });

    _socket.on('roomMembers', (roomMembers) {
      debugPrint('👥 Current Room Members: $roomMembers');
      _updateRoomMembers(List<String>.from(roomMembers));
    });

    // Group chat listener
    _socket.on('receiveGroupMessage', (data) {
      debugPrint('📥 Received group message: $data');
      if (isGroupChatPageOpen) {
        _onGroupMessageReceived?.call(data);
      } else {
        _groupChatNotification(data);
      }
    });

    _socket.on('receiveMessage', (data) {
      debugPrint('📥 [Socket] receiveMessage: $data');
      if (data is! Map) return;
      final payload = Map<String, dynamic>.from(data);

      // New message / call log → server-side notification list changed.
      _pingNotifications('receiveMessage:${payload['type']}');

      // Call logs may carry the caller only in `callerId`.
      final String senderId = _payloadSender(payload) ?? '';
      final String targetId = _str(payload['targetId']) ?? '';

      if (_str(payload['type']) == 'call') _forwardCancelFromCallLog(payload);

      if (isChatPageOpen &&
          (activeCustomerId == senderId || activeCustomerId == targetId)) {
        _onMessageReceived?.call(payload);
      } else {
        _applyFormRateUpdateInBackground(payload);
        _chatNotification(payload);
      }
    });

    _socket.on('incomingCall', (data) {
      debugPrint('📥 Agora incomingCall: $data');
      _pingNotifications('incomingCall');
      _onIncomingCall?.call(data);
    });

    _socket.on('callTerminated', (data) {
      debugPrint('📥 callTerminated from server: $data');
      _pingNotifications('callTerminated');

      final payload = Map<String, dynamic>.from((data as Map?) ?? const {});
      for (final listener in List<Function(Map<String, dynamic>)>.from(
          _onCallTerminatedListeners)) {
        listener(payload);
      }
      // If the server includes the final status, sync the cached log.
      if (_str(payload['callStatus']) != null) {
        _handleServerCallLogUpdate(payload);
      }
    });

    // Server should emit this to BOTH parties once a call's final status and
    // duration are saved. Harmless if the backend doesn't send it yet.
    _socket.on('callLogUpdated', (data) {
      debugPrint('📥 callLogUpdated: $data');
      if (data is! Map) return;
      _pingNotifications('callLogUpdated');
      final payload = Map<String, dynamic>.from(data);
      _forwardCancelFromCallLog(payload);
      _handleServerCallLogUpdate(payload);
    });

    _socket.on('messageDeleted', (data) {
      debugPrint("socket message deleted: ${data.toString()}");
      final messageId = data['messageId'];

      if (isChatPageOpen) {
        _onMessageDeleted?.call(messageId);
      } else {
        _handleBackgroundMessageDeletion(data);
      }
    });

    _socket.on('chatStatus', (data) {
      debugPrint("📥 chatStatus: ${data.toString()}");
      if (isChatPageOpen) {
        _onChatStatus?.call(data);
      } else {
        debugPrint("📥 Handling chatStatus in background.");
        _handleBackgroundChatStatus(data);
      }
    });

    _socket.on('messagesReadUpTo', (data) {
      debugPrint("📥 messagesReadUpTo: ${data.toString()}");
      if (isChatPageOpen) {
        _onMessagesReadUpTo?.call(data);
      } else {
        debugPrint("📥 Background messagesReadUpTo: $data");
        _handleBackgroundMessagesReadUpTo(data);
      }
    });

    _socket.on('productAdd', (data) {
      debugPrint("[Socket] New product added: $data");
      if (_onProductAdd != null) {
        final payload = Map<String, dynamic>.from((data as Map?) ?? const {});
        _onProductAdd!(payload);
      }
    });

    _socket.on('productUpdate', (data) {
      debugPrint("[Socket] Product updated: $data");
      if (_onProductUpdate != null) {
        final payload = Map<String, dynamic>.from((data as Map?) ?? const {});
        _onProductUpdate!(payload);
      }
    });

    _socket.on('productDelete', (data) {
      debugPrint("[Socket] Product deleted: $data");
      final dynamic productId =
          data is Map ? (data['productId'] ?? data['_id']) : data;
      if (_onProductDelete != null && productId != null) {
        _onProductDelete!(productId.toString());
      }
    });

    _socket.on('groupMessageMarkedDeleted', (data) {
      debugPrint('🗑️ Group message marked as deleted: $data');
      if (isGroupChatPageOpen) {
        _onGroupMessageDeleted?.call(data);
      } else {
        _handleBackgroundGroupMessageDeletion(data);
      }
    });

    _socket.on('groupMessageEdited', (data) {
      debugPrint('✏️ Group message edited: $data');
      if (isGroupChatPageOpen) {
        _onGroupMessageEdited?.call(data);
      } else {
        _handleBackgroundGroupMessageEdit(data);
      }
    });

    _socket.onDisconnect((_) {
      _isConnected = false;
      NotificationService.socketIsConnected = false;
      for (String email in _roomMembers) {
        LocalDbHelper.updateLastSeenTime(email);
        debugPrint(
            "⏳ Saved last seen for $email: ${DateTime.now().toIso8601String()}");
      }
      debugPrint('⚠️ Disconnected from socket server');
    });

    _socket.connect();
  }

  void onConnect(Function callback) {
    _onConnect = callback;
  }

  void onProductAdd(Function(Map<String, dynamic>) callback) {
    _onProductAdd = callback;
  }

  void onProductUpdate(Function(Map<String, dynamic>) callback) {
    _onProductUpdate = callback;
  }

  void onProductDelete(Function(String) callback) {
    _onProductDelete = callback;
  }

  void onChatStatus(Function(Map<String, dynamic>) callback) {
    debugPrint("🔧 Chat status callback set");
    _onChatStatus = callback;
  }

  void onMessagesReadUpTo(Function(Map<String, dynamic>) callback) {
    debugPrint("🔧 Messages read up to callback set");
    _onMessagesReadUpTo = callback;
  }

  void toggleGroupChatPageOpen(bool toggle) {
    debugPrint(
        "🔄 [SocketService] Toggling group chat page: ${toggle ? "OPEN" : "CLOSED"}");
    isGroupChatPageOpen = toggle;
  }

  void setGroupChatPageState(bool isOpen) {
    debugPrint(
        "🔄 [SocketService] Setting group chat page state: ${isOpen ? "OPEN" : "CLOSED"}");
    isGroupChatPageOpen = isOpen;
  }

  void onGroupMessageReceived(Function(Map<String, dynamic>) callback) {
    debugPrint("🔧 [SocketService] Group message callback registered");
    _onGroupMessageReceived = callback;
  }

  void onGroupMessageDeleted(Function(Map<String, dynamic>) callback) {
    debugPrint("🔧 [SocketService] Group message deleted callback registered");
    _onGroupMessageDeleted = callback;
  }

  void onGroupMessageEdited(Function(Map<String, dynamic>) callback) {
    debugPrint("🔧 [SocketService] Group message edited callback registered");
    _onGroupMessageEdited = callback;
  }

  void onGroupListUpdate(
      Function(String groupId, String message, DateTime timestamp) callback) {
    _onGroupListUpdateCallback = callback;
  }

  void clearGroupListUpdate() {
    _onGroupListUpdateCallback = null;
  }

  void sendGroupMessage({
    required String message,
    required String senderId,
    required String senderName,
    required String groupId,
    String type = 'text',
    String? mediaUrl,
    String? fileName,
    List<String>? mentions,
    String? replyTo,
    String? timestamp,
    String? messageId,
  }) {
    if (!_isConnected) {
      debugPrint('Socket is not connected. Cannot send group message.');
      return;
    }

    final payload = {
      'message': message,
      'senderId': senderId,
      'senderName': senderName,
      'groupId': groupId,
      'type': type,
      'mediaUrl': mediaUrl,
      'fileName': fileName,
      'mentions': mentions,
      'replyTo': replyTo,
      'timestamp': timestamp,
      'messageId': messageId,
    };

    _socket.emit('sendGroupMessage', payload);
    debugPrint('📤 Sent group message: $payload');
  }

  // Handle group message deletion in background (group-specific storage)
  void _handleBackgroundGroupMessageDeletion(Map<String, dynamic> data) async {
    debugPrint("🗑️ [Background] Group message deletion: ${data.toString()}");
    final messageId = data['messageId']?.toString();
    final groupId = data['groupId']?.toString();

    if (messageId == null || groupId == null || groupId.isEmpty) {
      debugPrint(
          "⚠️ [Background] Missing messageId or groupId in deletion data");
      return;
    }

    try {
      final localMessages = await LocalDbHelper.getGroupMessages(groupId);
      final index =
          localMessages.indexWhere((msg) => msg.messageId == messageId);
      if (index != -1) {
        final updatedMessage = localMessages[index].copyWith(
          isDeleted: true,
          message: "This message was deleted",
        );
        await LocalDbHelper.updateGroupMessage(updatedMessage, groupId);
        debugPrint(
            "✅ [Background] Marked message $messageId as deleted in group $groupId");
      }
    } catch (e) {
      debugPrint("❌ [Background] Error handling group message deletion: $e");
    }
  }

  // Handle group message edit in background (group-specific storage)
  void _handleBackgroundGroupMessageEdit(Map<String, dynamic> data) async {
    debugPrint("✏️ [Background] Group message edit: ${data.toString()}");
    final messageId = data['messageId']?.toString();
    final newMessage = data['newMessage']?.toString();
    final groupId = data['groupId']?.toString();

    if (messageId == null ||
        newMessage == null ||
        groupId == null ||
        groupId.isEmpty) {
      debugPrint("⚠️ [Background] Missing fields in group message edit data");
      return;
    }

    try {
      final localMessages = await LocalDbHelper.getGroupMessages(groupId);
      final index =
          localMessages.indexWhere((msg) => msg.messageId == messageId);
      if (index != -1) {
        final updatedMessage = localMessages[index].copyWith(
          message: newMessage,
          isEdited: true,
        );
        await LocalDbHelper.updateGroupMessage(updatedMessage, groupId);
        debugPrint(
            "✅ [Background] Updated edited message $messageId in group $groupId");
      }
    } catch (e) {
      debugPrint("❌ [Background] Error handling group message edit: $e");
    }
  }

  void deleteGroupMessage(
      {required String messageId,
      required String senderId,
      required String groupId}) {
    if (!_isConnected) {
      debugPrint('Socket is not connected. Cannot delete group message.');
      return;
    }

    final payload = {
      'messageId': messageId,
      'senderId': senderId,
      "groupId": groupId,
    };

    _socket.emit('deleteGroupMessage', payload);
    debugPrint('🗑️ Delete group message event emitted: $messageId');
  }

  void editGroupMessage(
      {required String messageId,
      required String senderId,
      required String newMessage,
      required String groupId}) {
    if (!_isConnected) {
      debugPrint('Socket is not connected. Cannot edit group message.');
      return;
    }

    final payload = {
      'messageId': messageId,
      'senderId': senderId,
      'newMessage': newMessage,
      "groupId": groupId
    };

    _socket.emit('editGroupMessage', payload);
    debugPrint('✏️ Edit group message event emitted: $messageId');
  }

  void sendChatOpened({
    String? agentEmail,
    required String customerEmail,
    required String role,
    required String lastMessageTimestamp,
  }) {
    if (!_isConnected) {
      debugPrint("⚠️ Cannot send chatOpened — socket not connected.");
      return;
    }
    final payload = {
      'customerEmail': customerEmail,
      'role': role,
      'lastMessageTimestamp': lastMessageTimestamp,
    };
    if (agentEmail != null && role == 'agent') {
      payload['agentEmail'] = agentEmail;
    }

    _socket.emit('chatOpened', payload);
    debugPrint("📤 Sending chatOpened event with payload: $payload");
  }

  void sendMarkAsReadUpTo({
    String? agentEmail,
    required String customerEmail,
    required String role,
    required String lastMessageTimestamp,
  }) {
    if (!_isConnected) {
      debugPrint("⚠️ Cannot send markAsReadUpTo — socket not connected.");
      return;
    }
    final payload = {
      'customerEmail': customerEmail,
      'role': role,
      'lastMessageTimestamp': lastMessageTimestamp,
    };
    if (agentEmail != null && role == 'agent') {
      payload['agentEmail'] = agentEmail;
    }
    debugPrint("📤 Sending markAsReadUpTo event with payload: $payload");
    _socket.emit('markAsReadUpTo', payload);
  }

  void sendChatClosed({
    String? agentEmail,
    required String customerEmail,
    required String role,
  }) {
    if (!_isConnected) {
      debugPrint("⚠️ Cannot send chatClosed — socket not connected.");
      return;
    }
    final payload = {
      'customerEmail': customerEmail,
      'role': role,
    };
    if (agentEmail != null && role == 'agent') {
      payload['agentEmail'] = agentEmail;
    }

    _socket.emit('chatClosed', payload);
    debugPrint("📤 Sending chatClosed event with payload: $payload");
  }

  void _handleBackgroundChatStatus(Map<String, dynamic> data) async {
    debugPrint("📥 Background Chat Status : ${data.toString()}");
    final status = data['status'];
    final customerEmail = data['customerEmail'];
    final lastMessageTimestampStr = data['lastMessageTimestamp'];
    debugPrint("Background Chat Status Updated: $status");

    if (status == 'opened' &&
        lastMessageTimestampStr != null &&
        customerEmail != null) {
      final lastMessageTimestamp = DateTime.tryParse(lastMessageTimestampStr);
      if (lastMessageTimestamp != null) {
        LocalDbHelper.saveReceiverOnChatPageStatus(true);

        final userType = await LocalDbHelper.getUserType();
        if (userType == "0") {
          // Customer
          final messages =
              await ChatStorageService().getCustomerMessages(customerEmail);
          for (var message in messages) {
            if (message.timestamp.isBefore(lastMessageTimestamp) ||
                message.timestamp == lastMessageTimestamp) {
              message.read = true;
              await ChatStorageService().saveMessage(message, customerEmail);
            }
          }
          debugPrint(
              "✅ Updated customer messages as read up to $lastMessageTimestampStr");
        } else {
          // Agent — agentEmail required from backend
          final agentEmail = data['agentEmail'];
          final boxName = '$agentEmail$customerEmail';
          final messages = await ChatStorageService().getMessages(boxName);
          for (var message in messages) {
            if (message.timestamp.isBefore(lastMessageTimestamp) ||
                message.timestamp == lastMessageTimestamp) {
              message.read = true;
              await ChatStorageService().saveMessage(message, boxName);
            }
          }
          debugPrint(
              "✅ Updated agent messages as read up to $lastMessageTimestampStr in box: $boxName");
        }
      }
    } else if (status == 'closed') {
      LocalDbHelper.saveReceiverOnChatPageStatus(false);
    }
  }

  void _handleBackgroundMessagesReadUpTo(Map<String, dynamic> data) async {
    final customerEmail = data['customerEmail'];
    final lastMessageTimestampStr = data['lastMessageTimestamp'];
    if (customerEmail == null || lastMessageTimestampStr == null) return;

    final userType = await LocalDbHelper.getUserType();
    final lastMessageTimestamp = DateTime.tryParse(lastMessageTimestampStr);
    if (lastMessageTimestamp == null) return;

    if (userType == "0") {
      // Customer
      final messages =
          await ChatStorageService().getCustomerMessages(customerEmail);
      for (var message in messages) {
        if (message.timestamp.isBefore(lastMessageTimestamp)) {
          message.read = true;
          await ChatStorageService().saveMessage(message, customerEmail);
        }
      }
      debugPrint(
          "✅ Updated customer messages as read up to $lastMessageTimestampStr");
    } else {
      // Agent — agentEmail required from backend
      final agentEmail = data['agentEmail'];

      final boxName = '$agentEmail$customerEmail';
      final messages = await ChatStorageService().getMessages(boxName);
      for (var message in messages) {
        if (message.timestamp.isBefore(lastMessageTimestamp)) {
          message.read = true;
          await ChatStorageService().saveMessage(message, boxName);
        }
      }
      debugPrint(
          "✅ Updated agent messages as read up to $lastMessageTimestampStr in box: $boxName");
    }

    onMessageReceivedCallback?.call();
  }

  void _handleBackgroundMessageDeletion(Map<String, dynamic> data) async {
    final messageId = data['messageId'];
    final senderId = data['senderId'];
    final targetId = data['targetId'];

    final userType = await LocalDbHelper.getUserType();

    if (userType == "0") {
      // For customers, retrieve messages using getCustomerMessages
      final messages = await ChatStorageService().getCustomerMessages(targetId);
      debugPrint("Retrieved messages for customer: ${messages.length}");

      final index =
          messages.indexWhere((message) => message.messageId == messageId);
      if (index != -1) {
        messages[index].isDeleted = true;
        messages[index].message = "This message is deleted";

        await ChatStorageService().saveMessage(messages[index], targetId);
        debugPrint(
            "Message marked as deleted for customer with ID: $messageId");

        final updatedMessages =
            await ChatStorageService().getCustomerMessages(targetId);
        final updatedIndex = updatedMessages
            .indexWhere((message) => message.messageId == messageId);
        if (updatedIndex != -1 && updatedMessages[updatedIndex].isDeleted) {
          debugPrint("Successfully updated message in storage for customer.");
        } else {
          debugPrint("Failed to update message in storage for customer.");
        }
      } else {
        debugPrint("Message not found for deletion with ID: $messageId");
      }
    } else {
      // For agents, the box name is a combination of targetId and senderId
      String boxName = '$targetId$senderId';

      final messages = await ChatStorageService().getMessages(boxName);
      final index =
          messages.indexWhere((message) => message.messageId == messageId);
      if (index != -1) {
        messages[index].isDeleted = true;
        messages[index].message = "This message is deleted";

        await ChatStorageService().saveMessage(messages[index], boxName);

        updateLastMessage(senderId, "message deleted");
      }
    }
  }

  void _updateRoomMembers(List<String> newRoomMembers) {
    if (_statusController.isClosed) return;
    Set<String> previousUsers = Set.from(_roomMembers);
    Set<String> currentUsers = Set.from(newRoomMembers);

    for (String email in previousUsers.difference(currentUsers)) {
      LocalDbHelper.updateLastSeenTime(email);
      debugPrint(
          "⏳ Updated last seen for $email: ${DateTime.now().toIso8601String()}");
    }

    _roomMembers = newRoomMembers;
    _statusController.add(List.from(_roomMembers));
  }

  void getRoomMembers() {
    _socket.emit('roomMembers');
  }

  bool isUserOnline(String email) {
    return _roomMembers.contains(email);
  }

  void updateLastSeenTime(String email) {
    LocalDbHelper.updateLastSeenTime(email);
  }

  String getLastSeenTime(String email) {
    if (_roomMembers.contains(email)) return "Online";

    DateTime? lastSeen = LocalDbHelper.getLastSeenTime(email);
    if (lastSeen == null) return "Not Available";

    Duration diff = DateTime.now().difference(lastSeen);
    if (diff.inSeconds < 30) return "Just now";
    if (diff.inMinutes < 1) return "Few seconds ago";
    if (diff.inMinutes == 1) return "1 min ago";
    if (diff.inHours < 1) return "${diff.inMinutes} min ago";
    if (diff.inHours == 1) return "1 hour ago";
    if (diff.inDays < 1) return "${diff.inHours}h ago";
    if (diff.inDays == 1) return "Yesterday";
    return "${diff.inDays}d ago";
  }

  void onReceiveMessage(Function(Map<String, dynamic>) callback) {
    _onMessageReceived = callback;
  }

  void onMessageDeleted(Function(String) callback) {
    _onMessageDeleted = callback;
  }

  void onIncomingCall(Function(Map<String, dynamic>) callback) {
    _onIncomingCall = callback;
  }

  void onCallTerminated(Function(Map<String, dynamic>) callback) {
    if (!_onCallTerminatedListeners.contains(callback)) {
      _onCallTerminatedListeners.add(callback);
    }
  }

  void offCallTerminated(Function(Map<String, dynamic>) callback) {
    _onCallTerminatedListeners.remove(callback);
  }

  void updateLastMessage(String email, String message) {
    LocalDbHelper.updateLastMessage(email, message);
  }

  String getLastMessage(String email) {
    String? lastMessage = LocalDbHelper.getLastMessage(email);
    if (lastMessage == null) return "last message";
    return lastMessage;
  }

  void sendMessage({
    String? targetEmail,
    String? message,
    required String senderEmail,
    required String senderName,
    String type = 'text',
    Map<String, dynamic>? form,
    String? mediaUrl,
    String? timestamp,
    String? messageId,
    bool read = false,
    String? referenceId,
  }) {
    if (_isConnected) {
      Map<String, dynamic> messageData = {
        'senderId': senderEmail,
        'senderName': senderName,
        'type': type,
        'read': read,
      };

      if (targetEmail != null) messageData['targetId'] = targetEmail;
      if (message != null) messageData['message'] = message;
      if (form != null) messageData['form'] = form;
      if (mediaUrl != null) messageData['mediaUrl'] = mediaUrl;
      if (timestamp != null) messageData['timestamp'] = timestamp;
      if (messageId != null) messageData["messageId"] = messageId;
      if (referenceId != null) messageData['referenceId'] = referenceId;

      _socket.emit('sendMessage', messageData);

      // Save the last message for the user last chatted
      if (type == "product") {
        updateLastMessage(targetEmail ?? "", "shared product");
      } else if (message != null &&
          message.contains("Your order is confirmed with form Id")) {
        updateLastMessage(targetEmail ?? "", "Order Confirmed");
      } else if (message != null &&
          message.contains("Your order is declined with form Id")) {
        updateLastMessage(targetEmail ?? "", "Order Declined");
      } else {
        updateLastMessage(targetEmail ?? "", message ?? "");
      }
    } else {
      debugPrint('Socket is not connected. Cannot send message.');
    }
  }

  void sendForm({
    required String senderId,
    required String targetId,
    required String senderName,
    required Map<String, dynamic> form,
    required String timestamp,
    required String messageId,
    String? orderId,
  }) {
    if (_isConnected) {
      final formData = {
        'senderId': senderId,
        'targetId': targetId,
        'senderName': senderName,
        'form': form,
        'timestamp': timestamp,
        'messageId': messageId,
      };
      if (orderId != null) {
        formData['orderId'] = orderId;
      }
      _socket.emit('sendForm', formData);
      debugPrint('📤 Sent form via socket: $formData');
    } else {
      debugPrint('Socket is not connected. Cannot send form.');
    }
  }

  void deleteMessage(String messageId, String senderId, [String? targetId]) {
    if (_isConnected) {
      Map<String, dynamic> messageData = {
        'messageId': messageId,
        'senderId': senderId,
      };

      if (targetId != null) {
        messageData['targetId'] = targetId;
      }

      _socket.emit('deleteMessage', messageData);
      debugPrint("🗑️ Delete message event emitted: $messageId");
    } else {
      debugPrint('Socket is not connected. Cannot delete message.');
    }
  }

  void sendAgoraCall({
    String? targetId,
    required String channelName,
    required String callerId,
    required String callerName,
    required String callId,
    required String timestamp,
  }) {
    if (_isConnected) {
      final payload = {
        'channelName': channelName,
        'callerId': callerId,
        // Also send as senderId so the backend call log stores the caller
        // as the sender → correct side after reload.
        'senderId': callerId,
        'callerName': callerName,
        'callId': callId,
        'timestamp': timestamp,
      };
      if (targetId != null) payload['targetId'] = targetId;
      debugPrint('📤 Emitting Agora call: $payload');
      _socket.emit('initiateCall', payload);
    }
  }

  void terminateCall({
    required String targetId,
    required String callId,
    String? channelName,
  }) {
    if (_isConnected) {
      final data = {
        'targetId': targetId,
        'callId': callId,
      };
      if (channelName != null) {
        data['channelName'] = channelName;
      }
      debugPrint("❌ Sending terminate call: $data");
      _socket.emit('terminateCall', data);
    }
  }

  void disconnect() {
    if (_isConnected) {
      _socket.disconnect();
      _isConnected = false;
      NotificationService.socketIsConnected = false;
      debugPrint('🛑 Socket disconnected');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('[SocketService] Lifecycle → $state');
    switch (state) {
      case AppLifecycleState.inactive:
        if (Platform.isIOS) _beginBackgroundTask();
        break;
      case AppLifecycleState.paused:
        _onAppPaused();
        break;
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;
      default:
        break;
    }
  }

  void _onAppPaused() {
    // Do NOT emit 'leave' here. The server's socket disconnect event fires
    // automatically when the socket drops (~30 s background task), so the server
    // still marks the user offline at the right time. Emitting 'leave' early
    // would cut the background window short — incoming call socket events would
    // not be routed to this user even though the socket is still alive.
    if (_isConnected) {
      _pendingRejoin = true;
    }
  }

  void _onAppResumed() {
    if (Platform.isIOS) _endBackgroundTask();

    // Socket events are lost while the app is backgrounded — resync the
    // notification list so calls received meanwhile show up without a
    // manual refresh.
    _pingNotifications('appResumed');

    if (!_isConnected) {
      _pendingRejoin = false;
      debugPrint('[SocketService] Resumed — socket dead, reconnecting...');
      try {
        _socket.connect();
      } catch (e) {
        debugPrint('[SocketService] Reconnect on resume failed: $e');
      }
    } else if (_pendingRejoin) {
      _pendingRejoin = false;
      _emitJoinDirectly();
    }
  }

  void _emitJoinDirectly() {
    if (_currentUserName == null ||
        _currentUserEmail == null ||
        _currentRole == null) {
      return;
    }
    try {
      _socket.emit('join', {
        'user': _currentUserName,
        'userId': _currentUserEmail,
        'role': _currentRole,
        if (_currentToken != null) 'token': _currentToken,
      });
      debugPrint('[SocketService] Re-joined after resume: $_currentUserEmail');
    } catch (e) {
      debugPrint('[SocketService] Failed to re-join on resume: $e');
    }
  }

  Future<void> _beginBackgroundTask() async {
    try {
      await _backgroundChannel.invokeMethod('beginBackgroundTask');
      debugPrint('[SocketService] iOS background task started');
    } catch (e) {
      debugPrint('[SocketService] beginBackgroundTask failed: $e');
    }
  }

  Future<void> _endBackgroundTask() async {
    try {
      await _backgroundChannel.invokeMethod('endBackgroundTask');
      debugPrint('[SocketService] iOS background task ended');
    } catch (e) {
      debugPrint('[SocketService] endBackgroundTask failed: $e');
    }
  }

  void dispose() {
    if (_observerRegistered) {
      WidgetsBinding.instance.removeObserver(this);
      _observerRegistered = false;
    }
    // NOTE: _notificationEvents is intentionally NOT closed here — it is
    // static and NotificationProvider stays subscribed across logout/login.
    if (_isConnected) {
      _socket.clearListeners();
      _statusController.close();
      _socket.disconnect();
      _isConnected = false;
      debugPrint('🛑🛑 Socket service disposed completely');
    } else {
      _socket.clearListeners();
      debugPrint('🛑 🛑 Socket disposed finally ');
    }
  }

  Future<void> _chatNotification(Map<String, dynamic> data) async {
    debugPrint(
        '🔔 [Socket] Chat notification (user not on chat screen): $data');

    final bool isCall = _str(data['type']) == 'call';
    final String? senderKey = _payloadSender(data);
    final String? targetKey = _str(data['targetId']);

    debugPrint(
      '🧭 [CustomerChatTrace][Socket] notification:start '
      'sender=$senderKey target=$targetKey messageId=${data['messageId']}',
    );

    // Call logs may arrive without `message` and with the caller only in
    // `callerId` — don't drop them.
    if (!data.containsKey('type') ||
        senderKey == null ||
        (!isCall && !data.containsKey('message'))) {
      debugPrint('ℹ️ Ignoring non-chat notification: $data');
      return;
    }

    final userType = await LocalDbHelper.getUserType();
    final String notificationMessage = isCall
        ? _callPreview(data['callStatus'])
        : data['type'] == "product"
            ? "Shared product"
            : (data['message']?.toString() ?? '');

    // Persist first so opening the chat immediately after a notification reads
    // the new message from Hive instead of briefly showing stale/empty state.
    String chatBoxName = '';
    try {
      final timestamp =
          DateTime.tryParse(data['timestamp']?.toString() ?? '') ??
              DateTime.now();
      final callerId = _str(data['callerId']);
      final incoming = ChatMessageModel(
        message: data['message']?.toString() ?? '',
        // For call logs the caller is the sender → correct side on reload.
        sender: senderKey,
        callerId: isCall ? (callerId ?? senderKey) : callerId,
        type: _str(data['type']) ?? 'text',
        timestamp: timestamp,
        mediaUrl: data['mediaUrl']?.toString(),
        callStatus: data['callStatus']?.toString(),
        callDuration: data['callDuration']?.toString(),
        callId: data['callId']?.toString(),
        messageId: data['messageId']?.toString() ??
            data['_id']?.toString() ??
            (isCall ? data['callId']?.toString() : null),
        isDeleted: false,
        read: false,
      );
      chatBoxName =
          userType == "0" ? (targetKey ?? '') : '${targetKey ?? ''}$senderKey';
      debugPrint(
        '🧭 [CustomerChatTrace][Socket] cache:start '
        'userType=$userType box=$chatBoxName messageId=${incoming.messageId}',
      );
      if (chatBoxName.isNotEmpty) {
        await _chatStorageService.saveMessage(incoming, chatBoxName);
      }
      debugPrint(
        '🧭 [CustomerChatTrace][Socket] cache:done '
        'box=$chatBoxName messageId=${incoming.messageId}',
      );
    } catch (e) {
      debugPrint(
          '⚠️ [Socket] Failed to cache incoming message to chat box: $e');
    }

    if (userType == "0") {
      // Customer-side notification logic
      final currentUserEmail = targetKey;
      final boxNameWithCount = "${currentUserEmail}count";
      final box = await Hive.openBox<int>(boxNameWithCount);
      int count = box.get('count', defaultValue: 0)! + 1;
      await box.put('count', count);
      debugPrint(
        '🧭 [CustomerChatTrace][Socket] unreadCount:updated '
        'box=$boxNameWithCount count=$count',
      );
      onMessageReceivedCallback?.call();
    } else {
      // Agent side
      if (targetKey != null) {
        await LocalDbHelper.incrementUnreadCount(targetKey, senderKey);
      }

      if (isCall) {
        updateLastMessage(senderKey, notificationMessage);
      } else if (data['type'] == "product") {
        updateLastMessage(senderKey, "shared product");
      } else {
        updateLastMessage(senderKey, data['message']?.toString() ?? '');
      }

      onMessageReceivedCallback?.call();
    }

    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is for important notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final notificationDetails =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    if (userType != "0") {
      // Agent-side consolidated notification
      const consolidatedNotificationId = 999;
      final box = await Hive.openBox<int>(
          '${LocalDbHelper.unreadCountsBoxKey}_$targetKey');
      final totalUnreadMessages =
          box.values.fold<int>(0, (sum, value) => sum + value);
      final usersWithUnread = box.values.where((count) => count > 0).length;

      String title;
      String message;
      String payload;

      if (usersWithUnread <= 1) {
        final unreadCount = targetKey == null
            ? 0
            : await LocalDbHelper.getUnreadCount(targetKey, senderKey) ?? 0;
        final senderName =
            _str(data['senderName']) ?? _str(data['callerName']) ?? senderKey;

        if (unreadCount > 1) {
          title = "$unreadCount messages from $senderName";
          message = "You have $unreadCount unread messages";
        } else {
          title = "New message from $senderName";
          message = notificationMessage;
        }

        payload = jsonEncode(data); // Normal payload to open chat
      } else {
        title =
            "$totalUnreadMessages unread messages from $usersWithUnread users";
        message = "You have $totalUnreadMessages unread messages";
        payload = "general_chat_summary";
      }

      await NotificationService.plugin.show(
        consolidatedNotificationId,
        title,
        message,
        notificationDetails,
        payload: payload,
      );
    } else {
      const title = "New Message from Agent";
      const id = 200;

      await NotificationService.plugin.show(
        id,
        title,
        notificationMessage,
        notificationDetails,
        payload: jsonEncode(data),
      );
    }
  }

  void toggleChatPageOpen(bool toggle) {
    isChatPageOpen = toggle;
  }

  void setChatPageState({required bool isOpen, String? customerId}) {
    isChatPageOpen = isOpen;
    activeCustomerId = isOpen ? customerId : null;
  }

  /// Handles notifications for group messages when the chat is not open
  Future<void> _groupChatNotification(Map<String, dynamic> data) async {
    debugPrint('🔔 Group Chat Notification: $data');

    // Backend now includes groupId in the broadcast. targetId is kept as fallback
    // for any in-flight messages sent before the backend fix.
    final groupId = data['groupId']?.toString().isNotEmpty == true
        ? data['groupId']!.toString()
        : (await LocalDbHelper.getGroupIdByTargetId(
                data['targetId']?.toString() ?? '') ??
            '');
    if (groupId.isEmpty) {
      debugPrint('ℹ️ Ignoring group chat notification without groupId');
      return;
    }

    final senderName = data['senderName']?.toString() ?? 'Team';
    final type = data['type']?.toString() ?? 'text';
    final rawMessage = data['message']?.toString() ?? '';

    String messageContent;
    switch (type) {
      case 'media':
        messageContent = '[Image]';
        break;
      case 'document':
        messageContent = '[Document]';
        break;
      case 'voice':
        messageContent = '[Voice message]';
        break;
      case 'text':
      default:
        messageContent = rawMessage.length > 30
            ? '${rawMessage.substring(0, 30)}...'
            : rawMessage;
        break;
    }

    final now = DateTime.now();

    // Unread count & last-message persistence — done BEFORE the notification
    // so a notification failure never blocks badges.
    try {
      await LocalDbHelper.saveGroupLastMessage(groupId, messageContent, now);
      debugPrint('✅ Saved last message for group $groupId: $messageContent');
    } catch (e) {
      debugPrint('❌ Error saving group last message: $e');
    }
    try {
      await LocalDbHelper.incrementGroupUnreadCount(groupId);
    } catch (e) {
      debugPrint('❌ Error incrementing group unread count: $e');
    }
    try {
      await LocalDbHelper.incrementGroupChatUnreadCount();
    } catch (e) {
      debugPrint('❌ Error incrementing global group chat unread count: $e');
    }

    debugPrint(
        '🔁 [Socket] groupListCallback registered: ${_onGroupListUpdateCallback != null}');
    _onGroupListUpdateCallback?.call(groupId, messageContent, now);

    // Push notification
    try {
      const androidDetails = AndroidNotificationDetails(
        'group_chat_channel_id',
        'Internal Chat Notifications',
        channelDescription: 'Notifications for internal team chat messages',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: 'app_logo',
        largeIcon: DrawableResourceAndroidBitmap('app_logo'),
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      await NotificationService.plugin.show(
        1001,
        'New update from Internal Chat ($senderName)',
        messageContent,
        const NotificationDetails(android: androidDetails, iOS: iosDetails),
        payload: jsonEncode({
          'isGroupMessage': true,
          'notificationType': 'groupChat',
          ...data,
        }),
      );
    } catch (e) {
      debugPrint('❌ Error showing group chat notification: $e');
    }
  }

  /// Handles notification taps
  Future<void> handleNotificationTap(NotificationResponse response) async {
    debugPrint("Notification tapped: ${response.payload}");

    if (response.payload == null) {
      debugPrint("Notification payload is null");
      return;
    }

    if (response.payload == "incoming_call") {
      debugPrint("Incoming call notification tapped — opening the app only.");
      return;
    }

    if (response.payload == "general_chat_summary") {
      debugPrint("Summary notification tapped — opening the app only.");
      return;
    }

    try {
      final Map<String, dynamic> notificationData =
          jsonDecode(response.payload!);

      if (notificationData['isGroupMessage'] == true) {
        debugPrint("Group message notification tapped");
        await handleGroupLocalNotificationTap(navigatorKey, notificationData);
        return;
      }

      if ("0" == await LocalDbHelper.getUserType()) {
        handleNotificationClickForCustomer(navigatorKey, notificationData);
      } else {
        handleNotificationClickForAgent(navigatorKey, notificationData);
      }
    } catch (e) {
      debugPrint("Not a JSON payload or failed to parse payload: $e");
    }
  }
}