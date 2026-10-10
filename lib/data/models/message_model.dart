class MessageModel {
  final String? senderId;

  /// Email/ID of whoever PLACED the call (only for type == 'call').
  final String? callerId;

  final String? senderName;
  final String? message;
  final bool? read;
  final String? type;
  final List<dynamic>? form;
  final String? mediaUrl;
  final String? timestamp;
  final bool isMe;
  final String? callStatus;
  final String? callDuration;
  final String? callId;
  final String? messageId;
  final bool? isDeleted;
  final String? referenceId;

  MessageModel({
    this.senderId,
    this.callerId,
    this.senderName,
    this.message,
    this.read,
    this.type,
    this.form,
    this.mediaUrl,
    this.timestamp,
    required this.isMe,
    this.callStatus,
    this.callDuration,
    this.callId,
    this.messageId,
    this.isDeleted,
    this.referenceId,
  });

  static String? _firstNonEmpty(List<dynamic> values) {
    for (final v in values) {
      final s = v?.toString().trim();
      if (s != null && s.isNotEmpty) return s;
    }
    return null;
  }

  factory MessageModel.fromJson(Map<String, dynamic> json, String agentEmail) {
    final type = json['type']?.toString() ?? 'text';
    final callerId =
        _firstNonEmpty([json['callerId'], json['caller'], json['from']]);

    // For call logs the caller IS the owner of the message.
    final senderId = type == 'call'
        ? _firstNonEmpty([callerId, json['senderId'], json['senderEmail']])
        : _firstNonEmpty(
            [json['senderId'], json['senderEmail'], json['sender']]);

    final me = agentEmail.trim().toLowerCase();

    return MessageModel(
      senderId: senderId,
      callerId: callerId,
      senderName: json['senderName']?.toString(),
      message: json['message']?.toString(),
      read: json['read'] as bool? ?? false,
      type: type,
      form: json['form'] is List
          ? json['form'] as List<dynamic>
          : (json['form'] is Map ? [json['form']] : null),
      mediaUrl: json['mediaUrl']?.toString(),
      timestamp: json['timestamp']?.toString(),
      isMe: me.isNotEmpty && senderId?.toLowerCase() == me,
      callStatus: json['callStatus']?.toString(),
      callDuration: json['callDuration']?.toString(),
      callId: json['callId']?.toString(),
      messageId: json['messageId']?.toString(),
      isDeleted: json['isDeleted'] as bool? ?? false,
      referenceId: json['referenceId']?.toString(),
    );
  }
}
