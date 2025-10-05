class GroupMessageModel {
  final String message;
  final DateTime timestamp;
  final String senderId;
  final String senderName;
  final String type;
  final String? mediaUrl;
  final String? fileName;
  final List<String>? mentions;
  final String? replyTo;
  final String messageId;
  final bool isDeleted;
  final bool read;

  GroupMessageModel({
    required this.message,
    required this.timestamp,
    required this.senderId,
    required this.senderName,
    required this.type,
    this.mediaUrl,
    this.fileName,
    this.mentions,
    this.replyTo,
    required this.messageId,
    this.isDeleted = false,
    this.read = false,
  });

  // Convert to Map for local storage
  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'senderId': senderId,
      'senderName': senderName,
      'type': type,
      'mediaUrl': mediaUrl,
      'fileName': fileName,
      'mentions': mentions,
      'replyTo': replyTo,
      'messageId': messageId,
      'isDeleted': isDeleted,
      'read': read,
    };
  }

  // Create from Map (for local storage)
  factory GroupMessageModel.fromMap(Map<String, dynamic> map) {
    return GroupMessageModel(
      message: map['message'] ?? '',
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      type: map['type'] ?? 'text',
      mediaUrl: map['mediaUrl'],
      fileName: map['fileName'],
      mentions: map['mentions'] != null ? List<String>.from(map['mentions']) : null,
      replyTo: map['replyTo'],
      messageId: map['messageId'], // Use _id as fallback
      isDeleted: map['isDeleted'] ?? false,
      read: map['read'] ?? false,
    );
  }

  // Create from API JSON
  factory GroupMessageModel.fromApiJson(Map<String, dynamic> json) {
    return GroupMessageModel(
      message: json['message'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      type: json['type'] ?? 'text',
      mediaUrl: json['mediaUrl'],
      fileName: json['fileName'],
      mentions: json['mentions'] != null ? List<String>.from(json['mentions']) : null,
      replyTo: json['replyTo'],
      messageId: json['messageId'], // Use _id as fallback
      isDeleted: json['isDeleted'] ?? false,
      read: json['read'] ?? false,
    );
  }
}
