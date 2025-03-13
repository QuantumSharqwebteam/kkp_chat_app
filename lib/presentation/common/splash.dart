import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';
import 'package:kkp_chat_app/presentation/common/onboarding_page.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    Timer(Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => OnboardingPage()),
      );
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Image.asset(
        'assets/icons/app_logo.png',
        width: Utils().width(context) * 0.7,
      )
          // SizedBox(
          //   width: Utils().width(context) * 0.8,
          //   child: Column(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: [
          //       CustomButton(
          //         text: 'Customer',
          //         height: 50,
          //         backgroundColor: AppColors.blue,
          //         onPressed: () {
          //           Navigator.pushNamed(
          //               context, CustomerRoutes.customerProfileSetup);
          //         },
          //       ),
          //       SizedBox(height: 20),
          //       CustomButton(
          //         text: 'Admin/Agent',
          //         height: 50,
          //         backgroundColor: AppColors.blue,
          //         onPressed: () {
          //           Navigator.pushNamed(
          //               context, MarketingRoutes.marketingHostScreen);
          //         },
          //       )
          //     ],
          //   ),
          // ),
          ),
    );
  }
}
