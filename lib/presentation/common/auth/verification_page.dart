import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/routes/customer_routes.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';
import 'package:kkp_chat_app/data/repositories/auth_repository.dart';
import 'package:kkp_chat_app/presentation/common/auth/new_pass_page.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_button.dart';
import 'package:pinput/pinput.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({
    super.key,
    required this.email,
    required this.isNewAccount,
  });
  final String email;
  final bool isNewAccount;

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final _otp = TextEditingController();
  AuthRepository auth = AuthRepository();
  bool _isVerifyLoading = false;
  bool _isResendEnabled = true;
  int _timerCount = 60;
  Timer? _timer;
  bool _isOtpError = false; // State variable to track OTP error

  Future<bool> _verifyOtp(context) async {
    setState(() {
      _isVerifyLoading = true;
      _isOtpError = false; // Reset error state on new attempt
    });

    if (_otp.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please enter the OTP')));
      setState(() {
        _isVerifyLoading = false;
        _isOtpError = true; // Set error state if OTP is empty
      });
      return false;
    }

    if (_otp.text.length != 6) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('OTP must be 6 digits long')));
      setState(() {
        _isVerifyLoading = false;
        _isOtpError = true; // Set error state if OTP length is incorrect
      });
      return false;
    }

    try {
      final response =
          await auth.verifyOtp(email: widget.email, otp: int.parse(_otp.text));

      if (response['message'] == "OTP Verified Successfully!") {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(response['message'])));
        return true;
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(response['message'])));
        setState(() {
          _isOtpError = true; // Set error state if OTP verification fails
        });
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$e"),
        ),
      );
      setState(() {
        _isOtpError = true; // Set error state if there's an exception
      });
      return false;
    } finally {
      setState(() {
        _isVerifyLoading = false;
      });
    }
  }

  void _startTimer() {
    _timerCount = 90;
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_timerCount > 0) {
          _timerCount--;
        } else {
          _isResendEnabled = true;
          _timer?.cancel();
        }
      });
    });
  }

  void _resendOtp() async {
    await auth.sendOtp(email: widget.email);
    setState(() {
      _isResendEnabled = false;
    });
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: Utils().width(context) * 0.8,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 50),
                  Text(
                    'Email Verification',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'We have sent the six digit verification code to ${widget.email}',
                    style: TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  // pinput
                  Center(
                    child: Pinput(
                      errorText: '',
                      forceErrorState:
                          _isOtpError, // Use the state variable here
                      errorBuilder: (errorText, pin) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 3),
                                child: Icon(
                                  Icons.warning_rounded,
                                  color: AppColors.errorRed,
                                  size: 20,
                                ),
                              ),
                              Text(
                                'Invalid code please try again',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.errorRed),
                              ),
                            ],
                          ),
                        );
                      },
                      useNativeKeyboard: true,
                      controller: _otp,
                      length: 6,
                      keyboardType: TextInputType.number,
                      closeKeyboardWhenCompleted: true,
                      animationCurve: Curves.easeIn,
                      showCursor: true,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      defaultPinTheme: PinTheme(
                        textStyle: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                      ),
                      focusedPinTheme: PinTheme(
                        textStyle: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.blue),
                        ),
                      ),
                      errorPinTheme: PinTheme(
                        textStyle: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 40),
                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomButton(
                        text: 'Go Back',
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        width: Utils().width(context) * 0.38,
                        backgroundColor: Colors.white,
                        textColor: Colors.black,
                        fontSize: 12,
                      ),
                      _isVerifyLoading
                          ? Center(child: CircularProgressIndicator())
                          : CustomButton(
                              text: 'Verify',
                              onPressed: () async {
                                if (await _verifyOtp(context) == true) {
                                  if (widget.isNewAccount == true) {
                                    if (context.mounted) {
                                      Navigator.pushReplacementNamed(context,
                                          CustomerRoutes.customerProfileSetup,
                                          arguments: {"forUpdate": false});
                                    }
                                  } else {
                                    if (context.mounted) {
                                      Navigator.pushReplacement(context,
                                          MaterialPageRoute(builder: (_) {
                                        return NewPassPage(
                                          email: widget.email,
                                        );
                                      }));
                                    }
                                  }
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Wrong OTP code, please try again')));
                                  }
                                }
                              },
                              width: Utils().width(context) * 0.38,
                              fontSize: 12,
                            ),
                    ],
                  ),
                  SizedBox(height: 30),
                  Text.rich(
                    TextSpan(
                      text: 'Didn\'t receive the Email? ',
                      style: TextStyle(fontSize: 12),
                      children: [
                        WidgetSpan(
                          child: InkWell(
                            onTap: _isResendEnabled ? _resendOtp : null,
                            child: Text(
                              _isResendEnabled
                                  ? 'Resend'
                                  : 'Resend in $_timerCount seconds',
                              style: TextStyle(
                                fontSize: 12,
                                color: _isResendEnabled
                                    ? AppColors.blue
                                    : Colors.grey,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  Image.asset(
                    'assets/images/verification.png',
                    height: 350,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
