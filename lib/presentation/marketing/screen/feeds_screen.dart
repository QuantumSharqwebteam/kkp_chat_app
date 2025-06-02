import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/core/network/auth_api.dart';
import 'package:kkpchatapp/core/services/socket_service.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/models/agent.dart';
import 'package:kkpchatapp/main.dart';
import 'package:kkpchatapp/presentation/common_widgets/shimmer_list.dart';
import 'package:kkpchatapp/presentation/marketing/screen/agent_customer_list_screen.dart';
import 'package:kkpchatapp/presentation/marketing/widget/filter_button.dart';
import 'package:kkpchatapp/presentation/marketing/widget/feed_list_card.dart';

class FeedsScreen extends StatefulWidget {
  final String? loggedAgentEmail;
  const FeedsScreen({super.key, this.loggedAgentEmail});

  @override
  State<FeedsScreen> createState() => _FeedsScreenState();
}

class _FeedsScreenState extends State<FeedsScreen> {
  final AuthApi _auth = AuthApi();
  final SocketService _socketService = SocketService(navigatorKey);
  List<Agent> _agentsList = [];
  bool _isLoading = true;
  Set<String> pinnedAgentsSet = {};
  StreamSubscription<List<String>>? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _fetchAgents();
    pinnedAgentsSet = LocalDbHelper.getPinnedAgents();
    _statusSubscription = _socketService.statusStream.listen((_) {
      if (mounted) {
        setState(() {}); // Forces a rebuild to reflect the new online status
      }
    });
    // _socketService.startRoomMembersUpdates();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    //_socketService.stopRoomMembersUpdates();
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

  bool showPinned = false;
  void togglePinnedMessages() {
    setState(() {
      showPinned = !showPinned;
    });
  }

  void togglePinAgent(String agentEmail) {
    setState(() {
      if (pinnedAgentsSet.contains(agentEmail)) {
        pinnedAgentsSet.remove(agentEmail);
      } else {
        pinnedAgentsSet.add(agentEmail);
      }
      LocalDbHelper.savePinnedAgents(pinnedAgentsSet);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildImageSection(),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: const BoxDecoration(color: Colors.white),
              child: Column(
                children: [
                  _buildFilterButtons(),
                  Expanded(
                    child: StreamBuilder<List<String>>(
                      stream: _socketService.statusStream,
                      builder: (context, snapshot) {
                        // Force rebuild when the status updates
                        return _isLoading ? ShimmerList() : _buildAgentList();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.only(top: 50),
          width: double.infinity,
          height: 231,
          color: AppColors.background,
          child: Image.asset(
            "assets/images/feed.png",
            height: 200,
            width: 300,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 40,
          right: 20,
          child: Image.asset(
            "assets/icons/logo.png",
            height: 30,
            width: 30,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          FilterButton(icon: Icons.search_rounded),
          FilterButton(
            onTap: togglePinnedMessages,
            text: "Pinned Messages",
          ),
        ],
      ),
    );
  }

  Widget _buildAgentList() {
    // Create a copy of the list to avoid modifying the original list directly
    List<Agent> displayList = List.from(_agentsList);

    if (showPinned) {
      // Filter to show only pinned agents
      displayList = displayList
          .where((agent) => pinnedAgentsSet.contains(agent.email))
          .toList();
    } else {
      // Exclude the logged-in agent and sort the list to show pinned agents first
      displayList = displayList
          .where((agent) => agent.email != widget.loggedAgentEmail)
          .toList();

      // Sort the list to show pinned agents first
      displayList.sort((a, b) {
        bool aIsPinned = pinnedAgentsSet.contains(a.email);
        bool bIsPinned = pinnedAgentsSet.contains(b.email);

        if (aIsPinned && !bIsPinned) {
          return -1; // a comes before b
        } else if (!aIsPinned && bIsPinned) {
          return 1; // b comes before a
        } else {
          return 0; // maintain the original order
        }
      });
    }

    if (displayList.isEmpty) {
      return const Center(child: Text("No agents found"));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      itemCount: displayList.length,
      physics: const AlwaysScrollableScrollPhysics(),
      separatorBuilder: (context, index) => Divider(
        thickness: 1,
        color: AppColors.dividerColor,
      ),
      itemBuilder: (context, index) {
        final agent = displayList[index];
        final isOnline = _socketService.isUserOnline(agent.email);
        final String lastSeen = _socketService.getLastSeenTime(agent.email);

        return FeedListCard(
          name: agent.name,
          message: "Hi any update....",
          time: isOnline ? "Online" : lastSeen,
          isActive: isOnline,
          isPinned: pinnedAgentsSet.contains(agent.email),
          onPinTap: () => togglePinAgent(agent.email),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AgentCustomersListScreen(
                  agentName: agent.name,
                  agentEmail: agent.email,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
