class ChatMessageModel {
  String message;
  String sender;
  DateTime timestamp;
  String? type;
  String? mediaUrl;
  Map<String, dynamic>? form;

  ChatMessageModel({
    required this.message,
    required this.sender,
    required this.timestamp,
    this.type,
    this.mediaUrl,
    this.form,
  });

  // Convert a ChatMessage object into a Map
  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'sender': sender,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'mediaUrl': mediaUrl,
      'form': form,
    };
  }

  // Create a ChatMessage object from a Map
  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    return ChatMessageModel(
      message: map['message'],
      sender: map['sender'],
      timestamp: DateTime.parse(map['timestamp']),
      type: map['type'],
      mediaUrl: map['mediaUrl'],
      form: map['form'],
    );
  }
}
