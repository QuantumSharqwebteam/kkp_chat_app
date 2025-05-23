import 'package:flutter/material.dart';
import 'package:flutter_initicon/flutter_initicon.dart';
import 'dart:async';
import 'package:kkpchatapp/config/routes/marketing_routes.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/services/socket_service.dart';
import 'package:kkpchatapp/logic/agent/agent_home_screen_provider.dart';
import 'package:kkpchatapp/main.dart';
import 'package:kkpchatapp/presentation/common/chat/call_history_screen.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_search_field.dart';
import 'package:kkpchatapp/presentation/common_widgets/shimmer_list.dart';
import 'package:kkpchatapp/presentation/marketing/screen/agent_chat_screen.dart';
import 'package:kkpchatapp/presentation/marketing/widget/feed_list_card.dart';
import 'package:kkpchatapp/presentation/marketing/widget/no_customer_assigned_widget.dart';

import 'package:provider/provider.dart';

class AgentHomeScreen extends StatefulWidget {
  final String? agentEmail;
  final String? agentName;
  const AgentHomeScreen({super.key, this.agentEmail, this.agentName});

  @override
  State<AgentHomeScreen> createState() => _AgentHomeScreenState();
}

class _AgentHomeScreenState extends State<AgentHomeScreen> {
  final _searchController = TextEditingController();
  final SocketService _socketService = SocketService(navigatorKey);
  StreamSubscription<List<String>>? _statusSubscription;

  @override
  void initState() {
    super.initState();
    final provider =
        Provider.of<AgentHomeScreenProvider>(context, listen: false);
    // Fetch customer data via global provider
    Future.microtask(() {
      provider.fetchCustomers(widget.agentEmail!);
    });

    _statusSubscription = _socketService.statusStream.listen((_) {
      if (mounted) setState(() {});
    });

    _socketService.onMessageReceived((data) {
      final provider =
          Provider.of<AgentHomeScreenProvider>(context, listen: false);
      provider.fetchCustomers(widget.agentEmail!);
    });
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AgentHomeScreenProvider>(context);
    final customers =
        provider.filteredCustomers; // Use filtered list from provider
    final isLoading = provider.isLoading;

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
                child: isLoading
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
                            return customers.isEmpty
                                ? Center(child: NoCustomerAssignedWidget())
                                : _buildCustomerInquiriesList(customers);
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

  Widget _buildProfileSection() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Initicon(text: widget.agentName ?? ""),
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
            icon: const Icon(Icons.notifications_active_outlined,
                color: Colors.black),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => CallHistoryScreen()));
            },
            icon: const Icon(Icons.call_outlined, color: Colors.black),
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, MarketingRoutes.marketingSettings);
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return CustomSearchBar(
      enable: true,
      controller: _searchController,
      hintText: "search",
      onChanged: (query) {
        // Delegate search query to provider
        Provider.of<AgentHomeScreenProvider>(context, listen: false)
            .updateSearchQuery(query);
      },
    );
  }

  Widget _buildCustomerInquiriesList(List<dynamic> customers) {
    customers.sort((a, b) {
      final isAOnline = _socketService.isUserOnline(a["email"]);
      final isBOnline = _socketService.isUserOnline(b["email"]);
      if (isAOnline && !isBOnline) return -1;
      if (!isAOnline && isBOnline) return 1;
      return 0;
    });

    return RefreshIndicator(
      onRefresh: () {
        final provider =
            Provider.of<AgentHomeScreenProvider>(context, listen: false);
        return provider.fetchCustomers(widget.agentEmail!);
      },
      child: ListView.builder(
        itemCount: customers.length,
        physics: const AlwaysScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final customer = customers[index];
          final isOnline = _socketService.isUserOnline(customer["email"]);
          final lastSeen = _socketService.getLastSeenTime(customer["email"]);
          final count = context
              .watch<AgentHomeScreenProvider>()
              .getCount(customer["email"]);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Stack(
              children: [
                FeedListCard(
                  name: customer["name"],
                  message: "last message",
                  isActive: isOnline,
                  time: isOnline ? "Online" : lastSeen,
                  enableLongPress: false,
                  onTap: () async {
                    final provider = Provider.of<AgentHomeScreenProvider>(
                        context,
                        listen: false);
                    provider.resetCount(widget.agentEmail!, customer["email"]);

                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AgentChatScreen(
                          navigatorKey: navigatorKey,
                          customerName: customer["name"],
                          customerEmail: customer["email"],
                          agentEmail: widget.agentEmail,
                          agentName: widget.agentName,
                        ),
                      ),
                    );

                    if (result == true) {
                      provider.fetchCustomers(widget.agentEmail!);
                    }
                  },
                ),
                if (count > 0)
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        count.toString(),
                        style: const TextStyle(
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
