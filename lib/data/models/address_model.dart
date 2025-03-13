class Address {
  final String houseNo;
  final String streetName;
  final String city;
  final String pincode;

  Address({
    required this.houseNo,
    required this.streetName,
    required this.city,
    required this.pincode,
  });

  // Named constructor to create an Address instance from a JSON map
  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      houseNo: json['houseNo'],
      streetName: json['streetName'],
      city: json['city'],
      pincode: json['pincode'],
    );
  }

  // Method to convert an Address instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'houseNo': houseNo,
      'streetName': streetName,
      'city': city,
      'pincode': pincode,
    };
  }
}
