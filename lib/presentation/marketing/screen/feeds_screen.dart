import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/image_constants.dart';
import 'package:kkp_chat_app/core/network/auth_api.dart';
import 'package:kkp_chat_app/data/models/agent.dart';
import 'package:kkp_chat_app/presentation/common_widgets/shimmer_list.dart';
import 'package:kkp_chat_app/presentation/marketing/screen/customer_list_screen.dart';
import 'package:kkp_chat_app/presentation/marketing/widget/filter_button.dart';
import 'package:kkp_chat_app/presentation/marketing/widget/recent_messages_list_card.dart';

class FeedsScreen extends StatefulWidget {
  const FeedsScreen({super.key});

  @override
  State<FeedsScreen> createState() => _FeedsScreenState();
}

class _FeedsScreenState extends State<FeedsScreen> {
  final AuthApi _auth = AuthApi();
  List<Agent> _agentsList = [];
  Set<String> pinnedAgentsSet = {}; // Set to store pinned agent emails
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
                    child: _isLoading ? ShimmerList() : _buildAgentList(),
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

  // Filter buttons section
  Widget _buildFilterButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          FilterButton(icon: Icons.search_rounded),
          // FilterButton(
          //   onTap: () {
          //     setState(() {
          //       showPinned = false; // Show all messages
          //     });
          //   },
          //   text: "All Chats",
          // ),
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
        : _agentsList;

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
        return RecentMessagesListCard(
          name: agent.name,
          message: "Hi any update....",
          time: "Just now",
          image: "assets/images/user1.png",
          isActive: true,
          isPinned: pinnedAgentsSet.contains(agent.email), // Check if pinned
          onPinTap: () => togglePinAgent(agent.email), // Toggle pin
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CustomersListScreen(
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
