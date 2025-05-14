import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/repositories/auth_repository.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_button.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_textfield.dart';

class ChangePassword extends StatefulWidget {
  const ChangePassword({super.key});

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  AuthRepository auth = AuthRepository();
  final _currentPass = TextEditingController();
  final _newPass = TextEditingController();
  final _newRepass = TextEditingController();
  bool _isLoading = false;
  String? currentPassErrorText;
  String? newPassErrorText;
  String? newRePassErrorText;

  void _changePassword(context) async {
    if (_newPass.text != _newRepass.text) {
      setState(() {
        newPassErrorText = newRePassErrorText = "Passwords don't match!";
      });
      return;
    }

    if (_newPass.text == _newRepass.text) {
      setState(() {
        newPassErrorText = newRePassErrorText = null;
      });
    }

    if (_currentPass.text.trim().isEmpty ||
        _newPass.text.trim().isEmpty ||
        _newRepass.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Fields can not be empty!")));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String? email = LocalDbHelper.getProfile()?.email;

      final response = await auth.updatePassword(
          currentPassword: _currentPass.text,
          newPassword: _newPass.text,
          email: email!);

      if (response['success'] == true) {
        Utils()
            .showSuccessDialog(context, "Password changed successfully!", true);

        Future.delayed(Duration(seconds: 2), () {
          Navigator.pop(context);
        });
      } else {
        Utils().showSuccessDialog(
            context, response['message'] ?? "Failed to update password", false);
      }
    } catch (e) {
      Utils().showSuccessDialog(context, "Error: ${e.toString()}", false);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: WillPopScope(
        onWillPop: () async {
          if (_isLoading) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text("Please wait while the password is being changed.")),
            );
            return false; // Prevent navigation
          }
          return true; // Allow navigation
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.background,
            surfaceTintColor: AppColors.background,
          ),
          body: Center(
            child: SizedBox(
              width: Utils().width(context) * 0.9,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Password and Security',
                    style: AppTextStyles.black20_500,
                  ),
                  SizedBox(height: 16),
                  CustomTextField(
                    controller: _currentPass,
                    errorText: currentPassErrorText,
                    height: 50,
                    hintText: 'Current Password',
                  ),
                  SizedBox(height: 10),
                  CustomTextField(
                    controller: _newPass,
                    errorText: newPassErrorText,
                    height: 50,
                    hintText: 'New Password',
                  ),
                  SizedBox(height: 10),
                  CustomTextField(
                    controller: _newRepass,
                    errorText: newRePassErrorText,
                    height: 50,
                    hintText: 'Retype New Password',
                  ),
                  SizedBox(height: 20),
                  // TextButton(
                  //   onPressed: () {},
                  //   child: Text(
                  //     'Forgot your password?',
                  //     style: TextStyle(
                  //       color: AppColors.blue,
                  //     ),
                  //   ),
                  // ),
                  Spacer(),
                  _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : CustomButton(
                          text: 'Change Password',
                          onPressed: () => _changePassword(context),
                          borderRadius: 30,
                          height: 50,
                          borderColor: Colors.black,
                          fontSize: 16,
                          backgroundColor: AppColors.blue00ABE9,
                        ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
