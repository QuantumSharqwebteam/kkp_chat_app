import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/routes/customer_routes.dart';
import 'package:kkp_chat_app/config/routes/marketing_routes.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';
import 'package:kkp_chat_app/data/sharedpreferences/shared_preference_helper.dart';
import 'package:kkp_chat_app/presentation/common/auth/login_page.dart';
import 'package:kkp_chat_app/presentation/common/onboarding_page.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  Future<void> _checkLogin(context) async {
    await Future.delayed(const Duration(seconds: 1));
    String? token = await SharedPreferenceHelper.getToken();
    String? userType = await SharedPreferenceHelper.getUserType();

    if (token != null && userType != null) {
      if (userType == '0') {
        if (mounted) {
          Navigator.pushReplacementNamed(context, CustomerRoutes.customerHost);
        }
      } else if (userType == '1') {
        if (mounted) {
          Navigator.pushReplacementNamed(
              context, MarketingRoutes.marketingHostScreen);
        }
      } else if (userType == '2') {
        if (mounted) {
          Navigator.pushReplacementNamed(
              context, MarketingRoutes.marketingHostScreen);
        }
      } else if (userType == '3') {
        if (mounted) {
          Navigator.pushReplacementNamed(
              context, MarketingRoutes.marketingHostScreen);
        }
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Invalid Credentials')));
      }
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) {
        return OnboardingPage();
      }));
    }
  }

  @override
  void initState() {
    _checkLogin(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Image.asset(
        'assets/icons/app_logo.png',
        width: Utils().width(context) * 0.7,
      )),
    );
  }
}
