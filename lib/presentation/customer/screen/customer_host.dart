import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:kkpchatapp/core/network/auth_api.dart';
import 'package:kkpchatapp/core/services/notification_service.dart';
import 'package:kkpchatapp/core/services/socket_service.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/models/profile_model.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/repositories/chat_reopsitory.dart';
import 'package:kkpchatapp/main.dart';
import 'package:kkpchatapp/presentation/common/auth/login_page.dart';
import 'package:kkpchatapp/presentation/common/chat/agora_audio_call_screen.dart';
import 'package:kkpchatapp/presentation/common_widgets/back_press_handler.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/incoming_call_widget.dart';
import 'package:kkpchatapp/presentation/customer/screen/customer_home_page.dart';
import 'package:kkpchatapp/presentation/customer/screen/customer_products_page.dart';
import 'package:kkpchatapp/presentation/customer/screen/customer_profile_page.dart';
import 'package:kkpchatapp/presentation/customer/screen/settings/customer_settings_page.dart';
import 'package:kkpchatapp/presentation/customer/widget/customer_nav_bar.dart';
import 'package:kkpchatapp/presentation/customer/screen/customer_chat_screen.dart';

class CustomerHost extends StatefulWidget {
  const CustomerHost({super.key, required this.navigatorKey});
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<CustomerHost> createState() => _CustomerHostState();
}

class _CustomerHostState extends State<CustomerHost> {
  int _selectedIndex = 0;

  late final SocketService _socketService;
  AuthApi auth = AuthApi();
  final chatRepository = ChatRepository();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  Profile? profile;

  OverlayEntry? _activeCallOverlay;

  @override
  void initState() {
    super.initState();
    _socketService = SocketService(widget.navigatorKey);
    _loadCurrentUserData().then((_) async {
      final token = await LocalDbHelper.getToken();

      if (profile != null) {
        _socketService.initSocket(
          profile!.name!,
          profile!.email!,
          "User",
          token: token,
        );
        _socketService.onReceiveMessage(_handleIncomingMessage);
        _socketService.onIncomingCall(_handleIncomingCall);
        await _initializeNotificationService();
        _handleFirebaseNotificationTaps();

        initCheck();
      }
    });
  }

  void initCheck() async {
    // Set the global flag to true after initialization
    isAppInitialized = true;
  }

  void _handleFirebaseNotificationTaps() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      debugPrint(
          '🔔 Notification opened (background/terminated): ${message.data}');

      if (isAppInitialized) {
        final agentName = message.data['senderName'];
        final customerEmail = profile!.email;
        final customerImage = profile!.profileUrl ?? "";

        final userType = await LocalDbHelper.getUserType();
        if (userType == "0") {
          _navigateToChat(
            name: agentName,
            email: customerEmail,
            image: customerImage,
          );
        }
      } else {
        debugPrint("App is not initialized. Skipping notification handling.");
      }
    });
  }

  void _navigateToChat({
    required String? name,
    required String? email,
    required String? image,
  }) {
    Navigator.push(
        widget.navigatorKey.currentContext!,
        MaterialPageRoute(
          builder: (_) => CustomerChatScreen(
            agentName: name,
            customerEmail: email,
            navigatorKey: widget.navigatorKey,
          ),
        ));
  }

  Future<void> _initializeNotificationService() async {
    await NotificationService.init(
      context,
      _navigatorKey,
      onNotificationClick: (agentName, customerEmail, customerImage) async {
        String? userType = await LocalDbHelper.getUserType();
        if (userType == "0" && profile != null) {
          _navigateToChat(
            name: agentName,
            email: customerEmail,
            image: customerImage,
          );
        }
      },
    );
  }

  Future<void> _loadCurrentUserData() async {
    try {
      final Map<String, dynamic> userData = await auth.getUserInfo();
      if (userData['message'] ==
          "Session expired due to login on another device") {
        Hive.deleteFromDisk();
        if (mounted) {
          Navigator.of(context)
              .pushReplacement(MaterialPageRoute(builder: (context) {
            return LoginPage();
          }));
        }
      }
      profile = Profile.fromJson(userData['message']);
      if (profile != null) {
        await LocalDbHelper.saveProfile(profile!);
      } else {
        debugPrint("SAVE PROFILE FAILED DUE TO NULL");
      }
    } catch (error) {
      debugPrint('Error in _loadCurrentUserData: $error');
    }
  }

  @override
  void dispose() {
    _socketService.disconnect();
    super.dispose();
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    final agentName = data['senderName'];
    final customerEmail = profile!.email;
    final customerImage = profile!.profileUrl ?? "";

    _navigateToChat(
      name: agentName,
      email: customerEmail,
      image: customerImage,
    );
  }

  void _handleIncomingCall(Map<String, dynamic> callData) {
    // Remove previous overlay if exists
    _activeCallOverlay?.remove();
    _activeCallOverlay = null;

    final channelName = callData['channelName'];
    final callerName = callData['callerName'];
    final callerId = callData['callerId'];
    final incomingCallId = callData["callId"];
    final uid = Utils().generateIntUidFromEmail(profile!.email!);
    final overlayState = Overlay.of(context);

    late OverlayEntry overlayEntry;
    Timer? timeoutTimer;
    final audioPlayer = AudioPlayer();

    Future<void> stopAndRemoveOverlay() async {
      await audioPlayer.stop();
      timeoutTimer?.cancel();
      overlayEntry.remove();
      _activeCallOverlay = null;
    }

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: IncomingCallWidget(
          callerName: callerName,
          onAnswer: () async {
            await stopAndRemoveOverlay();
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AgoraAudioCallScreen(
                    isCaller: false,
                    channelName: channelName,
                    uid: uid,
                    remoteUserId: callerId,
                    remoteUserName: callerName,
                    callId: incomingCallId,
                  ),
                ),
              );
            }
          },
          onReject: () async {
            await stopAndRemoveOverlay();
            await chatRepository.updateCallData(incomingCallId, "not answered");
            // Optionally emit reject event
          },
          audioPlayer: audioPlayer,
        ),
      ),
    );

    _activeCallOverlay = overlayEntry;
    overlayState.insert(overlayEntry);

    // Auto-dismiss after 30 seconds
    timeoutTimer = Timer(const Duration(seconds: 30), () async {
      await stopAndRemoveOverlay();
      await chatRepository.updateCallData(incomingCallId, "missed");
      // Optionally emit missed call
    });
  }

  final List<Widget> _screens = [
    CustomerHomePage(),
    CustomerProductsPage(),
    CustomerProfilePage(),
    CustomerSettingsPage(),
  ];

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget content = GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: CustomerNavBar(
          selectedIndex: _selectedIndex,
          onTabSelected: _onTabSelected,
        ),
      ),
    );
    return BackPressHandler(child: content);
  }
}
