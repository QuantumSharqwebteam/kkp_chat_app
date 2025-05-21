class FormDataModel {
  final String date;
  final String quality;
  final String weave;
  final String quantity;
  final String composition;
  final String rate;
  final String agentName;
  final String customerName;
  final String status;
  final String id;

  FormDataModel({
    required this.date,
    required this.quality,
    required this.weave,
    required this.quantity,
    required this.composition,
    required this.rate,
    required this.agentName,
    required this.customerName,
    required this.status,
    required this.id,
  });

  factory FormDataModel.fromJson(Map<String, dynamic> json) {
    return FormDataModel(
      date: json['date'] ?? '',
      quality: json['quality'] ?? '',
      weave: json['weave'] ?? '',
      quantity: json['quantity'] ?? '',
      composition: json['composition'] ?? '',
      rate: json['rate']?.toString() ?? '',
      agentName: json['agentName'] ?? '',
      customerName: json['customerName'] ?? '',
      status: json['status'] ?? '',
      id: json['_id'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'quality': quality,
      'weave': weave,
      'quantity': quantity,
      'composition': composition,
      'rate': rate,
      'agentName': agentName,
      'customerName': customerName,
      'status': status,
      '_id': id,
    };
  }
}
