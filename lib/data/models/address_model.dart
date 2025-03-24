class Address {
  final String? houseNo;
  final String? streetName;
  final String? city;
  final String? pincode;

  Address({
    this.houseNo,
    this.streetName,
    this.city,
    this.pincode,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      houseNo: json['houseNo'],
      streetName: json['streetName'],
      city: json['city'],
      pincode: json['pincode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'houseNo': houseNo,
      'streetName': streetName,
      'city': city,
      'pincode': pincode,
    };
  }

  // Method to convert an Address instance to a Map
  Map<String, dynamic> toMap() {
    return {
      'houseNo': houseNo,
      'streetName': streetName,
      'city': city,
      'pincode': pincode,
    };
  }

  // Named constructor to create an Address instance from a Map
  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      houseNo: map['houseNo'],
      streetName: map['streetName'],
      city: map['city'],
      pincode: map['pincode'],
    );
  }
}
