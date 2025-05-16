import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';

class AdminHomeChart extends StatelessWidget {
  final List<Map<String, dynamic>> trafficData;
  final bool enableAnimation;
  final String dataType; // 'messages' or ' active users'

  const AdminHomeChart({
    super.key,
    required this.trafficData,
    this.enableAnimation = true,
    required this.dataType,
  });

  @override
  Widget build(BuildContext context) {
    if (trafficData.isEmpty) {
      return Center(
          child: Container(
        color: AppColors.greyE5E7EB,
      ));
    }

    final sortedData = [...trafficData]
      ..sort((a, b) => a['monthNumber'].compareTo(b['monthNumber']));

    List<FlSpot> spots = sortedData.asMap().entries.map((entry) {
      int index = entry.key;
      final data = entry.value;
      double value = dataType == 'messages'
          ? data['totalMessages'].toDouble()
          : data['activeUsers'].toDouble();
      return FlSpot(index.toDouble(), value);
    }).toList();

    final maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    final interval = (maxY / 4).ceilToDouble();

    final yAxisLabel = dataType == 'messages' ? 'Messages' : 'Active Users';

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY + interval,
        gridData: FlGridData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Colors.black87,
            tooltipRoundedRadius: 6,
            tooltipPadding: const EdgeInsets.all(8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                final data = sortedData[index];
                return LineTooltipItem(
                  '${data['month']}\nMessages: ${data['totalMessages']}\nActive Users: ${data['activeUsers']}',
                  const TextStyle(color: Colors.white),
                );
              }).toList();
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            axisNameWidget: Text(
              "---------$yAxisLabel ----------->",
              style: AppTextStyles.greyAAAAAA_10_400,
            ),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: interval,
              getTitlesWidget: (value, _) =>
                  Text('${value.toInt()}', style: const TextStyle(fontSize: 8)),
            ),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: const Text(
              '------------------ Month --------------------->',
              style: AppTextStyles.greyAAAAAA_10_400,
            ),
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, _) {
                int index = value.toInt();
                if (index >= 0 && index < sortedData.length) {
                  return Text(sortedData[index]['month'],
                      style: TextStyle(fontSize: 8));
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.6,
            color: Colors.grey,
            barWidth: 0.5,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(show: false),
            dashArray: [4, 4],
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                radius: 3,
                color: Colors.white,
                strokeColor: AppColors.blue00ABE9,
                strokeWidth: 4,
              ),
            ),
          ),
        ],
      ),
      duration:
          enableAnimation ? const Duration(milliseconds: 500) : Duration.zero,
      curve: Curves.easeInOut,
    );
  }
}
