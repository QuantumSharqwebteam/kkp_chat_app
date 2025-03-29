import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:kkp_chat_app/config/routes/customer_routes.dart';
import 'package:kkp_chat_app/config/routes/marketing_routes.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';
import 'package:kkp_chat_app/data/repositories/auth_repository.dart';
import 'package:kkp_chat_app/data/local_storage/local_db_helper.dart';
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
  AuthRepository auth = AuthRepository();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  String emailError = '';
  String passError = '';
  bool isLoading = false;

  // Method to validate email format
  bool _isValidEmail(String email) {
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  Future<void> _login(context, String email, String pass) async {
    setState(() {
      isLoading = true;
      emailError = ''; // Clear previous email error
      passError = ''; // Clear previous password error
    });

    if (email.isEmpty) {
      setState(() {
        emailError = 'Email can\'t be empty';
        isLoading = false;
      });
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() {
        emailError = 'Please enter a valid email address';
        isLoading = false;
      });
      return;
    }

    if (pass.isEmpty) {
      setState(() {
        passError = 'Password can\'t be empty';
        isLoading = false;
      });
      return;
    }

    try {
      await auth.login(email: email, password: pass).then((value) async {
        if (value['message'] == 'User logged in successfully') {
          if (kDebugMode) {
            print("🪙TOKEN ${value['token']}");

            print("🧑‍🦰ROLE ${value['role']}");

            print("✉️EMAIL ${_email.text}");
          }
          await LocalDbHelper.saveToken(value['token'].toString());
          await LocalDbHelper.saveEmail(_email.text);
          await LocalDbHelper.saveUserType(value['role'].toString());

          if (value['role'].toString() == "0") {
            //customer
            Navigator.pushReplacementNamed(
                context, CustomerRoutes.customerHost);
          } else if (value['role'].toString() == "1") {
            //admin
            Navigator.pushReplacementNamed(
                context, MarketingRoutes.marketingHostScreen);
          } else if (value['role'].toString() == "2") {
            //agent
            Navigator.pushReplacementNamed(
                context, MarketingRoutes.marketingHostScreen);
          } else if (value['role'].toString() == "3") {
            //agent head
            Navigator.pushReplacementNamed(
                context, MarketingRoutes.marketingHostScreen);
          } else {
            // Invalid user type
            LocalDbHelper.removeEmail();
            LocalDbHelper.removeName();
            LocalDbHelper.removeProfile();
            LocalDbHelper.removeToken();
            LocalDbHelper.removeUserType();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Invlaid Credentials"),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(value['message']),
            ),
          );
        }
        setState(() {
          isLoading = false;
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$e"),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      persistentFooterAlignment: AlignmentDirectional.center,
      persistentFooterButtons: [
        Text.rich(
          TextSpan(
            text: 'Don\'t have an Account? ',
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
                      errorText: emailError.trim().isEmpty ? null : emailError,
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
                isLoading
                    ? const CircularProgressIndicator()
                    : CustomButton(
                        text: 'Login',
                        onPressed: () {
                          _login(context, _email.text, _pass.text);
                        },
                      ),
                SizedBox(height: 20),
                // CustomButton(
                //   text: 'marketing',
                //   onPressed: () {
                //     Navigator.pushNamed(
                //         context, MarketingRoutes.marketingHostScreen);
                //   },
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
