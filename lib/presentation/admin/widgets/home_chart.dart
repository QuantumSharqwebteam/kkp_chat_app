import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class HomeChart extends StatelessWidget {
  const HomeChart({super.key});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              interval: 5000,
              getTitlesWidget: (value, meta) {
                switch (value.toInt()) {
                  case 0:
                    return const Text("0K", style: TextStyle(fontSize: 10));
                  case 5000:
                    return const Text("5K", style: TextStyle(fontSize: 10));
                  case 10000:
                    return const Text("10K", style: TextStyle(fontSize: 10));
                  case 15000:
                    return const Text("15K", style: TextStyle(fontSize: 10));
                  default:
                    return Container();
                }
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                switch (value.toInt()) {
                  case 0:
                    return const Text("JAN", style: TextStyle(fontSize: 10));
                  case 1:
                    return const Text("Feb", style: TextStyle(fontSize: 10));
                  case 2:
                    return const Text("MAR 1", style: TextStyle(fontSize: 10));
                  case 3:
                    return const Text("2", style: TextStyle(fontSize: 10));
                  case 4:
                    return const Text("3", style: TextStyle(fontSize: 10));
                  case 5:
                    return const Text("4", style: TextStyle(fontSize: 10));
                  case 6:
                    return const Text("5", style: TextStyle(fontSize: 10));
                  case 7:
                    return const Text("6", style: TextStyle(fontSize: 10));
                  case 8:
                    return const Text("7", style: TextStyle(fontSize: 10));
                  case 9:
                    return const Text("8", style: TextStyle(fontSize: 10));
                  case 10:
                    return const Text("9", style: TextStyle(fontSize: 10));
                  default:
                    return Container();
                }
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              const FlSpot(0, 1000),
              const FlSpot(1, 4000),
              const FlSpot(2, 3000),
              const FlSpot(3, 7000),
              const FlSpot(4, 6000),
              const FlSpot(5, 11000),
              const FlSpot(6, 9000),
              const FlSpot(7, 12000),
              const FlSpot(8, 14000),
              const FlSpot(9, 15000),
            ],
            isCurved: false,
            color: Colors.grey, // Dashed line color
            barWidth: 1,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(show: false),
            dashArray: [4, 4], // Dotted Line
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: Colors.white, // Outer dot color
                  strokeColor: Colors.blue,
                  strokeWidth: 4,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
