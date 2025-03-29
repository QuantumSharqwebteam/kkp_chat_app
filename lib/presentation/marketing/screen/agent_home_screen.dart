import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/routes/marketing_routes.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';
import 'package:kkp_chat_app/core/network/auth_api.dart';
import 'package:kkp_chat_app/core/services/socket_service.dart';
import 'package:kkp_chat_app/data/models/agent.dart';
import 'package:kkp_chat_app/data/models/profile_model.dart';
import 'package:kkp_chat_app/data/repositories/auth_repository.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_search_field.dart';
import 'package:kkp_chat_app/presentation/marketing/widget/direct_messages_list_item.dart';
import 'package:kkp_chat_app/presentation/marketing/widget/recent_messages_list_card.dart';

class AgentHomeScreen extends StatefulWidget {
  const AgentHomeScreen({super.key});

  @override
  State<AgentHomeScreen> createState() => _AgentHomeScreenState();
}

class _AgentHomeScreenState extends State<AgentHomeScreen> {
  final _searchController = TextEditingController();
  Profile? profileData;
  String? name;
  List<Agent> _agentsList = [];
  bool _isLoading = true;
  AuthRepository authRepo = AuthRepository();
  final AuthApi _auth = AuthApi();
  final SocketService _socketService = SocketService();

  List<Map<String, dynamic>> users = [
    {
      "name": "Rumi",
      "image": "assets/images/user1.png",
      "status": "active",
      "unread": 0,
      "typing": false
    },
    {
      "name": "Riya",
      "image": "assets/images/user2.png",
      "status": "active",
      "unread": 2,
      "typing": false
    },
    {
      "name": "Radhika",
      "image": "assets/images/user3.png",
      "status": "active",
      "unread": 0,
      "typing": true
    },
    {
      "name": "Mariya",
      "image": "assets/images/user4.png",
      "status": "inactive",
      "unread": 0,
      "typing": false
    },
    {
      "name": "Kesi",
      "image": "assets/images/user5.png",
      "status": "inactive",
      "unread": 0,
      "typing": false
    },
  ];

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

  // List<Map<String, dynamic>> recentChats = [
  //   {
  //     "name": "Ramesh Jain",
  //     "message": "Can you describe....",
  //     "time": "2m",
  //     "image": "assets/images/user1.png",
  //     "isActive": false // Inactive user
  //   },
  //   {
  //     "name": "Rumika Mehra",
  //     "message": "How much does.......",
  //     "time": "3m",
  //     "image": "assets/images/user4.png",
  //     "isActive": true // Active user
  //   },
  //   {
  //     "name": "Rumi",
  //     "message": "I'm interested in.......",
  //     "time": "3m",
  //     "image": "assets/images/user1.png",
  //     "isActive": false
  //   },
  //   {
  //     "name": "Riya",
  //     "message": "I'm interested in.......",
  //     "time": "3m",
  //     "image": "assets/images/user2.png",
  //     "isActive": true // Active user
  //   },
  //   {
  //     "name": "Radhika",
  //     "message": "Typing...",
  //     "time": "3m",
  //     "image": "assets/images/user3.png",
  //     "isActive": false
  //   },
  //   {
  //     "name": "Amit Kumar",
  //     "message": "Let's connect soon!",
  //     "time": "4m",
  //     "image": "assets/images/user4.png",
  //     "isActive": true // Active user
  //   },
  // ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _fetchAgents();
  }

  Future<void> _loadUserInfo() async {
    try {
      profileData = await authRepo.getUserInfo();
      if (mounted) {
        setState(() {
          name = profileData?.name;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        if (mounted) {
          print(e.toString());
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildProfileSection(),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : NestedScrollView(
                        headerSliverBuilder: (context, innerBoxIsScrolled) {
                          return [
                            SliverToBoxAdapter(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSearchBar(),
                                  const SizedBox(height: 20),
                                  _buildDirectMessages(),
                                  const SizedBox(height: 20),
                                  Text("Recent Messages",
                                      style: AppTextStyles.black16_500)
                                ],
                              ),
                            ),
                          ];
                        },
                        body: _buildRecentMessages(),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Profile Section
  Widget _buildProfileSection() {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
      leading: CircleAvatar(
        radius: 26,
        backgroundImage: AssetImage("assets/images/profile.png"),
      ),
      title: Text(name ?? "User", style: AppTextStyles.black16_500),
      subtitle:
          Text("Let's find latest messages", style: AppTextStyles.black12_400),
      trailing: IconButton(
        onPressed: () {
          Navigator.pushNamed(context, MarketingRoutes.marketingNotifications);
        },
        icon: const Icon(
          Icons.notifications_active_outlined,
          color: Colors.black,
          size: 28,
        ),
      ),
    );
  }

  // Search Bar
  Widget _buildSearchBar() {
    return CustomSearchBar(
      enable: true,
      controller: _searchController,
      hintText: "search",
    );
  }

  // Direct Messages Section
  Widget _buildDirectMessages() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Direct Messages",
          style: AppTextStyles.black16_500,
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: DirectMessagesListItem(
                  name: user['name'],
                  image: user['image'],
                  status: user['status'],
                  unread: user['unread'],
                  typing: user['typing'],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Recent Messages List
  Widget _buildRecentMessages() {
    return ListView.builder(
      itemCount: _agentsList.length,
      physics: AlwaysScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final message = _agentsList[index];
        final isOnline = _socketService.isUserOnline(message.email);
        final String lastSeen = _socketService.getLastSeenTime(message.email);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: RecentMessagesListCard(
            name: message.name,
            image: "assets/images/user5.png",
            isActive: isOnline,
            time: isOnline ? "Online" : lastSeen,
            onTap: () {},
          ),
        );
      },
    );
  }
}
