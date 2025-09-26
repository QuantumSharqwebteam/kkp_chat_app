import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/routes/customer_routes.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/services/notification_service.dart';
import 'package:kkpchatapp/core/services/socket_service.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/main.dart';
import 'package:kkpchatapp/presentation/admin/screens/customer_inquries.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_button.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_settings_tile.dart';
import 'package:kkpchatapp/presentation/common_widgets/locale/locale_switcher.dart';
import 'package:kkpchatapp/presentation/customer/screen/settings/about_us_page.dart';
import 'package:kkpchatapp/presentation/customer/screen/settings/account_and_security.dart';
import 'package:kkpchatapp/presentation/customer/screen/settings/customer_complaint_page.dart';

class CustomerSettingsPage extends StatefulWidget {
  const CustomerSettingsPage({super.key});

  @override
  State<CustomerSettingsPage> createState() => _CustomerSettingsPageState();
}

class _CustomerSettingsPageState extends State<CustomerSettingsPage> {
  @override
  Widget build(BuildContext context) {
    //  final searchController = TextEditingController();
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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                "Change locale: ",
                style: AppTextStyles.black10_600,
              ),
              LanguageSwitcher(),
              const SizedBox(
                width: 16,
              )
            ],
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Container(
            //   width: Utils().width(context),
            //   color: AppColors.background,
            //   padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            //   child: CustomSearchBar(
            //     width: Utils().width(context),
            //     enable: true,
            //     controller: searchController,
            //     hintText: 'Search',
            //   ),
            // ),
            // SettingsTile(
            //   numberOfTiles: 1,
            //   leadingIcons: [Icons.shield_moon_outlined],
            // onTaps: [
            //   () {
            //     Navigator.push(context, MaterialPageRoute(builder: (context) {
            //       return AccountAndSecurity();
            //     }));
            //   }
            // ],
            //   title: 'Your account',
            //   titles: ['Account and Security'],
            //   subtitles: ['Account managment, password change'],
            //   description:
            //       'Manage your data and security for  better experience',
            // ),
            // SizedBox(height: 10),
            // Divider(
            //   color: Colors.black,
            //   thickness: 1,
            // ),
            // SettingsTile(
            //   numberOfTiles: 1,
            //   leadingIcons: [
            //     Icons.archive_outlined,
            //     Icons.notifications_none_outlined
            //   ],
            //   title: 'How you use KKP',
            //   titles: [
            //     // 'Archive',
            //     'Notifications',
            //   ],
            // onTaps: [
            //   // () {
            //   //   Navigator.pushNamed(context, CustomerRoutes.archiveSettings);
            //   // },
            //   () {
            //     Navigator.pushNamed(
            //         context, CustomerRoutes.notificationSettings);
            //   }
            // ],
            // ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              // mainAxisAlignment: MainAxisAlignment.center,
              // mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                              Navigator.push(context, MaterialPageRoute(builder: (context) {
                                return AccountAndSecurity();
                              }));
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
                              Navigator.push(context, MaterialPageRoute(builder: (context) {
                                return CustomerInquiriesPage();
                              }));
                            }
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            // Divider(
            //   color: Colors.black,
            //   thickness: 1,
            // ),
            // SettingsTile(
            //   title: 'Your Orders',
            //   numberOfTiles: 1,
            //   leadingIcons: [Icons.shopping_cart_outlined],
            //   titles: ['Order Enquiries'],
            //   onTaps: [
            //     () {
            //       Navigator.push(context, MaterialPageRoute(builder: (context) {
            //         return CustomerInquiriesPage();
            //       }));
            //     }
            //   ],
            // ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    child: CustomSettingsTile(
                      numberOfTiles: 1,
                      title: Text(
                        "Preferences",
                        style: TextStyle(
                            color: AppColors.grey7B7B7B, fontWeight: FontWeight.w500, fontSize: 14),
                      ),
                      showDividerAfterTitle: true,
                      titles: ['Notifications'],
                      leadingWidgets: [
                        CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          radius: 20,
                          child: Image.asset(
                            'assets/icons/Vector(2).png',
                            height: 24,
                            width: 24,
                          ),
                        ),
                      ],
                      subtitles: ["Your Notifications Hub"],
                      onTaps: [
                        () {
                          Navigator.pushNamed(context, CustomerRoutes.notificationSettings);
                        }
                      ],
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                child: CustomSettingsTile(
                  numberOfTiles: 1,
                  leadingWidgets: [
                    CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      radius: 20,
                      child: Image.asset(
                        'assets/icons/complaint.png',
                        height: 24,
                        width: 24,
                      ),
                    ),
                  ],
                  title: Text(
                    'Complaint',
                    style: TextStyle(
                        color: AppColors.grey7B7B7B,
                        fontWeight: FontWeight.w500,
                        fontSize: 14),
                  ),
                  showDividerAfterTitle: true,
                  titles: ['Complaint'],
                  subtitles: ['Manage Complaints'],
                  onTaps: [
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const CustomerComplaintPage()),
                      );
                    },
                  ],
                ),
              ),
            ),

            // SettingsTile(
            //   numberOfTiles: 1,
            //   leadingIcons: [
            //     Icons.info_outline_rounded,
            //     Icons.info_outline_rounded,
            //   ],
            //   title: 'More info and support',
            //   titles: [
            //     // 'Help',
            //     'About',
            //   ],
            //   onTaps: [
            //     // () {},
            //     () {
            //       Navigator.push(context, MaterialPageRoute(builder: (context) {
            //         return AboutUsPage();
            //       }));
            //     }
            //   ],
            // ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                child: CustomSettingsTile(
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
                        color: AppColors.grey7B7B7B, fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                  showDividerAfterTitle: true,
                  titles: ['About'],
                  subtitles: ['Manage Terms & Policy'],
                  onTaps: [
                    () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) {
                        return AboutUsPage();
                      }));
                    },
                  ],
                ),
              ),
            ),
            // Divider(
            //   color: Colors.black,
            //   thickness: 1,
            // ),
            // SettingsTile(
            //   onTaps: [
            //     () {
            //       Utils().showDialogWithActions(
            //         context,
            //         "Log out",
            //         icon: Icons.logout_outlined,
            //         "Are you sure you want to logOut",
            //         "LogOut",
            //         logOut,
            //       );
            //     }
            //   ],
            //   numberOfTiles: 1,
            //   leadingIcons: [
            //     Icons.logout_rounded,
            //   ],
            //   titles: ['Log out'],
            //   tileTitleStyle: TextStyle(
            //       color: AppColors.redF11515, fontWeight: FontWeight.w600),
            //   iconColor: AppColors.redF11515,
            // ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: CustomButton(
                onPressed: () {
                  Utils().showDialogWithActions(
                    context,
                    "Log Out",
                    "Are you sure you want to logout?",
                    "Log out",
                    logOut,
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
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
