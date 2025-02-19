import 'package:flutter/material.dart';
import 'package:kkp_chat_app/presentation/marketing/screen/agent_home_screen.dart';
import 'package:kkp_chat_app/presentation/marketing/screen/feeds_screen.dart';
import 'package:kkp_chat_app/presentation/marketing/screen/product_screen.dart';
import 'package:kkp_chat_app/presentation/marketing/screen/profile_screen.dart';

class MarketingHost extends StatefulWidget {
  const MarketingHost({super.key});

  @override
  State<MarketingHost> createState() => _MarketingHostState();
}

class _MarketingHostState extends State<MarketingHost> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    AgentHomeScreen(),
    ProductScreen(),
    ProfileScreen(),
    FeedsScreen()
  ];

  final List<String> _screenNames = [
    'Home',
    'Product',
    'Profile',
    'Feed',
  ];

  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      width: double.maxFinite,
      decoration: BoxDecoration(
        color: Colors.blue,
        boxShadow: [
          // Add a shadow (optional)
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 5,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            _pageController.jumpToPage(index);
          });
        },
        backgroundColor: Colors
            .transparent, // Make the BottomNavigationBar background transparent
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.5),
        showSelectedLabels: false, // Hide labels
        showUnselectedLabels: false, // Hide labels
        type: BottomNavigationBarType.fixed, // Important for consistent spacing
        elevation: 0, // Remove default elevation
        items: [
          _buildBarItem(0, Icons.home),
          _buildBarItem(1, Icons.shopping_cart),
          _buildBarItem(2, Icons.person),
          _buildBarItem(3, Icons.feed),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildBarItem(int index, IconData icon) {
    return BottomNavigationBarItem(
      icon: _buildCustomIcon(index, icon), // Use the custom icon builder
      label: _screenNames[index], // Still provide a label for accessibility
    );
  }

  Widget _buildCustomIcon(int index, IconData icon) {
    bool isSelected = index == _selectedIndex;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
          padding: EdgeInsets.all(isSelected ? 12 : 5),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                    ),
                  ]
                : [],
          ),
          child: Icon(
            icon,
            size: isSelected ? 32 : 24,
            color: isSelected ? Colors.blue : Colors.white.withOpacity(0.7),
          ),
        ),
        if (isSelected) // Show text only when selected
          Text(
            _screenNames[index],
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
      ],
    );
  }
}
