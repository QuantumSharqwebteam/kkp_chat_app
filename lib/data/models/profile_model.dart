import 'package:kkp_chat_app/data/models/address_model.dart';

class Profile {
  String? id;
  bool? lockedTemp;
  String? panNo;
  int? otp;
  List<Address>? address;
  String? gstNo;
  String? email;
  String? name;
  int? expireTime;
  String? password;
  int? mobile;
  String? customerType;
  String? role;
  DateTime? createdAt;
  DateTime? updatedAt;
  int? wrongPasswordCount;
  int? v;

  Profile(
      {this.id,
      this.lockedTemp,
      this.panNo,
      this.otp,
      this.address,
      this.gstNo,
      this.email,
      this.name,
      this.expireTime,
      this.password,
      this.mobile,
      this.customerType,
      this.role,
      this.createdAt,
      this.updatedAt,
      this.wrongPasswordCount,
      this.v});

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['_id'],
      lockedTemp: json['lockedTemp'],
      panNo: json['PANno'] ?? "NA",
      otp: json['otp'],
      address: json['address'] != null
          ? List<Address>.from(json['address'].map((x) => Address.fromJson(x)))
          : [],
      gstNo: json['GSTno'] ?? "NA",
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      expireTime: json['expireTime'] ?? 0,
      password: json['password'] ?? '',
      mobile: json['mobile'] ?? 0, // ✅ Always ensures a value
      customerType: json['customerType'],
      role: json['role'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      wrongPasswordCount: json['wrongPasswordCount'] ?? 0,
      v: json['__v'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'lockedTemp': lockedTemp,
      'PANno': panNo,
      'otp': otp,
      'address': address?.map((x) => x.toJson()).toList(),
      'GSTno': gstNo,
      'email': email,
      'name': name,
      'expireTime': expireTime,
      'password': password,
      'mobile': mobile,
      'customerType': customerType,
      'role': role,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'wrongPasswordCount': wrongPasswordCount,
      "__v": v
    };
  }

  // Method to convert the Profile object to a Map
  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'lockedTemp': lockedTemp,
      'panNo': panNo,
      'otp': otp,
      'address': address?.map((x) => x.toMap()).toList(),
      'gstNo': gstNo,
      'email': email,
      'name': name,
      'expireTime': expireTime,
      'password': password,
      'mobile': mobile,
      'customerType': customerType,
      'role': role,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'wrongPasswordCount': wrongPasswordCount,
      "__v": v
    };
  }

  // Named constructor to create a Profile instance from a Map
  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
        id: map['_id'],
        lockedTemp: map['lockedTemp'],
        panNo: map['panNo'],
        otp: map['otp'],
        address: map['address'] != null
            ? List<Address>.from(map['address'].map((x) => Address.fromMap(x)))
            : null,
        gstNo: map['gstNo'],
        email: map['email'],
        name: map['name'],
        expireTime: map['expireTime'],
        password: map['password'],
        mobile: map['mobile'],
        customerType: map['customerType'],
        role: map['role'],
        createdAt:
            map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
        updatedAt:
            map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
        wrongPasswordCount: map['wrongPasswordCount'],
        v: map['__v']);
  }
}
