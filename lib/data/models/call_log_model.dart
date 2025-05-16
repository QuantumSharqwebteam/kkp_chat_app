class CallLogModel {
  final String senderId;
  final String senderName;
  final String receiverId;
  final String receiverName;
  final String callStatus;
  final String? callDuration; // Nullable
  final DateTime timestamp;
  final String id;

  CallLogModel({
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.receiverName,
    required this.callStatus,
    this.callDuration,
    required this.timestamp,
    required this.id,
  });

  factory CallLogModel.fromJson(Map<String, dynamic> json) {
    final rawTimestamp = json['timestamp'] ?? '';
    DateTime utcTime;

    try {
      utcTime = DateTime.parse(rawTimestamp).toUtc(); // force parse as UTC
    } catch (e) {
      utcTime = DateTime.now().toUtc(); // fallback in case of error
    }

    return CallLogModel(
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      receiverId: json['receiverId'] ?? '',
      receiverName: json['receiverName'] ?? '',
      callStatus: json['callStatus'] ?? '',
      callDuration: json['callDuration'] as String?,
      timestamp: utcTime.toLocal(), // convert to local time here
      id: json['_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'callStatus': callStatus,
      'callDuration': callDuration,
      'timestamp': timestamp.toIso8601String(),
      '_id': id,
    };
  }
}
