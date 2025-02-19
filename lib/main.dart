import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/routes.dart';
import 'package:kkp_chat_app/config/theme/theme.dart';

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
      initialRoute: Routes.onBoarding,
      onGenerateRoute: generateRoute,
    );
  }
}
