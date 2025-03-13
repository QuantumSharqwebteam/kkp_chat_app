import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:kkp_chat_app/config/routes/customer_routes.dart';
import 'package:kkp_chat_app/config/routes/marketing_routes.dart';
import 'package:kkp_chat_app/core/network/auth_api.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';
import 'package:kkp_chat_app/data/sharedpreferences/shared_preferences.dart';
import 'package:kkp_chat_app/presentation/common/auth/forgot_pass_page.dart';
import 'package:kkp_chat_app/presentation/common/auth/signup_page.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_button.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_textfield.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  AuthApi auth = AuthApi();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  String emailError = '';
  String passError = '';

  Future<void> _login(context, String email, String pass) async {
    try {
      await auth.login(email, pass).then((value) {
        if (value['message'] == 'User logged in successfully') {
          Sharedpreferences.saveToken(value['token']);
          Sharedpreferences.saveUserType(value['role'].toString());
          if (value['role'].toString() == "0") {
            //customer
            Navigator.pushNamed(context, CustomerRoutes.customerHost);
          } else if (value['role'].toString() == "1") {
            //admin
            Navigator.pushNamed(context, MarketingRoutes.marketingHostScreen);
          } else if (value['role'].toString() == "2") {
            //agent
            Navigator.pushNamed(context, MarketingRoutes.marketingHostScreen);
          } else if (value['role'].toString() == "3") {
            //agent head
            Navigator.pushNamed(context, MarketingRoutes.marketingHostScreen);
          } else {
            // Invalid user type
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(value['message']),
            ),
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("wjhdfjbs $e"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      persistentFooterAlignment: AlignmentDirectional.center,
      persistentFooterButtons: [
        Text.rich(
          TextSpan(
            text: 'Don\'t have a Account? ',
            style: TextStyle(fontSize: 12),
            children: [
              WidgetSpan(
                child: InkWell(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => SignupPage()));
                  },
                  child: Text(
                    'Signup',
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
                  'Login',
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
                        'Email',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                    SizedBox(height: 5),
                    CustomTextField(
                      errorText: emailError.trim().isEmpty ? null : emailError,
                      controller: _email,
                      maxLines: 1,
                      keyboardType: TextInputType.emailAddress,
                      hintText: 'Enter your Email',
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
                        'Password',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                    SizedBox(height: 5),
                    CustomTextField(
                      errorText: passError.trim().isEmpty ? null : passError,
                      controller: _pass,
                      maxLines: 1,
                      isPassword: true,
                      keyboardType: TextInputType.visiblePassword,
                      hintText: 'Enter your Password',
                    ),
                  ],
                ),
                SizedBox(height: 5),
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => ForgotPassPage()));
                    },
                    child: Text(
                      'Forgot Password?',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                ),

                SizedBox(height: 40),
                CustomButton(
                  text: 'Login',
                  onPressed: () {
                    if (_email.text.trim().isNotEmpty ||
                        _pass.text.trim().isNotEmpty) {
                      _login(context, _email.text, _pass.text);
                    }
                  },
                ),
                SizedBox(height: 20),
                CustomButton(
                  text: 'Admin',
                  onPressed: () {
                    // if (_email.text.trim().isNotEmpty ||
                    //     _pass.text.trim().isNotEmpty) {
                    //   _login(context, _email.text, _pass.text);
                    // }
                    Navigator.pushNamed(
                        context, MarketingRoutes.marketingHostScreen);
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
