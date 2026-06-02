class ChatMessageModel {
  String? message;
  String? sender;
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

  ChatMessageModel({
    this.message,
    this.sender,
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
  });

  @override
  String toString() {
    return 'ChatMessageModel(message: $message, sender: $sender, timestamp: $timestamp, '
        'type: $type, mediaUrl: $mediaUrl, form: $form, forms: $forms, callStatus: $callStatus, '
        'callDuration: $callDuration,callId :$callId,isRead: $read), messageId: $messageId,isDeleted:$isDeleted ';
  }

  static Map<String, dynamic>? _normalizeMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return Map<String, dynamic>.from(raw);
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  static List<Map<String, dynamic>>? _normalizeList(dynamic raw) {
    if (raw is List) {
      return raw.whereType<Map>().map((entry) => Map<String, dynamic>.from(entry)).toList();
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

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'sender': sender,
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
    };
  }

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    final normalizedForms = _normalizeList(map['forms']);
    final fallbackForm = normalizedForms != null && normalizedForms.isNotEmpty
        ? Map<String, dynamic>.from(normalizedForms.first)
        : null;
    return ChatMessageModel(
      message: map['message'],
      sender: map['sender'],
      timestamp: DateTime.parse(map['timestamp']),
      type: map['type'],
      mediaUrl: map['mediaUrl'],
      form: _normalizeMap(map['form']) ?? fallbackForm,
      forms: normalizedForms,
      callStatus: map['callStatus'],
      callDuration: map['callDuration'],
      callId: map['callId'],
      messageId: map['messageId'],
      isDeleted: map['isDeleted'] ?? false,
      read: map['read'],
    );
  }
}
