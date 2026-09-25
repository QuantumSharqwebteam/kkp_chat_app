import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
import 'package:kkpchatapp/config/routes/customer_routes.dart';
import 'package:kkpchatapp/config/routes/marketing_routes.dart';
import 'package:kkpchatapp/presentation/admin/screens/admin_profile_page.dart';
import 'package:kkpchatapp/presentation/marketing/screen/profile_screen.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/services/socket_service.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/l10n/generated/app_localizations.dart';

import 'package:kkpchatapp/main.dart';
// import 'package:kkpchatapp/presentation/admin/screens/customer_inquries.dart';
import 'package:kkpchatapp/presentation/common/auth/login_page.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_button.dart';
// import 'package:kkpchatapp/presentation/common_widgets/settings_tile.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_settings_tile.dart';
import 'package:kkpchatapp/presentation/common_widgets/locale/locale_switcher.dart';
//import 'package:kkpchatapp/presentation/customer/screen/settings/about_us_page.dart';
import 'package:kkpchatapp/presentation/marketing/screen/analytics_management_screen.dart';
import 'package:kkpchatapp/presentation/marketing/screen/settings/manage_customers.dart';
import 'package:kkpchatapp/presentation/marketing/screen/settings/marketing_complaint_page.dart';
// import 'package:kkpchatapp/presentation/marketing/screen/settings/manage_customers.dart';
// import 'package:kkpchatapp/presentation/marketing/widget/marketing_settings_tile.dart';

class MarketingSettingsPage extends StatefulWidget {
  const MarketingSettingsPage({super.key});

  @override
  State<MarketingSettingsPage> createState() => _MarketingSettingsPageState();
}

class _MarketingSettingsPageState extends State<MarketingSettingsPage> {
  final SocketService _socketService = SocketService(navigatorKey);
  String? _userType;

