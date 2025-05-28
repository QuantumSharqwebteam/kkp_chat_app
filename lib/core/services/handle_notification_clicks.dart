import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/main.dart';
import 'package:kkpchatapp/presentation/common/chat/incoming_call_screen.dart';
import 'package:kkpchatapp/presentation/customer/screen/customer_chat_screen.dart';
import 'package:kkpchatapp/presentation/marketing/screen/agent_chat_screen.dart';

/// Handles notification click for customers.
Future<void> handleNotificationClickForCustomer(
    GlobalKey<NavigatorState> navigatorKey,
    Map<String, dynamic> notificationData) async {
//  final customerEmail = LocalDbHelper.getProfile()?.email;

  navigatorKey.currentState?.push(
    MaterialPageRoute(
      builder: (_) => CustomerChatScreen(
        agentName: "Agent",
        customerEmail: notificationData['targetId'],
        navigatorKey: navigatorKey,
      ),
    ),
  );
}

/// Handles push notification click for customers.
Future<void> handlePushNotificationClickForCustomer(
    GlobalKey<NavigatorState> navigatorKey,
    Map<String, dynamic> notificationData) async {
  final StreamController<bool> controller = StreamController<bool>();
  Timer? timer;

  // Function to trigger navigation
  void triggerNavigation() {
    final customerEmail = LocalDbHelper.getProfile()?.email;
    // ChatStorageService chatStorageService = ChatStorageService();
    // final Map<String, dynamic> notiData = notificationData;
    // final targetId = notificationData['targetId'];

    // ChatMessageModel pushMessage = ChatMessageModel(
    //   message: notiData['message'],
    //   sender: notiData['senderId'],
    //   timestamp: DateTime.now(),
    //   form: notiData['form'] ?? {},
    //   mediaUrl: notiData['mediaUrl'] ?? "",
    //   type: notiData['type'] ?? "",
    // );

    //chatStorageService.saveMessage(pushMessage, targetId);

    Navigator.push(
      navigatorKey.currentContext!,
      MaterialPageRoute(
        builder: (_) => CustomerChatScreen(
          agentName: "Agent",
          customerEmail: customerEmail,
          navigatorKey: navigatorKey,
        ),
      ),
    );
  }

  // Listen for changes to isAppInitialized
  controller.stream.listen((isInitialized) {
    if (isInitialized) {
      timer?.cancel(); // Cancel the timer if the variable becomes true
      triggerNavigation();
    }
  });

  // Start a timer to observe the variable for 20 seconds
  timer = Timer(Duration(seconds: 20), () {
    if (!controller.isClosed) {
      controller.close(); // Close the stream if the timer completes
      debugPrint("Timeout reached. App is not initialized.");
    }
  });

  // Simulate checking the variable (replace this with actual logic)
  Future.doWhile(() async {
    if (isAppInitialized) {
      controller.add(true);
      return false; // Exit the loop if the variable is true
    }
    await Future.delayed(Duration(milliseconds: 100)); // Check every 100ms
    return true;
  });
}

/// Handles notification click for agents.
Future<void> handleNotificationClickForAgent(
    GlobalKey<NavigatorState> navigatorKey,
    Map<String, dynamic> notificationData) async {
  final customerEmail = notificationData['senderId'];
  final customerName = notificationData['senderName'];
  navigatorKey.currentState?.push(
    MaterialPageRoute(
      builder: (_) => AgentChatScreen(
        customerName: customerName,
        customerEmail: customerEmail,
        agentEmail: notificationData['targetId'],
        agentName: LocalDbHelper.getProfile()?.name,
        navigatorKey: navigatorKey,
      ),
    ),
  );
}

/// Handles push notification click for agents.
Future<void> handlePushNotificationClickForAgent(
    GlobalKey<NavigatorState> navigatorKey,
    Map<String, dynamic> notificationData) async {
  final StreamController<bool> controller = StreamController<bool>();
  Timer? timer;

  // Function to trigger navigation
  void triggerNavigation() {
    // ChatStorageService chatStorageService = ChatStorageService();
    // final Map<String, dynamic> notiData = notificationData;
    // final boxName =
    //     LocalDbHelper.getProfile()!.email! + notificationData['senderId'];
    // final boxName = notificationData['targetId'] + notificationData['senderId'];

    // ChatMessageModel pushMessage = ChatMessageModel(
    //   message: notiData['message'],
    //   sender: notiData['senderId'],
    //   timestamp: DateTime.now(),
    //   form: notiData['form'] ?? {},
    //   mediaUrl: notiData['mediaUrl'] ?? "",
    //   type: notiData['type'] ?? "",
    // );

    // chatStorageService.saveMessage(pushMessage, boxName);

    final customerEmail = notificationData['senderId'];
    final customerName = notificationData['senderName'];
    final agentEmail = notificationData['targetId'];
    Navigator.push(
      navigatorKey.currentContext!,
      MaterialPageRoute(
        builder: (_) => AgentChatScreen(
          customerName: customerName,
          customerEmail: customerEmail,
          agentEmail: agentEmail,
          agentName: LocalDbHelper.getProfile()?.name,
          navigatorKey: navigatorKey,
        ),
      ),
    );
  }

  // Listen for changes to isAppInitialized
  controller.stream.listen((isInitialized) {
    if (isInitialized) {
      timer?.cancel(); // Cancel the timer if the variable becomes true
      triggerNavigation();
    }
  });

  // Start a timer to observe the variable for 20 seconds
  timer = Timer(Duration(seconds: 20), () {
    if (!controller.isClosed) {
      controller.close(); // Close the stream if the timer completes
      debugPrint("Timeout reached. App is not initialized.");
    }
  });

  // Simulate checking the variable (replace this with actual logic)
  Future.doWhile(() async {
    if (isAppInitialized) {
      controller.add(true);
      return false; // Exit the loop if the variable is true
    }
    await Future.delayed(Duration(milliseconds: 100)); // Check every 100ms
    return true;
  });
}

/// Handles incoming call notification.
/// Handles incoming call notification.
Future<void> handleIncomingCall(GlobalKey<NavigatorState> navigatorKey,
    Map<String, dynamic> callData) async {
  final StreamController<bool> controller = StreamController<bool>();
  Timer? timer;

  // Function to trigger the incoming call screen
  void triggerIncomingCall() {
    final channelName = callData['channelName'];
    final remoteUserName = callData['remoteUserName'];
    final remoteUserId = callData['remoteUserId'];
    final notificationId = callData['notificationId'];

    Navigator.push(
      navigatorKey.currentContext!,
      MaterialPageRoute(
        builder: (_) => IncomingCallScreen(
          callerName: remoteUserName,
          remoteUserId: remoteUserId,
          channelName: channelName,
          notificationId: notificationId,
        ),
      ),
    );
  }

  // Listen for changes to isAppInitialized
  controller.stream.listen((isInitialized) {
    if (isInitialized) {
      timer?.cancel(); // Cancel the timer if the variable becomes true
      triggerIncomingCall();
    }
  });

  // Start a timer to observe the variable for 20 seconds
  timer = Timer(Duration(seconds: 20), () {
    if (!controller.isClosed) {
      controller.close(); // Close the stream if the timer completes
      debugPrint("Timeout reached. App is not initialized.");
    }
  });

  // Simulate checking the variable (replace this with actual logic)
  Future.doWhile(() async {
    if (isAppInitialized) {
      controller.add(true);
      return false; // Exit the loop if the variable is true
    }
    await Future.delayed(Duration(milliseconds: 100)); // Check every 100ms
    return true;
  });
}
