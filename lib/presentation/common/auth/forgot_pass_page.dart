import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';
import 'package:kkp_chat_app/data/repositories/auth_repository.dart';
import 'package:kkp_chat_app/presentation/common/auth/verification_page.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_button.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_textfield.dart';

class ForgotPassPage extends StatefulWidget {
  const ForgotPassPage({super.key});

  @override
  State<ForgotPassPage> createState() => _ForgotPassPageState();
}

class _ForgotPassPageState extends State<ForgotPassPage> {
  AuthRepository auth = AuthRepository();
  final _email = TextEditingController();
  String? errorText;
  bool _isloading = false;
  DateTime? _lastPressed;

  // Method to validate email format
  bool _isValidEmail(String email) {
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  Future<void> forgetPassword(context) async {
    _isloading = true;

    try {
      final response = await auth.sendOtp(email: _email.text);
      if (response['message'] == "OTP sent") {
        _isloading = false;

        Navigator.push(context, MaterialPageRoute(builder: (_) {
          return VerificationPage(email: _email.text, isNewAccount: false);
        }));
      } else {
        _isloading = false;

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(response['message'])));
      }
    } catch (e) {
      _isloading = false;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
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
        body: SafeArea(
          child: Center(
            heightFactor: 1,
            child: SizedBox(
              width: Utils().width(context) * 0.8,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    Image.asset(
                      'assets/images/forgot.png',
                      height: 300,
                    ),
                    Text(
                      'Forgot Password?',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'No worries! Enter your email address below, and we will send you a link to reset your password',
                      style: TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
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
                          controller: _email,
                          maxLines: 1,
                          errorText: errorText,
                          keyboardType: TextInputType.emailAddress,
                          hintText: 'Enter your Email',
                        ),
                        SizedBox(height: 40),
                        _isloading
                            ? Center(
                                child: CircularProgressIndicator(),
                              )
                            : CustomButton(
                                text: 'Submit',
                                onPressed: () {
                                  setState(() {
                                    if (_email.text.isEmpty) {
                                      errorText = 'Email can\'t be empty';
                                    } else if (!_isValidEmail(_email.text)) {
                                      errorText =
                                          'Please enter a valid email address';
                                    } else {
                                      errorText = null;
                                      forgetPassword(context);
                                      // Navigator.push(context,
                                      //     MaterialPageRoute(builder: (_) {
                                      //   return VerificationPage(
                                      //     email: _email.text,
                                      //     isNewAccount: false,
                                      //   );
                                      // }));
                                    }
                                  });
                                },
                              ),
                        SizedBox(height: 20),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_back_rounded,
                                size: 20,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Back to Login',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return isAndroid12orAbove
        ? PopScope(
            onPopInvoked: (_) {
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
              } else {
                // Allow system navigation
                Navigator.pop(context);
              }
            },
            child: content,
          )
        : WillPopScope(
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
                return false; // Do not exit yet
              }
              return true; // Proceed to exit
            },
            child: content,
          );
  }
}
