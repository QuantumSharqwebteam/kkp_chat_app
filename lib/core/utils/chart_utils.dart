class ChartUtils {
  String getDateRange(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return '';
    final firstMonth = data.first['month'];
    final lastMonth = data.last['month'];
    return '$firstMonth - $lastMonth';
  }

  int getTotalCount(String selectedKey, List<Map<String, dynamic>> data) {
    return data.fold<num>(0, (sum, item) {
      var value = item[selectedKey];
      return sum + (value != null ? value.toDouble() : 0);
    }).toInt();
  }

  String getPercentageChange(String key, List<Map<String, dynamic>> data) {
    if (data.length < 2) return "";

    final int first = data.first[key] ?? 0;
    final int last = data.last[key] ?? 0;

    if (first == 0) return ""; // Avoid division by zero

    final change = ((last - first) / first * 100).toDouble();
    final isPositive = change >= 0;

    final color = isPositive ? '🟢' : '🔴';
    final sign = isPositive ? '+' : '';
    return "$color $sign${change.toStringAsFixed(1)}%";
  }
}
