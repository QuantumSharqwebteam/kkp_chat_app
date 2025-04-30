import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kkpchatapp/config/routes/customer_routes.dart';
import 'package:kkpchatapp/config/routes/marketing_routes.dart';
import 'package:kkpchatapp/config/theme/theme.dart';
import 'package:kkpchatapp/core/services/notification_service.dart';
import 'package:kkpchatapp/presentation/common/auth/login_page.dart';
import 'package:kkpchatapp/presentation/common/chat/agora_audio_call_screen.dart';
import 'package:kkpchatapp/presentation/common/splash.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_callkeep/flutter_callkeep.dart';
import 'package:uuid/uuid.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("📩 [Background] Notification: ${message.notification?.title}");
  await Firebase.initializeApp();
  if (message.data['call'] != null) {
    // Extract call information from notification payload
    String channelName = message.data['channelName'];
    String remoteUserId = message.data['remoteUserId'];
    String remoteUserName = message.data['remoteUserName'];

    // Generate a unique UUID for the call
    String uuid = const Uuid().v4();

    // Display incoming call notification
    CallKeep.instance.displayIncomingCall(
      CallEvent(
        uuid: uuid, // Unique call UUID
        handle: remoteUserId, // Handle of the caller (can be user ID or name)
        callerName: remoteUserName,
        hasVideo: false, // Since this is an audio call
        extra: {
          'channelName': channelName,
          'remoteUserId': remoteUserId,
          'remoteUserName': remoteUserName,
        },
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Configure CallKeep settings for handling incoming calls
  CallKeep.instance.configure(CallKeepConfig(
    appName: 'KKP Chat App',
    ios: CallKeepIosConfig(
      // iconName: 'CallKitLogo',
      handleType: CallKitHandleType.generic,
      isVideoSupported: false,
      maximumCallGroups: 2,
      maximumCallsPerCallGroup: 1,
      // audioSessionMode: AvAudioSessionMode.spokenAudio,
      audioSessionActive: true,
      audioSessionPreferredSampleRate: 44100.0,
      audioSessionPreferredIOBufferDuration: 0.005,
      supportsDTMF: true,
      supportsHolding: true,
      supportsGrouping: true,
      supportsUngrouping: true,
      ringtoneFileName: 'system_ringtone_default',
    ),
    android: CallKeepAndroidConfig(
      //logo: 'mipmap/ic_launcher',
      // notificationIcon: 'mipmap/ic_launcher',
      showMissedCallNotification: true,
      showCallBackAction: true,
      ringtoneFileName: 'system_ringtone_default',
      accentColor: '#0955fa',
      // backgroundUrl: 'https://example.com/background.png',
      incomingCallNotificationChannelName: 'Incoming Calls',
      missedCallNotificationChannelName: 'Missed Calls',
    ),
  ));

  // Register handler for incoming call events
  CallKeep.instance.handler = CallEventHandler(
    onCallAccepted: (CallEvent event) async {
      // Extract necessary data to initialize the call screen
      String channelName = event.extra?['channelName'];
      String remoteUserId = event.extra?['remoteUserId'];
      String remoteUserName = event.extra?['remoteUserName'];

      // Generate a unique UUID for the call
      int uid = const Uuid().v4().hashCode;

      // Navigate to the Agora audio call screen
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => AgoraAudioCallScreen(
            isCaller: false, // Receiver side
            channelName: channelName,
            remoteUserId: remoteUserId,
            remoteUserName: remoteUserName,
            uid: uid,
          ),
        ),
      );
    },
    onCallEnded: (CallEvent event) {
      // Handle end of call logic here
      debugPrint("Call ended: ${event.uuid}");
    },
    onCallDeclined: (CallEvent event) {
      // Handle call declined logic here
      debugPrint("Call declined: ${event.uuid}");
    },
  );

  runApp(MyApp(navigatorKey: navigatorKey));
}

class MyApp extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const MyApp({super.key, required this.navigatorKey});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    NotificationService.init(context, widget.navigatorKey);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
    );
  }
}
