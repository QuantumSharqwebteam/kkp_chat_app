import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kkpchatapp/core/network/auth_api.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _notificationClicked = false;
  static GlobalKey<NavigatorState>? navigatorKey;

  static Future<void> init(
      BuildContext context, GlobalKey<NavigatorState> navKey) async {
    navigatorKey = navKey;
    await _initializeLocalNotifications();
    if (context.mounted) {
      bool isGranted = await _requestPermission(context);
      if (isGranted) {
        await _checkAndUpdateFCMToken();
        _setupForegroundNotification();
        _setupBackgroundNotification();
        _setupTerminatedNotification();

        _messaging.onTokenRefresh.listen((newToken) async {
          debugPrint("🔄 [FCM Token Refreshed]: $newToken");
          await _checkAndUpdateFCMToken(newToken: newToken);
        });
      } else {
        if (context.mounted) {
          _showPermissionDialog(context);
        }
      }
    }
  }

  static void _setupTerminatedNotification() {
    Future.delayed(const Duration(milliseconds: 500), () {
      FirebaseMessaging.instance
          .getInitialMessage()
          .then((RemoteMessage? message) {
        if (message != null) {
          debugPrint(
              "🚀 App Opened via Notification: ${message.notification?.body}");
          _handleNotificationClick(message);
        }
      });
    });
  }

  static void _setupBackgroundNotification() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint(
          "🔔 Notification Clicked (Background): ${message.notification?.title}");
      _handleNotificationClick(message);
    });
  }

  static void _handleNotificationClick(RemoteMessage message) {
    if (_notificationClicked) {
      debugPrint("Duplicate notification click ignored.");
      return;
    }

    _notificationClicked = true;

    final Map<String, dynamic> notificationData = message.data;
    debugPrint('notification: $notificationData');
  }

  static void _setupForegroundNotification() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint("📩 Foreground Notification: ${message.notification?.body}");

      if (message.notification != null) {
        const AndroidNotificationDetails androidNotificationDetails =
            AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription: 'This channel is for important notifications',
          importance: Importance.high,
          priority: Priority.high,
        );

        const NotificationDetails notificationDetails =
            NotificationDetails(android: androidNotificationDetails);

        await _localNotificationsPlugin.show(
          message.notification.hashCode,
          message.notification?.body,
          message.data['message'],
          notificationDetails,
          payload: message.data['type'],
        );
      }
    });
  }

  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotificationsPlugin.initialize(initializationSettings);

    // Create a notification channel for Android 8.0 and above
    const AndroidNotificationChannel androidNotificationChannel =
        AndroidNotificationChannel(
      'high_importance_channel', // ID of the channel
      'High Importance Notifications', // Name of the channel
      description: 'This channel is for important notifications',
      importance: Importance.high,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidNotificationChannel);
  }

  static Future<bool> _requestPermission(BuildContext context) async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ User granted notification permission');
      return true;
    } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('❌ User denied notification permission');
      if (context.mounted) {
        _showPermissionDialog(context);
      }
      return false;
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('⚠️ Provisional permission granted');
      return true;
    }

    return false;
  }

  static void _showPermissionDialog(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible:
            false, // Prevent dismissing the dialog by tapping outside
        builder: (context) {
          return AlertDialog(
            title: const Text("Enable Notifications"),
            content: const Text(
                "Notifications are required for the app to function properly. Please enable them in settings."),
            actions: [
              TextButton(
                onPressed: () {
                  openAppSettings();
                },
                child: const Text("Open Settings"),
              ),
              TextButton(
                onPressed: () async {
                  PermissionStatus status =
                      await Permission.notification.status;
                  if (status.isGranted && context.mounted) {
                    Navigator.pop(context);
                    // _initializeNotificationService(context);
                  } else {
                    debugPrint('❌ User still denied notification permission');
                  }
                },
                child: const Text("Re-check Permission"),
              ),
            ],
          );
        },
      );
    });
  }

  // static Future<void> _initializeNotificationService(
  //     BuildContext context) async {
  //   await _checkAndUpdateFCMToken();
  //   _setupForegroundNotification();
  //   _setupBackgroundNotification();
  //   _setupTerminatedNotification();

  //   _messaging.onTokenRefresh.listen((newToken) async {
  //     debugPrint("🔄 [FCM Token Refreshed]: $newToken");
  //     await _checkAndUpdateFCMToken(newToken: newToken);
  //   });
  // }

  static Future<void> _checkAndUpdateFCMToken({String? newToken}) async {
    AuthApi auth = AuthApi();
    debugPrint("🔑 CHECKING FCM TOKEN ##########");
    try {
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
    await _messaging.deleteToken().whenComplete(() {
      debugPrint("FCM Token deleted");
    });
  }
}
