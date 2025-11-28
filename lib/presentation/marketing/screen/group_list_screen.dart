import 'package:flutter/material.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGroups();
    });
  }

  Future<void> _loadGroups() async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    await groupProvider.fetchAllGroups();
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
                final agentName = LocalDbHelper.getName();
                final agentEmail = LocalDbHelper.getEmail();
                return GroupChatTile(
                  groupName: group.groupName,
                  lastMessage: group.groupDescription,
                  time: group.lastActivity,
                  unreadCount: 0, // Replace with actual unread count logic
                  onTap: () {
                    // Navigate to group chat screen
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => InternalChatScreen(
                                  agentName: agentName ?? "agent",
                                  agentEmail: agentEmail ?? "agent@gmail.com",
                                  navigatorKey: navigatorKey,
                                  groupId: group.id,
                                  group: group,
                                )));
                  },
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddNewGroupScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
