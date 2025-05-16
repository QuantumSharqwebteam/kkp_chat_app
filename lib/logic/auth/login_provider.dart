import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/routes/customer_routes.dart';
import 'package:kkpchatapp/config/routes/marketing_routes.dart';
import 'package:kkpchatapp/core/utils/helper_functions.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/repositories/auth_repository.dart';

class LoginProvider with ChangeNotifier {
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

  AuthRepository auth = AuthRepository();

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

  Future<void> login(
      BuildContext context, String email, String password) async {
    setIsLoading(true);
    setEmailError('');
    setPasswordError('');

    if (email.isEmpty) {
      setEmailError('Email can\'t be empty');
      setIsLoading(false);
      return;
    }

    if (!HelperFunctions().isValidEmail(email)) {
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
      await auth.login(email: email, password: password).then((value) async {
        if (value['message'] == 'User logged in successfully') {
          if (kDebugMode) {
            print("🪙TOKEN ${value['token']}");
            print("🧑‍🦰ROLE ${value['role']}");
            print("✉️EMAIL $email");
          }
          await LocalDbHelper.saveToken(value['token'].toString());
          await LocalDbHelper.saveEmail(email);
          await LocalDbHelper.saveUserType(value['role'].toString());

          if (value['role'].toString() == "0") {
            //customer
            if (context.mounted) {
              Navigator.pushReplacementNamed(
                  context, CustomerRoutes.customerHost);
            }
          } else if (value['role'].toString() == "1") {
            //admin
            if (context.mounted) {
              Navigator.pushReplacementNamed(
                  context, MarketingRoutes.marketingHostScreen);
            }
          } else if (value['role'].toString() == "2") {
            //agent
            if (context.mounted) {
              Navigator.pushReplacementNamed(
                  context, MarketingRoutes.marketingHostScreen);
            }
          } else if (value['role'].toString() == "3") {
            //agent head
            if (context.mounted) {
              Navigator.pushReplacementNamed(
                  context, MarketingRoutes.marketingHostScreen);
            }
          } else {
            // Invalid user type
            LocalDbHelper.removeEmail();
            LocalDbHelper.removeName();
            LocalDbHelper.removeProfile();
            LocalDbHelper.removeToken();
            LocalDbHelper.removeUserType();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Invalid Credentials"),
                ),
              );
            }
          }
        } else if (value['message'] == "Invalid password") {
          setPasswordError("Wrong password");
        } else if (value['message'] == "Invalid email") {
          setEmailError("Invalid Email");
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("${value['status']} : ${value['message']}"),
              ),
            );
          }
        }
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
          ),
        );
      }
      debugPrint("Error: $e");
    } finally {
      setIsLoading(false);
    }
  }
}
