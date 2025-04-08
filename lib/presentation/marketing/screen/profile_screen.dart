import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';
import 'package:kkp_chat_app/core/services/socket_service.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';
import 'package:kkp_chat_app/data/local_storage/local_db_helper.dart';
import 'package:kkp_chat_app/data/models/profile_model.dart';
import 'package:kkp_chat_app/presentation/common/auth/login_page.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_button.dart';
import 'package:kkp_chat_app/presentation/common_widgets/profile_details_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SocketService _socketService = SocketService();
  late Profile? profile;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 300));
    profile = LocalDbHelper.getProfile();
  }

  void logout() async {
    await LocalDbHelper.removeToken();
    await LocalDbHelper.removeName();
    await LocalDbHelper.removeEmail();
    await LocalDbHelper.removeUserType();
    await LocalDbHelper.removeProfile();
    _socketService.dispose();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("My Account"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileSection(profile?.profileUrl),
            _buildStatsSection(),
            // _buildSettingsSection(context),
            const SizedBox(height: 10),
            _buildDetailsCard(),
            // const SizedBox(height: 10),
            // _buildSettingsSection(context),
            const SizedBox(height: 10),
            _buildLogoutButton(),
            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(String? url) {
    return Container(
      width: double.maxFinite,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(width: 1, color: AppColors.dividerD9D9D9),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 80,
            backgroundImage: AssetImage("assets/images/user2.png"),
            // foregroundImage: NetworkImage(url ?? ""),
          ),
          const SizedBox(height: 10),
          Text(
            profile?.name ?? "",
            style: AppTextStyles.black14_600.copyWith(fontSize: 28),
          ),
          Text(
            profile?.role ?? "",
            style: AppTextStyles.grey5C5C5C_16_600,
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(
          blurRadius: 4,
          spreadRadius: 0,
          color: AppColors.shadowColor,
          offset: const Offset(0, 4),
        )
      ]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatCard("128", "Total chats"),
          Container(height: 60, width: 1, color: AppColors.dividerD9D9D9),
          _buildStatCard("45", "Active Inquiries"),
          Container(height: 60, width: 1, color: AppColors.dividerD9D9D9),
          _buildStatCard("83", "Resolved"),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.blue4A76CD_24_600),
        Text(label,
            style: AppTextStyles.grey5C5C5C_16_600.copyWith(fontSize: 12)),
      ],
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 4),
            color: AppColors.shadowColor)
      ]),
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileDetailsField(
            icon: Icons.person,
            label: 'Name',
            value: profile?.name ?? "NA",
          ),
          ProfileDetailsField(
            icon: Icons.email,
            label: 'Email',
            value: profile?.email ?? "NA",
          ),
          ProfileDetailsField(
            icon: Icons.phone,
            label: 'Mobile No.',
            value: profile?.mobile.toString() ?? "",
          ),
        ],
      ),
    );
  }

  // Widget _buildSettingsSection(BuildContext context) {
  //   return Container(
  //     padding: EdgeInsets.symmetric(horizontal: 16),
  //     margin: EdgeInsets.symmetric(vertical: 10),
  //     decoration: BoxDecoration(color: Colors.white, boxShadow: [
  //       BoxShadow(
  //         blurRadius: 4,
  //         spreadRadius: 0,
  //         color: AppColors.shadowColor,
  //         offset: const Offset(0, 4),
  //       )
  //     ]),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Text(
  //           "Settings",
  //           style: AppTextStyles.black15_500.copyWith(fontSize: 18),
  //         ),
  //         _buildSettingsTile(
  //           context,
  //           Icons.notifications_none_rounded,
  //           "Notification",
  //           MarketingRoutes.marketingNotifications,
  //         ),
  //         _buildSettingsTile(context, Icons.lock_outline_rounded, "Privacy",
  //             MarketingRoutes.privacy),
  //         _buildSettingsTile(context, Icons.settings_rounded, "Settings",
  //             MarketingRoutes.marketingSettings),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildSettingsTile(
  //     BuildContext context, IconData icon, String title, String routeName) {
  //   return Container(
  //     width: double.maxFinite,
  //     decoration: BoxDecoration(
  //       border: Border(
  //         bottom: BorderSide(width: 2, color: AppColors.dividerD9D9D9),
  //       ),
  //     ),
  //     child: ListTile(
  //       leading: Icon(icon, color: Colors.black),
  //       title: Text(
  //         title,
  //         style: AppTextStyles.black16_500,
  //       ),
  //       trailing: const Icon(
  //         Icons.arrow_forward_ios,
  //         size: 20,
  //       ),
  //       onTap: () {
  //         Navigator.pushNamed(context, routeName);
  //       },
  //     ),
  //   );
  // }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: CustomButton(
        onPressed: () {
          Utils().showDialogWithActions(
            context,
            "Log out",
            icon: Icons.logout_outlined,
            "Are you sure you want to logOut",
            "LogOut",
            logout,
          );
        },
        borderWidth: 0,
        fontSize: 16,
        backgroundColor: AppColors.marketingNavBarColor,
        text: "Logout",
      ),
    );
  }
}
