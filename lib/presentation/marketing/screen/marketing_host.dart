import 'package:flutter/material.dart';
import 'package:kkp_chat_app/core/network/auth_api.dart';
import 'package:kkp_chat_app/core/services/socket_service.dart';
import 'package:kkp_chat_app/data/models/profile_model.dart';
import 'package:kkp_chat_app/data/local_storage/local_db_helper.dart';
import 'package:kkp_chat_app/presentation/admin/screens/admin_home.dart';
import 'package:kkp_chat_app/presentation/admin/screens/admin_profile_page.dart';
import 'package:kkp_chat_app/presentation/marketing/screen/agent_home_screen.dart';
import 'package:kkp_chat_app/presentation/marketing/screen/marketing_product_screen.dart';
import 'package:kkp_chat_app/presentation/marketing/screen/profile_screen.dart';
import 'package:kkp_chat_app/presentation/marketing/widget/marketing_nav_bar.dart';

import '../../admin/screens/agent_profile_list.dart';

class MarketingHost extends StatefulWidget {
  const MarketingHost({super.key});

  @override
  State<MarketingHost> createState() => _MarketingHostState();
}

class _MarketingHostState extends State<MarketingHost> {
  int _selectedIndex = 0;
  String? role;
  String? agentEmail;
  String? agentName;
  List<Widget> _screens = [];
  final SocketService _socketService = SocketService();
  AuthApi auth = AuthApi();

  @override
  void initState() {
    super.initState();
    _loadcredentials();
    _loadCurrentUserData().then((data) {
      _socketService.initSocket(agentName!, agentEmail!);
    });
    // _socketService.initSocket("Shoaib",
    //     "mohdshoaibrayeen3@gmail.com"); // Establish socket connection globally
    // _socketService.joinRoom("Shoaib", "mohdshoaibrayeen3@gmail.com");
  }

  Future<void> _loadCurrentUserData() async {
    try {
      Profile profile = await auth.getUserInfo();
      LocalDbHelper.saveProfile(profile);
      setState(() {
        agentName = profile.name;
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

  Future<void> _loadcredentials() async {
    role = LocalDbHelper.getUserType();
    agentEmail = LocalDbHelper.getEmail();
    _updateScreens();
  }

  void _updateScreens() {
    setState(() {
      _screens = [
        if (role == "1" || role == "3") AdminHome() else AgentHomeScreen(),
        AgentProfilesPage(),
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
