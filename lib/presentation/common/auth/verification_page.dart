import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/routes/customer_routes.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/logic/auth/verification_provider.dart';
import 'package:kkpchatapp/presentation/common/auth/new_pass_page.dart';
import 'package:kkpchatapp/presentation/common/auth/signup_page.dart';
import 'package:kkpchatapp/presentation/common_widgets/back_press_handler.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_button.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({
    super.key,
    required this.email,
    required this.isNewAccount,
    this.name,
  });
  final String email;
  final bool isNewAccount;
  final String? name;

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final _otp = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final verificationProvider = Provider.of<VerificationProvider>(context);

    Widget content = GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
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
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                        errorText: verificationProvider.isOtpError
                            ? verificationProvider.errorText
                            : '',
                        forceErrorState: verificationProvider.isOtpError,
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
                        onChanged: (value) {
                          verificationProvider.setOtp(value);
                        },
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
                            Navigator.pushReplacement(context,
                                MaterialPageRoute(builder: (context) {
                              return SignupPage();
                            }));
                          },
                          width: Utils().width(context) * 0.38,
                          backgroundColor: Colors.white,
                          textColor: Colors.black,
                          fontSize: 12,
                        ),
                        verificationProvider.isVerifyLoading
                            ? Center(child: CircularProgressIndicator())
                            : CustomButton(
                                text: 'Verify',
                                onPressed: () async {
                                  if (await verificationProvider.verifyOtp(
                                          context, widget.email) ==
                                      true) {
                                    if (widget.isNewAccount == true) {
                                      if (context.mounted) {
                                        Navigator.pushReplacementNamed(context,
                                            CustomerRoutes.customerProfileSetup,
                                            arguments: {
                                              "forUpdate": false,
                                              "name": widget.name
                                            });
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
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Wrong OTP code, please try again'),
                                        ),
                                      );
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
                        text: 'Didn\'t receive the OTP? ',
                        style: TextStyle(fontSize: 12),
                        children: [
                          WidgetSpan(
                            child: InkWell(
                              onTap: verificationProvider.isResendEnabled
                                  ? () => verificationProvider
                                      .resendOtp(widget.email)
                                  : null,
                              child: Text(
                                verificationProvider.isResendEnabled
                                    ? 'Resend'
                                    : 'Resend in ${verificationProvider.timerCount} seconds',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: verificationProvider.isResendEnabled
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
      ),
    );

    return BackPressHandler(child: content);
  }
}
