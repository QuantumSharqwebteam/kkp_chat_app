class Address {
  final String? id;
  final String? houseNo;
  final String? streetName;
  final String? city;
  final String? pincode;

  Address({
    this.id,
    this.houseNo,
    this.streetName,
    this.city,
    this.pincode,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['_id'] ?? "NA",
      houseNo: json['houseNo'] ?? "NA",
      streetName: json['streetName'] ?? "NA",
      city: json['city'] ?? "NA",
      pincode: json['pincode'] ?? "NA",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      'houseNo': houseNo,
      'streetName': streetName,
      'city': city,
      'pincode': pincode,
    };
  }

  // Method to convert an Address instance to a Map
  Map<String, dynamic> toMap() {
    return {
      "_id": id,
      'houseNo': houseNo,
      'streetName': streetName,
      'city': city,
      'pincode': pincode,
    };
  }

  // Named constructor to create an Address instance from a Map
  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      id: map['_id'],
      houseNo: map['houseNo'],
      streetName: map['streetName'],
      city: map['city'],
      pincode: map['pincode'],
    );
  }
}
