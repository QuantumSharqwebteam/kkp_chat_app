import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/models/call_log_model.dart';
import 'package:kkpchatapp/data/repositories/chat_reopsitory.dart';
import 'package:kkpchatapp/presentation/common_widgets/empty_call_logs_widget.dart';
import 'package:kkpchatapp/presentation/marketing/widget/settings/call_log_tile.dart';

class CallHistoryScreen extends StatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen> {
  final _chatRepo = ChatRepository();
  List<CallLogModel> callLogs = [];
  bool isLoading = true;
  String? role;

  @override
  void initState() {
    super.initState();
    fetchCallLogs();
    fetchUserRole();
  }

  void fetchUserRole() {
    LocalDbHelper.getUserType().then((value) {
      setState(() {
        role = value;
      });
    });
  }

  Future<void> fetchCallLogs() async {
    final email = LocalDbHelper.getEmail();
    try {
      final fetchedLogs = await _chatRepo.fetchCallLogs(email!);
      if (!mounted) return;
      setState(() {
        callLogs = fetchedLogs;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching call logs: $e');
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Call History", style: AppTextStyles.black16_500),
        backgroundColor: Colors.white,
      ),
      body: buildCallLogList(),
    );
  }

  Widget buildCallLogList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (callLogs.isEmpty) {
      return const Center(child: EmptyCallLogsWidget());
    }

    final Map<String, List<CallLogModel>> groupedLogs = {};

    for (var log in callLogs) {
      final date = log.timestamp;
      final now = DateTime.now();
      String key;

      if (DateUtils.isSameDay(date, now)) {
        key = "Today";
      } else if (DateUtils.isSameDay(
          date, now.subtract(const Duration(days: 1)))) {
        key = "Yesterday";
      } else {
        key = "${date.day}/${date.month}/${date.year}";
      }

      groupedLogs.putIfAbsent(key, () => []).add(log);
    }

    final currentUserId = LocalDbHelper.getEmail();

    return ListView(
      children: groupedLogs.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.maxFinite,
              color: Colors.grey[200],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                entry.key,
                style: AppTextStyles.grey12_600,
              ),
            ),
            ...entry.value.map(
              (log) => CallLogTile(
                role: role,
                log: log,
                currentUserId: currentUserId!,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
