import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/repositories/auth_repository.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/presentation/common/auth/login_page.dart';
import 'package:kkpchatapp/presentation/common/auth/verification_page.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_button.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_textfield.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  AuthRepository auth = AuthRepository();
  final AuthRepository _authRepository = AuthRepository();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _repass = TextEditingController();
  bool _isLoading = false;
  String? nameError;
  String? emailError;
  String? passError;
  String? repassError;
  DateTime? _lastPressed;

  // Method to validate email format
  bool _isValidEmail(String email) {
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  Future<void> _signup(context) async {
    setState(() {
      _isLoading = true;
      nameError =
          emailError = passError = repassError = null; // Clear previous errors
    });

    if (_name.text.trim().isEmpty) {
      setState(() {
        nameError = "Name can't be Empty";
        _isLoading = false;
      });
      return;
    }

    if (_email.text.trim().isEmpty) {
      setState(() {
        emailError = "Email can't be Empty";
        _isLoading = false;
      });
      return;
    }

    if (!_isValidEmail(_email.text.trim())) {
      setState(() {
        emailError = "Please enter a valid email address";
        _isLoading = false;
      });
      return;
    }

    if (_pass.text.trim().isEmpty) {
      setState(() {
        passError = "Password can't be Empty";
        _isLoading = false;
      });
      return;
    }

    if (_repass.text.trim().isEmpty) {
      setState(() {
        repassError = "Re-enter Password can't be Empty";
        _isLoading = false;
      });
      return;
    }

    if (_pass.text != _repass.text) {
      setState(() {
        passError = repassError = "Password doesn't match";
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await _authRepository.signup(
        email: _email.text,
        password: _pass.text,
      );

      if (response['message'] == "User signed up successfully") {
        try {
          await LocalDbHelper.saveToken(response['token'].toString());

          await _saveUser(context, _name.text);

          final result = await auth.sendOtp(email: _email.text);
          if (result['message'] == "OTP sent") {
            if (context.mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) {
                    return VerificationPage(
                      email: _email.text,
                      isNewAccount: true,
                      name: _name.text,
                    );
                  },
                ),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(result['message'] + ' Try again later')));
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) {
              return LoginPage();
            }));
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()),
          ));
          return;
        }
      } else if (response['status'] == 400) {
        setState(() {
          emailError = "Email already exists.";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        Utils().showSuccessDialog(context, "Error: ${e.toString()}", false);
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveUser(context, String name) async {
    try {
      final response = await auth.updateUserDetails(
          name: name,
          address: null,
          customerType: null,
          gstNo: null,
          number: null,
          panNo: null);

      if (response['message'] == "Item updated successfully") {
        await LocalDbHelper.saveName(response['data']['name'].toString());
        if (kDebugMode) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(response['message'])));
        }
      } else {
        if (kDebugMode) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(response['message'])));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isAndroid12orAbove =
        Platform.isAndroid && int.parse(Platform.version.split('.')[0]) > 12;

    Widget content = GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Image.asset(
                'assets/icons/logo.png',
                height: 25,
              ),
            )
          ],
        ),
        body: Center(
          heightFactor: 1.2,
          child: SizedBox(
            width: Utils().width(context) * 0.8,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  CustomButton(
                    text: 'Signup with Google',
                    fontSize: 14,
                    height: 45,
                    image: SvgPicture.asset('assets/icons/google.svg'),
                    onPressed: () {},
                    textColor: Colors.black,
                    backgroundColor: Colors.white,
                    borderRadius: 10,
                    elevation: 0,
                    borderColor: Colors.grey.shade300,
                    borderWidth: 1,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'OR',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 10),
                  // Name textField
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Text(
                          'Full Name',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                      SizedBox(height: 5),
                      CustomTextField(
                        controller: _name,
                        errorText: nameError,
                        maxLines: 1,
                        keyboardType: TextInputType.name,
                        hintText: 'Enter your full name',
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  // Email textField
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Text(
                          'Email',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                      SizedBox(height: 5),
                      CustomTextField(
                        errorText: emailError,
                        controller: _email,
                        maxLines: 1,
                        keyboardType: TextInputType.emailAddress,
                        hintText: 'Enter your Email',
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  // Password textField
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Text(
                          'Password',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                      SizedBox(height: 5),
                      CustomTextField(
                        controller: _pass,
                        errorText: passError,
                        helperText: 'Must be at least 8 characters',
                        maxLines: 1,
                        isPassword: true,
                        keyboardType: TextInputType.visiblePassword,
                        hintText: 'Create a Password',
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  // Password textField
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Text(
                          'Confirm Password',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                      SizedBox(height: 5),
                      CustomTextField(
                        controller: _repass,
                        errorText: repassError,
                        helperText: 'Must be at least 8 characters',
                        borderRadius: 10,
                        height: 45,
                        maxLines: 1,
                        isPassword: true,
                        keyboardType: TextInputType.visiblePassword,
                        hintText: 'Confirm Password',
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  _isLoading
                      ? CircularProgressIndicator()
                      : CustomButton(
                          text: 'Create Account',
                          onPressed: () {
                            _signup(context);
                          },
                        ),
                  const SizedBox(height: 20),
                  Text.rich(
                    TextSpan(
                      text: 'Already have an Account? ',
                      style: AppTextStyles.black10_500,
                      children: [
                        WidgetSpan(
                          child: InkWell(
                            onTap: () {
                              Navigator.pushReplacement(context,
                                  MaterialPageRoute(builder: (context) {
                                return LoginPage();
                              }));
                            },
                            child: Text(
                              'Login',
                              style: AppTextStyles.black12_700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return isAndroid12orAbove
        ? PopScope(
            child: content,
            onPopInvoked: (_) {
              DateTime now = DateTime.now();
              if (_lastPressed == null ||
                  now.difference(_lastPressed!) > Duration(seconds: 2)) {
                _lastPressed = now;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Press back again to exit'),
                ));
              } else {
                Navigator.pop(context);
              }
            },
          )
        : WillPopScope(
            child: content,
            onWillPop: () async {
              DateTime now = DateTime.now();
              if (_lastPressed == null ||
                  now.difference(_lastPressed!) > Duration(seconds: 2)) {
                _lastPressed = now;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Press back again to exit"),
                    duration: Duration(seconds: 2),
                  ),
                );
                return false;
              }
              return true;
            },
          );
  }
}
