class ChatMessageModel {
  String? message;
  String? sender;

  /// Email/ID of whoever PLACED the call. Only meaningful when type == 'call'.
  /// Used to decide which side a call bubble is drawn on after a reload.
  String? callerId;

  DateTime timestamp;
  String? type;
  String? mediaUrl;
  Map<String, dynamic>? form;
  List<Map<String, dynamic>>? forms;
  String? callStatus;
  String? callDuration;
  String? callId;
  String? messageId;
  bool isDeleted;
  bool? read;
  String? referenceId;

  ChatMessageModel({
    this.message,
    this.sender,
    this.callerId,
    required this.timestamp,
    this.type,
    this.mediaUrl,
    this.form,
    this.forms,
    this.callStatus,
    this.callDuration,
    this.callId,
    this.messageId,
    this.isDeleted = false,
    this.read = false,
    this.referenceId,
  });

  @override
  String toString() {
    return 'ChatMessageModel(message: $message, sender: $sender, callerId: $callerId, '
        'timestamp: $timestamp, type: $type, mediaUrl: $mediaUrl, form: $form, forms: $forms, '
        'callStatus: $callStatus, callDuration: $callDuration, callId: $callId, '
        'isRead: $read, messageId: $messageId, isDeleted: $isDeleted)';
  }

  // ── Direction helpers ─────────────────────────────────────────────────────

  static String? _norm(String? v) {
    final s = v?.trim().toLowerCase();
    return (s == null || s.isEmpty) ? null : s;
  }

  /// The user this message belongs to. For call logs this is the caller,
  /// for everything else it is the sender.
  String? get ownerId {
    if (type == 'call' && _norm(callerId) != null) return callerId;
    return sender;
  }

  /// Single source of truth for left/right placement.
  /// `true` → draw on the right (sent by [myEmail]).
  bool isFromUser(String? myEmail) {
    final me = _norm(myEmail);
    final owner = _norm(ownerId);
    return me != null && owner != null && owner == me;
  }

  // ── Form helpers ──────────────────────────────────────────────────────────

  static Map<String, dynamic>? _normalizeMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return Map<String, dynamic>.from(raw);
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  static List<Map<String, dynamic>>? _normalizeList(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList();
    }
    return null;
  }

  List<Map<String, dynamic>> get formEntries {
    if (forms != null && forms!.isNotEmpty) return forms!;
    if (form != null) return [form!];
    return [];
  }

  Map<String, dynamic>? get primaryForm =>
      form ?? (forms?.isNotEmpty == true ? forms!.first : null);

  // ── Persistence ───────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'sender': sender,
      'callerId': callerId,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'mediaUrl': mediaUrl,
      'form': form,
      'forms': forms?.map((entry) => Map<String, dynamic>.from(entry)).toList(),
      'callStatus': callStatus,
      'callDuration': callDuration,
      'callId': callId,
      'messageId': messageId,
      'isDeleted': isDeleted,
      'read': read,
      'referenceId': referenceId,
    };
  }

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    final normalizedForms = _normalizeList(map['forms']);
    final fallbackForm = normalizedForms != null && normalizedForms.isNotEmpty
        ? Map<String, dynamic>.from(normalizedForms.first)
        : null;

    final callerId = _firstNonEmpty([map['callerId']]);

    return ChatMessageModel(
      message: map['message']?.toString(),
      // Server may send the caller under a different key for call logs.
      sender: _firstNonEmpty([
        map['sender'],
        map['senderId'],
        callerId,
        map['senderEmail'],
      ]),
      callerId: callerId,
      timestamp: DateTime.tryParse(map['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      type: map['type']?.toString(),
      mediaUrl: map['mediaUrl']?.toString(),
      form: _normalizeMap(map['form']) ?? fallbackForm,
      forms: normalizedForms,
      callStatus: map['callStatus']?.toString(),
      callDuration: map['callDuration']?.toString(),
      callId: map['callId']?.toString(),
      messageId: map['messageId']?.toString(),
      isDeleted: map['isDeleted'] ?? false,
      read: map['read'],
      referenceId: map['referenceId']?.toString(),
    );
  }

  static String? _firstNonEmpty(List<dynamic> values) {
    for (final v in values) {
      final s = v?.toString();
      if (s != null && s.trim().isNotEmpty) return s.trim();
    }
    return null;
  }
}
