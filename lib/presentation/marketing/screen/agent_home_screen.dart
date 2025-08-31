import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_initicon/flutter_initicon.dart';
import 'package:kkpchatapp/config/routes/marketing_routes.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/logic/agent/agent_home_screen_provider.dart';
import 'package:kkpchatapp/logic/agent/chat_refresh_provider.dart';
import 'package:kkpchatapp/main.dart';
import 'package:kkpchatapp/presentation/common/chat/call_history_screen.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_search_field.dart';
import 'package:kkpchatapp/presentation/common_widgets/shimmer_list.dart';
import 'package:kkpchatapp/presentation/marketing/screen/agent_chat_screen.dart';
import 'package:kkpchatapp/presentation/marketing/widget/feed_list_card.dart';
import 'package:kkpchatapp/presentation/marketing/widget/no_customer_assigned_widget.dart';
import 'package:provider/provider.dart';

class AgentHomeScreen extends StatefulWidget {
  const AgentHomeScreen({super.key});

  @override
  State<AgentHomeScreen> createState() => _AgentHomeScreenState();
}

class _AgentHomeScreenState extends State<AgentHomeScreen> {
  final _searchController = TextEditingController();
  StreamSubscription<List<String>>? _statusSubscription;

  @override
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatRefreshProvider =
          Provider.of<ChatRefreshProvider>(context, listen: false);
      chatRefreshProvider.addListener(() {
        if (chatRefreshProvider.shouldRefresh) {
          context.read<AssignedCustomersProvider>().fetchAssignedCustomers();
          chatRefreshProvider.reset();
        }
      });
    });
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AssignedCustomersProvider>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildProfileSection(provider.agentName),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: provider.isLoading
                    ? ShimmerList(itemCount: 8)
                    : NestedScrollView(
                        headerSliverBuilder: (context, _) => [
                          SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSearchBar(provider),
                                const SizedBox(height: 20),
                                Text("Customer Inquiries",
                                    style: AppTextStyles.black16_500),
                              ],
                            ),
                          )
                        ],
                        body: StreamBuilder<List<String>>(
                          stream: provider.socketService.statusStream,
                          builder: (context, _) {
                            return provider.filteredCustomers.isEmpty
                                ? const NoCustomerAssignedWidget()
                                : _buildCustomerInquiriesList(provider);
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

  Widget _buildProfileSection(String? name) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      leading: Initicon(
        text: name ?? "",
        size: 35,
      ),
      title: Text(name ?? "", style: AppTextStyles.black16_500),
      subtitle:
          Text("Let's find latest messages", style: AppTextStyles.black10_500),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => Navigator.pushNamed(
                context, MarketingRoutes.marketingNotifications),
            icon: const Icon(Icons.notifications_active_outlined,
                color: Colors.black),
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const CallHistoryScreen()),
            ),
            icon: const Icon(Icons.call_outlined, color: Colors.black),
          ),
          IconButton(
            onPressed: () =>
                Navigator.pushNamed(context, MarketingRoutes.marketingSettings),
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AssignedCustomersProvider provider) {
    return CustomSearchBar(
      enable: true,
      controller: _searchController,
      hintText: "Search",
      onChanged: provider.updateSearchQuery,
    );
  }

  Widget _buildCustomerInquiriesList(AssignedCustomersProvider provider) {
    final socket = provider.socketService;

    // Get the list of valid customers from the provider (already sorted by the provider)
    final validCustomers = provider.filteredCustomers.where((customer) {
      final email = customer['email'];
      final name = customer['name'];
      final isDeleted = customer['isDeleted'] ?? false;
      return email != null &&
          name != null &&
          email.toString().isNotEmpty &&
          !isDeleted;
    }).toList();

    // We don't need to sort here anymore since the provider handles it
    return RefreshIndicator(
      onRefresh: () async => provider.fetchAssignedCustomers(),
      child: ListView.builder(
        itemCount: validCustomers.length,
        physics: const AlwaysScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final customer = validCustomers[index];
          final name = customer['name'] ?? "Unnamed";
          final email = customer['email']?.toString() ?? "";
          final isAccountDeleted = customer['isDeleted'] ?? false;
          final isOnline = customer['isOnline'] ?? false; // Use the flag we set
          final lastSeen = isOnline ? "Online" : socket.getLastSeenTime(email);
          final notificationCount = customer['notificationCount'] ?? 0;
          final lastMessage = socket.getLastMessage(email);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Stack(
              children: [
                FeedListCard(
                  name: name,
                  message: lastMessage,
                  isAccountDeleted: isAccountDeleted,
                  isActive: isOnline, // Use our local flag
                  time: isOnline ? "Online" : lastSeen,
                  enableLongPress: false,
                  onTap: () async {
                    await provider.resetNotificationCount(email);
                    if (context.mounted) {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AgentChatScreen(
                            navigatorKey: navigatorKey,
                            customerName: name,
                            customerEmail: email,
                            agentEmail: provider.agentEmail,
                            agentName: provider.agentName,
                            isAccountDeleted: isAccountDeleted,
                          ),
                        ),
                      );
                      if (result == true) {
                        await provider.fetchAssignedCustomers();
                      }
                    }
                  },
                ),
                if (notificationCount > 0)
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
                        notificationCount.toString(),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
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
