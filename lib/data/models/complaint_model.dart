// class Complaint {
//   final String subject;
//   final String description;

//   Complaint({required this.subject, required this.description});

//   factory Complaint.fromJson(Map<String, dynamic> json) {
//     return Complaint(
//       subject: json['subject'] ?? 'No Subject',
//       description: json['description'] ?? 'No Description',
//     );
//   }
// }
// }

// import 'dart:convert';

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

//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'userModel': userModel,
//       'subject': subject,
//       'description': description,
//       'createdAt': createdAt,
//       'updatedAt': updatedAt,
//     };
//   }

//   String get toJson => jsonEncode(toMap());
}

final data = {
  "status": 200,
  "message": [
    {
      "_id": "68d4f1e8556fb3297560efc7",
      "user": {
        "_id": "67e16612692e4c246135619c",
        "email": "mukilankumar003@gmail.com",
        "name": "Mukilan"
      },
      "subject": "App not responding",
      "description":
          "When I click the submit button, nothing happens. I've tried refreshing and using different browsers.",
      "status": "pending",
      "createdAt": "2025-09-25T07:40:24.167Z",
      "updatedAt": "2025-09-25T07:40:24.167Z",
      "__v": 0
    },
    {
      "_id": "68d55825b988846bc2fc9b31",
      "user": {
        "_id": "68ac2a9a983d8d291d237f64",
        "email": "hemanthba191@gmail.com",
        "name": "Hemanth"
      },
      "subject": "hi",
      "description": "Hello",
      "status": "pending",
      "createdAt": "2025-09-25T14:56:37.200Z",
      "updatedAt": "2025-09-25T14:56:37.200Z",
      "__v": 0
    }
  ]
};
