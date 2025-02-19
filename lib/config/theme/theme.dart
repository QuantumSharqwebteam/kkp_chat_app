import 'package:flutter/material.dart';

class AppTheme {
  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: Colors.white,
    fontFamily: 'Poppins',
    appBarTheme: AppBarTheme(
      color: Colors.white,
      elevation: 4,
    ),
    // textTheme: TextTheme(
    //   bodyText1: TextStyle(color: Colors.black),
    //   bodyText2: TextStyle(color: Colors.black),
    //   headline1: TextStyle(color: Colors.black),
    // ),
    // buttonTheme: ButtonThemeData(
    //   buttonColor: Colors.blue,
    //   textTheme: ButtonTextTheme.primary,
    // ),
    // iconTheme: IconThemeData(
    //   color: Colors.blue,
    // ),
  );
}
