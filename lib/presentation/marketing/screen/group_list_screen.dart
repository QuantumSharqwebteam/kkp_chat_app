import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/models/group_model.dart';
import 'package:kkpchatapp/logic/agent/group_provider.dart';
import 'package:kkpchatapp/main.dart';
import 'package:kkpchatapp/presentation/admin/screens/internal_chat/internal_chat_screen.dart';
import 'package:kkpchatapp/presentation/marketing/add_new_group_scree.dart';
import 'package:kkpchatapp/presentation/marketing/widget/group_chat_tile.dart';
import 'package:provider/provider.dart';

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  String? role;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRole();
      _loadGroups();
    });
  }

  Future<void> _loadRole() async {
    final loadedRole = await LocalDbHelper.getUserType();
    if (!mounted) return;
    setState(() => role = loadedRole);
  }

  Future<void> _loadGroups() async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    await groupProvider.fetchAllGroups();
    // fetchAllGroups already loads unread counts; also load last messages.
    await groupProvider.loadLastMessagesFromStorage();
  }

  /// Pull-to-refresh. Forces the network fetch — the plain load short-circuits
  /// on a warm cache, which would make the gesture look like it did nothing.
  Future<void> _refreshGroups() async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    await groupProvider.fetchAllGroups(forceRefresh: true);
    if (!mounted) return;
    await groupProvider.loadLastMessagesFromStorage();
  }

  Future<void> _openGroupChat(BuildContext context, GroupModel group) async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final navigator = Navigator.of(context);
    final agentName = LocalDbHelper.getName();
    final agentEmail = LocalDbHelper.getEmail();

    // Clear badge immediately — optimistic update (no async gap before push)
    unawaited(groupProvider.clearUnreadCount(group.id));

    await navigator.push(
      MaterialPageRoute(
        builder: (context) => InternalChatScreen(
          agentName: agentName ?? 'agent',
          agentEmail: agentEmail ?? 'agent@gmail.com',
          navigatorKey: navigatorKey,
          groupId: group.id,
          group: group,
        ),
      ),
    );

    // Refresh last message previews when returning from chat.
    if (mounted) {
      await groupProvider.loadLastMessagesFromStorage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
      ),
      body: Consumer<GroupProvider>(
        builder: (context, groupProvider, child) {
          // Cold start only — once groups exist, a refresh shows the pull
          // spinner rather than replacing the list with a loader.
          if (groupProvider.state == GroupState.loading &&
              groupProvider.groups.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _refreshGroups,
            child: groupProvider.groups.isEmpty
                // A plain Center is not scrollable, so the pull gesture would
                // never trigger on the empty state. AlwaysScrollableScrollPhysics
                // on a ListView keeps it draggable with nothing in it.
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.3),
                      const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('You are not added to any groups.'),
                          SizedBox(height: 20),
                          Icon(Icons.group_off, size: 60, color: Colors.grey),
                        ],
                      ),
                    ],
                  )
                : Builder(
                    builder: (context) {
                      // Most recently messaged group first.
                      final orderedGroups =
                          groupProvider.groupsByRecentActivity;
                      return ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: orderedGroups.length,
                        itemBuilder: (context, index) {
                          final group = orderedGroups[index];
                          final unread =
                              groupProvider.groupUnreadCounts[group.id] ?? 0;
                          return GroupChatTile(
                            groupName: group.groupName,
                            memberCount: group.members.length,
                            lastMessage:
                                groupProvider.groupLastMessages[group.id] ?? '',
                            time: groupProvider.groupLastMessageTimes[group.id],
                            unreadCount: unread,
                            onTap: () => _openGroupChat(context, group),
                          );
                        },
                      );
                    },
                  ),
          );
        },
      ),
      floatingActionButton: role == "2"
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppColors.bluePrimary,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddNewGroupScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'New Group',
                style: AppTextStyles.black12_400.copyWith(color: Colors.white),
              ),
            ),
    );
  }
}
