import 'package:flutter/material.dart';
import 'package:flutter_initicon/flutter_initicon.dart';
import 'package:intl/intl.dart';
import 'package:kkpchatapp/data/models/call_log_model.dart';

class CallLogTile extends StatelessWidget {
  final CallLogModel log;
  final String? currentUserId;

  const CallLogTile({
    super.key,
    required this.log,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final isOutgoing = log.senderId == currentUserId;
    final otherUserName = isOutgoing ? log.receiverName : log.senderName;
    final callTime = DateFormat.jm().format(log.timestamp); // e.g., 4:32 PM
    final status = log.callStatus;

    final statusIcon = _getCallStatusIcon(status, isOutgoing);
    final statusColor = _getStatusColor(status);

    final bool isAnswered = status.toLowerCase() == 'answered';
    final String? durationText =
        isAnswered && log.callDuration != null ? ': ${log.callDuration}' : null;

    return ListTile(
      leading:
          Initicon(text: otherUserName), // Your custom initials/avatar widget
      title: Text(otherUserName),
      subtitle: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 16),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '$status${durationText ?? ''}',
              style: TextStyle(fontSize: 13, color: statusColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      trailing: Text(
        callTime,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }

  IconData _getCallStatusIcon(String status, bool isOutgoing) {
    switch (status.toLowerCase()) {
      case 'missed':
        return isOutgoing ? Icons.call_missed_outgoing : Icons.call_missed;
      case 'answered':
        return isOutgoing ? Icons.call_made : Icons.call_received;
      case 'declined':
        return Icons.call_end;
      default:
        return Icons.phone;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'missed':
        return Colors.red;
      case 'answered':
        return Colors.green;
      case 'declined':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
