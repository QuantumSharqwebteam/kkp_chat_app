import 'package:flutter/material.dart';
import 'package:kkp_chat_app/presentation/common/home_screen.dart';

class Routes {
  static const String home = '/home';
}

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case Routes.home:
      return MaterialPageRoute(builder: (_) => HomeScreen());

    default:
      return MaterialPageRoute(builder: (_) => HomeScreen());
  }
}
