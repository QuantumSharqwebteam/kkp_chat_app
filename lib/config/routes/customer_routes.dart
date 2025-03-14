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
import 'package:kkp_chat_app/presentation/customer/screen/customer_profile_setup_page.dart';
import 'package:kkp_chat_app/presentation/customer/screen/settings/about_settings_page.dart';
import 'package:kkp_chat_app/presentation/customer/screen/settings/archive_settings_page.dart';
import 'package:kkp_chat_app/presentation/customer/screen/settings/change_password.dart';
import 'package:kkp_chat_app/presentation/customer/screen/settings/notification_settings.dart';
import 'package:kkp_chat_app/presentation/customer/screen/settings/order_enquiries.dart';
import 'package:kkp_chat_app/presentation/customer/screen/settings/password_and_security.dart';
import 'package:kkp_chat_app/presentation/customer/screen/settings/save_login_page.dart';
import 'package:kkp_chat_app/presentation/marketing/screen/chat_screen.dart';

import '../../data/models/product_model.dart';

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
  static const String customerProfileSetup = "customerProfileSetup";
  static const String passwordAndSecurity = "passwordAndSecurity";
  static const String changePassword = "changePassword";
  static const String saveLogin = "saveLogin";
  static const String archiveSettings = "archiveSettings";
  static const String notificationSettings = "notificationSettings";
  static const String orderEnquiries = "orderEnquiries";
  static const String aboutSettingPage = "aboutSettingPage";

  static List<String> allRoutes = [
    customerHome,
    onBoarding,
    signUp,
    login,
    forgot,
    newPass,
    verification,
    customerHost,
    customerNotification,
    customerProductDescriptionPage,
    customerSupportChat,
    customerProfileSetup,
    passwordAndSecurity,
    changePassword,
    saveLogin,
    archiveSettings,
    notificationSettings,
    orderEnquiries,
    aboutSettingPage,
  ];
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
      final product = settings.arguments as Product?;
      if (product == null) {
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text("Error: No product data provided")),
          ),
        );
      }
      return MaterialPageRoute(
        builder: (_) => CustomerProductDescriptionPage(product: product),
      );

    case CustomerRoutes.customerProfileSetup:
      return MaterialPageRoute(builder: (_) => CustomerProfileSetupPage());

    case CustomerRoutes.passwordAndSecurity:
      return MaterialPageRoute(builder: (_) => PasswordAndSecurity());

    case CustomerRoutes.changePassword:
      return MaterialPageRoute(builder: (_) => ChangePassword());

    case CustomerRoutes.saveLogin:
      return MaterialPageRoute(builder: (_) => SaveLoginPage());

    case CustomerRoutes.archiveSettings:
      return MaterialPageRoute(builder: (_) => ArchiveSettingsPage());

    case CustomerRoutes.notificationSettings:
      return MaterialPageRoute(builder: (_) => NotificationSettings());

    case CustomerRoutes.orderEnquiries:
      return MaterialPageRoute(builder: (_) => OrderEnquiries());

    case CustomerRoutes.aboutSettingPage:
      return MaterialPageRoute(builder: (_) => AboutSettingsPage());

    case CustomerRoutes.customerSupportChat:
      return MaterialPageRoute(
        builder: (_) => ChatScreen(
          agentImage: 'assets/images/user4.png',
          agentName: 'Product Enquirers',
          customerImage: 'assets/images/profile.png',
          customerName: 'John',
        ),
      );

    default:
      return MaterialPageRoute(builder: (_) => CustomerHomePage());
  }
}
