import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/main.dart';
import 'package:kkpchatapp/presentation/admin/screens/internal_chat/internal_chat_screen.dart';
import 'package:kkpchatapp/presentation/common/chat/incoming_call_screen.dart';
import 'package:kkpchatapp/presentation/customer/screen/customer_chat_screen.dart';
import 'package:kkpchatapp/presentation/marketing/screen/agent_chat_screen.dart';

Future<void> _resetCustomerUnreadCount(
    GlobalKey<NavigatorState> navigatorKey, String? customerEmail) async {
  if (customerEmail == null || customerEmail.isEmpty) return;

  final boxNameWithCount = '${customerEmail}count';
  final box = await Hive.openBox<int>(boxNameWithCount);
  await box.put('count', 0);
}

/// Handles notification click for customers.
Future<void> handleNotificationClickForCustomer(
    GlobalKey<NavigatorState> navigatorKey,
    Map<String, dynamic> notificationData) async {
  debugPrint(
      'handleNotificationClickForCustomer invoked. isAppInitialized: $isAppInitialized, navigatorKey set:, navigatorStateAvailable: ${navigatorKey.currentState != null}');
  final customerEmail =
      (notificationData['targetId'] as String?) ?? LocalDbHelper.getEmail();
  if (notificationData["type"] == "product") {
    notificationData["message"] = "Shared product";
  }
  await _resetCustomerUnreadCount(navigatorKey, customerEmail);

  navigatorKey.currentState?.push(
    MaterialPageRoute(
      builder: (_) => CustomerChatScreen(
        agentName: "Agent",
        customerEmail: customerEmail,
        navigatorKey: navigatorKey,
      ),
    ),
  );
}

/// Handles push notification click for customers.
Future<void> handlePushNotificationClickForCustomer(
    GlobalKey<NavigatorState> navigatorKey,
    Map<String, dynamic> notificationData) async {
  debugPrint(
      'handlePushNotificationClickForCustomer invoked. isAppInitialized: $isAppInitialized, navigatorStateAvailable: ${navigatorKey.currentState != null}');
  final StreamController<bool> controller = StreamController<bool>();
  Timer? timer;
  // I/flutter ( 1646): 🚀@@ App Opened via Notification: {targetName: waxoc , senderName: Agent mohd 3,
  // senderId: mohdshoaibrayeen3@gmail.com, mediaUrl: , targetId: waxoc97364@cristout.com, notificationId: 686e51da4013003d981995e4, type: text, message: kedkde, timestamp: 2025-07-09T16:56:16.789956}

  // Function to trigger navigation
  void triggerNavigation() {
    final customerEmail =
        (notificationData["targetId"] as String?) ?? LocalDbHelper.getEmail();
    final agentEmail = notificationData["senderId"];
    final agentName = notificationData["senderName"];
    if (notificationData["type"] == "product") {
      notificationData["message"] = "Shared product";
    }
    if (customerEmail == null || customerEmail.isEmpty) {
      debugPrint(
          "Customer email missing in notification payload; skipping navigation.");
      return;
    }

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

    _resetCustomerUnreadCount(navigatorKey, customerEmail).whenComplete(() {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => CustomerChatScreen(
            agentName: agentName,
            customerEmail: customerEmail,
            agentEmail: agentEmail,
            navigatorKey: navigatorKey,
          ),
        ),
      );
    });
  }

  controller.stream.listen((isInitialized) {
    if (isInitialized) {
      timer?.cancel();
      controller.close();
      triggerNavigation();
    }
  });

  timer = Timer(Duration(seconds: 20), () {
    if (!controller.isClosed) {
      controller.close();
      debugPrint("Timeout reached. App is not initialized.");
    }
  });

  Future.doWhile(() async {
    if (isAppInitialized) {
      controller.add(true);
      return false;
    }
    await Future.delayed(Duration(milliseconds: 100));
    return true;
  });
}

