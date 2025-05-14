import 'package:flutter/material.dart';
import 'package:kkpchatapp/data/repositories/auth_repository.dart';
import 'package:kkpchatapp/presentation/common/auth/verification_page.dart';

class ForgotPassProvider with ChangeNotifier {
  String _email = '';
  String? _errorText;
  bool _isLoading = false;

  String get email => _email;
  String? get errorText => _errorText;
  bool get isLoading => _isLoading;

  void setEmail(String email) {
    _email = email;
    notifyListeners();
  }

  void setErrorText(String? errorText) {
    _errorText = errorText;
    notifyListeners();
  }

  void setIsLoading(bool isLoading) {
    _isLoading = isLoading;
    notifyListeners();
  }

  Future<void> forgetPassword(BuildContext context) async {
    setIsLoading(true);

    try {
      final response = await AuthRepository().sendOtp(email: _email);
      if (response['message'] == "OTP sent") {
        setIsLoading(false);
        if (context.mounted) {
          Navigator.push(context, MaterialPageRoute(builder: (_) {
            return VerificationPage(email: _email, isNewAccount: false);
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
