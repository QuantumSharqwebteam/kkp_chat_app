import 'package:kkpchatapp/data/models/user_model.dart';

class ComplaintModel {
  final String id;
  final UserModel userModel;
  final String subject;
  final String description;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  ComplaintModel({
    required this.id,
    required this.userModel,
    required this.subject,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  static ComplaintModel fromJson(Map<String, dynamic> json) {
    DateTime _parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed;
        // try parsing as int string (epoch millis)
        final intVal = int.tryParse(value);
        if (intVal != null) return DateTime.fromMillisecondsSinceEpoch(intVal);
      }
      return DateTime.now();
    }

    return ComplaintModel(
      id: (json['_id'] ?? '').toString(),
      userModel: UserModel.fromJson(
          json['user'] is Map<String, dynamic> ? json['user'] : {}),
      subject: (json['subject'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }
}
