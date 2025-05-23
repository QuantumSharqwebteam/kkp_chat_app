import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:kkpchatapp/core/network/auth_api.dart';
import 'package:kkpchatapp/core/services/notification_service.dart';
import 'package:kkpchatapp/core/services/socket_service.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/models/profile_model.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/repositories/chat_reopsitory.dart';
import 'package:kkpchatapp/main.dart';
import 'package:kkpchatapp/presentation/admin/screens/admin_home.dart';
import 'package:kkpchatapp/presentation/admin/screens/admin_profile_page.dart';
import 'package:kkpchatapp/presentation/common/auth/login_page.dart';
import 'package:kkpchatapp/presentation/common/chat/agora_audio_call_screen.dart';
import 'package:kkpchatapp/presentation/marketing/screen/agent_chat_screen.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/incoming_call_widget.dart';
import 'package:kkpchatapp/presentation/marketing/screen/agent_home_screen.dart';
import 'package:kkpchatapp/presentation/marketing/screen/feeds_screen.dart';
import 'package:kkpchatapp/presentation/marketing/screen/marketing_product_screen.dart';
import 'package:kkpchatapp/presentation/marketing/screen/profile_screen.dart';
import 'package:kkpchatapp/presentation/marketing/widget/marketing_nav_bar.dart';
import 'package:kkpchatapp/presentation/common_widgets/back_press_handler.dart';

class MarketingHost extends StatefulWidget {
  const MarketingHost({super.key, required this.navigatorKey});
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<MarketingHost> createState() => _MarketingHostState();
}

class _MarketingHostState extends State<MarketingHost> {
  int _selectedIndex = 0;
  String? role;
  String? rolename;
  String? agentEmail;
  String? agentName;
  List<Widget> _screens = [];
  final SocketService _socketService = SocketService(navigatorKey);
  final chatRepository = ChatRepository();
  AuthApi auth = AuthApi();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  OverlayEntry? _activeCallOverlay;

  @override
  void initState() {
    super.initState();
    _loadUserDataAndInitializeSocket().then((_) {
      _initializeNotificationService().then((_) {});
    });
    initCheck();
  }

  void initCheck() async {
    // Set the global flag to true after initialization
    isAppInitialized = true;
  }

  Future<void> _initializeNotificationService() async {
    await NotificationService.init(context, _navigatorKey);
  }

  Future<void> _loadUserDataAndInitializeSocket() async {
    final token = await LocalDbHelper.getToken();
    await _loadUserData().whenComplete(() {
      if (agentName != null && agentEmail != null && rolename != null) {
        _socketService.initSocket(agentName!, agentEmail!, rolename!,
            token: token);
        _socketService.onReceiveMessage(_handleIncomingMessage);
        _socketService.onIncomingCall(_handleIncomingCall);
      } else {
        debugPrint("Skipping socket init: agentName or agentEmail is null");
      }
    });
  }

  Future<void> _loadUserData() async {
    try {
      // Load role and email
      role = await LocalDbHelper.getUserType();
      agentEmail = LocalDbHelper.getEmail();

      debugPrint(
          'Loaded role: $role, Loaded email: $agentEmail'); // Debug print

      // Determine role name
      if (role == "1") {
        rolename = "admin";
      } else if (role == "2") {
        rolename = "agent";
      } else if (role == "3") {
        rolename = "agent Head";
      }

      // Load user profile
      final Map<String, dynamic> userData = await auth.getUserInfo();
      if (userData['message'] ==
          "Session expired due to login on another device") {
        if (mounted) {
          Navigator.of(context)
              .pushReplacement(MaterialPageRoute(builder: (context) {
            return LoginPage();
          }));
        }
      } else {
        Profile? profile = Profile.fromJson(userData['message']);
        await LocalDbHelper.saveProfile(profile).whenComplete(() {
          debugPrint(
              'Loaded profile: $profile'); // Debug print to check loaded profile
        });

        setState(() {
          agentName = profile.name ?? "";
          agentEmail = profile.email ?? ""; // Ensure email is also set
          debugPrint(
              'Agent Name: $agentName, Agent Email: $agentEmail'); // Debug print to check values
        });
        await _updateScreens();
      }
    } catch (error) {
      debugPrint('Error in _loadUserData: $error');
    }
  }

  @override
  void dispose() {
    _socketService.disconnect(); // Disconnect when leaving the host screen
    super.dispose();
  }

  Future<void> _updateScreens() async {
    setState(() {
      _screens = [
        if (role == "1")
          AdminHome()
        else
          AgentHomeScreen(agentEmail: agentEmail!, agentName: agentName!),
        FeedsScreen(loggedAgentEmail: agentEmail!),
        MarketingProductScreen(),
        if (role == "1" || role == "3") AdminProfilePage() else ProfileScreen(),
      ];
    });
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToChat({
    required String? customername,
    required String customeremail,
    String? targetId,
  }) {
    Navigator.push(
        widget.navigatorKey.currentContext!,
        MaterialPageRoute(
          builder: (_) => AgentChatScreen(
            customerName: customername,
            customerEmail: customeremail,
            agentEmail: LocalDbHelper.getProfile()?.email ?? targetId,
            navigatorKey: widget.navigatorKey,
          ),
        ));
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    // Handle incoming message
    debugPrint('Incoming message: $data');

    _navigateToChat(
        customeremail: data["senderId"],
        customername: data["senderName"],
        targetId: data['targetId']);
  }

  void _handleIncomingCall(Map<String, dynamic> callData) {
    // debugPrint("Incoming call data2: ${callData.toString()}");
    // Remove previous overlay if exists
    _activeCallOverlay?.remove();
    _activeCallOverlay = null;

    final channelName = callData['channelName'];
    final callerName = callData['callerName'];
    final callerId = callData['callerId'];
    final incomingCallId = callData["callId"];
    final uid = Utils().generateIntUidFromEmail(agentEmail!);
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
                    messageId: incomingCallId,
                  ),
                ),
              );
            }
          },
          onReject: () async {
            await stopAndRemoveOverlay();
            await chatRepository.updateCallData(incomingCallId, "missed");
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
      // Optionally emit missed call
      await chatRepository.updateCallData(incomingCallId, "missed");
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
        bottomNavigationBar: MarketingNavBar(
          selectedIndex: _selectedIndex,
          onTabSelected: _onTabSelected,
        ),
      ),
    );
    return BackPressHandler(child: content);
  }
}
