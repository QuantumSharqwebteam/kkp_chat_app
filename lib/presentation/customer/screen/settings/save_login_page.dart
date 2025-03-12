import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';

class SaveLoginPage extends StatefulWidget {
  const SaveLoginPage({super.key});

  @override
  State<SaveLoginPage> createState() => _SaveLoginPageState();
}

class _SaveLoginPageState extends State<SaveLoginPage> {
  bool isSavedLoginEnabled = false;
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
                'Save login information',
                style: AppTextStyles.black20_500,
              ),
              SizedBox(height: 16),
              ListTile(
                title: Text(
                  'Saved login',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                trailing: Switch(
                  thumbColor: WidgetStatePropertyAll(Colors.black),
                  trackOutlineColor: WidgetStatePropertyAll(Colors.transparent),
                  activeTrackColor: AppColors.greyD9D9D9,
                  inactiveTrackColor: AppColors.greyD9D9D9,
                  value: isSavedLoginEnabled,
                  onChanged: (newValue) {
                    setState(() {
                      isSavedLoginEnabled = newValue;
                    });
                  },
                  activeColor: Colors.blue,
                ),
              ),
              Text(
                'We\'ll remember your account information for you on this device. You won\'t need to enter it when you log in again.',
                style: AppTextStyles.black12_400,
              )
            ],
          ),
        ),
      ),
    );
  }
}