  bool get _isAgentHead => _userType == "3";
  TextStyle get _optionTitleStyle => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.black,
      );
  TextStyle get _optionSubtitleStyle => const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        color: Colors.black,
      );

  @override
  void initState() {
    super.initState();
    _loadUserType();
  }

  Future<void> _loadUserType() async {
    final userType = await LocalDbHelper.getUserType();
    if (!mounted) return;
    setState(() {
      _userType = userType;
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    // final searchController = TextEditingController();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          "Settings",
          style: AppTextStyles.black14_600,
        ),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)?.changeLocale ?? 'Change locale:',
                style: AppTextStyles.black10_600,
              ),
              const SizedBox(
                width: 4,
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
        padding: EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            Container(
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomSettingsTile(
                    numberOfTiles: 2,
                    tileTitleStyle: _optionTitleStyle,
                    tileSubtitleStyle: _optionSubtitleStyle,
                    title: Text(
                      AppLocalizations.of(context)!.account,
                      style: TextStyle(
                          color: AppColors.grey7B7B7B,
                          fontWeight: FontWeight.w500,
                          fontSize: 14),
                    ),
                    showDividerAfterTitle: true,
                    leadingWidgets: [
                      CircleAvatar(
                        backgroundColor: Colors.blue.shade50,
                        radius: 20,
                        child: const Icon(Icons.person_outlined,
                            color: Colors.blue),
                      ),
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => _isAgentHead
                                ? const AdminProfilePage()
                                : const ProfileScreen(),
                          ),
                        );
                      },
                      () {
                        Navigator.pushNamed(
                            context, CustomerRoutes.passwordAndSecurity);
                      }
                    ],
                    titles: [locale.myAccount, locale.accountAndSecurity],
                    subtitles: [
                      "View your profile details",
                      locale.accountManagementPasswordChange
                    ],
                  ),
                  // Divider(
                  //   color: AppColors.grey7B7B7B,
                  //   thickness: 1,
                  // ),
                  // CustomSettingsTile(
                  //   numberOfTiles: 1,
                  //   titles: ['Order Enquires'],
                  //   leadingWidgets: [
                  //     CircleAvatar(
                  //       backgroundColor: Colors.blue.shade50,
                  //       radius: 20,
                  //       child: Image.asset(
                  //         'assets/icons/Vector(1).png',
                  //         height: 24,
                  //         width: 24,
                  //       ),
                  //     ),
                  //   ],
                  //   subtitles: ["Track All Order Enquires in One Place"],
                  //   onTaps: [
                  //     () {
                  //       Navigator.push(
                  //         context,
                  //         MaterialPageRoute(
                  //           builder: (context) => CustomerInquiriesPage(),
                  //         ),
                  //       );
                  //     }
                  //   ],
                  // ),
                ],
              ),
            ),

            Container(
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
                    tileTitleStyle: _optionTitleStyle,
                    tileSubtitleStyle: _optionSubtitleStyle,
                    title: Text(
                      locale.management,
                      style: TextStyle(
                          color: AppColors.grey7B7B7B,
                          fontWeight: FontWeight.w500,
                          fontSize: 14),
                    ),
                    showDividerAfterTitle: true,
                    titles: [locale.userManagement],
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
                    subtitles: [locale.viewCustomers],
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

                  if (_isAgentHead)
                    CustomSettingsTile(
                      numberOfTiles: 1,
                      tileTitleStyle: _optionTitleStyle,
                      tileSubtitleStyle: _optionSubtitleStyle,
                      titles: const ["Agent List"],
                      leadingWidgets: [
                        CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          radius: 20,
                          child: const Icon(
                            Icons.groups_2_outlined,
                            color: Colors.green,
                          ),
                        ),
                      ],
                      subtitles: const ["View and manage agents"],
                      onTaps: [
                        () {
                          Navigator.pushNamed(
                            context,
                            MarketingRoutes.agentProfileList,
                          );
                        }
                      ],
                    ),

                  CustomSettingsTile(
                    numberOfTiles: 1,
                    tileTitleStyle: _optionTitleStyle,
                    tileSubtitleStyle: _optionSubtitleStyle,
                    // title: Text(
                    //   "",
                    //   style: TextStyle(
                    //       color: AppColors.grey7B7B7B,
                    //       fontWeight: FontWeight.w500,
                    //       fontSize: 14),
                    // ),
                    showDividerAfterTitle: true,
                    titles: [locale.manageAnalyticsData],
                    leadingWidgets: [
                      CircleAvatar(
                        backgroundColor: Colors.blue.shade50,
                        radius: 20,
                        child: Icon(
                          Icons.analytics_outlined,
                          color: Colors.green,
                        ),
                      ),
                    ],
                    // subtitles: ["View customers"],
                    onTaps: [
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AnalyticsManagementScreen(),
                          ),
                        );
                      }
                    ],
                  ),
                  // Container(
                  //   child: ListTile(
                  //     leading: Icon(Icons.analytics_outlined),
                  //     title: Text("Manage Analytics Data"),
                  //     onTap: () {
                  //       Navigator.push(
                  //         context,
                  //         MaterialPageRoute(
                  //             builder: (_) => AnalyticsManagementScreen()),
                  //       );
                  //     },
                  //   ),
                  // )
                  // user management , inaquiry mangement , notifications and reports and system settins tiles
                ],
              ),
            ),
            // SizedBox(height: 10),
            // Divider(
            //   color: AppColors.grey7B7B7B,
            //   thickness: 1,
            // ),
            // ColoredDivider(),

            Container(
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
                tileTitleStyle: _optionTitleStyle,
                tileSubtitleStyle: _optionSubtitleStyle,
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
                  AppLocalizations.of(context)!.complaints,
                  style: TextStyle(
                      color: AppColors.grey7B7B7B,
                      fontWeight: FontWeight.w500,
                      fontSize: 14),
                ),
                showDividerAfterTitle: true,
                titles: [AppLocalizations.of(context)!.allComplaint],
                subtitles: [AppLocalizations.of(context)!.viewComplaints],
                onTaps: [
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MarketingComplaintPage()),
                    );
                  },
                ],
              ),
            ),

            //

            CustomButton(
              onPressed: () {
                Utils().showDialogWithActions(
                  context,
                  locale.logout,
                  locale.confirmLogout,
                  locale.logout,
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
              text: locale.logout,
              icon: Icons.logout_outlined,
              backgroundColor: AppColors.redF11515,
              textColor: Colors.white,
              fontSize: 16,
              borderRadius: 10,
              borderWidth: 0,
              height: 50,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
