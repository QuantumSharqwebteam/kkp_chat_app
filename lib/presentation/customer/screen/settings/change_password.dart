import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';
import 'package:kkp_chat_app/data/repositories/auth_repository.dart';
import 'package:kkp_chat_app/data/sharedpreferences/shared_preference_helper.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_button.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_textfield.dart';

class ChangePassword extends StatefulWidget {
  const ChangePassword({super.key});

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  final AuthRepository _authRepository = AuthRepository();
  final _currentPass = TextEditingController();
  final _newPass = TextEditingController();
  final _newRepass = TextEditingController();
  bool _isLoading = false;

  void _changePassword() async {
    if (_newPass.text != _newRepass.text) {
      Utils().showSuccessDialog(context, "New passwords do not match!");
      return;
    }

    if (_currentPass.text == _newPass.text) {
      Utils().showSuccessDialog(context, "New password must be different!");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var email = await SharedPreferenceHelper.getEmail();

      final response = await _authRepository.updatePassword(
          _currentPass.text, _newPass.text, email!);

      if (response['success'] == true) {
        if (mounted) {
          Utils().showSuccessDialog(context, "Password changed successfully!");
        }
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      } else {
        if (mounted) {
          Utils().showSuccessDialog(
              context, response['message'] ?? "Failed to update password");
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
                height: 50,
                hintText: 'Current Password',
              ),
              SizedBox(height: 10),
              CustomTextField(
                controller: _newPass,
                height: 50,
                hintText: 'New Password',
              ),
              SizedBox(height: 10),
              CustomTextField(
                controller: _newRepass,
                height: 50,
                hintText: 'Retype New Password',
              ),
              SizedBox(height: 20),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Forgot your password?',
                  style: TextStyle(
                    color: AppColors.blue,
                  ),
                ),
              ),
              Spacer(),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : CustomButton(
                      text: 'Change Password',
                      onPressed: _changePassword,
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
    );
  }
}
