import 'package:flutter/material.dart';
import 'package:kkp_chat_app/presentation/common/home_screen.dart';
import 'package:kkp_chat_app/presentation/marketing/screen/agent_home_screen.dart';

class Routes {
  static const String home = '/home';

  //marketing side routes
  static const String agentHomeScreen = "Agent_home_screen";
}

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case Routes.home:
      return MaterialPageRoute(builder: (_) => HomeScreen());

    //Marketing side routes
    case Routes.agentHomeScreen:
      return MaterialPageRoute(builder: (_) => AgentHomeScreen());

    default:
      return MaterialPageRoute(builder: (_) => HomeScreen());
  }
}
