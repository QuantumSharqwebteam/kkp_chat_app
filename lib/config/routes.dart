import 'package:flutter/material.dart';
import 'package:kkp_chat_app/presentation/common/auth/login_page.dart';
import 'package:kkp_chat_app/presentation/common/auth/signup_page.dart';
import 'package:kkp_chat_app/presentation/common/home_screen.dart';
import 'package:kkp_chat_app/presentation/common/onboarding_page.dart';

class Routes {
  static const String home = '/home';
  static const String onBoarding = '/onBoarding';
  static const String signUp = '/signUp';
  static const String login = '/login';
}

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case Routes.home:
      return MaterialPageRoute(builder: (_) => HomeScreen());

    case Routes.onBoarding:
      return MaterialPageRoute(builder: (_) => OnboardingPage());

    case Routes.signUp:
      return MaterialPageRoute(builder: (_) => SignupPage());

    case Routes.login:
      return MaterialPageRoute(builder: (_) => LoginPage());

    default:
      return MaterialPageRoute(builder: (_) => HomeScreen());
  }
}
