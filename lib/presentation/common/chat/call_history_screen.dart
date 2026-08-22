import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/services/logging_service.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/models/call_log_model.dart';
import 'package:kkpchatapp/data/repositories/chat_reopsitory.dart';
import 'package:kkpchatapp/l10n/generated/app_localizations.dart';
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
    final userType = await LocalDbHelper.getUserType();
    // "0" is the customer role; label the dump so agent and customer runs are
    // distinguishable in the console (this screen is shared by both).
    final side = userType == '0' ? 'customer' : 'agent';

    if (email == null) {
      LoggingService.instance.logNetwork(
        'Call history ($side): no logged-in email, skipping fetch',
        level: LogLevel.warning,
      );
      if (!mounted) return;
      setState(() => isLoading = false);
      return;
    }

    try {
      final fetchedLogs = await _chatRepo.fetchCallLogs(email);
      if (!mounted) return;

      // Deduplicate by id
      final seen = <String>{};
      final uniqueLogs = fetchedLogs.where((log) => seen.add(log.id)).toList();

      // Sort newest first
      uniqueLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      LoggingService.instance.logApiData(
        'Call history ($side) $email — '
        '${fetchedLogs.length} fetched, ${uniqueLogs.length} after dedupe',
        uniqueLogs.map((log) => log.toJson()).toList(),
      );

      setState(() {
        callLogs = uniqueLogs;
        isLoading = false;
      });
    } catch (e, stack) {
      debugPrint('Error fetching call logs: $e');
      LoggingService.instance.logNetwork(
        'Failed to fetch call logs ($side) for $email: $e',
        level: LogLevel.error,
        error: e,
        stackTrace: stack,
      );
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
        title: Text(AppLocalizations.of(context)!.callHistory,
            style: AppTextStyles.black16_500),
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
