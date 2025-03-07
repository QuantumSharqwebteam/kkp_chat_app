import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';
import 'package:kkp_chat_app/presentation/admin/widgets/agent_management_list_tile.dart';
import 'package:kkp_chat_app/presentation/common_widgets/my_vertical_divider.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  List<Map<String, dynamic>> agents = [
    {
      "title": "Marketing Agent 1",
      "subtitle": "Rumi",
      "image": "assets/images/user1.png",
      "status": "active",
    },
    {
      "title": "Marketing Agent 2",
      "subtitle": "Riya",
      "image": "assets/images/user2.png",
      "status": "active",
    },
    {
      "title": "Marketing Agent 3",
      "subtitle": "Mariya",
      "image": "assets/images/user4.png",
      "status": "inactive",
    },
    {
      "title": "Marketing Agent 4",
      "subtitle": "Kesi",
      "image": "assets/images/user5.png",
      "status": "inactive",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          spacing: 10,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTrafficChart(),
            _buildTrafficStatsCard(),
            _buildCategorySection(),
            _buildAgentManagementSection()
          ],
        ),
      ),
    );
  }

  Widget _buildTrafficChart() {
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Traffic on site",
              style: AppTextStyles.black16_600
                  .copyWith(color: Colors.black.withValues(alpha: 0.60)),
            ),
            const Text(
              "Visits\nJan - Mar 10,2025   *5,705 Total   +52%",
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 210,
              child: LineChart(
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
                              return const Text("0K",
                                  style: TextStyle(fontSize: 10));
                            case 5000:
                              return const Text("5K",
                                  style: TextStyle(fontSize: 10));
                            case 10000:
                              return const Text("10K",
                                  style: TextStyle(fontSize: 10));
                            case 15000:
                              return const Text("15K",
                                  style: TextStyle(fontSize: 10));
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
                              return const Text("JAN",
                                  style: TextStyle(fontSize: 10));
                            case 1:
                              return const Text("Feb",
                                  style: TextStyle(fontSize: 10));
                            case 2:
                              return const Text("MAR 1",
                                  style: TextStyle(fontSize: 10));
                            case 3:
                              return const Text("2",
                                  style: TextStyle(fontSize: 10));
                            case 4:
                              return const Text("3",
                                  style: TextStyle(fontSize: 10));
                            case 5:
                              return const Text("4",
                                  style: TextStyle(fontSize: 10));
                            case 6:
                              return const Text("5",
                                  style: TextStyle(fontSize: 10));
                            case 7:
                              return const Text("6",
                                  style: TextStyle(fontSize: 10));
                            case 8:
                              return const Text("7",
                                  style: TextStyle(fontSize: 10));
                            case 9:
                              return const Text("8",
                                  style: TextStyle(fontSize: 10));
                            case 10:
                              return const Text("9",
                                  style: TextStyle(fontSize: 10));
                            default:
                              return Container();
                          }
                        },
                      ),
                    ),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrafficStatsCard() {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(width: 1, color: AppColors.greyD9D9D9)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          spacing: 10,
          children: [
            _buildStatItem("Visitors", "86K", "+52% mo/mo", Colors.green),
            MyVerticalDivider(height: 80),
            _buildStatItem(
                "Unique Visitors", "80K", "+58% mo/mo", Colors.green),
            MyVerticalDivider(height: 80),
            _buildStatItem("Page View", "224K", "+14% mo/mo", Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String title, String value, String change, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 14, color: Colors.black54)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(change, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        // Blue border
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: "Category ",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                TextSpan(
                  text: "Search wise",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 3.5,
            children: [
              _categoryItem("Shirt", "12K"),
              _categoryItem("Pant", "8K"),
              _categoryItem("T-Shirt", "10K"),
              _categoryItem("Jeans", "16K"),
              _categoryItem("Hoodies", "22K", highlight: true),
              _categoryItem("Jacket", "18K"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _categoryItem(String title, String count, {bool highlight = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 14)),
          Text(
            count,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: highlight ? Colors.green : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentManagementSection() {
    // Counting Active & Offline Agents
    int activeCount =
        agents.where((agent) => agent["status"] == "active").length;
    int offlineCount =
        agents.where((agent) => agent["status"] == "inactive").length;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Agent Management",
            style: AppTextStyles.black16_500,
          ),
          // Agent Status Bar
          Container(
            margin: EdgeInsets.symmetric(horizontal: 10),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusItem("Active", activeCount, Colors.green),
                _buildStatusItem("Offline", offlineCount, Colors.blue),
              ],
            ),
          ),

          SizedBox(height: 10),

          // Agent List
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: agents.length,
            separatorBuilder: (context, index) => Divider(
              height: 2,
              color: AppColors.dividerD9D9D9,
            ),
            itemBuilder: (context, index) {
              final agent = agents[index];
              return AgentManagementListTile(
                title: agent["title"]!,
                subtitle: agent["subtitle"]!,
                image: agent["image"]!,
                status: agent["status"]!,
              );
            },
          ),
        ],
      ),
    );
  }

  // Helper widget for Active/Offline status
  Widget _buildStatusItem(String label, int count, Color color) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          "Agent",
          style: TextStyle(fontSize: 16, color: Colors.black),
        ),
        const SizedBox(width: 5),
        CircleAvatar(
          radius: 14,
          backgroundColor: color,
          child: Text(
            count.toString(),
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
