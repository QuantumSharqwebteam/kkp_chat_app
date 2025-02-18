import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/routes.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_button.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_textfield.dart';

class NewPassPage extends StatelessWidget {
  NewPassPage({super.key});

  final _newpass = TextEditingController();
  final _repass = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    'assets/images/new_pass.png',
                    height: 300,
                  ),
                  Text(
                    'Create new Password',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Your new passwordmust be diffrent from the previously used password',
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
                          'New Password',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                      SizedBox(height: 5),
                      CustomTextField(
                        controller: _newpass,
                        maxLines: 1,
                        isPassword: true,
                        keyboardType: TextInputType.emailAddress,
                        hintText: 'Enter Password',
                      ),
                      SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Text(
                          'Confirm New Password',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                      SizedBox(height: 5),
                      CustomTextField(
                        controller: _repass,
                        maxLines: 1,
                        isPassword: true,
                        keyboardType: TextInputType.emailAddress,
                        hintText: 'Re-enter Password',
                      ),
                      SizedBox(height: 40),
                      CustomButton(
                        text: 'Reset Password',
                        onPressed: () {
                          Navigator.pushNamed(context, Routes.login);
                        },
                      ),
                      SizedBox(height: 20),
                    ],
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
