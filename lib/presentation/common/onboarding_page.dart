import 'package:flutter/material.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';

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
                    Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
