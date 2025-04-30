import 'package:flutter/material.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/presentation/customer/screen/customer_chat_screen.dart';
import 'package:kkpchatapp/presentation/marketing/screen/agent_chat_screen.dart';

/// Handles notification click for customers.
/// Navigates to the [CustomerChatScreen] based on the notification data.
Future<void> handleNotificationClickForCustomer(
    BuildContext context,
    GlobalKey<NavigatorState> navigatorKey,
    Map<String, dynamic> notificationData) async {
  final customerEmail = LocalDbHelper.getProfile()?.email;
  final customerImage = LocalDbHelper.getProfile()?.profileUrl ?? "";

  navigatorKey.currentState?.push(
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

/// Handles push notification click for customers.
/// Navigates to the [CustomerChatScreen] based on the notification data.
Future<void> handlePushNotificationClickForCustomer(
    GlobalKey<NavigatorState> navigatorKey,
    Map<String, dynamic> notificationData) async {
  final customerEmail = LocalDbHelper.getProfile()?.email;
  final customerImage = LocalDbHelper.getProfile()?.profileUrl ?? "";

  navigatorKey.currentState?.push(
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

/// Handles notification click for agents.
/// Navigates to the [AgentChatScreen] based on the notification data.
Future<void> handleNotificationClickForAgent(
    BuildContext context,
    GlobalKey<NavigatorState> navigatorKey,
    Map<String, dynamic> notificationData) async {
  final customerEmail = notificationData['senderId'];
  final customerName = notificationData['senderName'];
  navigatorKey.currentState?.push(
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

/// Handles push notification click for agents.
/// Navigates to the [AgentChatScreen] based on the notification data.
Future<void> handlePushNotificationClickForAgent(
    GlobalKey<NavigatorState> navigatorKey,
    Map<String, dynamic> notificationData) async {
  final customerEmail = notificationData['senderId'];
  final customerName = notificationData['senderName'];
  navigatorKey.currentState?.push(
    MaterialPageRoute(
      builder: (_) => AgentChatScreen(
        customerName: customerName,
        customerEmail: customerEmail,
        agentEmail: LocalDbHelper.getProfile()?.email,
        agentName: LocalDbHelper.getProfile()?.name,
        navigatorKey: navigatorKey,
      ),
    ),
  );
}
