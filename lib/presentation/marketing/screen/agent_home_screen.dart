import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/core/services/socket_service.dart';
import 'package:kkpchatapp/data/models/meet_model.dart';
import 'package:kkpchatapp/l10n/generated/app_localizations.dart';
import 'package:kkpchatapp/logic/agent/agent_home_screen_provider.dart';
import 'package:kkpchatapp/logic/agent/chat_refresh_provider.dart';
import 'package:kkpchatapp/logic/agent/notification_provider.dart';
import 'package:kkpchatapp/logic/meeting/meet_management.dart';
import 'package:kkpchatapp/main.dart';
import 'package:kkpchatapp/presentation/admin/screens/meetings/meeting_list_screen.dart';
import 'package:kkpchatapp/presentation/common/auth/login_page.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_search_field.dart';
import 'package:kkpchatapp/presentation/common_widgets/shimmer_list.dart';
import 'package:kkpchatapp/presentation/marketing/screen/agent_chat_screen.dart';
import 'package:kkpchatapp/config/routes/marketing_routes.dart';
import 'package:kkpchatapp/presentation/common/chat/call_history_screen.dart';
import 'package:kkpchatapp/presentation/marketing/widget/custom_drawer.dart';
import 'package:kkpchatapp/presentation/marketing/widget/feed_list_card.dart';
import 'package:kkpchatapp/presentation/marketing/widget/no_customer_assigned_widget.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AgentHomeScreen extends StatefulWidget {
  const AgentHomeScreen({super.key});

  @override
  State<AgentHomeScreen> createState() => _AgentHomeScreenState();
}

