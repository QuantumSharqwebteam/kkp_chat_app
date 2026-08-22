class FormDataModel {
  final String date;
  final String quality;
  final String weave;
  final String quantity;
  final String composition;
  final String rate;
  final String agentName;
  final String customerName;
  final String buyerName;
  final String status;
  final String reason;
  final String id;
  final String orderId;

  FormDataModel({
    required this.date,
    required this.quality,
    required this.weave,
    required this.quantity,
    required this.composition,
    required this.rate,
    required this.agentName,
    required this.customerName,
    required this.buyerName,
    required this.status,
    required this.reason,
    required this.id,
    required this.orderId,
  });

  /// Trims a raw field and maps the backend's "Unknown Buyer" placeholder to an
  /// empty string, so the UI can show its own "not available" copy.
  ///
  /// Public because local optimistic updates must normalize exactly the same
  /// way as a fresh fetch — otherwise an edited row renders differently from
  /// the same row after a refresh.
  static String normalize(dynamic value) {
    if (value == null) return '';
    final str = value.toString().trim();
    if (str.toLowerCase() == 'unknown buyer') return '';
    return str;
  }

  static String _asString(dynamic value) => normalize(value);

  factory FormDataModel.fromJson(Map<String, dynamic> json) {
    return FormDataModel(
      date: _asString(json['date']),
      quality: _asString(json['quality']),
      weave: _asString(json['weave']),
      quantity: _asString(json['quantity']),
      composition: _asString(json['composition']),
      rate: _asString(json['rate']),
      agentName: _asString(json['agentName']),
      customerName: _asString(json['customerName']),
      buyerName: _asString(json['buyerName']),
      status: _asString(json['status']),
      reason: _asString(json['reason']),
      id: _asString(json['_id']),
      orderId: _asString(json['orderId']).isNotEmpty
          ? _asString(json['orderId'])
          : _asString(json['_id']),
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
      'buyerName': buyerName,
      'status': status,
      'reason': reason,
      '_id': id,
      'orderId': orderId,
    };
  }

  FormDataModel copyWith({
    String? date,
    String? quality,
    String? weave,
    String? quantity,
    String? composition,
    String? rate,
    String? agentName,
    String? customerName,
    String? buyerName,
    String? status,
    String? reason,
    String? id,
    String? orderId,
  }) {
    return FormDataModel(
      date: date ?? this.date,
      quality: quality ?? this.quality,
      weave: weave ?? this.weave,
      quantity: quantity ?? this.quantity,
      composition: composition ?? this.composition,
      rate: rate ?? this.rate,
      agentName: agentName ?? this.agentName,
      customerName: customerName ?? this.customerName,
      buyerName: buyerName ?? this.buyerName,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
    );
  }
}
