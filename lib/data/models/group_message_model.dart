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
  final bool isEdited;
  final String? groupId;

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
    this.isEdited = false,
    this.groupId,
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
      'isEdited': isEdited,
      'groupId': groupId,
    };
  }

  factory GroupMessageModel.fromMap(Map<String, dynamic> map) {
    return GroupMessageModel(
      message: map['message'] ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      type: map['type'] ?? 'text',
      mediaUrl: map['mediaUrl'],
      fileName: map['fileName'],
      mentions: map['mentions'] != null ? List<String>.from(map['mentions']) : null,
      replyTo: map['replyTo'],
      messageId: map['messageId'] ?? map['_id'] ?? '',
      isDeleted: map['isDeleted'] ?? false,
      read: map['read'] ?? false,
      isEdited: map['isEdited'] ?? false,
      groupId: map['groupId'],
    );
  }

  factory GroupMessageModel.fromApiJson(Map<String, dynamic> json) {
    return GroupMessageModel(
      message: json['message'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
          : DateTime.now(),
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      type: json['type'] ?? 'text',
      mediaUrl: json['mediaUrl'],
      fileName: json['fileName'],
      mentions: json['mentions'] != null ? List<String>.from(json['mentions']) : null,
      replyTo: json['replyTo'],
      messageId: json['messageId'] ?? json['_id'] ?? '',
      isDeleted: json['isDeleted'] ?? false,
      read: json['read'] ?? false,
      isEdited: json['isEdited'] ?? false,
      groupId: json['groupId'],
    );
  }

  GroupMessageModel copyWith({
    String? message,
    DateTime? timestamp,
    String? senderId,
    String? senderName,
    String? type,
    String? mediaUrl,
    String? fileName,
    List<String>? mentions,
    String? replyTo,
    String? messageId,
    bool? isDeleted,
    bool? read,
    bool? isEdited,
    String? groupId,
  }) {
    return GroupMessageModel(
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      type: type ?? this.type,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      fileName: fileName ?? this.fileName,
      mentions: mentions ?? this.mentions,
      replyTo: replyTo ?? this.replyTo,
      messageId: messageId ?? this.messageId,
      isDeleted: isDeleted ?? this.isDeleted,
      read: read ?? this.read,
      isEdited: isEdited ?? this.isEdited,
      groupId: groupId ?? this.groupId,
    );
  }
}
