import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceHelper {
  static const String _keyToken = 'token';
  static const String _userType = '0';
  static const String _name = 'name';
  static const String _email = 'email';

  static Future<void> saveToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
  }

  static Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<void> removeToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
  }

  static Future<void> saveEmail(String email) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_email, email);
  }

  static Future<String?> getEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_email);
  }

  static Future<void> removeEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_email);
  }

  static Future<void> saveUserType(String userType) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userType, userType);
  }

  static Future<String?> getUserType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userType);
  }

  static Future<void> removeUserType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userType);
  }

  static Future<void> saveName(String name) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_name, name);
  }

  static Future<String?> getName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_name);
  }

  static Future<void> removeName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_name);
  }
}
