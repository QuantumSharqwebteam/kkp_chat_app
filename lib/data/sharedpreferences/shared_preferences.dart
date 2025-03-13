import 'package:shared_preferences/shared_preferences.dart';

class Sharedpreferences {
  static const String _keyToken = 'token';
  static const String _userType = '0';

  static Future<void> saveToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
  }

  static Future<void> saveUserType(String userType) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userType, userType);
  }
}
