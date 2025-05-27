class MessageModel {
  final String? senderId;
  final String? senderName;
  final String? message;
  final bool? read;
  final String? type;
  final List<dynamic>? form;
  final String? mediaUrl;
  final DateTime? timestamp;
  final bool isMe;

  MessageModel({
    this.senderId,
    this.senderName,
    this.message,
    this.read,
    this.type,
    this.form,
    this.mediaUrl,
    this.timestamp,
    required this.isMe,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json, String agentEmail) {
    final rawTimestamp = json['timestamp'] as String?;
    return MessageModel(
      senderId: json['senderId'] as String?,
      senderName: json['senderName'] as String?,
      message: json['message'] as String?,
      read: json['read'] as bool? ?? false,
      type: json['type'] as String? ?? 'text',
      form: json['form'] as List<dynamic>?,
      mediaUrl: json['mediaUrl'] as String?,
      timestamp:
          rawTimestamp != null ? DateTime.parse(rawTimestamp).toUtc() : null,
      isMe: json['senderId'] == agentEmail,
    );
  }
}