class _AgentHomeScreenState extends State<AgentHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  StreamSubscription<List<String>>? _statusSubscription;
  ChatRefreshProvider? _chatRefreshProvider;
  VoidCallback? _chatRefreshListener;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Held in fields so dispose() can actually detach. Previously both the
      // provider and the closure were locals, so removeListener had nothing to
      // remove and every mount left another live listener behind.
      final chatRefreshProvider =
          Provider.of<ChatRefreshProvider>(context, listen: false);
      _chatRefreshProvider = chatRefreshProvider;
      _chatRefreshListener = () {
        if (!mounted) return;
        if (chatRefreshProvider.shouldRefresh) {
          context.read<AssignedCustomersProvider>().fetchAssignedCustomers();
          chatRefreshProvider.reset();
        }
      };
      chatRefreshProvider.addListener(_chatRefreshListener!);

      // ← FIX: fetch notifications for badge count
      Provider.of<MeetingManagement>(context, listen: false).fetchAllMeetings();
    });
  }

  void logout() async {
    await LocalDbHelper.removeToken();
    await LocalDbHelper.removeName();
    await LocalDbHelper.removeEmail();
    await LocalDbHelper.removeUserType();
    await LocalDbHelper.removeProfile();

    SocketService(navigatorKey).dispose();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    final listener = _chatRefreshListener;
    if (listener != null) {
      _chatRefreshProvider?.removeListener(listener);
    }
    _statusSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final provider = Provider.of<AssignedCustomersProvider>(context);
    final meetingManagement = Provider.of<MeetingManagement>(context);

    return Scaffold(
      key: _scaffoldKey,
      drawer: CustomDrawer(
        agentName: provider.agentName,
        agentEmail: provider.agentEmail,
        onLogout: logout,
      ),
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
                                // Today's Meetings Section
                                _buildUpcomingMeetingsSection(
                                    meetingManagement, context),
                                const SizedBox(height: 15),
                                Text(locale.customerInquiries,
                                    style: AppTextStyles.black16_500),
                                const SizedBox(height: 5),
                                _buildSearchBar(provider),
                              ],
                            ),
                          )
                        ],
                        body: StreamBuilder<List<String>>(
                          stream: provider.socketService.statusStream,
                          builder: (context, _) {
                            if (provider.assignedCustomers.isEmpty) {
                              return const NoCustomerAssignedWidget();
                            }

                            if (provider.filteredCustomers.isEmpty) {
                              return _buildEmptySearchState(locale);
                            }

                            return _buildCustomerInquiriesList(provider);
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
    final locale = AppLocalizations.of(context)!;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      leading: IconButton(
        onPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
        icon: Icon(Icons.menu),
      ),
      title: Text(name ?? "", style: AppTextStyles.black16_500),
      subtitle:
          Text(locale.findLatestMessages, style: AppTextStyles.black10_500),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const CallHistoryScreen()),
            ),
            icon: const Icon(Icons.call_outlined, color: Colors.black),
          ),
          // ← FIX: notification icon with unread badge using Consumer
          Consumer<NotificationProvider>(
            builder: (context, notifProvider, _) {
              final unreadCount = notifProvider.notifications
                  .where((n) => !(n.viewed ?? false))
                  .length;
              return IconButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    MarketingRoutes.marketingNotifications,
                  ).then((_) {
                    // Cache-first: markAsRead/markAllRead already updated the
                    // shared list, so the badge is correct without refetching.
                    notifProvider.ensureLoaded();
                  });
                },
                icon: unreadCount > 0
                    ? Badge(
                        label: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: Colors.red,
                        child: const Icon(Icons.notifications_active_outlined),
                      )
                    : const Icon(Icons.notifications_active_outlined),
                iconSize: 25,
              );
            },
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
    final locale = AppLocalizations.of(context)!;
    return CustomSearchBar(
      enable: true,
      controller: _searchController,
      hintText: locale.search,
      onChanged: provider.updateSearchQuery,
    );
  }

  Widget _buildCustomerInquiriesList(AssignedCustomersProvider provider) {
    final locale = AppLocalizations.of(context)!;
    final socket = provider.socketService;

    final validCustomers = provider.filteredCustomers.where((customer) {
      final email = customer['email']?.toString();
      final isDeleted = customer['isDeleted'] ?? false;
      return email != null && email.isNotEmpty && !isDeleted;
    }).toList();

    return RefreshIndicator(
      onRefresh: () async => provider.fetchAssignedCustomers(),
      child: ListView.builder(
        itemCount: validCustomers.length,
        physics: const AlwaysScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final customer = validCustomers[index];
          final name = customer['name'] ?? locale.unnamed;
          final email = customer['email']?.toString() ?? "";
          final isAccountDeleted = customer['isDeleted'] ?? false;
          final isOnline = customer['isOnline'] ?? false;
          final lastSeen = isOnline ? "Online" : socket.getLastSeenTime(email);
          final notificationCount = customer['notificationCount'] ?? 0;
          // false when this customer was transferred to another agent —
          // the chat then opens read-only.
          final bool canMessage = customer['canMessage'] as bool? ?? true;
          final lastMessage = socket.getLastMessage(email);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Stack(
              children: [
                FeedListCard(
                  name: name,
                  message: lastMessage,
                  isAccountDeleted: isAccountDeleted,
                  isActive: isOnline,
                  time: isOnline ? locale.online : lastSeen,
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
                            canMessage: canMessage,
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
                    top: 5,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        notificationCount.toString(),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 10),
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

  Widget _buildEmptySearchState(AppLocalizations locale) {
    return Center(
      child: Text(
        locale.noCustomersAvailable,
        style: AppTextStyles.grey12_600,
      ),
    );
  }

  Widget _buildUpcomingMeetingsSection(
      MeetingManagement meetingManagement, BuildContext context) {
    final nextMeetings = meetingManagement.getNextUpcomingMeeting();
    final locale = AppLocalizations.of(context)!;

    final hasMeetings = nextMeetings != null && nextMeetings.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(locale.upcomingMeetings, style: AppTextStyles.black16_500),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => MeetingsListScreen(
                      email: LocalDbHelper.getEmail()!,
                    ),
                  ),
                );
                Provider.of<MeetingManagement>(context, listen: false)
                    .fetchAllMeetings();
              },
              child: const Text(
                "See all",
                style: TextStyle(decoration: TextDecoration.underline),
              ),
            )
          ],
        ),
        hasMeetings
            ? Column(
                children: nextMeetings
                    .map((meeting) =>
                        _buildUpcomingMeetingCard(meeting, context))
                    .toList(),
              )
            : _buildNoMeetingsCard(context),
      ],
    );
  }

  Widget _buildUpcomingMeetingCard(MeetingModel meeting, BuildContext context) {
    final startTime = DateTime.parse(meeting.startTime).toLocal();
    final now = DateTime.now();
    final timeDifference = startTime.difference(now);

    String timeRemaining;
    if (timeDifference.inDays > 0) {
      timeRemaining =
          "${timeDifference.inDays} day${timeDifference.inDays > 1 ? 's' : ''}";
    } else if (timeDifference.inHours > 0) {
      timeRemaining =
          "${timeDifference.inHours} hour${timeDifference.inHours > 1 ? 's' : ''}";
    } else {
      timeRemaining =
          "${timeDifference.inMinutes} minute${timeDifference.inMinutes > 1 ? 's' : ''}";
    }

    return Container(
      height: 100,
      width: double.maxFinite,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${startTime.day.toString().padLeft(2, '0')}/${startTime.month.toString().padLeft(2, '0')}",
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  "${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "Upcoming",
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  meeting.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      meeting.location,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      "by ${meeting.scheduledPerson.name}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "In $timeRemaining",
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  launchUrl(Uri.parse(meeting.link));
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    "Join",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoMeetingsCard(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
        ),
        child: Text(
          "No upcoming meetings for today",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }
}
