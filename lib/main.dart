import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/routes/customer_routes.dart';
import 'package:kkp_chat_app/config/routes/marketing_routes.dart';
import 'package:kkp_chat_app/config/theme/theme.dart';
import 'package:kkp_chat_app/presentation/common/splash.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KKP Chat App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: "/splash",
      routes: {
        "/splash": (context) => Splash(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == CustomerRoutes.customerHost) {
          return generateCustomerRoute(settings);
        } else if (settings.name == MarketingRoutes.marketingHostScreen) {
          return generateMarketingRoute(settings);
        } else {
          return null;
        }
      },
    );
  }
}
