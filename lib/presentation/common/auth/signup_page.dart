import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kkp_chat_app/config/routes/marketing_routes.dart';
import 'package:kkp_chat_app/core/network/auth_api.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';
import 'package:kkp_chat_app/data/sharedpreferences/shared_preferences.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_button.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_textfield.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  AuthApi auth = AuthApi();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _repass = TextEditingController();

  // Future<void> _signup(context, String email, String pass) async {
  //   try {
  //     await auth.signup(email, pass).then((value) {
  //       if (value['message'] == 'User logged in successfully') {
  //         Sharedpreferences.saveToken(value['token']);
  //         Sharedpreferences.saveUserType(value['role'].toString());
  //       } else {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(
  //             content: Text(value['message']),
  //           ),
  //         );
  //       }
  //     });
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(" $e"),
  //       ),
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      persistentFooterAlignment: AlignmentDirectional.center,
      persistentFooterButtons: [
        Text.rich(
          TextSpan(
            text: 'Already have an Account? ',
            style: TextStyle(fontSize: 12),
            children: [
              WidgetSpan(
                child: InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, MarketingRoutes.login);
                  },
                  child: Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 15),
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
                      helperText: 'Must be atleast 8 characters',
                      maxLines: 1,
                      isPassword: true,
                      keyboardType: TextInputType.visiblePassword,
                      hintText: 'Create a Password',
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
                      helperText: 'Must be atleast 8 characters',
                      borderRadius: 10,
                      height: 45,
                      maxLines: 1,
                      isPassword: true,
                      keyboardType: TextInputType.visiblePassword,
                      hintText: 'Confirm Password',
                    ),
                  ],
                ),
                SizedBox(height: 40),
                CustomButton(
                  text: 'Create Account',
                  onPressed: () {
                    Navigator.pushNamed(context, MarketingRoutes.login);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