/// Handles notification click for agents.
Future<void> handleNotificationClickForAgent(
    GlobalKey<NavigatorState> navigatorKey,
    Map<String, dynamic> notificationData) async {
  debugPrint(
      'handleNotificationClickForAgent invoked. isAppInitialized: $isAppInitialized, navigatorStateAvailable: ${navigatorKey.currentState != null}');
  if (notificationData["type"] == "product") {
    notificationData["message"] = "Shared product";
  }
  final customerEmail = notificationData['senderId'];
  final agentEmail = notificationData['targetId'];
  final customerName = notificationData['senderName'];
  await LocalDbHelper.clearUnreadCount(agentEmail, customerEmail);
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

/// Handles group chat notification tap (local notification, app in foreground/background)
Future<void> handleGroupLocalNotificationTap(
    GlobalKey<NavigatorState> navigatorKey,
    Map<String, dynamic> notificationData) async {
  debugPrint(
      "🔔 Group chat notification tapped: ${notificationData.toString()}");

  try {
    final groupId = notificationData['groupId']?.toString() ?? '';
    if (groupId.isEmpty) {
      debugPrint(
          "⚠️ handleGroupLocalNotificationTap: groupId missing in payload");
      return;
    }

    // Clear the per-group unread count now that the user is opening the chat
    await LocalDbHelper.clearGroupUnreadCount(groupId);
    await LocalDbHelper.clearGroupChatUnreadCount();

    // Use the logged-in user's own credentials, not the sender's
    final agentName = LocalDbHelper.getName() ?? '';
    final agentEmail = LocalDbHelper.getEmail() ?? '';

    if (navigatorKey.currentContext != null) {
      Navigator.push(
        navigatorKey.currentContext!,
        MaterialPageRoute(
          builder: (_) => InternalChatScreen(
            agentName: agentName,
            agentEmail: agentEmail,
            navigatorKey: navigatorKey,
            groupId: groupId,
          ),
        ),
      );
    }
  } catch (e) {
    debugPrint("❌ Error handling group chat notification tap: $e");
  }
}

/// Handles push notification click for agents.
Future<void> handlePushNotificationClickForAgent(
    GlobalKey<NavigatorState> navigatorKey,
    Map<String, dynamic> notificationData) async {
  debugPrint(
      'handlePushNotificationClickForAgent invoked. isAppInitialized: $isAppInitialized, navigatorStateAvailable: ${navigatorKey.currentState != null}');
  final StreamController<bool> controller = StreamController<bool>();
  Timer? timer;

  // Function to trigger navigation
  void triggerNavigation() async {
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
    final agentName = notificationData['targetName'];
    if (notificationData["type"] == "product") {
      notificationData["message"] = "Shared product";
    }
    await LocalDbHelper.clearUnreadCount(agentEmail, customerEmail);
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => AgentChatScreen(
          customerName: customerName,
          customerEmail: customerEmail,
          agentEmail: agentEmail,
          agentName: agentName,
          // agentName: LocalDbHelper.getProfile()?.name,
          navigatorKey: navigatorKey,
        ),
      ),
    );
  }

  controller.stream.listen((isInitialized) {
    if (isInitialized) {
      timer?.cancel();
      controller.close();
      triggerNavigation();
    }
  });

  timer = Timer(Duration(seconds: 20), () {
    if (!controller.isClosed) {
      controller.close();
      debugPrint("Timeout reached. App is not initialized.");
    }
  });

  Future.doWhile(() async {
    if (isAppInitialized) {
      controller.add(true);
      return false;
    }
    await Future.delayed(Duration(milliseconds: 100));
    return true;
  });
}

/// Handles incoming call notification.
Future<void> handleIncomingCall(GlobalKey<NavigatorState> navigatorKey,
    Map<String, dynamic> callData) async {
  debugPrint(
      'handleIncomingCall invoked. isAppInitialized: $isAppInitialized, navigatorStateAvailable: ${navigatorKey.currentState != null}');
  final StreamController<bool> controller = StreamController<bool>();
  Timer? timer;

  // Function to trigger the incoming call screen
  void triggerIncomingCall() {
    final channelName = callData['channelName'];
    final remoteUserName = callData['remoteUserName'];
    final remoteUserId = callData['remoteUserId'];
    final notificationId = callData['notificationId'];
    final callId = callData["callId"];

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => IncomingCallScreen(
          callerName: remoteUserName,
          remoteUserId: remoteUserId,
          channelName: channelName,
          notificationId: notificationId,
          callId: callId,
        ),
      ),
    );
  }

  controller.stream.listen((isInitialized) {
    if (isInitialized) {
      timer?.cancel();
      controller.close();
      triggerIncomingCall();
    }
  });

  timer = Timer(Duration(seconds: 20), () {
    if (!controller.isClosed) {
      controller.close();
      debugPrint("Timeout reached. App is not initialized.");
    }
  });

  Future.doWhile(() async {
    if (isAppInitialized) {
      controller.add(true);
      return false;
    }
    await Future.delayed(Duration(milliseconds: 100));
    return true;
  });
}

/// Handles group push notification for agents (app was killed/backgrounded)
Future<void> handleGroupPushNotification(GlobalKey<NavigatorState> navigatorKey,
    Map<String, dynamic> notificationData) async {
  final StreamController<bool> controller = StreamController<bool>();
  Timer? timer;

  // Function to trigger navigation to InternalChatScreen
  void triggerGroupNavigation() {
    final groupId = notificationData['groupId']?.toString() ?? '';
    if (groupId.isEmpty) {
      debugPrint("⚠️ handleGroupPushNotification: groupId missing in payload");
      return;
    }

    // Use the logged-in user's own credentials, not the sender's
    final agentName = LocalDbHelper.getName() ?? '';
    final agentEmail = LocalDbHelper.getEmail() ?? '';

    LocalDbHelper.clearGroupUnreadCount(groupId);
    LocalDbHelper.clearGroupChatUnreadCount();

    Navigator.push(
      navigatorKey.currentContext!,
      MaterialPageRoute(
        builder: (_) => InternalChatScreen(
          agentName: agentName,
          agentEmail: agentEmail,
          navigatorKey: navigatorKey,
          groupId: groupId,
        ),
      ),
    );
  }

  controller.stream.listen((isInitialized) {
    if (isInitialized) {
      timer?.cancel();
      controller.close();
      triggerGroupNavigation();
    }
  });

  timer = Timer(const Duration(seconds: 20), () {
    if (!controller.isClosed) {
      controller.close();
      debugPrint("Timeout reached. App is not initialized.");
    }
  });

  Future.doWhile(() async {
    if (isAppInitialized) {
      controller.add(true);
      return false;
    }
    await Future.delayed(const Duration(milliseconds: 100));
    return true;
  });
}
