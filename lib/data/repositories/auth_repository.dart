import 'package:kkp_chat_app/core/network/auth_api.dart';

class AuthRepository {
  final AuthApi _authApi;

  AuthRepository({AuthApi? authApi}) : _authApi = authApi ?? AuthApi();

  Future<Map<String, dynamic>> signup(String email, String password) {
    return _authApi.signup(email, password);
  }

  Future<Map<String, dynamic>> login(String email, String password) {
    return _authApi.login(email, password);
  }

  Future<Map<String, dynamic>> updatePassword(
      String currentPassword, String newPassword, String email) {
    return _authApi.updatePasswordFromSettings(
        currentPassword, newPassword, email);
  }
}
