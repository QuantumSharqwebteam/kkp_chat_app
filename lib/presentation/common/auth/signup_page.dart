import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kkp_chat_app/config/routes/marketing_routes.dart';
import 'package:kkp_chat_app/core/network/auth_api.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';
import 'package:kkp_chat_app/data/repositories/auth_repository.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_button.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_textfield.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  AuthApi auth = AuthApi();
  final AuthRepository _authRepository = AuthRepository();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _repass = TextEditingController();
  bool _isLoading = false;

  void _signup() async {
    if (_pass.text != _repass.text) {
      Utils().showSuccessDialog(context, "Passwords do not match!");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authRepository.signup(
        _email.text,
        _pass.text,
      );

      if (response['success'] == true) {
        if (mounted) {
          Utils()
              .showSuccessDialog(context, "Signup successful! Please login.");
        }
        // Future.delayed(Duration(seconds: 2), () {
        //   if (mounted) {
        //     Navigator.pushNamed(context, MarketingRoutes.login);
        //   }
        // });
      } else {
        if (mounted) {
          Utils().showSuccessDialog(
              context, response['message'] ?? "Signup failed");
        }
      }
    } catch (e) {
      if (mounted) {
        Utils().showSuccessDialog(context, "Error: ${e.toString()}");
      }
    } finally {
      setState(() {
        _isLoading = false;
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
                _isLoading
                    ? CircularProgressIndicator()
                    : CustomButton(
                        text: 'Create Account',
                        onPressed: _signup,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
