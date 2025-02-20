import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/routes/marketing_routes.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_button.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: Utils().width(context) * 0.9,
            child: Column(
              children: [
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      'assets/icons/logo.png',
                      height: 50,
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, MarketingRoutes.login);
                      },
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Image.asset(
                  'assets/images/onBoarding.png',
                  width: Utils().width(context) * 0.8,
                ),
                Text(
                  '“Instant Inquiries,\n Seamless Sales.”',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "A smart and efficient chat-based solution that connects customer with marketing agents in real time. Instantly manage inquiries, check stock availability, and track orders- all in one place. Empowering businesses with seamless communication and actionable insights.",
                  style: TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: Utils().height(context) * 0.08),
                CustomButton(
                  text: 'Get Started',
                  onPressed: () {
                    Navigator.pushNamed(context, MarketingRoutes.signUp);
                  },
                  borderRadius: 10,
                  backgroundColor: AppColors.blue,
                  borderColor: Colors.black,
                  borderWidth: 2,
                  width: Utils().width(context) * 0.5,
                  height: 45,
                  fontSize: 12,
                ),
                Spacer(),
                SizedBox(
                  width: Utils().width(context) * 0.7,
                  child: Text.rich(
                    TextSpan(
                      text: 'By using KKP chat application, You agree to the ',
                      style: TextStyle(fontSize: 12),
                      children: [
                        WidgetSpan(
                          child: InkWell(
                            onTap: () {},
                            child: Text(
                              'Terms',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        TextSpan(
                          text: ' and ',
                          style: TextStyle(fontSize: 12),
                        ),
                        WidgetSpan(
                          child: InkWell(
                            onTap: () {},
                            child: Text(
                              'Privacy Policy',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
