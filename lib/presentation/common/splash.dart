import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/routes/customer_routes.dart';
import 'package:kkpchatapp/config/routes/marketing_routes.dart';
import 'package:kkpchatapp/core/services/logging_service.dart';
import 'package:kkpchatapp/data/api/auth_service.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/logic/agent/group_provider.dart';
import 'package:kkpchatapp/presentation/common/onboarding_page.dart';
import 'package:provider/provider.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  final AuthApi auth = AuthApi();
  Timer? _refreshTokenTimer;

  Future<void> _checkLogin(context) async {
    String? token = await LocalDbHelper.getToken();
    final String? userType = await LocalDbHelper.getUserType();
    final String? email = LocalDbHelper.getEmail();
    final bool hasSeenOnboarding = await LocalDbHelper.hasSeenOnboarding();

    // final int? lastRefreshTime = await LocalDbHelper.getLastRefreshTime();
    // final int currentTime = DateTime.now().millisecondsSinceEpoch;

    // // Check if 24 hours have passed since the last refresh
    // if (lastRefreshTime != null &&
    //     (currentTime - lastRefreshTime) < 24 * 60 * 60 * 1000) {
    //   // Schedule the next refresh
    //   _scheduleNextRefresh(
    //       24 * 60 * 60 * 1000 - (currentTime - lastRefreshTime), context);
    // } else {
    //   // Refresh the token immediately
    //   await _refreshToken(token, context);
    //   // Schedule the next refresh for 24 hours later
    //   _scheduleNextRefresh(24 * 60 * 60 * 1000, context);
    // }

    await _refreshToken(token, context);

    if (token != null && userType != null) {
      // Fetch user groups in the background
      await _fetchUserGroups(email ?? "");

      if (userType == '0') {
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            CustomerRoutes.customerHost,
          );
        }
      } else if (userType == '1' || userType == '2' || userType == '3') {
        if (mounted) {
          Navigator.pushReplacementNamed(context, MarketingRoutes.marketingHostScreen);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid Credentials')));
      }
    } else {
      if (!mounted) return;

      if (!hasSeenOnboarding) {
        await LocalDbHelper.setOnboardingSeen(true);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) {
              return const OnboardingPage();
            },
          ),
        );
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  Future<void> _refreshToken(String? token, context) async {
    if (token != null && token.isNotEmpty) {
      await auth.refreshToken(token).then((response) async {
        if (response['message'] == "Refresh token generated successfully") {
          token = response['token'];
          await LocalDbHelper.saveToken(response['token']);
          await LocalDbHelper.saveLastRefreshTime(DateTime.now().millisecondsSinceEpoch);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'])));
        }
      });
    }
  }

  /// Fetch user groups in the background
  Future<void> _fetchUserGroups(String email) async {
    try {
      // Use Provider to access GroupProvider
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      await Future.wait([groupProvider.fetchUsersGroups(email), groupProvider.fetchAllGroups()]);
    } catch (e) {
      // Log error but do not block navigation
      LoggingService.instance.logNetwork(
        "Failed to load user groups:${e.toString()}",
      );
    }
  }

  // void _scheduleNextRefresh(int durationMillis, context) {
  //   _refreshTokenTimer?.cancel(); // Cancel any existing timer
  //   _refreshTokenTimer =
  //       Timer(Duration(milliseconds: durationMillis), () async {
  //     String? token = await LocalDbHelper.getToken();
  //     _refreshToken(token, context);
  //     _scheduleNextRefresh(
  //         24 * 60 * 60 * 1000, context); // Schedule the next refresh
  //   });
  // }

  @override
  void initState() {
    super.initState();
    _checkLogin(context);
  }

  @override
  void dispose() {
    _refreshTokenTimer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/icons/app_logo.png',
          width: Utils().width(context) * 0.7,
        ),
      ),
    );
  }
}
