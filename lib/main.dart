import 'dart:convert';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kkpchatapp/config/routes/customer_routes.dart';
import 'package:kkpchatapp/config/routes/marketing_routes.dart';
import 'package:kkpchatapp/config/theme/theme.dart';
import 'package:kkpchatapp/core/services/call_kit_service.dart';
import 'package:kkpchatapp/core/services/logging_service.dart';
import 'package:kkpchatapp/core/services/notification_service.dart';
import 'package:kkpchatapp/data/api/auth_service.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/repositories/chat_reopsitory.dart';
import 'package:kkpchatapp/data/repositories/product_repository.dart';
import 'package:kkpchatapp/l10n/generated/app_localizations.dart';
import 'package:kkpchatapp/logic/agent/agent_provider.dart';
import 'package:kkpchatapp/logic/agent/chat_refresh_provider.dart';
import 'package:kkpchatapp/logic/agent/group_provider.dart';
import 'package:kkpchatapp/logic/agent/inquiry_provider.dart';
import 'package:kkpchatapp/logic/agent/complaints_provider.dart';
import 'package:kkpchatapp/logic/agent/marketing_product_provider.dart';
import 'package:kkpchatapp/logic/agent/notification_provider.dart';
import 'package:kkpchatapp/core/services/socket_service.dart';
import 'package:kkpchatapp/logic/app_state_provider.dart';
import 'package:kkpchatapp/logic/auth/forgot_pass_provider.dart';
import 'package:kkpchatapp/logic/auth/login_provider.dart';
import 'package:kkpchatapp/logic/auth/new_pass_provider.dart';
import 'package:kkpchatapp/logic/auth/signup_provider.dart';
import 'package:kkpchatapp/logic/auth/verification_provider.dart';
import 'package:kkpchatapp/logic/customer/customer_home_provider.dart';
import 'package:kkpchatapp/logic/customer/customer_product_provider.dart';
import 'package:kkpchatapp/logic/locale/locale_provider.dart';
import 'package:kkpchatapp/logic/meeting/meet_management.dart';
import 'package:kkpchatapp/presentation/common/auth/login_page.dart';
import 'package:kkpchatapp/presentation/common/chat/call_provider.dart';
import 'package:kkpchatapp/presentation/common/chat/chat_status_provider.dart';
import 'package:kkpchatapp/presentation/common/splash.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:kkpchatapp/core/services/connectivity_service.dart';
import 'package:kkpchatapp/core/utils/route_observer.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'firebase_options.dart';

