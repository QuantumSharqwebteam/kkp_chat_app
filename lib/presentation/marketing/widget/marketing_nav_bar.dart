import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:motion_tab_bar_v2/motion-tab-bar.dart';

class MarketingNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;

  const MarketingNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return MotionTabBar(
      initialSelectedTab: _getTabName(selectedIndex),
      labels: [
        "Home",
        "Chats",
        "Inquiry",
        "Product",
        "Settings",
      ],
      icons: [
        Icons.home_filled,
        Icons.feed,
        Icons.live_help_outlined,
        Icons.shopping_bag_rounded,
        Icons.settings_outlined,
      ],
      tabSize: 40,
      tabBarHeight: 55,
      textStyle: const TextStyle(
        fontSize: 13, // Adjust text size
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      tabIconSize: 25,
      tabIconSelectedSize: 25,
      tabIconColor: Colors.white,
      tabIconSelectedColor: AppColors.marketingNavBarColor,
      tabSelectedColor: Colors.white,
      tabBarColor: AppColors.marketingNavBarColor,
      onTabItemSelected: (index) {
        onTabSelected(index);
      },
    );
  }

  String _getTabName(int index) {
    switch (index) {
      case 0:
        return "Home";
      case 1:
        return "Chats";
      case 2:
        return "Inquiry";
      case 3:
        return "Product";
      case 4:
        return "Settings";
      default:
        return "Home";
    }
  }
}
