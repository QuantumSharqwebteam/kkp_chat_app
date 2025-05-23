import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:motion_tab_bar_v2/motion-tab-bar.dart';

class CustomerNavBar extends StatelessWidget {
  const CustomerNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  final int selectedIndex;
  final Function(int) onTabSelected;

  @override
  Widget build(BuildContext context) {
    return MotionTabBar(
      initialSelectedTab: _getTabName(selectedIndex),
      labels: ["Home", "Product", "Profile", "Settings"],
      icons: [
        Icons.home_filled,
        Icons.shopping_bag,
        Icons.person,
        Icons.settings,
      ],
      tabSize: 40,
      tabBarHeight: 55,
      textStyle: const TextStyle(
        fontSize: 13, // Adjust text size
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      tabIconSize: 35,
      tabIconSelectedSize: 35,
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
        return "Product";
      case 2:
        return "Profile";
      case 3:
        return "Settings";
      default:
        return "Home";
    }
  }
}
