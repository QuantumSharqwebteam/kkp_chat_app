import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/logic/auth/signup_provider.dart';
import 'package:kkpchatapp/presentation/common/auth/login_page.dart';
import 'package:kkpchatapp/presentation/common_widgets/back_press_handler.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_button.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_textfield.dart';
import 'package:provider/provider.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _repass = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final signupProvider = Provider.of<SignupProvider>(context);

    Widget content = GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
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
                  SizedBox(height: 20),
                  // CustomButton(
                  //   text: 'Signup with Google',
                  //   fontSize: 14,
                  //   height: 45,
                  //   image: SvgPicture.asset('assets/icons/google.svg'),
                  //   onPressed: () {},
                  //   textColor: Colors.black,
                  //   backgroundColor: Colors.white,
                  //   borderRadius: 10,
                  //   elevation: 0,
                  //   borderColor: Colors.grey.shade300,
                  //   borderWidth: 1,
                  // ),
                  // SizedBox(height: 10),
                  // Text(
                  //   'OR',
                  //   style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  // ),
                  // SizedBox(height: 10),
                  // Name textField
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Text(
                          'Full Name',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                      SizedBox(height: 5),
                      CustomTextField(
                        controller: _name,
                        errorText: signupProvider.nameError,
                        maxLines: 1,
                        keyboardType: TextInputType.name,
                        hintText: 'Enter your full name',
                        onChanged: (value) => signupProvider.setName(value),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  // Email textField
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
                        errorText: signupProvider.emailError,
                        controller: _email,
                        maxLines: 1,
                        keyboardType: TextInputType.emailAddress,
                        hintText: 'Enter your Email',
                        onChanged: (value) => signupProvider.setEmail(value),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  // Password textField
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Text(
                          'Password',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                      SizedBox(height: 5),
                      CustomTextField(
                        controller: _pass,
                        errorText: signupProvider.passwordError,
                        //helperText: 'Must be at least 6 characters',
                        maxLines: 1,
                        isPassword: true,
                        keyboardType: TextInputType.visiblePassword,
                        hintText: 'Create a Password',
                        onChanged: (value) => signupProvider.setPassword(value),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  // Password textField
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Text(
                          'Confirm Password',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                      SizedBox(height: 5),
                      CustomTextField(
                        controller: _repass,
                        errorText: signupProvider.rePasswordError,
                        //helperText: 'Must be at least 6 characters',
                        borderRadius: 10,
                        height: 45,
                        maxLines: 1,
                        isPassword: true,
                        keyboardType: TextInputType.visiblePassword,
                        hintText: 'Confirm Password',
                        onChanged: (value) =>
                            signupProvider.setRePassword(value),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  signupProvider.isLoading
                      ? CupertinoActivityIndicator(radius: 20)
                      : CustomButton(
                          text: 'Create Account',
                          onPressed: () {
                            signupProvider.signup(context);
                          },
                        ),
                  const SizedBox(height: 20),
                  Text.rich(
                    TextSpan(
                      text: 'Already have an Account? ',
                      style: AppTextStyles.black10_500,
                      children: [
                        WidgetSpan(
                          child: InkWell(
                            onTap: () {
                              Navigator.pushReplacement(context,
                                  MaterialPageRoute(builder: (context) {
                                return LoginPage();
                              }));
                            },
                            child: Text(
                              'Login',
                              style: AppTextStyles.black12_700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return BackPressHandler(child: content);
  }
}
