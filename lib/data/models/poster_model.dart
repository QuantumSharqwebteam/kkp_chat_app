class PosterModel {
  final String id;
  final String mediaUrl;
  final DateTime timestamp;

  PosterModel({
    required this.id,
    required this.mediaUrl,
    required this.timestamp,
  });

  factory PosterModel.fromJson(Map<String, dynamic> json) {
    return PosterModel(
      id: json['_id'] ?? '',
      mediaUrl: json['mediaUrl'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}
