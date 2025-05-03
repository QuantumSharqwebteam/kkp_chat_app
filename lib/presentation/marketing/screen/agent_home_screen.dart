import 'package:flutter/material.dart';
import 'dart:async';
import 'package:kkpchatapp/config/routes/marketing_routes.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/config/theme/image_constants.dart';
import 'package:kkpchatapp/core/services/socket_service.dart';
import 'package:kkpchatapp/data/repositories/chat_reopsitory.dart';
import 'package:kkpchatapp/main.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_search_field.dart';
import 'package:kkpchatapp/presentation/common_widgets/shimmer_list.dart';
import 'package:kkpchatapp/presentation/marketing/screen/agent_chat_screen.dart';
import 'package:kkpchatapp/presentation/marketing/widget/feed_list_card.dart';
import 'package:kkpchatapp/presentation/marketing/widget/no_customer_assigned_widget.dart';

class AgentHomeScreen extends StatefulWidget {
  final String? agentEmail;
  final String? agentName;
  const AgentHomeScreen({super.key, this.agentEmail, this.agentName});

  @override
  State<AgentHomeScreen> createState() => _AgentHomeScreenState();
}

class _AgentHomeScreenState extends State<AgentHomeScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = true;
  final _chatRepo = ChatRepository();
  List<dynamic> _assignedCustomers = [];
  List<dynamic> _filteredCustomers = [];
  final SocketService _socketService = SocketService(navigatorKey);
  StreamSubscription<List<String>>? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _fetchAssignedCustomers();
    _statusSubscription = _socketService.statusStream.listen((_) {
      if (mounted) {
        setState(() {}); // Forces a rebuild to reflect the new online status
      }
    });
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchAssignedCustomers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final fetchedCustomerList =
          await _chatRepo.fetchAssignedCustomerList(widget.agentEmail!);
      setState(() {
        _assignedCustomers = fetchedCustomerList;
        _filteredCustomers = fetchedCustomerList;
      });
    } catch (e) {
      debugPrint("Error loading customer list: ${e.toString()}");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCustomers = _assignedCustomers.where((customer) {
        final name = customer["name"].toLowerCase();
        return name.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                    ? ShimmerList(itemCount: 8)
                    : NestedScrollView(
                        headerSliverBuilder: (context, innerBoxIsScrolled) {
                          return [
                            SliverToBoxAdapter(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSearchBar(),
                                  // const SizedBox(height: 20),
                                  // _buildDirectMessages(),
                                  const SizedBox(height: 20),
                                  Text("Customer Inquiries",
                                      style: AppTextStyles.black16_500)
                                ],
                              ),
                            ),
                          ];
                        },
                        body: StreamBuilder<List<String>>(
                          stream: _socketService.statusStream,
                          builder: (context, snapshot) {
                            return _filteredCustomers.isEmpty
                                ? Center(child: NoCustomerAssignedWidget())
                                : _buildCustomerInquiriesList();
                          },
                        ),
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
        backgroundImage: AssetImage(ImageConstants.userImage),
      ),
      title: Text(widget.agentName ?? "user", style: AppTextStyles.black16_500),
      subtitle:
          Text("Let's find latest messages", style: AppTextStyles.black12_400),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(
                  context, MarketingRoutes.marketingNotifications);
            },
            icon: const Icon(
              Icons.notifications_active_outlined,
              color: Colors.black,
              size: 28,
            ),
          ),
          IconButton(
              onPressed: () {
                Navigator.pushNamed(context, MarketingRoutes.marketingSettings);
              },
              icon: Icon(
                Icons.settings_outlined,
              ))
        ],
      ),
    );
  }

  // Search Bar
  Widget _buildSearchBar() {
    return CustomSearchBar(
      enable: true,
      controller: _searchController,
      hintText: "search",
      onChanged: _onSearchChanged,
    );
  }

  // // Direct Messages Section
  // Widget _buildDirectMessages() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       const Text(
  //         "Direct Messages",
  //         style: AppTextStyles.black16_500,
  //       ),
  //       const SizedBox(height: 10),
  //       SizedBox(
  //         height: 100,
  //         child: ListView.builder(
  //           scrollDirection: Axis.horizontal,
  //           itemCount: users.length,
  //           itemBuilder: (context, index) {
  //             final user = users[index];
  //             return Padding(
  //               padding: const EdgeInsets.symmetric(horizontal: 10),
  //               child: DirectMessagesListItem(
  //                 name: user['name'],
  //                 image: user['image'],
  //                 status: user['status'],
  //                 unread: user['unread'],
  //                 typing: user['typing'],
  //               ),
  //             );
  //           },
  //         ),
  //       ),
  //     ],
  //   );
  // }

  // Recent Messages List
  Widget _buildCustomerInquiriesList() {
    return RefreshIndicator(
      onRefresh: () {
        return _fetchAssignedCustomers();
      },
      child: ListView.builder(
        itemCount: _filteredCustomers.length,
        physics: AlwaysScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final assignedCustomer = _filteredCustomers[index];
          final isOnline =
              _socketService.isUserOnline(assignedCustomer["email"]);
          final String lastSeen =
              _socketService.getLastSeenTime(assignedCustomer["email"]);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: FeedListCard(
              name: assignedCustomer["name"],
              message: "last message",
              image: "assets/images/user3.png",
              isActive: isOnline,
              time: isOnline ? "Online" : lastSeen,
              enableLongPress: false,
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AgentChatScreen(
                      navigatorKey: navigatorKey,
                      customerName: assignedCustomer["name"],
                      customerEmail: assignedCustomer['email'],
                      agentEmail: widget.agentEmail,
                      agentName: widget.agentName,
                    ),
                  ),
                );
                if (result == true) {
                  await _fetchAssignedCustomers();
                }
              },
            ),
          );
        },
      ),
    );
  }
}
