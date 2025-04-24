import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:kkpchatapp/core/network/auth_api.dart';
import 'package:kkpchatapp/core/services/notification_service.dart';
import 'package:kkpchatapp/core/services/socket_service.dart';
import 'package:kkpchatapp/data/models/profile_model.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/presentation/customer/screen/customer_home_page.dart';
import 'package:kkpchatapp/presentation/customer/screen/customer_products_page.dart';
import 'package:kkpchatapp/presentation/customer/screen/customer_profile_page.dart';
import 'package:kkpchatapp/presentation/customer/screen/settings/customer_settings_page.dart';
import 'package:kkpchatapp/presentation/customer/widget/customer_nav_bar.dart';
import 'package:kkpchatapp/presentation/customer/screen/customer_chat_screen.dart';

class CustomerHost extends StatefulWidget {
  const CustomerHost({super.key});

  @override
  State<CustomerHost> createState() => _CustomerHostState();
}

class _CustomerHostState extends State<CustomerHost> {
  int _selectedIndex = 0;
  final SocketService _socketService = SocketService();
  AuthApi auth = AuthApi();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  Profile? profile;

  @override
  void initState() {
    super.initState();

    _loadCurrentUserData().then((_) async {
      if (profile != null) {
        _socketService.initSocket(profile!.name!, profile!.email!, "User");
        await _initializeNotificationService();
        _handleFirebaseNotificationTaps();
      }
    });
  }

  void _handleFirebaseNotificationTaps() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      debugPrint('🔔 Notification opened (background/terminated): ${message.data}');

      final agentName = message.data['senderName'];
      final customerEmail = profile!.email;
      final customerImage = profile!.profileUrl ?? "";

      final userType = LocalDbHelper.getUserType();
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
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CustomerChatScreen(
        agentName: name,
        customerEmail: email,
        customerImage: image,
      ),
    ));
  }


  Future<void> _initializeNotificationService() async {
    await NotificationService.init(
      context,
      _navigatorKey,
      onNotificationClick: (payload) {
        String? userType = LocalDbHelper.getUserType();
        if (userType == "0" && profile != null) {
          _navigateToChat(
            name: "Agent",
            email: profile!.email,
            image: profile?.profileUrl ?? "",
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
    return MaterialApp(
      navigatorKey: _navigatorKey,
      home: Scaffold(
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
  }
}
