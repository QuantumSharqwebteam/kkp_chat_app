class MessageModel {
  final String? senderId;
  final String? senderName;
  final String? message;
  final bool? read;
  final String? type;
  final List<dynamic>? form; // Now dynamic list instead of ChatFormData
  final String? mediaUrl;
  final String? timestamp;
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
    return MessageModel(
      senderId: json['senderId'] as String?,
      senderName: json['senderName'] as String?,
      message: json['message'] as String?,
      read: json['read'] as bool? ?? false,
      type: json['type'] as String? ?? 'text',
      form: json['form'] as List<dynamic>?, // Just cast to dynamic list
      mediaUrl: json['mediaUrl'] as String?,
      timestamp: json['timestamp'] as String?,
      isMe: json['senderId'] == agentEmail,
    );
  }
}
