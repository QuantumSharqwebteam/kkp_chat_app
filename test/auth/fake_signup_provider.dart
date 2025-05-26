import 'package:flutter/material.dart';

import 'fake_auth_repository.dart';
import 'fake_helper_functions.dart';
import 'fake_local_db_helper.dart';

class FakeSignupProvider with ChangeNotifier {
  String _name = '';
  String _email = '';
  String _password = '';
  String _rePassword = '';
  bool _isLoading = false;
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _rePasswordError;

  String get name => _name;
  String get email => _email;
  String get password => _password;
  String get rePassword => _rePassword;
  bool get isLoading => _isLoading;
  String? get nameError => _nameError;
  String? get emailError => _emailError;
  String? get passwordError => _passwordError;
  String? get rePasswordError => _rePasswordError;

  final FakeAuthRepository auth = FakeAuthRepository();
  final FakeHelperFunctions helperFunctions = FakeHelperFunctions();

  void setName(String name) {
    _name = name;
    notifyListeners();
  }

  void setEmail(String email) {
    _email = email;
    notifyListeners();
  }

  void setPassword(String password) {
    _password = password;
    notifyListeners();
  }

  void setRePassword(String rePassword) {
    _rePassword = rePassword;
    notifyListeners();
  }

  void setIsLoading(bool isLoading) {
    _isLoading = isLoading;
    notifyListeners();
  }

  void setNameError(String? error) {
    _nameError = error;
    notifyListeners();
  }

  void setEmailError(String? error) {
    _emailError = error;
    notifyListeners();
  }

  void setPasswordError(String? error) {
    _passwordError = error;
    notifyListeners();
  }

  void setRePasswordError(String? error) {
    _rePasswordError = error;
    notifyListeners();
  }

  Future<void> signup() async {
    setIsLoading(true);
    setNameError(null);
    setEmailError(null);
    setPasswordError(null);
    setRePasswordError(null);

    if (_name.trim().isEmpty) {
      setNameError("Name can't be Empty");
      setIsLoading(false);
      return;
    }

    if (_email.trim().isEmpty) {
      setEmailError("Email can't be Empty");
      setIsLoading(false);
      return;
    }

    if (!helperFunctions.isValidEmail(_email.trim())) {
      setEmailError("Please enter a valid email address");
      setIsLoading(false);
      return;
    }

    if (_password.trim().isEmpty) {
      setPasswordError("Password can't be Empty");
      setIsLoading(false);
      return;
    }

    if (_rePassword.trim().isEmpty) {
      setRePasswordError("Re-enter Password can't be Empty");
      setIsLoading(false);
      return;
    }

    if (_password != _rePassword) {
      setPasswordError("Password doesn't match");
      setRePasswordError("Password doesn't match");
      setIsLoading(false);
      return;
    }

    try {
      final response = await auth.signup(email: _email, password: _password);

      if (response['message'] == "User signed up successfully") {
        await FakeLocalDbHelper.saveToken(response['token'].toString());
        await FakeLocalDbHelper.saveUserType("0");

        final result = await auth.sendOtp(email: _email);
        if (result['message'] == "OTP sent") {
          // Simulate navigation to VerificationPage
        } else {
          // Simulate showing a snackbar
        }
      } else if (response['status'] == 400) {
        setEmailError("Email already exists.");
      }
    } catch (e) {
      // Simulate showing an error dialog
    } finally {
      setIsLoading(false);
    }
  }

  // Future<void> _saveUser(String name) async {
  //   try {
  //     final response = await auth.updateUserDetails(name: name);
  //     if (response['message'] == "Item updated successfully") {
  //       await FakeLocalDbHelper.saveName(response['data']['name'].toString());
  //     }
  //   } catch (e) {
  //     // Simulate showing an error snackbar
  //   }
  // }
}
