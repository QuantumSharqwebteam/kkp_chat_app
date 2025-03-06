import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';
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
                  hintText: 'Search'),
            ),
            SettingsTile(
              numberOfTiles: 1,
              leadingIcons: [Icons.account_circle_outlined],
              title: 'Your account',
              titles: ['Account Centre'],
              subtitles: ['Password, security, personal details,ad preference'],
              description:
                  'Manage your connected experiance and account settings across',
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
            ),
          ],
        ),
      ),
    );
  }
}
