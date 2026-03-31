import 'package:flutter/material.dart';
import 'package:flutter_initicon/flutter_initicon.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/l10n/generated/app_localizations.dart';
import 'package:kkpchatapp/presentation/admin/screens/meetings/meeting_list_screen.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_button.dart';
import 'package:kkpchatapp/presentation/marketing/screen/group_list_screen.dart';

class CustomDrawer extends StatelessWidget {
  final String? agentName;
  final String? agentEmail;
  final VoidCallback onLogout;

  const CustomDrawer({
    super.key,
    required this.agentName,
    required this.onLogout,
    required this.agentEmail,
  });

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Pro

            Container(
              height: 50,
              color: AppColors.bluePrimary,
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.bluePrimary,
              child: Row(
                children: [
                  Initicon(text: agentName ?? "", size: 40),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agentName ?? "",
                        style: AppTextStyles.black16_600.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Agent",
                        style: AppTextStyles.black12_400.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Drawer Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(context, icon: Icons.meeting_room, title: "Meetings", onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => MeetingsListScreen(
                                  email: LocalDbHelper.getEmail()!,
                                )));
                  }),
                  // _buildDrawerItem(
                  //   context,
                  //   icon: Icons.chat,
                  //   title: "Internal Chat",
                  //   onTap: () {
                  //     Navigator.push(
                  //         context,
                  //         MaterialPageRoute(
                  //             builder: (context) => InternalChatScreen(
                  //                   agentName: agentName ?? "agent",
                  //                   agentEmail: agentEmail ?? "agent@gmail.com",
                  //                   navigatorKey: navigatorKey,
                  //                 )));
                  //   },
                  // ),
                  _buildDrawerItem(context, icon: Icons.group, title: "Groups", onTap: () {
                    Navigator.push(
                        context, MaterialPageRoute(builder: (context) => GroupListScreen()));
                  })
                  // Add more items as needed
                ],
              ),
            ),
            // Logout Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: CustomButton(
                onPressed: () {
                  Utils().showDialogWithActions(
                    context,
                    locale.logout,
                    icon: Icons.logout_outlined,
                    locale.confirmLogout,
                    locale.logout,
                    onLogout,
                  );
                },
                borderWidth: 0,
                fontSize: 16,
                backgroundColor: AppColors.redF11515,
                text: locale.logout,
                icon: Icons.logout_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.bluePrimary),
      title: Text(title, style: AppTextStyles.black16_500),
      onTap: onTap,
    );
  }
}
