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
  static bool _notificationClicked = false;
  static GlobalKey<NavigatorState>? navigatorKey;
  static Function(String?, String?, String?)? onNotificationTap;
  static AppLifecycleState? appLifecycleState;

  // Initialize notification service
  static Future<void> init(
      BuildContext context, GlobalKey<NavigatorState> navKey,
      {Function(String?, String?, String?)? onNotificationClick}) async {
    navigatorKey = navKey;
    onNotificationTap = onNotificationClick;

    WidgetsBinding.instance.addObserver(NotificationService());
    await _initializeLocalNotifications();
    if (context.mounted) {
      bool isGranted = await requestPermission(context);
      if (isGranted) {
        await checkAndUpdateFCMToken();
        _setupBackgroundNotification();
        _setupTerminatedNotification();

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
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint(
          "🔔 Notification Clicked (Background): ${message.notification?.title}");
      _handleBackgroundMessage(message);
      handleNotificationClick(message);
    });
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    final Map<String, dynamic> notificationData = message.data;
    debugPrint('notification: $notificationData');

    // Extract necessary data from the message using the correct keys
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

        if (customerEmail != null) {
          // Save the message to Hive local storage
          // final message = ChatMessageModel(
          //   message: notificationData["message"],
          //   timestamp: DateTime.parse(DateTime.now().toIso8601String()),
          //   sender: notificationData["senderId"],
          //   type: notificationData["type"],
          //   mediaUrl: notificationData["mediaUrl"],
          //   form: notificationData["form"],
          // );

          //   chatStorageService.saveMessage(message, customerEmail);
        }

        // if (isAppInitialized) {
        //   handlePushNotificationClickForCustomer(
        //       navigatorKey!, notificationData);
        // }
      }
      // if ("0" != await LocalDbHelper.getUserType()) {
      //   if (isAppInitialized) {
      //     handlePushNotificationClickForAgent(navigatorKey!, notificationData);
      //   }
      // }
    });
  }

  static Future<void> _setupTerminatedNotification() async {
    RemoteMessage? message =
        await FirebaseMessaging.instance.getInitialMessage();

    if (message != null) {
      // debugPrint("🚀 full message data: ${message.toMap()}");
      debugPrint(
          "🚀@@ App Opened via Notification: ${message.toMap()['data']}");

      final data = message.toMap()['data'];
      final customerEmail = data['targetId'];
      final agentEmail = data["senderId"];

      // Check if the notification data contains a call
      if (data != null && data['call'] == "true") {
        // Handle the incoming call
        handleIncomingCall(navigatorKey!, data);
      } else {
        // Handle regular notification click
        if ("0" == await LocalDbHelper.getUserType()) {
          handlePushNotificationClickForCustomer(navigatorKey!, data);
        } else {
          LocalDbHelper.clearUnreadCount(agentEmail, customerEmail);
          handlePushNotificationClickForAgent(navigatorKey!, data);
        }
      }
    }
  }

  // Setup foreground notifications (when the app is in the foreground)
  // static void _setupForegroundNotification() {
  //   FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
  //     debugPrint("📩 Foreground Notification: ${message.notification?.body}");

  //     if (_appLifecycleState == AppLifecycleState.resumed) {
  //       // App is in the foreground, do not show local notification
  //       return;
  //     }

  //     if (message.notification != null) {
  //       const AndroidNotificationDetails androidNotificationDetails =
  //           AndroidNotificationDetails(
  //         'high_importance_channel',
  //         'High Importance Notifications',
  //         channelDescription: 'This channel is for important notifications',
  //         importance: Importance.high,
  //         priority: Priority.high,
  //       );

  //       const NotificationDetails notificationDetails =
  //           NotificationDetails(android: androidNotificationDetails);

  //       await _localNotificationsPlugin.show(
  //         message.notification.hashCode,
  //         message.notification?.title,
  //         message.notification?.body,
  //         notificationDetails,
  //         payload: jsonEncode(message.data),
  //       );
  //     }
  //   });
  // }

  // Method to show incoming call notification
  static Future<void> showIncomingCallNotification(String callerName) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'call_channel_id',
      'Call Notifications',
      channelDescription:
          'This channel is used for incoming call notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(
          'incoming_call'), // Use your custom sound file for Android
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'incoming_call.mp3', // Use your custom sound file for iOS
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotificationsPlugin.show(
      0,
      'Incoming Call',
      'Incoming call from $callerName',
      platformChannelSpecifics,
      payload: 'incoming_call',
    );
  }

  // Initialize local notifications plugin
  // static Future<void> _initializeLocalNotifications() async {
  //   const AndroidInitializationSettings initializationSettingsAndroid =
  //       AndroidInitializationSettings('@mipmap/ic_launcher');

  //   // ✅ iOS/macOS-specific initialization
  //   const DarwinInitializationSettings initializationSettingsDarwin =
  //       DarwinInitializationSettings(
  //     requestAlertPermission: true,
  //     requestSoundPermission: true,
  //     requestBadgePermission: true,
  //     defaultPresentAlert: true,
  //     defaultPresentSound: true,
  //     defaultPresentBadge: true,
  //     defaultPresentBanner: true,
  //     defaultPresentList: true,
  //   );

  //   const InitializationSettings initializationSettings =
  //       InitializationSettings(
  //     android: initializationSettingsAndroid,
  //     iOS: initializationSettingsDarwin,
  //   );

  //   await _localNotificationsPlugin.initialize(initializationSettings,
  //       onDidReceiveNotificationResponse: (NotificationResponse response) {
  //     _handleNotificationTap(response);
  //   });

  //   // Create notification channel for Android 8.0 and above
  //   const AndroidNotificationChannel androidNotificationChannel =
  //       AndroidNotificationChannel(
  //     'high_importance_channel',
  //     'High Importance Notifications',
  //     description: 'This channel is for important notifications',
  //     importance: Importance.high,
  //   );

  //   await _localNotificationsPlugin
  //       .resolvePlatformSpecificImplementation<
  //           AndroidFlutterLocalNotificationsPlugin>()
  //       ?.createNotificationChannel(androidNotificationChannel);
  // }

  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

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
      // ✅ Default notification channel (optional)
      const AndroidNotificationChannel defaultChannel =
          AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is for important notifications',
        importance: Importance.high,
      );
      await androidPlugin.createNotificationChannel(defaultChannel);

      // ✅ Call notification channel with custom sound
      const AndroidNotificationChannel callChannel = AndroidNotificationChannel(
        'call_channel_id',
        'Call Notifications',
        description: 'This channel is used for incoming call notifications',
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound(
            'incoming_call'), // 👈 without .mp3
        playSound: true,
      );
      await androidPlugin.createNotificationChannel(callChannel);
    }
  }

  // Handle notification tap
  static Future<void> _handleNotificationTap(
      NotificationResponse response) async {
    debugPrint("Notification tapped: ${response.payload}");

    if (response.payload != null) {
      final Map<String, dynamic> notificationData =
          jsonDecode(response.payload!);

      if ("0" == await LocalDbHelper.getUserType()) {
        if (isAppInitialized) {
          handlePushNotificationClickForCustomer(
              navigatorKey!, notificationData);
        }
      } else {
        if (isAppInitialized) {
          handlePushNotificationClickForAgent(navigatorKey!, notificationData);
        }
      }
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