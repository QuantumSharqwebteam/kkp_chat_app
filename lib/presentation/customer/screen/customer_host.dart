import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:kkpchatapp/core/network/auth_api.dart';
import 'package:kkpchatapp/core/services/notification_service.dart';
import 'package:kkpchatapp/core/services/socket_service.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/models/profile_model.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/presentation/common/chat/agora_audio_call_screen.dart';
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
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  Profile? profile;

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
      }
    });
  }

  void _handleFirebaseNotificationTaps() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      debugPrint(
          '🔔 Notification opened (background/terminated): ${message.data}');

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
            customerImage: image,
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
      profile = await auth.getUserInfo();
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
    final channelName = callData['channelName'];
    final callerName = callData['callerName'];
    final callerId = callData['callerId'];
    final uid = Utils().generateIntUidFromEmail(profile!.email!);

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (context) {
        return Container(
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$callerName is calling...',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.call_end, color: Colors.white),
                    label: const Text("Reject"),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () {
                      Navigator.pop(context); // close bottom sheet
                    },
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.call, color: Colors.white),
                    label: const Text("Answer"),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () {
                      Navigator.pop(context); // close bottom sheet

                      // Navigate to the audio call screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AgoraAudioCallScreen(
                            isCaller: false,
                            channelName: channelName,
                            uid: uid,
                            remoteUserId: callerId,
                            remoteUserName: callerName,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
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
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: CustomerNavBar(
        selectedIndex: _selectedIndex,
        onTabSelected: _onTabSelected,
      ),
    );
  }
}
