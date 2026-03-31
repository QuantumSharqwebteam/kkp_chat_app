import 'package:kkpchatapp/data/models/user_model.dart';

class Activity {
  final String id;
  final UserModel user;
  final String featureUsed;
  final DateTime timestamp;

  Activity({
    required this.id,
    required this.user,
    required this.featureUsed,
    required this.timestamp,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    final dynamic userJson = json["user"];
    final parsedUser = userJson is Map<String, dynamic>
        ? UserModel.fromJson(userJson)
        : UserModel(id: '', email: '', name: 'Unknown User');

    final dynamic rawTimestamp = json["timestamp"];
    DateTime parsedTimestamp = DateTime.now();

    if (rawTimestamp is String) {
      parsedTimestamp = DateTime.tryParse(rawTimestamp)?.toLocal() ?? DateTime.now();
    } else if (rawTimestamp is int) {
      parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(
        rawTimestamp,
        isUtc: true,
      ).toLocal();
    }

    return Activity(
      id: (json["_id"] ?? '').toString(),
      user: parsedUser,
      featureUsed: (json["featureUsed"] ?? 'Unknown').toString(),
      timestamp: parsedTimestamp,
    );
  }

  String get username => user.name.isNotEmpty ? user.name : 'Unknown User';
  String get userEmail => user.email;
}
