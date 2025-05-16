import 'package:flutter/material.dart';
import 'package:kkpchatapp/data/models/profile_model.dart';
import 'package:kkpchatapp/main.dart';
import 'package:kkpchatapp/presentation/customer/screen/customer_home_page.dart';
import 'package:kkpchatapp/presentation/customer/screen/customer_host.dart';
import 'package:kkpchatapp/presentation/customer/screen/customer_product_description_page.dart';
import 'package:kkpchatapp/presentation/customer/screen/customer_profile_setup_page.dart';
import 'package:kkpchatapp/presentation/customer/screen/settings/about_settings_page.dart';
import 'package:kkpchatapp/presentation/customer/screen/settings/archive_settings_page.dart';
import 'package:kkpchatapp/presentation/customer/screen/settings/change_password.dart';
import 'package:kkpchatapp/presentation/customer/screen/settings/notification_settings.dart';
import 'package:kkpchatapp/presentation/customer/screen/settings/order_enquiries.dart';
import 'package:kkpchatapp/presentation/customer/screen/settings/account_and_security.dart';
import 'package:kkpchatapp/presentation/customer/screen/customer_chat_screen.dart';
import 'package:kkpchatapp/presentation/marketing/screen/marketings_notifications_page.dart';

import '../../data/models/product_model.dart';

class CustomerRoutes {
  static const String customerHost = "customerHost";
  static const String customerNotification = "customerNotification";
  static const String customerProductDescriptionPage =
      "customerProductDescription";
  static const String customerSupportChat = "customerSuppoertChat";
  static const String customerProfileSetup = "customerProfileSetup";
  static const String passwordAndSecurity = "passwordAndSecurity";
  static const String changePassword = "changePassword";
  static const String archiveSettings = "archiveSettings";
  static const String notificationSettings = "notificationSettings";
  static const String orderEnquiries = "orderEnquiries";
  static const String aboutSettingPage = "aboutSettingPage";

  static List<String> allRoutes = [
    customerHost,
    customerNotification,
    customerProductDescriptionPage,
    customerSupportChat,
    customerProfileSetup,
    passwordAndSecurity,
    changePassword,
    archiveSettings,
    notificationSettings,
    orderEnquiries,
    aboutSettingPage,
  ];
}

Route<dynamic> generateCustomerRoute(RouteSettings settings) {
  switch (settings.name) {
    case CustomerRoutes.customerHost:
      return MaterialPageRoute(
          builder: (context) => CustomerHost(
                navigatorKey: navigatorKey,
              ));

    case CustomerRoutes.customerNotification:
      return MaterialPageRoute(builder: (context) => NotificationsScreen());

    case CustomerRoutes.customerProductDescriptionPage:
      final product = settings.arguments as Product?;
      if (product == null) {
        return MaterialPageRoute(
          builder: (context) => const Scaffold(
            body: Center(child: Text("Error: No product data provided")),
          ),
        );
      }
      return MaterialPageRoute(
        builder: (context) => CustomerProductDescriptionPage(product: product),
      );

    case CustomerRoutes.customerProfileSetup:
      final args = settings.arguments as Map<String, dynamic>?;
      final profile = args?['profile'] as Profile?;
      final name = args?['name'] as String?;
      return MaterialPageRoute(
        builder: (context) => CustomerProfileSetupPage(
          forUpdate: profile != null,
          profile: profile,
          name: name,
        ),
      );

    case CustomerRoutes.passwordAndSecurity:
      return MaterialPageRoute(builder: (context) => AccountAndSecurity());

    case CustomerRoutes.changePassword:
      return MaterialPageRoute(builder: (context) => ChangePassword());

    case CustomerRoutes.archiveSettings:
      return MaterialPageRoute(builder: (context) => ArchiveSettingsPage());

    case CustomerRoutes.notificationSettings:
      return MaterialPageRoute(builder: (context) => NotificationSettings());

    case CustomerRoutes.orderEnquiries:
      return MaterialPageRoute(builder: (context) => OrderEnquiries());

    case CustomerRoutes.aboutSettingPage:
      return MaterialPageRoute(builder: (context) => AboutSettingsPage());

    case CustomerRoutes.customerSupportChat:
      return MaterialPageRoute(
        builder: (context) => CustomerChatScreen(
          navigatorKey: navigatorKey,
        ),
      );

    default:
      return MaterialPageRoute(builder: (context) => CustomerHomePage());
  }
}
