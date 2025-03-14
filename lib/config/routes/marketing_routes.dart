import 'package:flutter/material.dart';
import 'package:kkp_chat_app/presentation/admin/screens/add_agent.dart';
import 'package:kkp_chat_app/presentation/admin/screens/admin_home.dart';
import 'package:kkp_chat_app/presentation/admin/screens/agent_profile_list.dart';
import 'package:kkp_chat_app/presentation/admin/screens/customer_inquries.dart';
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
import 'package:kkp_chat_app/presentation/marketing/screen/marketing_product_descrption_page.dart';
import 'package:kkp_chat_app/presentation/marketing/screen/settings/marketing_settings.dart';
import 'package:kkp_chat_app/presentation/marketing/screen/marketings_notifications_page.dart';

import '../../data/models/product_model.dart';

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
  static const String addAgent = "/addAgentPage";
  static const String agentProfileList = "/agentProfileList";
  static const String customerInquriesPage = "/customerInquriesPage";

  //marketing side
  static const String marketingHostScreen = "Marketing_host";
  static const String agentHomeScreen = "AgentHomeScreen";
  static const String marketingNotifications = "Notification_page";
  static const String addProductScreen = "Add_Product_screen";
  static const String marketingProductDescription =
      "Marketing_Product_Description_Page";
  static const String marketingSettings = "/Marketing_Settings";

  static List<String> allRoutes = [
    home,
    onBoarding,
    signUp,
    login,
    forgot,
    verification,
    newPass,
    privacy,
    settings,
    adminHome,
    agentHomeScreen,
    marketingHostScreen,
    marketingNotifications,
    addProductScreen,
    addAgent,
    agentProfileList,
    customerInquriesPage,
    marketingProductDescription,
    marketingSettings,
  ];
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

    case MarketingRoutes.marketingProductDescription:
      final product = settings.arguments as Product?;
      if (product == null) {
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text("Error: No product data provided")),
          ),
        );
      }
      return MaterialPageRoute(
          builder: (_) => MarketingProductDescrptionPage(
                product: product,
              ));

    //admin side

    case MarketingRoutes.adminHome:
      return MaterialPageRoute(builder: (_) => AdminHome());
    case MarketingRoutes.addAgent:
      return MaterialPageRoute(builder: (_) => AddAgent());
    case MarketingRoutes.agentProfileList:
      return MaterialPageRoute(builder: (_) => AgentProfilesPage());

    case MarketingRoutes.customerInquriesPage:
      return MaterialPageRoute(builder: (_) => CustomerInquiriesPage());

    case MarketingRoutes.marketingSettings:
      return MaterialPageRoute(builder: (_) => MarketingSettingsPage());

    default:
      return MaterialPageRoute(
          builder: (_) => Scaffold(
                body: Center(child: Text("no such page available")),
              ));
  }
}