// Global flag to indicate if the app is initialized
bool isAppInitialized = false;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ── Full payload log — use this to debug terminated/background state ────────
  debugPrint('═══════════════════════════════════════════════════════════');
  debugPrint('🔥 [FCM BACKGROUND HANDLER] triggered');
  debugPrint('   messageId        : ${message.messageId}');
  debugPrint('   from             : ${message.from}');
  debugPrint('   sentTime         : ${message.sentTime}');
  debugPrint('   notification.title: ${message.notification?.title}');
  debugPrint('   notification.body : ${message.notification?.body}');
  debugPrint('   data (full)      : ${message.data}');
  debugPrint('═══════════════════════════════════════════════════════════');

  // Local notifications plugin for the background isolate
  final FlutterLocalNotificationsPlugin bgLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  try {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('app_logo');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await bgLocalNotificationsPlugin.initialize(initSettings);
  } catch (e) {
    debugPrint('❌ Error initializing local notifications in background: $e');
  }

  // ── Call detection ──────────────────────────────────────────────────────────
  // Backend sends call: "true" in the FCM data payload for incoming calls.
  final bool isCallNotification = message.data['call'] == 'true';

  if (isCallNotification) {
    debugPrint(
        '📞 [FCM BG] Detected incoming call — showing native CallKit UI');
    try {
      final callId = message.data['callId'] ??
          DateTime.now().millisecondsSinceEpoch.toString();
      // Backend uses remoteUserName / remoteUserId; fall back to older names
      final callerName = message.data['remoteUserName'] ??
          message.data['callerName'] ??
          'Incoming Call';
      final callerId =
          message.data['remoteUserId'] ?? message.data['callerId'] ?? '';
      final channelName = message.data['channelName'] ?? '';

      // The backend does not embed the agent uid in FCM payloads — it's derived
      // client-side from the agent's email hash.  We must open Hive here
      // (background isolate has no shared state) and compute it ourselves;
      // falling back to 0 causes HTTP 400 on Agora token requests and then
      // the stale CallKit notification triggers a memory leak on next start.
      int uid = 0;
      try {
        await Hive.initFlutter();
        await Hive.openBox('CREDENTIALS');
        final email = LocalDbHelper.getEmail();
        if (email != null && email.isNotEmpty) {
          uid = Utils().generateIntUidFromEmail(email);
        }
      } catch (_) {
        // Hive unavailable in this isolate — fall back to FCM payload value
        uid = int.tryParse(message.data['uid'] ?? '') ?? 0;
      }

      debugPrint('   callId     : $callId');
      debugPrint('   callerName : $callerName');
      debugPrint('   callerId   : $callerId');
      debugPrint('   channelName: $channelName');
      debugPrint('   uid        : $uid');

      final params = CallKitParams(
        id: callId,
        nameCaller: callerName,
        handle: callerName,
        type: 0,
        appName: 'KKP Group',
        ios: const IOSParams(
          handleType: 'generic',
          supportsHolding: false,
          supportsGrouping: false,
          supportsUngrouping: false,
          supportsDTMF: false,
          iconName: 'AppIcon',
          ringtonePath: 'system_ringtone_default',
        ),
        android: const AndroidParams(
          isCustomNotification: true,
          isShowLogo: false,
          ringtonePath: 'system_ringtone_default',
          backgroundColor: '#0B3D91',
          actionColor: '#4CAF50',
          textColor: '#ffffff',
          isCustomSmallExNotification: true,
        ),
        extra: {
          'channelName': channelName,
          'callerName': callerName,
          'callerId': callerId,
          'uid': uid.toString(),
        },
      );
      await FlutterCallkitIncoming.showCallkitIncoming(params);
      debugPrint('✅ [FCM BG] CallKit showCallkitIncoming completed');
    } catch (e) {
      debugPrint('❌ [FCM BG] Error showing CallKit: $e');
    }
    return;
  }

  final String role = message.data['role'] ?? 'agent';
  final String notificationType =
      message.data['notificationType'] ?? 'individual';
  debugPrint(
      '📨 [FCM BG] Chat message — role: $role, notificationType: $notificationType');

  try {
    await Hive.initFlutter();

    if (notificationType == 'group') {
      // Handle group chat notification
      await LocalDbHelper.incrementGroupChatUnreadCount();
      debugPrint("📈 Incremented group chat unread count");

      // Show a local notification for group messages
      try {
        final title = "Internal Chat Update";
        final body = message.data['message'] ?? 'New group message';
        const androidDetails = AndroidNotificationDetails(
          'group_chat_channel_id',
          'Internal Chat Notifications',
          channelDescription: 'Notifications for internal team chat messages',
          importance: Importance.max,
          priority: Priority.high,
        );
        const iosDetails = DarwinNotificationDetails(
            presentAlert: true, presentBadge: true, presentSound: true);
        final notificationDetails =
            NotificationDetails(android: androidDetails, iOS: iosDetails);
        await bgLocalNotificationsPlugin.show(
            1001, title, body.toString(), notificationDetails,
            payload: jsonEncode({
              'isGroupMessage': true,
              'notificationType': 'groupChat',
              ...message.data
            }));
      } catch (e) {
        debugPrint('❌ Error showing group notification in background: $e');
      }
    } else {
      // Handle direct chat notification
      final String customerEmail;
      final String agentEmail;

      if (role == 'User') {
        customerEmail = message.data['senderId'];
        agentEmail = message.data['targetId'];
      } else {
        customerEmail = message.data['targetId'];
        agentEmail = message.data['senderId'];
      }

      if (role == 'User') {
        final box = await Hive.openBox<int>(
            '${LocalDbHelper.unreadCountsBoxKey}_$agentEmail');
        final currentCount = box.get(customerEmail, defaultValue: 0);
        await box.put(customerEmail, currentCount! + 1);
        debugPrint(
            "📈 Unread count incremented for customerEmail: $customerEmail");
      } else {
        final userBoxName = '${customerEmail}count';
        final userBox = await Hive.openBox<int>(userBoxName);
        final currentCount = userBox.get('count', defaultValue: 0);
        await userBox.put('count', currentCount! + 1);
        debugPrint("📈 Unread count incremented for user: $customerEmail");
      }

      // Show a local notification for direct chat messages when in background
      try {
        final title = (role == 'User')
            ? 'New Message from Customer'
            : 'New Message from Agent';
        final body = message.data['type'] == 'product'
            ? 'Shared product'
            : (message.data['message'] ?? 'New message');
        const androidDetails = AndroidNotificationDetails(
          'your_channel_id',
          'your_channel_name',
          channelDescription: 'your_channel_description',
          importance: Importance.max,
          priority: Priority.high,
        );
        const iosDetails = DarwinNotificationDetails(
            presentAlert: true, presentBadge: true, presentSound: true);
        final notificationDetails =
            NotificationDetails(android: androidDetails, iOS: iosDetails);
        final payload = jsonEncode(message.data);
        final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
        await bgLocalNotificationsPlugin.show(
            id, title, body.toString(), notificationDetails,
            payload: payload);
      } catch (e) {
        debugPrint('❌ [FCM BG] Error showing chat notification: $e');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint("❌ Error initializing Hive or updating count: $e");
    }
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  // Initialize logging service
  await LoggingService.instance.initialize();

  await Future.wait([
    Hive.openBox('CREDENTIALS'),
    Hive.openBox("lastSeenTimeBox"),
    Hive.openBox('feedBox'),
    Hive.openBox("lastMessageMap"),
    Hive.openBox("inquiryFormsBox"),
    Hive.openBox(LocalDbHelper.groupLastMessageBoxKey),
    Hive.openBox<int>(LocalDbHelper.groupChatUnreadCountKey),
    Hive.openBox<int>(LocalDbHelper.groupUnreadCountsBoxKey),
    dotenv.load(fileName: "keys.env"),
  ]);

  await ConnectivityService.instance.initialize();
  if (ConnectivityService.instance.isOnline) {
    await AuthApi.prefetchAwsKeys();
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }

  // Init native call UI service (CallKit on iOS, ConnectionService on Android)
  CallKitService.instance.init();

  // Set the global flag to true after initialization
  // isAppInitialized = true;
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  // Handle terminated state
  RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();

  runApp(
    // AppStateProvider must sit above MyApp so initState can read readiness
    ChangeNotifierProvider(
      create: (_) => AppStateProvider(),
      child: MyApp(navigatorKey: navigatorKey, initialMessage: initialMessage),
    ),
  );
}

class MyApp extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final RemoteMessage? initialMessage;

  const MyApp({super.key, required this.navigatorKey, this.initialMessage});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    NotificationService.init(context, widget.navigatorKey);

    // Handle the initial message if the app was opened via a notification.
    // Wait for AppStateProvider to mark the app as ready (Splash -> Host finished),
    // otherwise queue processing in NotificationService.
    if (widget.initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          // Wait up to ~5 seconds for provider to become available and app to be ready
          int attempts = 0;
          while (attempts < 50) {
            final appState =
                // ignore: use_build_context_synchronously
                Provider.of<AppStateProvider>(context, listen: false);
            if (appState.isAppReady == true) break;
            await Future.delayed(const Duration(milliseconds: 100));
            attempts++;
          }
        } catch (e) {
          // Provider not available yet; NotificationService has its own queue fallback
          debugPrint('AppStateProvider not available yet: $e');
        }

        // Let NotificationService handle or enqueue this notification safely
        NotificationService.handleInitialMessage(widget.initialMessage!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LoginProvider()),
        ChangeNotifierProvider(create: (_) => SignupProvider()),
        ChangeNotifierProvider(create: (_) => VerificationProvider()),
        ChangeNotifierProvider(create: (_) => ForgotPassProvider()),
        ChangeNotifierProvider(create: (_) => NewPassProvider()),
        ChangeNotifierProvider(create: (_) => ChatRefreshProvider()),
        ChangeNotifierProvider(create: (_) => ChatStatusProvider()),
        ChangeNotifierProvider(
            create: (_) => CallProvider(widget.navigatorKey)),
        ChangeNotifierProvider(create: (_) => ComplaintsProvider()),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider()..fetchNotifications(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              MarketingProductProvider(ProductRepository())..fetchProducts(),
        ),
        ChangeNotifierProvider(
            create: (_) =>
                CustomerHomeProvider(SocketService(navigatorKey), navigatorKey)
                  ..fetchPosters()
                  ..fetchProducts()),
        ChangeNotifierProvider(
          create: (_) => AgentProvider()..fetchAgents(),
        ),
        ChangeNotifierProvider(
          create: (context) => InquiryProvider(ChatRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => CustomerProductProvider(),
        ),
        ChangeNotifierProvider(create: (context) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => MeetingManagement()),
        ChangeNotifierProvider(create: (_) => GroupProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, child) {
          return MaterialApp(
            navigatorObservers: [routeObserver],
            navigatorKey: widget.navigatorKey,
            title: 'KKP Chat App',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            initialRoute: "/splash",
            routes: {
              "/splash": (context) => const Splash(),
              "/login": (context) => LoginPage(),
            },
            onGenerateRoute: (settings) {
              if (CustomerRoutes.allRoutes.contains(settings.name)) {
                return generateCustomerRoute(settings);
              } else if (MarketingRoutes.allRoutes.contains(settings.name)) {
                return generateMarketingRoute(settings);
              } else {
                return null;
              }
            },
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('hi'),
              Locale('ta'),
            ],
            locale: localeProvider.locale,
          );
        },
      ),
    );
  }
}
