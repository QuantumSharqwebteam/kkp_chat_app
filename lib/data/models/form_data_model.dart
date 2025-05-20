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

  late final String dateOnly;
  late final String timeOnly;
  final DateTime? parsedDate;

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
  }) : parsedDate = DateTime.tryParse(date) {
    if (parsedDate != null) {
      dateOnly = _formatDate(parsedDate!);
      timeOnly = _formatTime(parsedDate!);
    } else {
      dateOnly = '';
      timeOnly = '';
    }
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

  Map<String, dynamic> toSingleMap() {
    return {
      'Date': dateOnly,
      'Quality': quality,
      'Weave': weave,
      'Quantity': quantity,
      'Composition': composition,
      'Rate': rate,
      'Agent Name': agentName,
      'Customer Name': customerName,
      'Status': status,
      'ID': id,
      'Time': timeOnly,
    };
  }

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

  static List<Map<String, dynamic>> formDataModelToListOfMaps(
      List<FormDataModel> models) {
    return models.map((model) => model.toSingleMap()).toList();
  }

  String _formatDate(DateTime date) {
    return "${_monthName(date.month)} ${date.day}, ${date.year}";
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'pm' : 'am';
    return "$hour:$minute $period";
  }

  String _monthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    return months[month - 1];
  }
}
