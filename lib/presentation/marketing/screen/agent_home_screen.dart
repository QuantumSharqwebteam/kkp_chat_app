import 'package:flutter/material.dart';
import 'package:flutter_initicon/flutter_initicon.dart';
import 'dart:async';
import 'package:kkpchatapp/config/routes/marketing_routes.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/services/socket_service.dart';
import 'package:kkpchatapp/data/repositories/chat_reopsitory.dart';
import 'package:kkpchatapp/logic/agent/chat_refresh_provider.dart';
import 'package:kkpchatapp/main.dart';
import 'package:kkpchatapp/presentation/common/chat/call_history_screen.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_search_field.dart';
import 'package:kkpchatapp/presentation/common_widgets/shimmer_list.dart';
import 'package:kkpchatapp/presentation/marketing/screen/agent_chat_screen.dart';
import 'package:kkpchatapp/presentation/marketing/widget/feed_list_card.dart';
import 'package:kkpchatapp/presentation/marketing/widget/no_customer_assigned_widget.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

// Make sure this path is correct

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

    final chatRefreshProvider =
        Provider.of<ChatRefreshProvider>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      chatRefreshProvider.addListener(() {
        if (chatRefreshProvider.shouldRefresh) {
          _fetchAssignedCustomers();
          chatRefreshProvider.reset();
        }
      });
    });
    _fetchAssignedCustomers();
    _statusSubscription = _socketService.statusStream.listen((_) {
      if (mounted) {
        setState(() {}); // Forces a rebuild to reflect the new online status
      }
    });
    _socketService.onMessageReceived((data) {},
        refreshCallback: _fetchAssignedCustomers);
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

      // Fetch notification count for each user
      for (var customer in fetchedCustomerList) {
        final countBoxName = '${widget.agentEmail}${customer["email"]}count';
        final timeBoxName =
            '${widget.agentEmail}${customer["email"]}lastMessageTime';

        final countBox = await Hive.openBox<int>(countBoxName);
        final timeBox = await Hive.openBox<String>(
            timeBoxName); // assuming you save time as ISO string

        final count = countBox.get('count', defaultValue: 0);
        final lastMessageTimeStr = timeBox.get('lastMessageTime');
        final lastMessageTime = lastMessageTimeStr != null
            ? DateTime.tryParse(lastMessageTimeStr)
            : null;

        customer['notificationCount'] = count;
        customer['lastMessageTime'] = lastMessageTime;
      }

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
      leading: Initicon(text: widget.agentName!),
      title: Text(widget.agentName ?? "", style: AppTextStyles.black16_500),
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
              size: 24,
            ),
          ),
          IconButton(
            onPressed: () {
              // Navigate to the CallHistoryPage or perform an action related to call logs
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CallHistoryScreen()),
              );
            },
            icon: Icon(
              Icons
                  .call_outlined, // You can choose a different icon if preferred
              color: Colors.black,
              size: 24,
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

  // Recent Messages List
  Widget _buildCustomerInquiriesList() {
    // Sort the list to show online users first
    _filteredCustomers.sort((a, b) {
      final isAOnline = _socketService.isUserOnline(a["email"]);
      final isBOnline = _socketService.isUserOnline(b["email"]);

      if (isAOnline && !isBOnline) return -1;
      if (!isAOnline && isBOnline) return 1;

      final timeA =
          a['lastMessageTime'] ?? DateTime.fromMillisecondsSinceEpoch(0);
      final timeB =
          b['lastMessageTime'] ?? DateTime.fromMillisecondsSinceEpoch(0);
      return timeB.compareTo(timeA); // Descending order
    });

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
          final int notificationCount =
              assignedCustomer['notificationCount'] ?? 0;
          final isAccountDeleted = assignedCustomer["isDeleted"];
          final customerLastChattedMessage =
              _socketService.getLastMessage(assignedCustomer["email"]);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Stack(
              children: [
                FeedListCard(
                  isAccountDeleted: isAccountDeleted,
                  name: assignedCustomer["name"],
                  message: customerLastChattedMessage,
                  isActive: isOnline,
                  time: isOnline ? "Online" : lastSeen,
                  enableLongPress: false,
                  onTap: () async {
                    final boxNameWithCount =
                        '${widget.agentEmail}${assignedCustomer["email"]}count';
                    final box = await Hive.openBox<int>(boxNameWithCount);
                    await box.put('count', 0);
                    setState(() {
                      // Update in-memory list to reflect zero count
                      assignedCustomer['notificationCount'] = 0;
                    });
                    if (context.mounted) {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AgentChatScreen(
                            navigatorKey: navigatorKey,
                            customerName: assignedCustomer["name"],
                            customerEmail: assignedCustomer['email'],
                            agentEmail: widget.agentEmail,
                            agentName: widget.agentName,
                            isAccountDeleted: isAccountDeleted,
                          ),
                        ),
                      );
                      if (result == true) {
                        await _fetchAssignedCustomers();
                      }
                    }
                  },
                ),
                if (notificationCount > 0)
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        notificationCount.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
