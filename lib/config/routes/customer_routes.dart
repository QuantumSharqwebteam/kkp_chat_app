import 'package:flutter/material.dart';
import 'package:kkp_chat_app/presentation/common/auth/forgot_pass_page.dart';
import 'package:kkp_chat_app/presentation/common/auth/login_page.dart';
import 'package:kkp_chat_app/presentation/common/auth/new_pass_page.dart';
import 'package:kkp_chat_app/presentation/common/auth/signup_page.dart';
import 'package:kkp_chat_app/presentation/common/auth/verification_page.dart';
import 'package:kkp_chat_app/presentation/common/onboarding_page.dart';
import 'package:kkp_chat_app/presentation/customer/screen/customer_home_page.dart';
import 'package:kkp_chat_app/presentation/customer/screen/customer_host.dart';
import 'package:kkp_chat_app/presentation/customer/screen/customer_notification_page.dart';
import 'package:kkp_chat_app/presentation/customer/screen/customer_product_description_page.dart';
import 'package:kkp_chat_app/presentation/marketing/screen/chat_screen.dart';

class CustomerRoutes {
  static const String customerHome = '/customerHome';
  static const String onBoarding = '/onBoarding';
  static const String signUp = '/signUp';
  static const String login = '/login';
  static const String forgot = '/forgot';
  static const String newPass = '/newPass';
  static const String verification = '/verification';

  static const String customerHost = "customerHost";
  static const String customerNotification = "customerNotification";
  static const String customerProductDescriptionPage =
      "customerProductDescription";
  static const String customerSupportChat = "customerSuppoertChat";
}

Route<dynamic> generateCustomerRoute(RouteSettings settings) {
  switch (settings.name) {
    case CustomerRoutes.onBoarding:
      return MaterialPageRoute(builder: (_) => OnboardingPage());

    case CustomerRoutes.signUp:
      return MaterialPageRoute(builder: (_) => SignupPage());

    case CustomerRoutes.login:
      return MaterialPageRoute(builder: (_) => LoginPage());

    case CustomerRoutes.forgot:
      return MaterialPageRoute(builder: (_) => ForgotPassPage());

    case CustomerRoutes.newPass:
      return MaterialPageRoute(builder: (_) => NewPassPage());

    case CustomerRoutes.verification:
      return MaterialPageRoute(builder: (_) => VerificationPage());

    case CustomerRoutes.customerHost:
      return MaterialPageRoute(builder: (_) => CustomerHost());

    case CustomerRoutes.customerNotification:
      return MaterialPageRoute(builder: (_) => CustomerNotificationPage());

    case CustomerRoutes.customerProductDescriptionPage:
      return MaterialPageRoute(
          builder: (_) => CustomerProductDescriptionPage());

    case CustomerRoutes.customerSupportChat:
      return MaterialPageRoute(
          builder: (_) => ChatScreen(
                agentImage: 'assets/images/user4.png',
                agentName: 'Product Enquirers',
                customerImage: 'assets/images/profile.png',
                customerName: 'John',
              ));

    default:
      return MaterialPageRoute(builder: (_) => CustomerHomePage());
  }
}
