import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_button.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_textfield.dart';

class ChangePassword extends StatelessWidget {
  ChangePassword({super.key});
  final _currentPass = TextEditingController();
  final _newPass = TextEditingController();
  final _newRepass = TextEditingController();
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
              CustomButton(
                text: 'Change Password',
                onPressed: () {},
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
