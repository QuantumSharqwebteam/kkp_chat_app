import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kkpchatapp/core/utils/helper_functions.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/repositories/auth_repository.dart';
import 'package:kkpchatapp/presentation/common/auth/login_page.dart';
import 'package:kkpchatapp/presentation/common/auth/verification_page.dart';

class SignupProvider with ChangeNotifier {
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

  void setName(String name) {
    _name = name;
    if (name.trim().isEmpty) {
      setNameError("Name can't be Empty");
    } else if (!_validateName(name)) {
      setNameError("Name should be at least 3 words");
    } else {
      setNameError(null); // Clear the error if the input is valid
    }
    notifyListeners();
  }

  void setEmail(String email) {
    _email = email;
    notifyListeners();
  }

  void setPassword(String password) {
    _password = password;
    if (password.trim().isEmpty) {
      setPasswordError("Password can't be Empty");
    } else if (!_validatePassword(password)) {
      setPasswordError("Password should be at least 6 characters");
    } else {
      setPasswordError(null); // Clear the error if the input is valid
    }
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

  bool _validateName(String name) {
    return name.length >= 3;
  }

  bool _validatePassword(String password) {
    return password.length >= 6;
  }

  Future<void> signup(BuildContext context) async {
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

    if (!_validateName(_name)) {
      setNameError("Name should be at least 3 words");
      setIsLoading(false);
      return;
    }

    if (_email.trim().isEmpty) {
      setEmailError("Email can't be Empty");
      setIsLoading(false);
      return;
    }

    if (!HelperFunctions().isValidEmail(_email.trim())) {
      setEmailError("Please enter a valid email address");
      setIsLoading(false);
      return;
    }

    if (_password.trim().isEmpty) {
      setPasswordError("Password can't be Empty");
      setIsLoading(false);
      return;
    }

    if (!_validatePassword(_password)) {
      setPasswordError("Password should be at least 6 characters");
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
      final response = await AuthRepository().signup(
        email: _email,
        password: _password,
      );

      if (response['message'] == "User signed up successfully") {
        try {
          await LocalDbHelper.saveToken(response['token'].toString());
          await LocalDbHelper.saveUserType("0");

          if (context.mounted) {
            await _saveUser(context, _name);
          }

          final result = await AuthRepository().sendOtp(email: _email);
          if (result['message'] == "OTP sent") {
            if (context.mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) {
                    return VerificationPage(
                      email: _email,
                      isNewAccount: true,
                      name: _name,
                    );
                  },
                ),
              );
            }
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(result['message'] + ' Try again later')));
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) {
                return LoginPage();
              }));
            }
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(e.toString()),
            ));
          }
          return;
        }
      } else if (response['status'] == 400) {
        setEmailError("Email already exists.");
      }
    } catch (e) {
      if (context.mounted) {
        Utils().showSuccessDialog(context, "Error: ${e.toString()}", false);
      }
    } finally {
      setIsLoading(false);
    }
  }

  Future<void> _saveUser(BuildContext context, String name) async {
    try {
      final response = await AuthRepository().updateUserDetails(
          name: name,
          address: null,
          customerType: null,
          gstNo: null,
          number: null,
          panNo: null);

      if (response['message'] == "Item updated successfully") {
        await LocalDbHelper.saveName(response['data']['name'].toString());
        if (kDebugMode) {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(response['message'])));
          }
        }
      } else {
        if (kDebugMode) {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(response['message'])));
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
      return;
    }
  }
}
