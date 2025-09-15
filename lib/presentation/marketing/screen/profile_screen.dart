import 'package:flutter/material.dart';
import 'package:flutter_initicon/flutter_initicon.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/services/socket_service.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/models/profile_model.dart';
import 'package:kkpchatapp/main.dart';
import 'package:kkpchatapp/presentation/common/auth/login_page.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_button.dart';
import 'package:kkpchatapp/presentation/common_widgets/profile_details_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SocketService _socketService = SocketService(navigatorKey);
  late Profile? profile;
  String? selectedGender;

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
            // _buildStatsSection(),
            // _buildSettingsSection(context),
            const SizedBox(height: 10),
            _buildDetailsCard(),
            // const SizedBox(height: 10),
            // _buildSettingsSection(context),
            // const SizedBox(height: 10),
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
              bottom: BorderSide(width: 8, color: AppColors.backgroundDCEBFF),
              top: BorderSide(width: 5, color: AppColors.backgroundDCEBFF)),
          color: Colors.white,
          boxShadow: [
            // BoxShadow(
            //   blurRadius: 4,
            //   spreadRadius: 0,
            //   color: AppColors.shadowColor,
            //   offset: const Offset(0, 4),
            // )
          ]),
      child: Column(
        children: [
          const SizedBox(
            height: 5,
          ),
          Initicon(
            text: profile!.name!,
            size: 100,
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

  Widget _buildDetailsCard() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(
            spreadRadius: 6,
            blurRadius: 4,
            offset: const Offset(0, 4),
            color: Colors.white)
      ]),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileDetailsField(
            icon: Icons.person_outlined,
            label: 'Full Name',
            value: profile?.name ?? "NA",
          ),
          SizedBox(
            height: 10,
          ),
          ProfileDetailsField(
            icon: Icons.email_outlined,
            label: 'Email Adress',
            value: profile?.email ?? "NA",
          ),
          SizedBox(
            height: 10,
          ),
          ProfileDetailsField(
            icon: Icons.phone_outlined,
            label: 'Mobile No.',
            value: profile?.mobile.toString() ?? "",
          ),
        ],
      ),
    );
  }

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
        backgroundColor: AppColors.redF11515,
        text: "Log Out",
        icon: Icons.logout_outlined,
      ),
    );
  }
}
