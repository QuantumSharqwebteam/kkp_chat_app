import 'package:flutter/material.dart';
import 'package:flutter_initicon/flutter_initicon.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
//import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/models/profile_model.dart';
import 'package:kkpchatapp/l10n/generated/app_localizations.dart';
import 'package:kkpchatapp/logic/agent/group_provider.dart';
import 'package:kkpchatapp/presentation/admin/screens/meetings/meeting_list_screen.dart';
//import 'package:kkpchatapp/presentation/common_widgets/custom_button.dart';
import 'package:kkpchatapp/presentation/marketing/screen/group_list_screen.dart';
import 'package:provider/provider.dart';

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

  // Helper method to format role display text dynamically
  String _getFormattedRole(String? role) {
    if (role == null || role.isEmpty) {
      return "Agent";
    }
    if (role.toLowerCase() == 'agenthead') {
      return "Agent Head";
    }
    return role;
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;

    // Fetch the stored profile dynamically from local storage
    final Profile? profile = LocalDbHelper.getProfile();
    final String displayName = profile?.name ?? agentName ?? "";
    final String displayRole = _getFormattedRole(profile?.role);

    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Status Bar Padding Container
            Container(
              height: MediaQuery.of(context).padding.top,
              color: AppColors.bluePrimary,
            ),
            // Header Section
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.bluePrimary,
              child: Row(
                children: [
                  Initicon(
                    text: displayName.isNotEmpty ? displayName : "User",
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: AppTextStyles.black16_600
                              .copyWith(color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          displayRole,
                          style: AppTextStyles.black12_400
                              .copyWith(color: Colors.white70),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Drawer Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    context,
                    icon: Icons.meeting_room,
                    title: "Meetings",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MeetingsListScreen(
                            email: LocalDbHelper.getEmail()!,
                          ),
                        ),
                      );
                    },
                  ),
                  Consumer<GroupProvider>(
                    builder: (context, groupProvider, _) {
                      final total = groupProvider.totalGroupUnreadCount;
                      return ListTile(
                        leading: Badge(
                          isLabelVisible: total > 0,
                          label: Text(
                            total > 99 ? '99+' : '$total',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10),
                          ),
                          backgroundColor: AppColors.redF11515,
                          child:
                              Icon(Icons.group, color: AppColors.bluePrimary),
                        ),
                        title: Text("Groups", style: AppTextStyles.black16_500),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const GroupListScreen()),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Logout Button
            // Padding(
            //   padding: const EdgeInsets.all(16),
            //   child: CustomButton(
            //     onPressed: () {
            //       Utils().showDialogWithActions(
            //         context,
            //         locale.logout,
            //         icon: Icons.logout_outlined,
            //         locale.confirmLogout,
            //         locale.logout,
            //         onLogout,
            //       );
            //     },
            //     borderWidth: 0,
            //     fontSize: 16,
            //     backgroundColor: AppColors.redF11515,
            //     text: locale.logout,
            //     icon: Icons.logout_outlined,
            //   ),
            // ),
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
