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

  Future<void> _checkLogin(context) async {
    // await Future.delayed(const Duration(seconds: 1));

    final String? token = await LocalDbHelper.getToken();
    final String? userType = await LocalDbHelper.getUserType();

    // if (token != null && token.isNotEmpty) {
    //   await auth.refreshToken(token).then((response) async {
    //     if (response['message'] == "Refresh token generated successfully") {
    //       token = response['token'];
    //       await LocalDbHelper.saveToken(response['token']);
    //       await LocalDbHelper.saveLastRefreshTime(
    //           DateTime.now().millisecondsSinceEpoch);
    //     } else {
    //       ScaffoldMessenger.of(context)
    //           .showSnackBar(SnackBar(content: Text(response['message'])));
    //     }
    //   });
    // }

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

  @override
  void initState() {
    super.initState();
    _checkLogin(context);
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
