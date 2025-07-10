import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
import 'package:kkpchatapp/config/routes/customer_routes.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/core/services/socket_service.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/main.dart';
import 'package:kkpchatapp/presentation/admin/screens/customer_inquries.dart';
import 'package:kkpchatapp/presentation/common/auth/login_page.dart';
import 'package:kkpchatapp/presentation/common_widgets/colored_divider.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_button.dart';
// import 'package:kkpchatapp/presentation/common_widgets/settings_tile.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_settings_tile.dart';
import 'package:kkpchatapp/presentation/customer/screen/settings/about_us_page.dart';
import 'package:kkpchatapp/presentation/marketing/screen/marketings_notifications_page.dart';
import 'package:kkpchatapp/presentation/marketing/screen/settings/manage_customers.dart';
// import 'package:kkpchatapp/presentation/marketing/screen/settings/manage_customers.dart';
// import 'package:kkpchatapp/presentation/marketing/widget/marketing_settings_tile.dart';

class MarketingSettingsPage extends StatefulWidget {
  const MarketingSettingsPage({super.key});

  @override
  State<MarketingSettingsPage> createState() => _MarketingSettingsPageState();
}

class _MarketingSettingsPageState extends State<MarketingSettingsPage> {
  final SocketService _socketService = SocketService(navigatorKey);
  @override
  Widget build(BuildContext context) {
    // final searchController = TextEditingController();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          'Settings and Activity',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: Utils().width(context),
              color: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              // child: CustomSearchBar(
              //     width: Utils().width(context),
              //     enable: true,
              //     controller: searchController,
              //     hintText: 'Search'),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              // mainAxisAlignment: MainAxisAlignment.center,
              // mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomSettingsTile(
                          numberOfTiles: 1,
                          leadingWidgets: [
                            CircleAvatar(
                              backgroundColor: Colors.blue.shade50,
                              radius: 20,
                              child: Image.asset(
                                'assets/icons/Vector.png',
                                height: 24,
                                width: 24,
                              ),
                            ),
                          ],
                          onTaps: [
                            () {
                              Navigator.pushNamed(
                                  context, CustomerRoutes.passwordAndSecurity);
                            }
                          ],
                          title: Text(
                            'Account & your orders',
                            style: TextStyle(
                                color: AppColors.grey7B7B7B,
                                fontWeight: FontWeight.w500,
                                fontSize: 14),
                          ),
                          showDividerAfterTitle: true,
                          titles: ['Account & Security'],
                          subtitles: ['Account management, password change'],
                        ),
                        // SizedBox(
                        //   height: 10,
                        // ),
                        Divider(
                          thickness: 1,
                          height: 0,
                          color: AppColors.greyE5E7EB, // light gray
                        ),
                        // user management , inaquiry mangement , notifications and reports and system settins tiles
                        CustomSettingsTile(
                          numberOfTiles: 1,
                          title: Text(''),
                          titles: ['Order Enquires'],
                          leadingWidgets: [
                            CircleAvatar(
                              backgroundColor: Colors.blue.shade50,
                              radius: 20,
                              child: Image.asset(
                                'assets/icons/Vector(1).png',
                                height: 24,
                                width: 24,
                              ),
                            ),
                          ],
                          subtitles: ["Track All Order Enquires in One Place"],
                          onTaps: [
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CustomerInquiriesPage(),
                                ),
                              );
                            }
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // SizedBox(height: 1),
            // Divider(
            //   color: AppColors.grey7B7B7B,
            //   thickness: 1,
            // ),
            // ColoredDivider(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CustomSettingsTile(
                          numberOfTiles: 1,
                          title: Text(
                            "Management",
                            style: TextStyle(
                                color: AppColors.grey7B7B7B,
                                fontWeight: FontWeight.w500,
                                fontSize: 14),
                          ),
                          showDividerAfterTitle: true,
                          titles: ['User Management'],
                          leadingWidgets: [
                            CircleAvatar(
                              backgroundColor: Colors.blue.shade50,
                              radius: 20,
                              child: Icon(
                                Icons.person_2_outlined,
                                color: Colors.green,
                              ),
                            ),
                          ],
                          subtitles: ["View customers"],
                          onTaps: [
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ManageCustomers(),
                                ),
                              );
                            }
                          ],
                        ),

                        // user management , inaquiry mangement , notifications and reports and system settins tiles
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // SizedBox(height: 10),
            // Divider(
            //   color: AppColors.grey7B7B7B,
            //   thickness: 1,
            // ),
            // ColoredDivider(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CustomSettingsTile(
                          numberOfTiles: 1,
                          leadingWidgets: [
                            CircleAvatar(
                              backgroundColor: Colors.blue.shade50,
                              radius: 20,
                              child: Image.asset(
                                'assets/icons/Vector(3).png',
                                height: 24,
                                width: 24,
                              ),
                            ),
                          ],
                          title: Text(
                            'Terms & Policy',
                            style: TextStyle(
                                color: AppColors.grey7B7B7B,
                                fontWeight: FontWeight.w500,
                                fontSize: 14),
                          ),
                          showDividerAfterTitle: true,
                          titles: ['About'],
                          subtitles: ['Manage Terms & Policy'],
                          onTaps: [
                            () {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (context) {
                                return AboutUsPage();
                              }));
                            },
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // MarketingSettingsTile(
            //   title: "Notifications & Reports",
            //   leadingIcon: Icons.notifications_none,
            //   subTitles: [
            //     "Manage Message Alerts",
            //     // "View Sales & Inquiry Reports"
            //   ],
            //   onTapActions: [
            //     () {
            //       // Navigator.pushNamed(context, '/manageAlerts');
            //     },
            //     // () {
            //     //   //  Navigator.pushNamed(context, '/viewReports');
            //     // }
            //   ],
            // ),
            // MarketingSettingsTile(
            //   title: "System Settings",
            //   leadingIcon: Icons.settings_outlined,
            //   subTitles: ["Security & Access Control"],
            //   onTapActions: [
            //     () {
            //       // Navigator.pushNamed(context, '/securitySettings');
            //     }
            //   ],
            // ),

            //More info and support sections tiles
            SizedBox(height: 10),
            // Divider(
            //   color: AppColors.grey7B7B7B,
            //   thickness: 1,
            // ),
            // ColoredDivider(),

            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: CustomButton(
                onPressed: () {
                  Utils().showDialogWithActions(
                    context,
                    "Log Out",
                    "Are you sure you want to logout?",
                    "Log out",
                    () async {
                      await LocalDbHelper.removeToken();
                      await LocalDbHelper.removeUserType();
                      await LocalDbHelper.removeName();
                      await LocalDbHelper.removeEmail();
                      _socketService.dispose();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage()),
                          (route) => false,
                        );
                      }
                    },
                    icon: Icons.logout_outlined,
                  );
                },
                text: "Log Out",
                icon: Icons.logout_outlined,
                backgroundColor: AppColors.redF11515,
                textColor: Colors.white,
                fontSize: 16,
                borderRadius: 10,
                borderWidth: 0,
                height: 50,
              ),
            )
          ],
        ),
      ),
    );
  }
}
