import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/routes/customer_routes.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/core/services/notification_service.dart';
import 'package:kkpchatapp/core/services/socket_service.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/main.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_search_field.dart';
import 'package:kkpchatapp/presentation/common_widgets/settings_tile.dart';
import 'package:kkpchatapp/presentation/customer/screen/settings/about_us_page.dart';
import 'package:kkpchatapp/presentation/customer/screen/settings/account_and_security.dart';

class CustomerSettingsPage extends StatefulWidget {
  const CustomerSettingsPage({super.key});

  @override
  State<CustomerSettingsPage> createState() => _CustomerSettingsPageState();
}

class _CustomerSettingsPageState extends State<CustomerSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final searchController = TextEditingController();
    final SocketService socketService = SocketService(navigatorKey);

    void logOut() async {
      try {
        // 1. Clear all persistent data
        await Future.wait([
          LocalDbHelper.removeToken(),
          LocalDbHelper.removeUserType(),
          LocalDbHelper.removeEmail(),
          LocalDbHelper.removeName(),
          LocalDbHelper.removeProfile(),
          LocalDbHelper.clearFCMToken(),
          NotificationService.deleteFCMToken(),
        ]);

        // 2. Dispose socket
        socketService.dispose();

        // 3. If still in UI, navigate:
        if (context.mounted) {
          Navigator.pop(context);
          Navigator.of(context).pushNamedAndRemoveUntil(
            "/login", // ← the named route you defined
            (Route<dynamic> route) => false, // ← clears everything
          );
        }
      } catch (e) {
        debugPrint("Error during logout: $e");
      }
    }

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
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return AccountAndSecurity();
                  }));
                }
              ],
              title: 'Your account',
              titles: ['Account and Security'],
              subtitles: ['Account managment, password change'],
              description:
                  'Manage your data and security for  better experience',
            ),
            SizedBox(height: 10),
            Divider(
              color: Colors.black,
              thickness: 1,
            ),
            SettingsTile(
              numberOfTiles: 1,
              leadingIcons: [
                Icons.archive_outlined,
                Icons.notifications_none_outlined
              ],
              title: 'How you use KKP',
              titles: [
                // 'Archive',
                'Notifications',
              ],
              onTaps: [
                // () {
                //   Navigator.pushNamed(context, CustomerRoutes.archiveSettings);
                // },
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
              numberOfTiles: 1,
              leadingIcons: [
                Icons.info_outline_rounded,
                Icons.info_outline_rounded,
              ],
              title: 'More info and support',
              titles: [
                // 'Help',
                'About',
              ],
              onTaps: [
                // () {},
                () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return AboutUsPage();
                  }));
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
                  Utils().showDialogWithActions(
                    context,
                    "Log out",
                    icon: Icons.logout_outlined,
                    "Are you sure you want to logOut",
                    "LogOut",
                    logOut,
                  );
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
