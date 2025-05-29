import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/routes/marketing_routes.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/network/auth_api.dart';
import 'package:kkpchatapp/core/services/socket_service.dart';
import 'package:kkpchatapp/core/utils/chart_utils.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/models/agent.dart';
import 'package:kkpchatapp/data/repositories/chat_reopsitory.dart';
import 'package:kkpchatapp/main.dart';
import 'package:kkpchatapp/presentation/admin/widgets/agent_management_list_tile.dart';
import 'package:kkpchatapp/presentation/admin/widgets/admin_home_chart.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_button.dart';
import 'package:kkpchatapp/presentation/common_widgets/my_vertical_divider.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  final AuthApi _auth = AuthApi();
  final _chatRepo = ChatRepository();
  final SocketService _socketService = SocketService(navigatorKey);
  List<Agent> _agentsList = [];
  List<Map<String, dynamic>> trafficData = [];
  bool _isLoading = true;
  String selectedChartType = 'messages';

  StreamSubscription<List<String>>? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _fetchAgents();
    _fetchTrafficData();
    _statusSubscription = _socketService.statusStream.listen((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchAgents() async {
    try {
      List<Agent> agents = await _auth.getAgent();
      if (mounted) {
        setState(() {
          _agentsList = agents;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching agents: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchTrafficData() async {
    try {
      List<Map<String, dynamic>> fetchData =
          await _chatRepo.fetchTrafficChartData();
      if (mounted) {
        setState(() {
          trafficData = fetchData;
        });
      }
    } catch (e) {
      debugPrint("Error fetching traffic data: $e");
    }
  }

  Future<void> _launchURL() async {
    final Uri url =
        Uri.parse('https://development.d3uxrpw60z2zmg.amplifyapp.com');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (kDebugMode) {
        print('Could not launch $url');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.background,
        title: const Text(
          "Admin Dashboard",
          style: AppTextStyles.black18_600,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            onPressed: () {
              Navigator.pushNamed(
                  context, MarketingRoutes.marketingNotifications);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.pushNamed(context, MarketingRoutes.marketingSettings);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          spacing: 10,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSeeMoreAdminDataButton(),
            _buildTrafficChart(),
            _buildTrafficStatsCard(),
            _buildCustomerInquriesButton(),
            _buildAgentManagementSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSeeMoreAdminDataButton() {
    return TextButton(
        onPressed: _launchURL, child: Text("See more data in web"));
  }

  Widget _buildTrafficChart() {
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "User Traffic Analytics",
              style: AppTextStyles.black16_600
                  .copyWith(color: Colors.black.withAlpha(150)),
            ),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text:
                        "${selectedChartType == 'messages' ? 'Messages' : 'Active Users'}\n"
                        "${ChartUtils().getDateRange(trafficData)}   ",
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  TextSpan(
                    text:
                        "*${ChartUtils().getTotalCount(selectedChartType == 'messages' ? 'totalMessages' : 'activeUsers', trafficData)} Total   ",
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  TextSpan(
                    text: ChartUtils().getPercentageChange(
                        selectedChartType == 'messages'
                            ? 'totalMessages'
                            : 'activeUsers',
                        trafficData),
                    style: TextStyle(
                      fontSize: 10,
                      color: ChartUtils()
                              .getPercentageChange(
                                  selectedChartType == 'messages'
                                      ? 'totalMessages'
                                      : 'activeUsers',
                                  trafficData)
                              .contains('-')
                          ? Colors.red
                          : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text("View: ", style: AppTextStyles.greyAAAAAA_10_400),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: selectedChartType,
                  items: const [
                    DropdownMenuItem(
                        value: 'messages',
                        child: Text(
                          "Messages",
                          style: AppTextStyles.black10_500,
                        )),
                    DropdownMenuItem(
                        value: 'users',
                        child: Text(
                          "Active Users",
                          style: AppTextStyles.black10_500,
                        )),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedChartType = value;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 210,
              child: AdminHomeChart(
                trafficData: trafficData,
                dataType: selectedChartType,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrafficStatsCard() {
    final utils = ChartUtils();

    final totalVisitors = utils.getTotalCount('activeUsers', trafficData);
    final visitorsChange =
        utils.getPercentageChange('activeUsers', trafficData);

    final totalMessages = utils.getTotalCount('totalMessages', trafficData);
    final messagesChange =
        utils.getPercentageChange('totalMessages', trafficData);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(width: 1, color: AppColors.greyD9D9D9),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              "Visitors",
              totalVisitors.toString(),
              visitorsChange,
            ),
            MyVerticalDivider(height: 80),
            _buildStatItem(
              "Messages",
              totalMessages.toString(),
              messagesChange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String title,
    String value,
    String change,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title, style: AppTextStyles.black60alpha_12_500),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.black16_600),
        const SizedBox(height: 4),
        Text(change,
            style: TextStyle(
              fontSize: 12,
              color: ChartUtils()
                      .getPercentageChange(
                          selectedChartType == 'messages'
                              ? 'totalMessages'
                              : 'activeUsers',
                          trafficData)
                      .contains('-')
                  ? Colors.red
                  : Colors.green,
            )),
      ],
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
    // Calculate online and offline agent counts
    final onlineEmails = _socketService.onlineUsers;
    final activeCount =
        _agentsList.where((agent) => onlineEmails.contains(agent.email)).length;
    final offlineCount = _agentsList.length - activeCount;

    return StreamBuilder<List<String>>(
      stream: _socketService.statusStream,
      builder: (context, snapshot) {
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
                    child: Text(
                      "See All",
                      style: AppTextStyles.black12_400.copyWith(
                        color: AppColors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
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
                    _buildStatusItem(
                        "Active", activeCount, AppColors.activeGreen),
                    _buildStatusItem("Offline", offlineCount, AppColors.blue),
                  ],
                ),
              ),

              SizedBox(height: 10),

              // Agent List
              _isLoading
                  ? Center(child: const CircularProgressIndicator())
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount:
                          _agentsList.length > 5 ? 5 : _agentsList.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 2,
                        color: AppColors.dividerD9D9D9,
                      ),
                      itemBuilder: (context, index) {
                        final agent = _agentsList[index];
                        final isOnline =
                            _socketService.isUserOnline(agent.email);
                        return AgentManagementListTile(
                          title: agent.name,
                          subtitle: agent.role,
                          name: agent.name,
                          isOnline: isOnline,
                        );
                      },
                    ),
            ],
          ),
        );
      },
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
