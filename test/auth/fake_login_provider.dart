import 'package:flutter/material.dart';

import 'fake_auth_repository.dart';
import 'fake_helper_functions.dart';
import 'fake_local_db_helper.dart';

class FakeLoginProvider with ChangeNotifier {
  String _email = '';
  String _password = '';
  bool _isLoading = false;
  String _emailError = '';
  String _passwordError = '';

  String get email => _email;
  String get password => _password;
  bool get isLoading => _isLoading;
  String get emailError => _emailError;
  String get passwordError => _passwordError;

  final FakeAuthRepository auth = FakeAuthRepository();
  final FakeHelperFunctions helperFunctions = FakeHelperFunctions();

  void setEmail(String email) {
    _email = email;
    notifyListeners();
  }

  void setPassword(String password) {
    _password = password;
    notifyListeners();
  }

  void setIsLoading(bool isLoading) {
    _isLoading = isLoading;
    notifyListeners();
  }

  void setEmailError(String error) {
    _emailError = error;
    notifyListeners();
  }

  void setPasswordError(String error) {
    _passwordError = error;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    setIsLoading(true);
    setEmailError('');
    setPasswordError('');

    if (email.isEmpty) {
      setEmailError('Email can\'t be empty');
      setIsLoading(false);
      return;
    }

    if (!helperFunctions.isValidEmail(email)) {
      setEmailError('Please enter a valid email address');
      setIsLoading(false);
      return;
    }

    if (password.isEmpty) {
      setPasswordError('Password can\'t be empty');
      setIsLoading(false);
      return;
    }

    try {
      final value = await auth.login(email: email, password: password);
      if (value['message'] == 'User logged in successfully') {
        await FakeLocalDbHelper.saveToken(value['token'].toString());
        await FakeLocalDbHelper.saveEmail(email);
        await FakeLocalDbHelper.saveUserType(value['role'].toString());
      } else if (value['message'] == "Invalid password") {
        setPasswordError("Wrong password");
      } else if (value['message'] == "Invalid email") {
        setEmailError("Invalid Email");
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      setIsLoading(false);
    }
  }
}
