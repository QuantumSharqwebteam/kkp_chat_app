import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/utils/utils.dart';

class AboutSettingsPage extends StatelessWidget {
  const AboutSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        title: Text(
          'About',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Center(
        child: SizedBox(
          width: Utils().width(context) * 0.9,
          child: Column(
            children: [
              SizedBox(height: 20),
              CircleAvatar(
                radius: 45,
                backgroundImage:
                    AssetImage('assets/images/profile_avataar.png'),
              ),
              SizedBox(height: 5),
              Text(
                'John',
                style: AppTextStyles.black18_600,
              ),
              Text(
                textAlign: TextAlign.center,
                'To help keep our community authentic,we’re showing information about accounts on KKP app.People can see this by tapping on the your profile choosing about this account',
                style:
                    AppTextStyles.black12_400.copyWith(color: Colors.black54),
              ),
              SizedBox(height: 10),
              Material(
                elevation: 5,
                borderRadius: BorderRadius.circular(5),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: Colors.white),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month_outlined,
                          size: 30,
                        ),
                        SizedBox(width: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date joined',
                              style: AppTextStyles.black12_400
                                  .copyWith(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              'February 2025',
                              style: AppTextStyles.black12_400,
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
