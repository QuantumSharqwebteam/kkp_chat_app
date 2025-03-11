import 'package:flutter/material.dart';
import 'package:kkp_chat_app/presentation/admin/screens/add_agent.dart';
import 'package:kkp_chat_app/presentation/admin/screens/admin_home.dart';
import 'package:kkp_chat_app/presentation/marketing/screen/feeds_screen.dart';
import 'package:kkp_chat_app/presentation/marketing/screen/marketing_product_screen.dart';

import 'package:kkp_chat_app/presentation/marketing/widget/marketing_nav_bar.dart';

class MarketingHost extends StatefulWidget {
  const MarketingHost({super.key});

  @override
  State<MarketingHost> createState() => _MarketingHostState();
}

class _MarketingHostState extends State<MarketingHost> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    //AgentHomeScreen(),
    AdminHome(),
    FeedsScreen(),
    MarketingProductScreen(),
    //ProfileScreen(),
    AddAgent(),
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
      bottomNavigationBar: MarketingNavBar(
        selectedIndex: _selectedIndex,
        onTabSelected: _onTabSelected,
      ),
    );
  }
}
