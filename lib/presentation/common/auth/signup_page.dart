import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_button.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_textfield.dart';

class SignupPage extends StatelessWidget {
  SignupPage({super.key});
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _repass = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                SizedBox(height: 30),
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
                SizedBox(height: 15),
                Text(
                  'OR',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 15),
                // Name textField
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Full Name',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    CustomTextField(
                      controller: _name,
                      borderRadius: 10,
                      height: 45,
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
                    Text(
                      'Email',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    CustomTextField(
                      controller: _email,
                      borderRadius: 10,
                      height: 45,
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
                    Text(
                      'Password',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    CustomTextField(
                      controller: _email,
                      borderRadius: 10,
                      height: 45,
                      maxLines: 1,
                      isPassword: true,
                      keyboardType: TextInputType.visiblePassword,
                      hintText: 'Create a Password',
                    ),
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
