import 'package:kkp_chat_app/data/models/address_model.dart';

class Profile {
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
  DateTime? createdOn;
  int? wrongPasswordCount;

  Profile({
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
    this.createdOn,
    this.wrongPasswordCount,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      lockedTemp: json['lockedTemp'],
      panNo: json['PANno'],
      otp: json['otp'],
      address: json['address'] != null
          ? List<Address>.from(json['address'].map((x) => Address.fromJson(x)))
          : null,
      gstNo: json['GSTno'],
      email: json['email'],
      name: json['name'],
      expireTime: json['expireTime'],
      password: json['password'],
      mobile: json['mobile'],
      customerType: json['customerType'],
      role: json['role'],
      createdOn:
          json['createdOn'] != null ? DateTime.parse(json['createdOn']) : null,
      wrongPasswordCount: json['wrongPasswordCount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
      'createdOn': createdOn?.toIso8601String(),
      'wrongPasswordCount': wrongPasswordCount,
    };
  }
}
