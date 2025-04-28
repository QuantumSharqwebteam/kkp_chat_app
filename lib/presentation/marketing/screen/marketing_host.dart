import 'package:flutter/material.dart';
import 'package:kkpchatapp/core/network/auth_api.dart';
import 'package:kkpchatapp/core/services/notification_service.dart';
import 'package:kkpchatapp/core/services/socket_service.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/models/profile_model.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/presentation/admin/screens/admin_home.dart';
import 'package:kkpchatapp/presentation/admin/screens/admin_profile_page.dart';
import 'package:kkpchatapp/presentation/common/chat/agora_audio_call_screen.dart';
import 'package:kkpchatapp/presentation/marketing/screen/agent_home_screen.dart';
import 'package:kkpchatapp/presentation/marketing/screen/feeds_screen.dart';
import 'package:kkpchatapp/presentation/marketing/screen/marketing_product_screen.dart';
import 'package:kkpchatapp/presentation/marketing/screen/profile_screen.dart';
import 'package:kkpchatapp/presentation/marketing/widget/marketing_nav_bar.dart';

import '../../../core/services/call_overlay_service.dart';

class MarketingHost extends StatefulWidget {
  const MarketingHost({super.key});

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
  final SocketService _socketService = SocketService();
  AuthApi auth = AuthApi();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _loadUserDataAndInitializeSocket();
    _initializeNotificationService();
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
        // _socketService.onIncomingCall(_handleIncomingCall);
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
      Profile? profile = await auth.getUserInfo();
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

  void _handleIncomingMessage(Map<String, dynamic> data) {
    // Handle incoming message
    debugPrint('Incoming message: $data');
  }

  // void _handleIncomingCall(Map<String, dynamic> callData) {
  //   final channelName = callData['channelName'];
  //   final callerName = callData['callerName'];
  //   final callerId = callData['callerId'];
  //   final uid = Utils().generateIntUidFromEmail(agentEmail!);

  //   CallOverlayService().showIncomingCall(
  //     callerName: callerName,
  //     onAccept: () {
  //       Navigator.of(_navigatorKey.currentContext!).push(
  //         MaterialPageRoute(
  //           builder: (_) => AgoraAudioCallScreen(
  //             isCaller: false,
  //             channelName: channelName,
  //             uid: uid,
  //             remoteUserId: callerId,
  //             remoteUserName: callerName,
  //           ),
  //         ),
  //       );
  //     },
  //     onReject: () {
  //       debugPrint('Call rejected by user');
  //       // send a reject signal via socket if needed
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: MarketingNavBar(
        selectedIndex: _selectedIndex,
        onTabSelected: _onTabSelected,
      ),
    );
  }
}
