import 'package:kkpchatapp/core/network/auth_api.dart';
import 'package:kkpchatapp/data/models/address_model.dart';
import 'package:kkpchatapp/data/models/profile_model.dart';

class AuthRepository {
  final AuthApi _authApi;

  AuthRepository({AuthApi? authApi}) : _authApi = authApi ?? AuthApi();

  Future<Map<String, dynamic>> signup(
      {required String email, required String password}) {
    return _authApi.signup(email: email, password: password);
  }

  Future<Map<String, dynamic>> login(
      {required String email, required String password}) {
    return _authApi.login(email: email, password: password);
  }

  Future<Map<String, dynamic>> updateUserDetails({
    String? name,
    String? number,
    String? customerType,
    String? gstNo,
    String? panNo,
    String? profileUrl,
    Address? address,
  }) {
    return _authApi.updateDetails(
      name: name,
      number: number,
      customerType: customerType,
      address: address,
      gstNo: gstNo,
      panNo: panNo,
      profileUrl: profileUrl,
    );
  }

  Future<Map<String, dynamic>> forgotPassword(
      {required String email, required String password}) {
    return _authApi.forgetPassword(email: email, password: password);
  }

  Future<Map<String, dynamic>> sendOtp({required String email}) {
    return _authApi.sendOtp(email: email);
  }

  Future<Profile> getUserInfo() {
    return _authApi.getUserInfo();
  }

  Future<Map<String, dynamic>> verifyOtp(
      {required String email, required int otp}) {
    return _authApi.verifyOtp(email: email, otp: otp);
  }

  Future<Map<String, dynamic>> updatePassword(
      {required String currentPassword,
      required String newPassword,
      required String email}) {
    return _authApi.updatePasswordFromSettings(
        currentPassword, newPassword, email);
  }
}
