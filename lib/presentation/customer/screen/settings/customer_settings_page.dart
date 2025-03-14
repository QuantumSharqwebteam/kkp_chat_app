import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/routes/customer_routes.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';
import 'package:kkp_chat_app/presentation/common/auth/login_page.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_search_field.dart';
import 'package:kkp_chat_app/presentation/common_widgets/settings_tile.dart';

class CustomerSettingsPage extends StatelessWidget {
  const CustomerSettingsPage({super.key});

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
                hintText: 'Search',
              ),
            ),
            SettingsTile(
              numberOfTiles: 1,
              leadingIcons: [Icons.shield_moon_outlined],
              onTaps: [
                () {
                  Navigator.pushNamed(
                      context, CustomerRoutes.passwordAndSecurity);
                }
              ],
              title: 'Your account',
              titles: ['Password and Security'],
              subtitles: ['Password, security, personal details,ad preference'],
              description:
                  'Manage your connected experiance and account settings across devices',
            ),
            SizedBox(height: 10),
            Divider(
              color: Colors.black,
              thickness: 1,
            ),
            SettingsTile(
              numberOfTiles: 2,
              leadingIcons: [
                Icons.archive_outlined,
                Icons.notifications_none_outlined
              ],
              title: 'How you use KKP',
              titles: ['Archive', 'Notifications'],
              onTaps: [
                () {
                  Navigator.pushNamed(context, CustomerRoutes.archiveSettings);
                },
                () {
                  Navigator.pushNamed(
                      context, CustomerRoutes.notificationSettings);
                }
              ],
            ),
            SizedBox(height: 10),
            Divider(
              color: Colors.black,
              thickness: 1,
            ),
            SettingsTile(
              title: 'Your Orders',
              numberOfTiles: 1,
              leadingIcons: [Icons.shopping_cart_outlined],
              titles: ['Order Enquirer'],
              onTaps: [
                () {
                  Navigator.pushNamed(context, CustomerRoutes.orderEnquiries);
                }
              ],
            ),
            SizedBox(height: 10),
            Divider(
              color: Colors.black,
              thickness: 1,
            ),
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
            Divider(
              color: Colors.black,
              thickness: 1,
            ),
            SettingsTile(
              onTaps: [
                () {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                      (route) => false);
                }
              ],
              numberOfTiles: 1,
              leadingIcons: [
                Icons.logout_rounded,
              ],
              titles: ['Log out'],
              tileTitleStyle: TextStyle(
                  color: AppColors.redF11515, fontWeight: FontWeight.w600),
              iconColor: AppColors.redF11515,
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
