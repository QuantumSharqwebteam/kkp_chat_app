import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/routes/customer_routes.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';
import 'package:kkp_chat_app/presentation/common_widgets/settings_tile.dart';

class PasswordAndSecurity extends StatelessWidget {
  const PasswordAndSecurity({super.key});

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
              Text(
                'Login & recovery',
                style: AppTextStyles.black16_500,
              ),
              Text(
                'Manage your password, login preference and recovery methods',
                style: AppTextStyles.black14_400,
              ),
              SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  children: [
                    SettingsTile(
                      titles: ['Change password'],
                      numberOfTiles: 1,
                      isDense: true,
                      onTaps: [
                        () {
                          Navigator.pushNamed(
                              context, CustomerRoutes.changePassword);
                        }
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
