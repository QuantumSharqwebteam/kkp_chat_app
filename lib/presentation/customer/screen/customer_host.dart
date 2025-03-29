import 'package:flutter/material.dart';
import 'package:kkp_chat_app/core/network/auth_api.dart';
import 'package:kkp_chat_app/core/services/socket_service.dart';
import 'package:kkp_chat_app/data/models/profile_model.dart';
import 'package:kkp_chat_app/data/local_storage/local_db_helper.dart';
import 'package:kkp_chat_app/presentation/customer/screen/customer_home_page.dart';
import 'package:kkp_chat_app/presentation/customer/screen/customer_products_page.dart';
import 'package:kkp_chat_app/presentation/customer/screen/customer_profile_page.dart';
import 'package:kkp_chat_app/presentation/customer/screen/settings/customer_settings_page.dart';
import 'package:kkp_chat_app/presentation/customer/widget/customer_nav_bar.dart';

class CustomerHost extends StatefulWidget {
  const CustomerHost({super.key});

  @override
  State<CustomerHost> createState() => _CustomerHostState();
}

class _CustomerHostState extends State<CustomerHost> {
  int _selectedIndex = 0;
  final SocketService _socketService = SocketService();
  AuthApi auth = AuthApi();
  String? customerEmail;
  String? customerName;

  @override
  void initState() {
    super.initState();

    _loadCurrentUserData().then((data) {
      _socketService.initSocket(customerName!, customerEmail!, "User");
    });
  }

  Future<void> _loadCurrentUserData() async {
    try {
      Profile? profile = LocalDbHelper.getProfile();
      setState(() {
        customerName = profile?.name;
        customerEmail = profile?.email;
      });
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
