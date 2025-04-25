import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/routes/customer_routes.dart';
import 'package:kkpchatapp/config/routes/marketing_routes.dart';
import 'package:kkpchatapp/core/network/auth_api.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/presentation/common/onboarding_page.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init();
    });
  }

  Future<void> _init() async {
    // 1. Read token & userType in parallel
    final results = await Future.wait([
      LocalDbHelper.getToken(),
      LocalDbHelper.getUserType(),
    ]);

    final String? token = results[0];
    final String? userType = results[1];

    // 2. Conditionally refresh
    Map<String, dynamic>? refreshResp;
    if (token != null) {
      try {
        refreshResp = await AuthApi().refreshToken(token);
        if (refreshResp['status'] == 200 || refreshResp['status'] == 201) {
          await LocalDbHelper.saveToken(refreshResp['token']);
        }
      } catch (_) {
        refreshResp = null;
      }
    }

    // Navigate based on the result
    if (userType != null &&
        (refreshResp?['status'] == 200 || refreshResp?['status'] == 201)) {
      final route = (userType == '0')
          ? CustomerRoutes.customerHost
          : MarketingRoutes.marketingHostScreen;
      if (mounted) {
        Navigator.pushReplacementNamed(context, route);
      }
    } else {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => OnboardingPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Image(
          image: AssetImage('assets/icons/app_logo.png'),
          width: 200,
          height: 200,
        ),
      ),
    );
  }
}
