import 'package:flutter/material.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';
import 'package:kkp_chat_app/data/repositories/auth_repository.dart';
import 'package:kkp_chat_app/presentation/common/auth/login_page.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_button.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_textfield.dart';

class NewPassPage extends StatefulWidget {
  const NewPassPage({super.key, required this.email});
  final String email;

  @override
  State<NewPassPage> createState() => _NewPassPageState();
}

class _NewPassPageState extends State<NewPassPage> {
  AuthRepository auth = AuthRepository();
  final _newpass = TextEditingController();
  final _repass = TextEditingController();
  String? newpassError;
  String? repassError;
  bool _isloading = false;

  Future<void> _changepassword(context) async {
    _isloading = true;

    if (_newpass.text.trim().isEmpty) {
      setState(() {
        newpassError = "Field can't be empty";
        _isloading = false;
      });
      return;
    }
    if (_repass.text.trim().isEmpty) {
      setState(() {
        repassError = "Field can't be empty";
        _isloading = false;
      });
      return;
    }
    if (_newpass.text.trim() != _repass.text.trim()) {
      setState(() {
        newpassError = repassError = "Passwords doesn't match";
        _isloading = false;
      });
      return;
    }

    try {
      final response = await auth.forgotPassword(
          password: _repass.text, email: widget.email);

      if (response['message'] ==
          'OTP Verified and New Password has been Set Successfully!') {
        _isloading = false;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Password Changed Successfully")));
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return LoginPage();
        }));
      } else {
        _isloading = false;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(response['message'])));
      }
    } catch (e) {
      _isloading = false;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

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
                      _isloading
                          ? const CircularProgressIndicator()
                          : CustomButton(
                              text: 'Reset Password',
                              onPressed: () {
                                _changepassword(context);
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
