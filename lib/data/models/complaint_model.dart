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
    return ComplaintModel(
      id: json['_id'],
      userModel: UserModel.fromJson(json['user']),
      subject: json['subject'],
      description: json['description'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
