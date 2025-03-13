import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/routes/marketing_routes.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';
import 'package:kkp_chat_app/config/theme/image_constants.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';
import 'package:kkp_chat_app/presentation/admin/widgets/agent_management_list_tile.dart';
import 'package:kkp_chat_app/presentation/admin/widgets/home_chart.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_button.dart';
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
            _buildCustomerInquriesButton(),
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
              child: HomeChart(),
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
            _buildStatItem(
                "Visitors", "86K", "+52% mo/mo", AppColors.green22C55E),
            MyVerticalDivider(height: 80),
            _buildStatItem(
                "Unique Visitors", "80K", "+58% mo/mo", AppColors.greyAAAAAA),
            MyVerticalDivider(height: 80),
            _buildStatItem(
                "Page View", "224K", "+14% mo/mo", AppColors.greyAAAAAA),
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
        Text(title, style: AppTextStyles.black60alpha_12_500),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.black16_600),
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
            text: TextSpan(
              children: [
                TextSpan(
                  text: "Category ",
                  style: AppTextStyles.black16_600.copyWith(
                    color: AppColors.black60opac,
                  ),
                ),
                TextSpan(
                  text: "Search wise",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    color: AppColors.black60opac,
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
              _categoryItem("Shirt", "12K", ImageConstants.shirt),
              _categoryItem("Pant", "8K", ImageConstants.pant),
              _categoryItem("T-Shirt", "10K", ImageConstants.tshirt),
              _categoryItem("Jeans", "16K", ImageConstants.jeans),
              _categoryItem("Hoodies", "22K", ImageConstants.hoodiies,
                  highlight: true),
              _categoryItem("Jacket", "18K", ImageConstants.jacket),
            ],
          ),
        ],
      ),
    );
  }

  Widget _categoryItem(String title, String count, String icon,
      {bool highlight = false}) {
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
          Image.asset(
            icon,
            height: 21,
            width: 21,
          ),
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

  Widget _buildCustomerInquriesButton() {
    return CustomButton(
        onPressed: () {
          Navigator.pushNamed(context, MarketingRoutes.customerInquriesPage);
        },
        height: Utils().height(context) * 0.06,
        fontSize: 18,
        borderRadius: 10,
        text: "Customer Inquries");
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Agent Management",
                style: AppTextStyles.black16_700
                    .copyWith(color: AppColors.black60opac),
              ),
              GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                        context, MarketingRoutes.agentProfileList);
                  },
                  child: Text("See All")),
            ],
          ),
          // Agent Status Bar
          Container(
            margin: EdgeInsets.symmetric(horizontal: 2, vertical: 10),
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.backgroundEEEDED,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusItem("Active", activeCount, AppColors.activeGreen),
                _buildStatusItem("Offline", offlineCount, AppColors.blue),
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
          radius: 17,
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
