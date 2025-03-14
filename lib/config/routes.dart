import 'package:flutter/material.dart';
import 'package:kkp_chat_app/presentation/common/auth/forgot_pass_page.dart';
import 'package:kkp_chat_app/presentation/common/auth/login_page.dart';
import 'package:kkp_chat_app/presentation/common/auth/new_pass_page.dart';
import 'package:kkp_chat_app/presentation/common/auth/signup_page.dart';
import 'package:kkp_chat_app/presentation/common/auth/verification_page.dart';
import 'package:kkp_chat_app/presentation/common/home_screen.dart';
import 'package:kkp_chat_app/presentation/common/onboarding_page.dart';
import 'package:kkp_chat_app/presentation/marketing/screen/agent_home_screen.dart';
import 'package:kkp_chat_app/presentation/marketing/screen/marketing_host.dart';

class Routes {
  static const String home = '/home';
  static const String onBoarding = '/onBoarding';
  static const String signUp = '/signUp';
  static const String login = '/login';
  static const String forgot = '/forgot';
  static const String newPass = '/newPass';
  static const String verification = '/verification';

  //marketing side
  static const String marketingHostScreen = "Marketing_host";
  static const String agentHomeScreen = "AgentHomeScreen";
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

    case Routes.marketingHostScreen:
      return MaterialPageRoute(builder: (_) => MarketingHost());

    case Routes.forgot:
      return MaterialPageRoute(builder: (_) => ForgotPassPage());

    case Routes.newPass:
      return MaterialPageRoute(builder: (_) => NewPassPage());

    case Routes.verification:
      return MaterialPageRoute(builder: (_) => VerificationPage());
    //Marketing side routes
    case Routes.agentHomeScreen:
      return MaterialPageRoute(builder: (_) => AgentHomeScreen());

    default:
      return MaterialPageRoute(builder: (_) => HomeScreen());
  }
}
