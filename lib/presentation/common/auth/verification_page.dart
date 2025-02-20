import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/routes/marketing_routes.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_button.dart';
import 'package:pinput/pinput.dart';

class VerificationPage extends StatelessWidget {
  VerificationPage({super.key});
  final _otp = TextEditingController();
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
                    'We have sent the six digit verification code to your email address',
                    style: TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  // pinput
                  Center(
                    child: Pinput(
                      errorText: '',
                      forceErrorState: false,
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
                      CustomButton(
                        text: 'Verify',
                        onPressed: () {
                          Navigator.pushNamed(context, MarketingRoutes.newPass);
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
                            onTap: () {},
                            child: Text(
                              'Resend',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.blue,
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
