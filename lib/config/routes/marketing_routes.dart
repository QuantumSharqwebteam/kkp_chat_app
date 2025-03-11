import 'package:flutter/material.dart';
import 'package:kkp_chat_app/presentation/admin/screens/admin_home.dart';
import 'package:kkp_chat_app/presentation/common/auth/forgot_pass_page.dart';
import 'package:kkp_chat_app/presentation/common/auth/login_page.dart';
import 'package:kkp_chat_app/presentation/common/auth/new_pass_page.dart';
import 'package:kkp_chat_app/presentation/common/auth/signup_page.dart';
import 'package:kkp_chat_app/presentation/common/auth/verification_page.dart';
import 'package:kkp_chat_app/presentation/common/onboarding_page.dart';
import 'package:kkp_chat_app/presentation/common/privacy_page.dart';
import 'package:kkp_chat_app/presentation/common/settings/settings_page.dart';
import 'package:kkp_chat_app/presentation/marketing/screen/add_product_screen.dart';
import 'package:kkp_chat_app/presentation/marketing/screen/agent_home_screen.dart';
import 'package:kkp_chat_app/presentation/marketing/screen/marketing_host.dart';
import 'package:kkp_chat_app/presentation/marketing/screen/notifications_page.dart';

class MarketingRoutes {
  static const String home = '/home';
  static const String onBoarding = '/onBoarding';
  static const String signUp = '/signUp';
  static const String login = '/login';
  static const String forgot = '/forgot';
  static const String newPass = '/newPass';
  static const String verification = '/verification';
  static const String privacy = "/privacy";
  static const String settings = "/settings";
  // admin side
  static const String adminHome = "/adminHome";

  //marketing side
  static const String marketingHostScreen = "Marketing_host";
  static const String agentHomeScreen = "AgentHomeScreen";
  static const String marketingNotifications = "Notification_page";
  static const String addProductScreen = "Add_Product_screen";
}

Route<dynamic> generateMarketingRoute(RouteSettings settings) {
  switch (settings.name) {
    case MarketingRoutes.onBoarding:
      return MaterialPageRoute(builder: (_) => OnboardingPage());

    case MarketingRoutes.signUp:
      return MaterialPageRoute(builder: (_) => SignupPage());

    case MarketingRoutes.login:
      return MaterialPageRoute(builder: (_) => LoginPage());

    case MarketingRoutes.marketingHostScreen:
      return MaterialPageRoute(builder: (_) => MarketingHost());

    case MarketingRoutes.forgot:
      return MaterialPageRoute(builder: (_) => ForgotPassPage());

    case MarketingRoutes.newPass:
      return MaterialPageRoute(builder: (_) => NewPassPage());

    case MarketingRoutes.verification:
      return MaterialPageRoute(builder: (_) => VerificationPage());

    case MarketingRoutes.privacy:
      return MaterialPageRoute(builder: (_) => PrivacyPage());
    case MarketingRoutes.settings:
      return MaterialPageRoute(builder: (_) => SettingsPage());

    case MarketingRoutes.agentHomeScreen:
      return MaterialPageRoute(builder: (_) => AgentHomeScreen());
    case MarketingRoutes.marketingNotifications:
      return MaterialPageRoute(builder: (_) => NotificationsScreen());
    case MarketingRoutes.addProductScreen:
      return MaterialPageRoute(builder: (_) => AddProductScreen());

    //admin side

    case MarketingRoutes.adminHome:
      return MaterialPageRoute(builder: (_) => AdminHome());

    default:
      return MaterialPageRoute(builder: (_) => AgentHomeScreen());
  }
}
