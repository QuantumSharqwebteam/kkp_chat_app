import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kkp_chat_app/config/routes/customer_routes.dart';
import 'package:kkp_chat_app/config/routes/marketing_routes.dart';
import 'package:kkp_chat_app/config/theme/theme.dart';
import 'package:kkp_chat_app/presentation/common/splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "keys.env");
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
        if (CustomerRoutes.allRoutes.contains(settings.name)) {
          return generateCustomerRoute(settings);
        } else if (MarketingRoutes.allRoutes.contains(settings.name)) {
          return generateMarketingRoute(settings);
        } else {
          return null;
        }
      },
    );
  }
}
