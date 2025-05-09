class NotificationModel {
  final String? id;
  final String? title;
  final String? body;
  final String? senderId;
  final String? targetId;
  final String? senderName;
  final String? type;
  final bool? viewed;
  final DateTime? timestamp;
  final String? mediaUrl;
  final List<dynamic>? form;
  final int? v;

  NotificationModel({
    this.id,
    this.title,
    this.body,
    this.senderId,
    this.targetId,
    this.senderName,
    this.type,
    this.viewed,
    this.timestamp,
    this.mediaUrl,
    this.form,
    this.v,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedTimestamp;
    try {
      parsedTimestamp = json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString())
          : null;
    } catch (_) {
      parsedTimestamp = null;
    }

    return NotificationModel(
      id: json['_id'] as String?,
      title: json['title'] as String?,
      body: json['body'] as String?,
      senderId: json['senderId'] as String?,
      targetId: json['targetId'] as String?,
      senderName: json['senderName'] as String?,
      type: json['type'] as String?,
      viewed: json['viewed'] as bool?,
      timestamp: parsedTimestamp,
      mediaUrl: json['mediaUrl'] as String?,
      form: json['form'] is List ? json['form'] as List<dynamic> : [],
      v: json['__v'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'body': body,
      'senderId': senderId,
      'targetId': targetId,
      'senderName': senderName,
      'type': type,
      'viewed': viewed,
      'timestamp': timestamp?.toIso8601String(),
      'mediaUrl': mediaUrl,
      'form': form ?? [],
      '__v': v,
    };
  }
}
