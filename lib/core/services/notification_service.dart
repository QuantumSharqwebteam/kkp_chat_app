import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kkpchatapp/data/api/auth_service.dart';
//import 'package:kkpchatapp/core/services/chat_storage_service.dart';
import 'package:kkpchatapp/core/services/handle_notification_clicks.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
// import 'package:kkpchatapp/data/models/chat_message_model.dart';
import 'package:kkpchatapp/main.dart';
//import 'package:permission_handler/permission_handler.dart';

class NotificationService with WidgetsBindingObserver {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  // Public accessor for other services to reuse the same plugin instance
  static FlutterLocalNotificationsPlugin get plugin =>
      _localNotificationsPlugin;
  static bool _notificationClicked = false;
  static NotificationService? _observer;
  static GlobalKey<NavigatorState>? navigatorKey;
  static Function(String?, String?, String?)? onNotificationTap;
  static AppLifecycleState? appLifecycleState;
  // Queue for push notifications received while app is initializing/terminated
  static final List<Map<String, dynamic>> _pendingPushNotifications = [];
  static Timer? pendingProcessorTimer;
  static bool _pendingProcessorRunning = false;

  // Initialize notification service
  static Future<void> init(
      BuildContext context, GlobalKey<NavigatorState> navKey,
      {Function(String?, String?, String?)? onNotificationClick}) async {
    // Only set the navigatorKey and onNotificationTap if they aren't set
    // yet. Some screens (e.g., MarketingHost) also call init — we must not
    // overwrite the app root navigator key with a nested navigator.
    navigatorKey ??= navKey;
    onNotificationTap ??= onNotificationClick;

    if (_observer == null) {
      _observer = NotificationService();
      WidgetsBinding.instance.addObserver(_observer!);
    }
    await _initializeLocalNotifications();
    if (context.mounted) {
      bool isGranted = await requestPermission(context);
      if (isGranted) {
        await checkAndUpdateFCMToken();
        _setupBackgroundNotification();
        // Initial message from terminated state is handled by main.dart
        // via handleInitialMessage() — no need to call getInitialMessage() here.

        _messaging.onTokenRefresh.listen((newToken) async {
          debugPrint("🔄 [FCM Token Refreshed]: $newToken");
          await checkAndUpdateFCMToken(newToken: newToken);
        });
      } else {
        // if (context.mounted) {
        //   showPermissionDialog();
        // }
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    appLifecycleState = state;
    super.didChangeAppLifecycleState(state);
  }

  // Setup for background notifications (when the app is in the background)
  static void _setupBackgroundNotification() {
    // Foreground FCM messages — log full payload for debugging
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('═══════════════════════════════════════════════');
      debugPrint('📲 [FCM FOREGROUND] message received');
      debugPrint('   messageId   : ${message.messageId}');
      debugPrint('   from        : ${message.from}');
      debugPrint('   notification: title="${message.notification?.title}" body="${message.notification?.body}"');
      debugPrint('   data        : ${message.data}');
      debugPrint('═══════════════════════════════════════════════');
      // Foreground chat/call notifications are handled by the socket service.
      // No local notification shown here to avoid duplicates.
    });

    // Notification tapped while app was in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('═══════════════════════════════════════════════');
      debugPrint('🔔 [FCM TAP / Background→Foreground]');
      debugPrint('   messageId   : ${message.messageId}');
      debugPrint('   from        : ${message.from}');
      debugPrint('   notification: title="${message.notification?.title}" body="${message.notification?.body}"');
      debugPrint('   data        : ${message.data}');
      debugPrint('═══════════════════════════════════════════════');
      _handleBackgroundMessage(message);
      handleNotificationClick(message);
    });
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    final Map<String, dynamic> notificationData = message.data;
    debugPrint('📦 [FCM handleBackgroundMessage] data: $notificationData');

    // Call notifications must not increment chat unread counts
    if (notificationData['call'] == 'true') {
      debugPrint('📞 [FCM handleBackgroundMessage] call notification — skipping unread increment');
      return;
    }

    final String? customerEmail = notificationData['senderId'];
    final String? agentEmail = notificationData['targetId'];

    if (customerEmail != null && agentEmail != null) {
      await LocalDbHelper.incrementUnreadCount(agentEmail, customerEmail);
    }
  }

  // Handle notification clicks (both background and terminated)
  static Future<void> handleNotificationClick(RemoteMessage message) async {
    if (_notificationClicked) {
      debugPrint("Duplicate notification click ignored.");
      return;
    }

    _notificationClicked = true;

    final Map<String, dynamic> notificationData = message.data;
    debugPrint('notification: $notificationData');

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if ("0" == await LocalDbHelper.getUserType()) {
        // ChatStorageService chatStorageService =
        //     ChatStorageService(); // Get the customer's email
        final customerEmail = LocalDbHelper.getEmail();

        if (customerEmail != null) {}
      }
    });
  }

  // Public helper to handle an initial RemoteMessage (from main).
  // This ensures the same enqueue/handle logic used for other terminated
  // notifications is applied.
  static Future<void> handleInitialMessage(RemoteMessage message) async {
    try {
      final data = message.data;
      final notificationType = data['notificationType'] ?? 'individual';

      if (notificationType == 'group') {
        await _enqueueOrHandlePushNotification(data, isGroup: true);
      } else {
        if (data['call'] == "true") {
          await _enqueueOrHandlePushNotification(data, isCall: true);
        } else {
          await _enqueueOrHandlePushNotification(data);
        }
      }
    } catch (e) {
      debugPrint('❌ Error in handleInitialMessage: $e');
    }
  }

  static Future<void> _enqueueOrHandlePushNotification(
      Map<String, dynamic> data,
      {bool isGroup = false,
      bool isCall = false}) async {
    // If app is ready and navigator available, handle immediately
    if (navigatorKey != null &&
        isAppInitialized == true &&
        navigatorKey!.currentState != null) {
      try {
        final customerEmail = data['targetId'];
        final agentEmail = data['senderId'];
        if (isGroup) {
          await handleGroupPushNotification(navigatorKey!, data);
          return;
        }

        if (isCall) {
          // Do nothing else — just ensure app opens
          return;
        }

        if ("0" == await LocalDbHelper.getUserType()) {
          await handlePushNotificationClickForCustomer(navigatorKey!, data);
        } else {
          await LocalDbHelper.clearUnreadCount(agentEmail, customerEmail);
          await handlePushNotificationClickForAgent(navigatorKey!, data);
        }
      } catch (e) {
        debugPrint('❌ Error processing push notification immediately: $e');
      }
      return;
    }

    // Otherwise enqueue and start processor
    debugPrint('⚠️ App not ready — enqueueing push notification: $data');
    _pendingPushNotifications.add(data);
    _startPendingProcessor();
  }

  static void _startPendingProcessor() {
    if (_pendingProcessorRunning) return;
    _pendingProcessorRunning = true;
    pendingProcessorTimer =
        Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (navigatorKey != null &&
          isAppInitialized == true &&
          navigatorKey!.currentState != null) {
        debugPrint(
            '✅ App initialized — processing ${_pendingPushNotifications.length} queued notifications');
        // Drain the queue
        final List<Map<String, dynamic>> toProcess =
            List.from(_pendingPushNotifications);
        _pendingPushNotifications.clear();
        for (final data in toProcess) {
          try {
            final customerEmail = data['targetId'];
            final agentEmail = data['senderId'];
            if (data['notificationType'] == 'group' ||
                data['isGroupMessage'] == true) {
              await handleGroupPushNotification(navigatorKey!, data);
            } else if (data['call'] == 'true') {
              // nothing more to do — overlay is shown by socket event
            } else {
              if ("0" == await LocalDbHelper.getUserType()) {
                await handlePushNotificationClickForCustomer(
                    navigatorKey!, data);
              } else {
                await LocalDbHelper.clearUnreadCount(agentEmail, customerEmail);
                await handlePushNotificationClickForAgent(navigatorKey!, data);
              }
            }
          } catch (e) {
            debugPrint('❌ Error processing queued notification: $e');
          }
        }

        timer.cancel();
        pendingProcessorTimer = null;
        _pendingProcessorRunning = false;
      }
    });
  }

  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_logo');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
      requestBadgePermission: true,
      defaultPresentAlert: true,
      defaultPresentSound: true,
      defaultPresentBadge: true,
      defaultPresentBanner: true,
      defaultPresentList: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response);
      },
    );

    final androidPlugin =
        _localNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      const AndroidNotificationChannel defaultChannel =
          AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is for important notifications',
        importance: Importance.high,
      );
      await androidPlugin.createNotificationChannel(defaultChannel);

      // The backend tags call FCM messages with channel_id = call_channel_id.
      // We use Importance.low so Android does NOT show a heads-up banner —
      // the CallKit / full-screen notification already handles the call UI.
      const AndroidNotificationChannel callChannel = AndroidNotificationChannel(
        'call_channel_id',
        'Call Notifications',
        description: 'Suppressed — CallKit handles the incoming call UI',
        importance: Importance.low,
      );
      await androidPlugin.createNotificationChannel(callChannel);
    }
  }

  // Handle notification tap
  static Future<void> _handleNotificationTap(
      NotificationResponse response) async {
    debugPrint("Notification tapped: ${response.payload}");

    if (response.payload == null) {
      debugPrint("Notification payload is null");
      return;
    }

    // For simple control payloads (non-JSON) we handle them explicitly
    if (response.payload == 'incoming_call') {
      debugPrint('Incoming call notification tapped — app opened, CallKit handles the rest.');
      // flutter_callkit_incoming manages the call UI; the onEvent stream in
      // CallKitService will fire actionCallAccept/Decline as needed.
      return;
    }

    if (response.payload == 'general_chat_summary') {
      debugPrint('Summary notification tapped — opening app only.');
      return;
    }

    // Attempt to parse JSON payloads only
    if (response.payload is String) {
      Map<String, dynamic> notificationData;
      try {
        notificationData = jsonDecode(response.payload!);
      } catch (e) {
        debugPrint('Failed to parse notification payload as JSON: $e');
        return;
      }

      if (navigatorKey == null) {
        debugPrint(
            '⚠️ navigatorKey not set yet; cannot handle notification tap.');
        return;
      }

      try {
        // Group messages may be handled via a separate flow
        if (notificationData['isGroupMessage'] == true) {
          await handleGroupLocalNotificationTap(
              navigatorKey!, notificationData);
          return;
        }

        if ("0" == await LocalDbHelper.getUserType()) {
          await handlePushNotificationClickForCustomer(
              navigatorKey!, notificationData);
        } else {
          await handlePushNotificationClickForAgent(
              navigatorKey!, notificationData);
        }
      } catch (e) {
        debugPrint('❌ Error handling notification tap: $e');
      }
    } else {
      debugPrint(
          'Unhandled notification payload type: ${response.payload.runtimeType}');
    }
  }

  // Request notification permission
  static Future<bool> requestPermission(BuildContext context) async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    switch (settings.authorizationStatus) {
      case AuthorizationStatus.authorized:
        debugPrint('✅ User granted notification permission');
        return true;
      case AuthorizationStatus.provisional:
        debugPrint('⚠️ Provisional permission granted');
        return true;
      case AuthorizationStatus.denied:
      case AuthorizationStatus.notDetermined:
        debugPrint('❌ User denied or did not determine permission');
        return false;
    }
  }

  // Show permission dialog if notification permissions are denied
  // static void showPermissionDialog() {
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     final context = navigatorKey?.currentContext;

  //     if (context == null || !context.mounted) {
  //       debugPrint(
  //           "⚠️ Cannot show permission dialog: Context not ready or unmounted.");
  //       return;
  //     }

  //     showDialog(
  //       context: context,
  //       barrierDismissible: false,
  //       builder: (context) {
  //         return AlertDialog(
  //           title: const Text("Enable Notifications"),
  //           content: const Text(
  //               "Notifications are required for the app to function properly. Please enable them in settings."),
  //           actions: [
  //             TextButton(
  //               onPressed: () {
  //                 openAppSettings();
  //               },
  //               child: const Text("Open Settings"),
  //             ),
  //             TextButton(
  //               onPressed: () async {
  //                 PermissionStatus status =
  //                     await Permission.notification.status;
  //                 if (context.mounted && status.isGranted) {
  //                   Navigator.of(context).pop();
  //                 } else {
  //                   debugPrint('❌ User still denied notification permission');
  //                 }
  //               },
  //               child: const Text("Re-check Permission"),
  //             ),
  //           ],
  //         );
  //       },
  //     );
  //   });
  // }

  static Future<void> checkAndUpdateFCMToken({String? newToken}) async {
    final AuthApi auth = AuthApi();
    debugPrint("🔑 CHECKING FCM TOKEN ##########");
    try {
      // ✅ Only for iOS: wait until APNs token is available
      if (Platform.isIOS) {
        String? apnsToken = await _messaging.getAPNSToken();
        if (kDebugMode) {
          debugPrint("🍏 apn toke: $apnsToken");
        }
        if (apnsToken == null) {
          debugPrint(
              "❌ [iOS] APNs token not yet available. Aborting FCM token fetch.");
          return; // Wait and retry later
        }
      }

      String? currentToken;
      if (newToken == null) {
        currentToken = await _messaging.getToken();
      } else {
        currentToken = newToken;
      }

      if (currentToken != null) {
        String? savedToken = LocalDbHelper.getFCMToken();
        if (savedToken != currentToken) {
          debugPrint("🔑 [FCM Token Changed/New]: $currentToken");
          final response = await auth.updateFCMToken(currentToken);
          debugPrint(response.toString());
          await LocalDbHelper.saveFCMToken(currentToken);
        } else {
          debugPrint("🔑 [FCM Token Unchanged]: $currentToken");
        }
      } else {
        debugPrint("❌ [Error] Failed to get FCM token");
      }
    } catch (e) {
      debugPrint("❌ [Error] Sending/Checking FCM Token: $e");
    }
  }

  static Future<void> deleteFCMToken() async {
    try {
      await _messaging.deleteToken();
      await LocalDbHelper.clearFCMToken();
      debugPrint("🧹 FCM Token deleted and local token cleared.");
    } catch (e) {
      debugPrint("❌ Failed to delete FCM token: $e");
    }
  }
}
