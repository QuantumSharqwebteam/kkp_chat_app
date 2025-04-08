class FormDataModel {
  final String date;
  final String quality;
  final String weave;
  final String quantity;
  final String composition;
  final String rate;
  final String agentName;
  final String customerName;

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
  }) : parsedDate = DateTime.tryParse(date) {
    if (parsedDate != null) {
      dateOnly = _formatDate(parsedDate!);
      timeOnly = _formatTime(parsedDate!);
    } else {
      dateOnly = '';
      timeOnly = '';
    }
  }

  factory FormDataModel.fromJson(Map<String, dynamic> json) {
    return FormDataModel(
      date: json['date'] ?? '',
      quality: json['quality'] ?? '',
      weave: json['weave'] ?? '',
      quantity: json['quantity'] ?? '',
      composition: json['composition'] ?? '',
      rate: json['rate'] ?? '',
      agentName: json['agentName'] ?? '',
      customerName: json['customerName'] ?? '',
    );
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
