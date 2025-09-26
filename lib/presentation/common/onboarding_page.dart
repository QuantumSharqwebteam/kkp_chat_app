import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/l10n/generated/app_localizations.dart';
import 'package:kkpchatapp/presentation/common/auth/login_page.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_button.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
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
                      height: 45,
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) {
                          return LoginPage();
                        }));
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
                  height: 270,
                ),
                Text(
                  '“${l.appTagline}”',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  l.appDescription,
                  style: TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: Utils().height(context) * 0.04),
                CustomButton(
                  text: 'Get Started',
                  onPressed: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) {
                      return LoginPage();
                    }));
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
                      text: l.privacyPolicyAgreement,
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
                            onTap: () {
                              Utils().launchURL(
                                  'https://www.termsfeed.com/live/0e2fa12f-6123-4516-a47a-73308e7e90b8');
                            },
                            child: Text(
                              l.privacyPolicy,
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.blue),
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
