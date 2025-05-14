import 'package:flutter/material.dart';
import 'package:kkpchatapp/data/repositories/auth_repository.dart';
import 'package:kkpchatapp/presentation/common/auth/login_page.dart';

class NewPassProvider with ChangeNotifier {
  String _newPassword = '';
  String _rePassword = '';
  String? _newPassError;
  String? _rePassError;
  bool _isLoading = false;

  String get newPassword => _newPassword;
  String get rePassword => _rePassword;
  String? get newPassError => _newPassError;
  String? get rePassError => _rePassError;
  bool get isLoading => _isLoading;

  void setNewPassword(String newPassword) {
    _newPassword = newPassword;
    notifyListeners();
  }

  void setRePassword(String rePassword) {
    _rePassword = rePassword;
    notifyListeners();
  }

  void setNewPassError(String? error) {
    _newPassError = error;
    notifyListeners();
  }

  void setRePassError(String? error) {
    _rePassError = error;
    notifyListeners();
  }

  void setIsLoading(bool isLoading) {
    _isLoading = isLoading;
    notifyListeners();
  }

  Future<void> changePassword(BuildContext context, String email) async {
    setIsLoading(true);

    if (_newPassword.trim().isEmpty) {
      setNewPassError("Field can't be empty");
      setIsLoading(false);
      return;
    }
    if (_rePassword.trim().isEmpty) {
      setRePassError("Field can't be empty");
      setIsLoading(false);
      return;
    }
    if (_newPassword.trim() != _rePassword.trim()) {
      setNewPassError("Passwords doesn't match");
      setRePassError("Passwords doesn't match");
      setIsLoading(false);
      return;
    }

    try {
      final response = await AuthRepository()
          .forgotPassword(password: _rePassword, email: email);

      if (response['message'] ==
          'OTP Verified and New Password has been Set Successfully!') {
        setIsLoading(false);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Password Changed Successfully")));
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return LoginPage();
          }));
        }
      } else {
        setIsLoading(false);
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(response['message'])));
        }
      }
    } catch (e) {
      setIsLoading(false);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}
