import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/routes/customer_routes.dart';
import 'package:kkpchatapp/config/routes/marketing_routes.dart';
import 'package:kkpchatapp/core/network/auth_api.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/presentation/common/onboarding_page.dart';

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
    final int? lastRefreshTime = await LocalDbHelper.getLastRefreshTime();
    final int currentTime = DateTime.now().millisecondsSinceEpoch;

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
      if (userType == '0') {
        if (mounted) {
          Navigator.pushReplacementNamed(context, CustomerRoutes.customerHost);
        }
      } else if (userType == '1' || userType == '2' || userType == '3') {
        if (mounted) {
          Navigator.pushReplacementNamed(
              context, MarketingRoutes.marketingHostScreen);
        }
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Invalid Credentials')));
      }
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
        return OnboardingPage();
      }));
    }
  }

  Future<void> _refreshToken(String? token, context) async {
    if (token != null && token.isNotEmpty) {
      await auth.refreshToken(token).then((response) async {
        if (response['message'] == "Refresh token generated successfully") {
          token = response['token'];
          await LocalDbHelper.saveToken(response['token']);
          await LocalDbHelper.saveLastRefreshTime(
              DateTime.now().millisecondsSinceEpoch);
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(response['message'])));
        }
      });
    }
  }

  void _scheduleNextRefresh(int durationMillis, context) {
    _refreshTokenTimer?.cancel(); // Cancel any existing timer
    _refreshTokenTimer =
        Timer(Duration(milliseconds: durationMillis), () async {
      String? token = await LocalDbHelper.getToken();
      _refreshToken(token, context);
      _scheduleNextRefresh(
          24 * 60 * 60 * 1000, context); // Schedule the next refresh
    });
  }

  @override
  void initState() {
    super.initState();
    _checkLogin(context);
  }

  @override
  void dispose() {
    _refreshTokenTimer
        ?.cancel(); // Cancel the timer when the widget is disposed
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
