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
import 'package:kkpchatapp/presentation/marketing/widget/group_chat_file.dart';
import 'package:provider/provider.dart';

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  String? role;
  final Map<String, String> _groupLastMessages = {};
  final Map<String, DateTime?> _groupLastMessageTimes = {};

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
    // fetchAllGroups already calls loadUnreadCountsFromStorage internally
    await _loadGroupPreviews(groupProvider.groups);
  }

  Future<void> _loadGroupPreviews(List<GroupModel> groups) async {
    for (final group in groups) {
      final info = await LocalDbHelper.getGroupLastMessage(group.id);
      if (!mounted) return;
      if (info.message.isNotEmpty || info.timestamp != null) {
        setState(() {
          _groupLastMessages[group.id] = info.message;
          _groupLastMessageTimes[group.id] = info.timestamp;
        });
      }
    }
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

    // Reload previews when returning from chat
    if (mounted) {
      await _loadGroupPreviews(groupProvider.groups);
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
          if (groupProvider.state == GroupState.loading && groupProvider.groups.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          } else if (groupProvider.groups.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('You are not added to any groups.'),
                  SizedBox(height: 20),
                  Icon(Icons.group_off, size: 60, color: Colors.grey),
                ],
              ),
            );
          } else {
            return ListView.builder(
              itemCount: groupProvider.groups.length,
              itemBuilder: (context, index) {
                final group = groupProvider.groups[index];
                final unread = groupProvider.groupUnreadCounts[group.id] ?? 0;
                return GroupChatTile(
                  groupName: group.groupName,
                  memberCount: group.members.length,
                  lastMessage: _groupLastMessages[group.id] ?? '',
                  time: _groupLastMessageTimes[group.id],
                  unreadCount: unread,
                  onTap: () => _openGroupChat(context, group),
                );
              },
            );
          }
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
