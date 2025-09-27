// import 'dart:convert';

class UserModel {
  final String id;
  final String email;
  final String name;
  UserModel({
    required this.id,
    required this.email,
    required this.name,
  });

  static UserModel fromJson(Map<String, dynamic> json) {
    return UserModel(id: json['_id'], email: json['email'], name: json['name']);
  }

  // Map<String, dynamic> toMap() {
  //   return {
  //     'id': id,
  //     'email': email,
  //     'name': name,
  //   };
  // }

  // String get toJson => JsonEncode(toMap());
}
