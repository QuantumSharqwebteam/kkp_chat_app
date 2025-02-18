import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/routes.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_button.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_textfield.dart';

class ForgotPassPage extends StatelessWidget {
  ForgotPassPage({super.key});
  final _email = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: Utils().width(context) * 0.8,
            child: Column(
              children: [
                SizedBox(height: 20),
                Image.asset(
                  'assets/images/forgot.png',
                  height: 300,
                ),
                Text(
                  'Forgot Password?',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  'No worries! Enter your email address below, and we will send you link to reset your password',
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
                      keyboardType: TextInputType.emailAddress,
                      hintText: 'Enter your Email',
                    ),
                    SizedBox(height: 40),
                    CustomButton(
                      text: 'Submit',
                      onPressed: () {
                        Navigator.pushNamed(context, Routes.verification);
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
    );
  }
}
