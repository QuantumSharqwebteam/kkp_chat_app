import 'package:flutter/material.dart';
import 'package:kkp_chat_app/presentation/admin/screens/add_agent.dart';
import 'package:kkp_chat_app/presentation/admin/screens/admin_home.dart';
import 'package:kkp_chat_app/presentation/admin/screens/agent_profile_list.dart';
import 'package:kkp_chat_app/presentation/admin/screens/customer_inquries.dart';
import 'package:kkp_chat_app/presentation/common/chat/transfer_agent_screen.dart';
import 'package:kkp_chat_app/presentation/common/privacy_page.dart';
import 'package:kkp_chat_app/presentation/marketing/screen/add_product_screen.dart';
import 'package:kkp_chat_app/presentation/marketing/screen/agent_chat_screen.dart';
import 'package:kkp_chat_app/presentation/marketing/screen/agent_home_screen.dart';
import 'package:kkp_chat_app/presentation/marketing/screen/marketing_host.dart';
import 'package:kkp_chat_app/presentation/marketing/screen/marketing_product_descrption_page.dart';
import 'package:kkp_chat_app/presentation/marketing/screen/settings/marketing_settings.dart';
import 'package:kkp_chat_app/presentation/marketing/screen/marketings_notifications_page.dart';

import '../../data/models/product_model.dart';

class MarketingRoutes {
  static const String home = '/home';

  static const String privacy = "/privacy";
  // admin side
  static const String adminHome = "/adminHome";
  static const String addAgent = "/addAgentPage";
  static const String agentProfileList = "/agentProfileList";
  static const String customerInquriesPage = "/customerInquriesPage";

  //marketing side
  static const String agentChatScreen = "Agent_chat";
  static const String marketingHostScreen = "Marketing_host";
  static const String agentHomeScreen = "AgentHomeScreen";
  static const String marketingNotifications = "Notification_page";
  static const String addProductScreen = "Add_Product_screen";
  static const String marketingProductDescription =
      "Marketing_Product_Description_Page";
  static const String marketingSettings = "/Marketing_Settings";
  static const String transferAgentScreen = "Transfer_agent";

  static List<String> allRoutes = [
    home,
    privacy,
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
    agentChatScreen,
    transferAgentScreen,
  ];
}

Route<dynamic> generateMarketingRoute(RouteSettings settings) {
  switch (settings.name) {
    case MarketingRoutes.marketingHostScreen:
      return MaterialPageRoute(builder: (_) => MarketingHost());

    case MarketingRoutes.privacy:
      return MaterialPageRoute(builder: (_) => PrivacyPage());

    case MarketingRoutes.agentHomeScreen:
      return MaterialPageRoute(builder: (_) => AgentHomeScreen());

    case MarketingRoutes.marketingNotifications:
      return MaterialPageRoute(builder: (_) => NotificationsScreen());

    case MarketingRoutes.addProductScreen:
      return MaterialPageRoute(builder: (_) => AddProductScreen());

    case MarketingRoutes.transferAgentScreen:
      return MaterialPageRoute(builder: (_) => TransferAgentScreen());

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
        ),
      );

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

    case MarketingRoutes.agentChatScreen:
      // final args = settings.arguments;
      return MaterialPageRoute(builder: (_) => AgentChatScreen());

    default:
      return MaterialPageRoute(
          builder: (_) => Scaffold(
                body: Center(child: Text("no such page available")),
              ));
  }
}
