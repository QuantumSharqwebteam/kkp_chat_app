import 'dart:convert';
import 'package:kkpchatapp/data/models/address_model.dart';

class Agent {
  final String id;
  final bool lockedTemp;
  final int otp;
  final List<Address> address;
  final String gstNo;
  final String email;
  final String name;
  final int expireTime;
  final String password;
  final int mobile;
  final String customerType;
  final String role;
  final String createdAt;
  final String updatedAt;
  final int wrongPasswordCount;

  Agent({
    required this.id,
    required this.lockedTemp,
    required this.otp,
    required this.address,
    required this.gstNo,
    required this.email,
    required this.name,
    required this.expireTime,
    required this.password,
    required this.mobile,
    required this.customerType,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    required this.wrongPasswordCount,
  });

  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      id: json['id'] ?? "",
      lockedTemp: json['lockedTemp'] ?? false,
      otp: json['otp'] ?? 0,
      address: (json['address'] as List<dynamic>?)
              ?.map((e) => Address.fromJson(e))
              .toList() ??
          [],
      gstNo: json['GSTno'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? 'Name NA',
      expireTime: json['expireTime'] ?? 0,
      password: json['password'] ?? '',
      mobile: json['mobile'] ?? 0,
      customerType: json['customerType'] ?? '',
      role: json['role'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      wrongPasswordCount: json['wrongPasswordCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      'lockedTemp': lockedTemp,
      'otp': otp,
      'address': address.map((e) => e.toJson()).toList(),
      'GSTno': gstNo,
      'email': email,
      'name': name,
      'expireTime': expireTime,
      'password': password,
      'mobile': mobile,
      'customerType': customerType,
      'role': role,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'wrongPasswordCount': wrongPasswordCount,
    };
  }
}

// Function to parse JSON response
List<Agent> parseAgents(String responseBody) {
  final parsed = jsonDecode(responseBody)['message'] as List<dynamic>;
  return parsed.map((json) => Agent.fromJson(json)).toList();
}
