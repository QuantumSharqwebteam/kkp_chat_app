import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kkpchatapp/config/routes/customer_routes.dart';
import 'package:kkpchatapp/config/routes/marketing_routes.dart';
import 'package:kkpchatapp/config/theme/theme.dart';
import 'package:kkpchatapp/core/services/background_service.dart';
import 'package:kkpchatapp/core/services/notification_service.dart';
import 'package:kkpchatapp/logic/auth/forgot_pass_provider.dart';
import 'package:kkpchatapp/logic/auth/login_provider.dart';
import 'package:kkpchatapp/logic/auth/new_pass_provider.dart';
import 'package:kkpchatapp/logic/auth/signup_provider.dart';
import 'package:kkpchatapp/logic/auth/verification_provider.dart';
import 'package:kkpchatapp/presentation/common/auth/login_page.dart';
import 'package:kkpchatapp/presentation/common/splash.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
// Import the background service

// Global flag to indicate if the app is initialized
bool isAppInitialized = false;

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerMainIsolatePort();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }

  await Hive.initFlutter();

  await Future.wait([
    Hive.openBox('CREDENTIALS'),
    Hive.openBox("lastSeenTimeBox"),
    Hive.openBox('feedBox'),
    dotenv.load(fileName: "keys.env"),
  ]);

  // Initialize the background service
  initializeService();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Handle terminated state
  RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();

  runApp(
    MyApp(navigatorKey: navigatorKey, initialMessage: initialMessage),
  );
}

void registerMainIsolatePort() {
  final ReceivePort receivePort = ReceivePort();
  IsolateNameServer.registerPortWithName(receivePort.sendPort, 'main_isolate');
  receivePort.listen((message) {
    // Handle any messages from background isolate if needed
  });
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

    // Handle the initial message if the app was opened via a notification
    if (widget.initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        NotificationService.handleNotificationClick(widget.initialMessage!);
      });
    }

    if (Platform.isAndroid) {
      const platform = MethodChannel("flutter.io/foreground_service");
      platform.invokeMethod("disableBatteryOptimizations");
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
      ],
      child: MaterialApp(
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
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', 'US'),
        ],
      ),
    );
  }
}
