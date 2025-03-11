import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/routes/customer_routes.dart';
import 'package:kkp_chat_app/config/routes/marketing_routes.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_button.dart';

class Splash extends StatelessWidget {
  const Splash({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: Utils().width(context) * 0.8,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomButton(
                text: 'Customer',
                height: 50,
                backgroundColor: AppColors.blue,
                onPressed: () {
                  Navigator.pushNamed(
                      context, CustomerRoutes.customerProfileSetup);
                },
              ),
              SizedBox(height: 20),
              CustomButton(
                text: 'Admin/Agent',
                height: 50,
                backgroundColor: AppColors.blue,
                onPressed: () {
                  Navigator.pushNamed(
                      context, MarketingRoutes.marketingHostScreen);
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
