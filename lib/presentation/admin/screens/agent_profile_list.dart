import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_initicon/flutter_initicon.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/network/auth_api.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/models/agent.dart';
import 'package:kkpchatapp/data/repositories/auth_repository.dart';
import 'package:kkpchatapp/presentation/common_widgets/shimmer_list.dart';
import 'package:kkpchatapp/presentation/marketing/screen/agent_customer_list_screen.dart';
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
  final authRepository = AuthRepository();

  @override
  void initState() {
    super.initState();
    _fetchAgents();
  }

  Future<void> _fetchAgents() async {
    try {
      List<Agent> agents = await _auth.getAgent();
      // Sort so that 'AgentHead' comes first
      agents.sort((a, b) {
        if (a.role == 'AgentHead' && b.role != 'AgentHead') return -1;
        if (a.role != 'AgentHead' && b.role == 'AgentHead') return 1;
        return 0; // maintain original order if roles are the same or neither is AgentHead
      });

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

  void assignAgentToList(String email) async {
    try {
      final result = await AuthApi().assignAgent(email: email);
      if (result['status'] == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    "✅ ${result['message']} for getting transfered customers")),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    "⚠️ ${result['message']}! now not eligible for getting transfered customers")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Failed to assign agent: $e")),
        );
      }
    }
  }

  void removeAgentFromList(String email) async {
    try {
      final success = await AuthApi().removeAssignedAgent(email: email);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("✅ Agent removed from list")),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("⚠️ Failed to remove agent")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error: $e")),
        );
      }
    }
  }

  void _deleteAgent(String email) async {
    try {
      final result = await authRepository.deleteAgentAccount(agentEmail: email);

      if (mounted) {
        Utils().showSuccessDialog(context, "${result['message']}", true);
        _fetchAgents(); // Refresh agent list after deletion
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error deleting agent: ${e.toString()}");
      }
      if (mounted) {
        Utils().showSuccessDialog(context, "Try again later!", false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Agent Profiles List"),
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back),
        //   onPressed: () => Navigator.pop(context),
        // ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //  _buildHighlightedAgent(),
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

  // Widget _buildHighlightedAgent() {
  //   return Card(
  //     surfaceTintColor: Colors.white,
  //     color: Colors.white,
  //     child: Padding(
  //       padding: const EdgeInsets.all(18.0),
  //       child: Row(
  //         children: [
  //           const CircleAvatar(
  //             radius: 30,
  //             backgroundImage: AssetImage("assets/images/user1.png"),
  //           ),
  //           const SizedBox(width: 10),
  //           Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: const [
  //               Text("Arun",
  //                   style:
  //                       TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
  //               Text("Senior Admin",
  //                   style: TextStyle(fontSize: 14, color: Colors.grey)),
  //             ],
  //           )
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildStatsSection() {
    int totalAgents = _agentsList.length;
    DateTime now = DateTime.now();
    DateTime last7Days = now.subtract(const Duration(days: 7));

    int newAgents = _agentsList
        .where((agent) => DateTime.parse(agent.createdAt).isAfter(last7Days))
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
                builder: (context) => AgentCustomersListScreen(
                  agentName: agent.name,
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
              leading: Initicon(
                text: agent.name,
                size: 35,
              ),
              title: Text(agent.name, style: AppTextStyles.black16_600),
              subtitle: agent.role == 'AgentHead'
                  ? Row(
                      children: [
                        Text(
                          "🔰${agent.role}",
                          style: AppTextStyles.black14_400.copyWith(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Head',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Text(
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
                  if (value == 'Add agent to assign list') {
                    assignAgentToList(agent.email); // Replace with actual email
                  } else if (value == 'Remove from Assigned list') {
                    removeAgentFromList(
                        agent.email); // Replace with actual email
                  } else if (value == 'Delete') {
                    // Add delete logic here
                    _deleteAgent(agent.email);
                  }
                },
                itemBuilder: (BuildContext context) {
                  return [
                    'Add agent to assign list',
                    'Remove from Assigned list',
                    'Delete'
                  ].map((String choice) {
                    return PopupMenuItem<String>(
                      value: choice,
                      child: Text(choice),
                    );
                  }).toList();
                },
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
