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

    _loadCurrentUserData().whenComplete(() {
      _socketService.initSocket(profile!.name!, profile!.email!, "User");
      _initializeNotificationService();
    });
  }

  Future<void> _initializeNotificationService() async {
    await NotificationService.init(context, _navigatorKey);
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
      // Handle any errors that occur during the async operation
      debugPrint('Error in _loadCurrentUserData: $error');
    }
  }

  @override
  void dispose() {
    _socketService.disconnect(); // Disconnect when leaving the host screen
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
