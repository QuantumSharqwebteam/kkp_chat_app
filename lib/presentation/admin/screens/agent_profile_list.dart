import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/routes/marketing_routes.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';
import 'package:kkp_chat_app/config/theme/image_constants.dart';
import 'package:kkp_chat_app/core/network/auth_api.dart';
import 'package:kkp_chat_app/data/models/agent.dart';
import 'package:kkp_chat_app/presentation/common_widgets/shimmer_list.dart';
import 'package:kkp_chat_app/presentation/marketing/screen/customer_list_screen.dart';
import 'package:shimmer/shimmer.dart';
// Import reusable shimmer list

class AgentProfilesPage extends StatefulWidget {
  const AgentProfilesPage({super.key});

  @override
  State<AgentProfilesPage> createState() => _AgentProfilesPageState();
}

class _AgentProfilesPageState extends State<AgentProfilesPage> {
  final AuthApi _auth = AuthApi();
  List<Agent> _agentsList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAgents();
  }

  Future<void> _fetchAgents() async {
    try {
      List<Agent> agents = await _auth.getAgent();
      setState(() {
        _agentsList = agents;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching agents: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Agent Profiles List"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHighlightedAgent(),
            const SizedBox(height: 20),
            _isLoading ? _buildShimmerStatsSection() : _buildStatsSection(),
            const SizedBox(height: 20),
            const Text("Agent Profiles",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: _isLoading
                  ? const ShimmerList(
                      itemCount: 4) // 🔥 Using reusable shimmer list
                  : _buildAgentList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightedAgent() {
    return Card(
      surfaceTintColor: Colors.white,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundImage: AssetImage("assets/images/user1.png"),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("Arun",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("Senior Admin",
                    style: TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    int totalAgents = _agentsList.length;
    int newAgents = _agentsList
        .where((agent) => DateTime.parse(agent.createdOn)
            .isAfter(DateTime.now().subtract(const Duration(days: 30))))
        .length;

    return Row(
      children: [
        Expanded(child: _buildStatCard("Total Agents", totalAgents.toString())),
        const SizedBox(width: 10),
        Expanded(child: _buildStatCard("New Agents", newAgents.toString())),
      ],
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withValues(alpha: .2),
              spreadRadius: 2,
              blurRadius: 4),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.black14_400),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(value, style: AppTextStyles.black22_600),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentList() {
    if (_agentsList.isEmpty) {
      return const Center(child: Text("No agents found"));
    }

    return ListView.builder(
      itemCount: _agentsList.length,
      itemBuilder: (context, index) {
        final agent = _agentsList[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CustomersListScreen(
                  agentName: agent.name,
                  agentImage: ImageConstants.userImage,
                  agentEmail: agent.email, // Pass the agent's email
                ),
              ),
            );
          },
          child: Card(
            surfaceTintColor: Colors.white,
            color: Colors.white,
            elevation: 5,
            child: ListTile(
              leading: const CircleAvatar(
                backgroundImage: AssetImage("assets/images/user3.png"),
              ),
              title: Text(agent.name, style: AppTextStyles.black16_600),
              subtitle: Text(
                agent.role,
                style: AppTextStyles.black14_400.copyWith(
                  color: AppColors.black60opac,
                ),
              ),
              trailing: PopupMenuButton<String>(
                splashRadius: 20,
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
                surfaceTintColor: Colors.white,
                elevation: 10,
                onSelected: (value) {
                  // Handle actions here
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                      value: "restrict", child: Text("Restrict Access")),
                  const PopupMenuItem(
                      value: "delete", child: Text("Delete Profile")),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// **Shimmer Loading for Stats Section**
  Widget _buildShimmerStatsSection() {
    return Row(
      children: [
        Expanded(child: _buildShimmerStatCard()),
        const SizedBox(width: 10),
        Expanded(child: _buildShimmerStatCard()),
      ],
    );
  }

  Widget _buildShimmerStatCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 140,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
