import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_initicon/flutter_initicon.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/network/auth_api.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/models/agent.dart';
import 'package:kkpchatapp/data/repositories/auth_repository.dart';
import 'package:kkpchatapp/presentation/common_widgets/shimmer_list.dart';
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
  List<String> _assignedAgentEmails = [];

  @override
  void initState() {
    super.initState();
    _fetchAgents();
    _fetchAssignedAgentList();
  }

  Future<void> _fetchAssignedAgentList() async {
    try {
      List<String> assignedAgents =
          await authRepository.fetchAssignedAgentList();
      setState(() {
        _assignedAgentEmails = assignedAgents;
      });
    } catch (e) {
      debugPrint("Error fetching assigned agent list: $e");
    }
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

        _fetchAssignedAgentList();
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

        _fetchAssignedAgentList();
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
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context);
      });
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

  Widget _buildStatsSection() {
    int totalAgents = _agentsList.length;
    int assignedAgents = _agentsList
        .where((agent) => _assignedAgentEmails.contains(agent.email))
        .length;

    return Row(
      children: [
        Expanded(child: _buildStatCard("Total Agents", totalAgents.toString())),
        const SizedBox(width: 10),
        Expanded(
            child:
                _buildStatCard("Assigned Agents", assignedAgents.toString())),
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

  void _showAgentDetailDialog(BuildContext context, Agent agent) {
    bool isAssigned = _assignedAgentEmails.contains(agent.email);
    DateTime createdAtDate = DateTime.parse(agent.createdAt);
    String formattedDate =
        "${createdAtDate.day}/${createdAtDate.month}/${createdAtDate.year}";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          surfaceTintColor: Colors.white,
          backgroundColor: Colors.white,
          title: Text(
            agent.name,
            style: AppTextStyles.black14_600,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Email: ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    TextSpan(
                      text: agent.email,
                      style: AppTextStyles.black12_400,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Role: ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    TextSpan(
                      text: agent.role,
                      style: AppTextStyles.black12_400,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'mobile: ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    TextSpan(
                      text: agent.mobile.toString(),
                      style: AppTextStyles.black12_400,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Created At: ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    TextSpan(
                      text: formattedDate,
                      style: AppTextStyles.black12_400,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Status: ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    TextSpan(
                      text: isAssigned ? "Assigned" : "Not Assigned",
                      style: TextStyle(
                        color: isAssigned ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              Text(
                isAssigned
                    ? "**This agent is eligible to chat with customers."
                    : "**This agent is not eligible to chat with customers.",
                style: AppTextStyles.black14_400,
              ),
              // Add more details as needed
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAgentList() {
    if (_agentsList.isEmpty) {
      return const Center(child: Text("No agents found"));
    }

    // Fetch the current user's role
    String currentUserRole =
        LocalDbHelper.getProfile()?.role ?? ""; // Fetch the current user's role
    debugPrint("fetched role from db in agent profile list :$currentUserRole");
    String currentUserEmail = LocalDbHelper.getProfile()?.email ??
        ''; // Fetch the current user's email

    return ListView.builder(
      itemCount: _agentsList.length,
      itemBuilder: (context, index) {
        final agent = _agentsList[index];
        bool isAssigned = _assignedAgentEmails.contains(agent.email);

        return GestureDetector(
          onTap: () {
            _showAgentDetailDialog(context, agent);
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
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  agent.role == 'AgentHead'
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
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      isAssigned ? "Assigned" : "Not Assigned",
                      style: TextStyle(
                        color: isAssigned
                            ? AppColors.activeGreen
                            : AppColors.inActiveRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                splashRadius: 20,
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
                surfaceTintColor: Colors.white,
                elevation: 10,
                onSelected: (value) {
                  if (value == 'Add agent to assign list') {
                    assignAgentToList(agent.email);
                  } else if (value == 'Delete Agent Profile') {
                    _deleteAgent(agent.email);
                  } else if (value == "Remove agent from assign list") {
                    removeAgentFromList(agent.email);
                  }
                },
                itemBuilder: (BuildContext context) {
                  List<String> menuItems = [];

                  // Add 'Add agent to assign list' only if the agent is not assigned
                  if (!isAssigned) {
                    menuItems.add('Add agent to assign list');
                  }

                  // Add 'Remove agent from assign list' only if the agent is assigned and not an AgentHead
                  if (isAssigned && agent.role != "AgentHead") {
                    menuItems.add("Remove agent from assign list");
                  }

                  // Logic to determine if 'Delete Agent Profile' should be shown
                  if (currentUserRole == 'Admin') {
                    // Admin can delete any agent profile
                    menuItems.add('Delete Agent Profile');
                  } else if (currentUserRole == 'AgentHead' &&
                      agent.email != currentUserEmail) {
                    // AgentHead can delete other agents but not themselves
                    menuItems.add('Delete Agent Profile');
                  }

                  return menuItems.map((String choice) {
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
