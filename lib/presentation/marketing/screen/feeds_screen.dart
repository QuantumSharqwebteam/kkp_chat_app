import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/image_constants.dart';
import 'package:kkp_chat_app/core/network/auth_api.dart';
import 'package:kkp_chat_app/core/services/socket_service.dart';
import 'package:kkp_chat_app/data/models/agent.dart';
import 'package:kkp_chat_app/presentation/common_widgets/shimmer_list.dart';
import 'package:kkp_chat_app/presentation/marketing/screen/agent_customer_list_screen.dart';
import 'package:kkp_chat_app/presentation/marketing/widget/filter_button.dart';
import 'package:kkp_chat_app/presentation/marketing/widget/recent_messages_list_card.dart';

class FeedsScreen extends StatefulWidget {
  final String? loggedAgentEmail;
  const FeedsScreen({super.key, this.loggedAgentEmail});

  @override
  State<FeedsScreen> createState() => _FeedsScreenState();
}

class _FeedsScreenState extends State<FeedsScreen> {
  final AuthApi _auth = AuthApi();
  final SocketService _socketService = SocketService();
  List<Agent> _agentsList = [];
  bool _isLoading = true;
  Set<String> pinnedAgentsSet = {};
  StreamSubscription<List<String>>? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _fetchAgents();
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
    List<Agent> displayList = showPinned
        ? _agentsList
            .where((agent) => pinnedAgentsSet.contains(agent.email))
            .toList()
        : _agentsList
            .where((agent) =>
                agent.email !=
                widget.loggedAgentEmail) // Exclude logged-in agent
            .toList();

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

        return RecentMessagesListCard(
          name: agent.name,
          message: "Hi any update....",
          time: isOnline ? "Online" : lastSeen,
          image: "assets/images/user1.png",
          isActive: isOnline,
          isPinned: pinnedAgentsSet.contains(agent.email),
          onPinTap: () => togglePinAgent(agent.email),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AgentCustomersListScreen(
                  agentName: agent.name,
                  agentImage: ImageConstants.userImage,
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
