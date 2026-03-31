class ExtractedProductData {
  final String? id;
  final String chatId;
  final String agentEmail;
  final String customerEmail;
  final String? customerName;
  final String? quality;
  final String? weave;
  final String? quantity;
  final String? composition;
  final num? rate;
  final DateTime extractedAt;
  final double confidence;
  final int? extractionTimeMs;
  final bool sent;
  final DateTime? sentAt;
  final String? orderId;
  final String? status;

  ExtractedProductData({
    this.id,
    required this.chatId,
    required this.agentEmail,
    required this.customerEmail,
    this.customerName,
    this.quality,
    this.weave,
    this.quantity,
    this.composition,
    this.rate,
    required this.extractedAt,
    required this.confidence,
    this.extractionTimeMs,
    this.sent = false,
    this.sentAt,
    this.orderId,
    this.status,
  });

  factory ExtractedProductData.fromJson(Map<String, dynamic> json) {
    return ExtractedProductData(
      id: json['id'] as String?,
      chatId: json['chat_id'] as String,
      agentEmail: json['agent_email'] as String,
      customerEmail: json['customer_email'] as String,
      customerName: json['customer_name'] as String?,
      quality: json['quality'] as String?,
      weave: json['weave'] as String?,
      quantity: json['quantity'] as String?,
      composition: json['composition'] as String?,
      rate: json['rate'] as num?,
      extractedAt: DateTime.parse(json['extracted_at'] as String),
      confidence: (json['confidence'] as num).toDouble(),
      extractionTimeMs: json['extraction_time_ms'] as int?,
      sent: (json['sent'] as int? ?? 0) == 1,
      sentAt: json['sent_at'] != null ? DateTime.tryParse(json['sent_at']) : null,
      orderId: json['order_id'] as String?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'chat_id': chatId,
      'agent_email': agentEmail,
      'customer_email': customerEmail,
      'customer_name': customerName,
      'quality': quality,
      'weave': weave,
      'quantity': quantity,
      'composition': composition,
      'rate': rate,
      'extracted_at': extractedAt.toIso8601String(),
      'confidence': confidence,
      'sent': sent ? 1 : 0,
      'sent_at': sentAt?.toIso8601String(),
      'order_id': orderId,
      'status': status,
      if (extractionTimeMs != null) 'extraction_time_ms': extractionTimeMs,
    };
  }

  ExtractedProductData copyWith({
    String? id,
    String? chatId,
    String? agentEmail,
    String? customerEmail,
    String? customerName,
    String? quality,
    String? weave,
    String? quantity,
    String? composition,
    num? rate,
    DateTime? extractedAt,
    double? confidence,
    int? extractionTimeMs,
    bool? sent,
    DateTime? sentAt,
    String? orderId,
    String? status,
  }) {
    return ExtractedProductData(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      agentEmail: agentEmail ?? this.agentEmail,
      customerEmail: customerEmail ?? this.customerEmail,
      customerName: customerName ?? this.customerName,
      quality: quality ?? this.quality,
      weave: weave ?? this.weave,
      quantity: quantity ?? this.quantity,
      composition: composition ?? this.composition,
      rate: rate ?? this.rate,
      extractedAt: extractedAt ?? this.extractedAt,
      confidence: confidence ?? this.confidence,
      extractionTimeMs: extractionTimeMs ?? this.extractionTimeMs,
      sent: sent ?? this.sent,
      sentAt: sentAt ?? this.sentAt,
      orderId: orderId ?? this.orderId,
      status: status ?? this.status,
    );
  }
}
