import 'package:flutter/material.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/presentation/customer/screen/customer_chat_screen.dart';
import 'package:kkpchatapp/presentation/marketing/screen/agent_chat_screen.dart';

Future<void> handleNotificationClickForCustomer(BuildContext context,
    navigatorKey, Map<String, dynamic> notificationData) async {
  final customerEmail = LocalDbHelper.getProfile()?.email;
  final customerImage = LocalDbHelper.getProfile()?.profileUrl ?? "";

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => CustomerChatScreen(
        agentName: "Agent",
        customerEmail: customerEmail,
        customerImage: customerImage,
        navigatorKey: navigatorKey,
      ),
    ),
  );
}

Future<void> handleNotificationClickForAgent(BuildContext context, navigatorKey,
    Map<String, dynamic> notificationData) async {
  final customerEmail = notificationData['senderId'];
  final customerName = notificationData['senderName'];
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AgentChatScreen(
        customerName: customerName,
        customerEmail: customerEmail,
        agentEmail: LocalDbHelper.getEmail(),
        agentName: LocalDbHelper.getProfile()?.name,
        navigatorKey: navigatorKey,
      ),
    ),
  );
}
