import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/routes/customer_routes.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';
import 'package:kkp_chat_app/data/sharedpreferences/shared_preference_helper.dart';
import 'package:kkp_chat_app/presentation/common/auth/login_page.dart';
import 'package:kkp_chat_app/presentation/common_widgets/colored_divider.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_search_field.dart';
import 'package:kkp_chat_app/presentation/common_widgets/settings_tile.dart';
import 'package:kkp_chat_app/presentation/marketing/screen/settings/manage_customers.dart';
import 'package:kkp_chat_app/presentation/marketing/screen/settings/track_inquries.dart';
import 'package:kkp_chat_app/presentation/marketing/widget/marketing_settings_tile.dart';

class MarketingSettingsPage extends StatefulWidget {
  const MarketingSettingsPage({super.key});

  @override
  State<MarketingSettingsPage> createState() => _MarketingSettingsPageState();
}

class _MarketingSettingsPageState extends State<MarketingSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final searchController = TextEditingController();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        title: Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: Utils().width(context),
              color: AppColors.background,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: CustomSearchBar(
                  width: Utils().width(context),
                  enable: true,
                  controller: searchController,
                  hintText: 'Search'),
            ),

            SettingsTile(
              numberOfTiles: 1,
              leadingIcons: [Icons.account_circle_outlined],
              onTaps: [
                () {
                  Navigator.pushNamed(
                      context, CustomerRoutes.passwordAndSecurity);
                }
              ],
              title: 'Your account',
              titles: ['Account Centre'],
              subtitles: ['Password, security, personal details,ad preference'],
              description:
                  'Manage your connected experiance and account settings across',
            ),
            SizedBox(height: 10),
            Divider(
              color: AppColors.grey7B7B7B,
              thickness: 1,
            ),
            ColoredDivider(),
            // user management , inaquiry mangement , notifications and reports and system settins tiles
            MarketingSettingsTile(
              title: "User Management",
              leadingIcon: Icons.account_circle_outlined,
              subTitles: ["View & Manage Customers"],
              onTapActions: [
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ManageCustomers(),
                    ),
                  );
                }
              ],
            ),
            MarketingSettingsTile(
              title: "Inquiry Management",
              leadingIcon: Icons.question_answer_outlined,
              subTitles: ["Track Customer Inquiries"],
              onTapActions: [
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TrackInquries(),
                    ),
                  );
                }
              ],
            ),
            MarketingSettingsTile(
              title: "Notifications & Reports",
              leadingIcon: Icons.notifications_none,
              subTitles: [
                "Manage Message Alerts",
                "View Sales & Inquiry Reports"
              ],
              onTapActions: [
                () {
                  // Navigator.pushNamed(context, '/manageAlerts');
                },
                () {
                  //  Navigator.pushNamed(context, '/viewReports');
                }
              ],
            ),
            MarketingSettingsTile(
              title: "System Settings",
              leadingIcon: Icons.settings_outlined,
              subTitles: ["Security & Access Control"],
              onTapActions: [
                () {
                  // Navigator.pushNamed(context, '/securitySettings');
                }
              ],
            ),

            //More info and support sections tiles
            SizedBox(height: 10),
            Divider(
              color: AppColors.grey7B7B7B,
              thickness: 1,
            ),
            ColoredDivider(),
            SettingsTile(
              numberOfTiles: 2,
              leadingIcons: [
                Icons.info_outline_rounded,
                Icons.info_outline_rounded,
              ],
              title: 'More info and support',
              titles: ['Help', 'About'],
              onTaps: [
                () {},
                () {
                  Navigator.pushNamed(context, CustomerRoutes.aboutSettingPage);
                }
              ],
            ),
            TextButton.icon(
              onPressed: () {
                Utils().showDialogWithActions(
                  context,
                  "Log Out",
                  "Are you sure you want to logout?",
                  "Log out",
                  () async {
                    await SharedPreferenceHelper.removeToken();
                    await SharedPreferenceHelper.removeUserType();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage()),
                          (route) => false);
                    }
                  },
                  icon: Icons.logout_outlined,
                );
              },
              icon: Icon(
                Icons.logout_outlined,
                size: 28,
                color: AppColors.redF11515,
              ),
              label: Text(
                "Log Out",
                style: TextStyle(fontSize: 18, color: AppColors.redF11515),
              ),
            )
          ],
        ),
      ),
    );
  }
}
