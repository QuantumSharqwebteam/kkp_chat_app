class Activity {
  final String id;
  final String username;
  final String featureUsed;
  final DateTime timestamp;

  Activity({
    required this.id,
    required this.username,
    required this.featureUsed,
    required this.timestamp,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json["_id"],
      username: json["user"]["name"],
      featureUsed: json["featureUsed"],
      timestamp: DateTime.parse(json["timestamp"]),
    );
  }
}
