import 'package:flutter/material.dart';
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
import 'package:kkp_chat_app/presentation/customer/screen/customer_chat_screen.dart';

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
      final args = settings.arguments as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (_) => CustomerProfileSetupPage(
          forUpdate: args?['forUpdate'] ?? false,
          name: args?['name'],
          email: args?['email'],
          number: args?['number'],
          gstNo: args?['gstNo'],
          panNo: args?['panNo'],
          address: args?['address'],
          isExportSelected: args?['isExportSelected'] ?? false,
          isDomesticSelected: args?['isDomesticSelected'] ?? false,
        ),
      );

    case CustomerRoutes.passwordAndSecurity:
      return MaterialPageRoute(builder: (_) => PasswordAndSecurity());

    case CustomerRoutes.changePassword:
      return MaterialPageRoute(builder: (_) => ChangePassword());

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
        builder: (_) => CustomerChatScreen(),
      );

    default:
      return MaterialPageRoute(builder: (_) => CustomerHomePage());
  }
}
