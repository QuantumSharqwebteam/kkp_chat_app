import 'package:flutter/material.dart';
import 'package:flutter_initicon/flutter_initicon.dart';
import 'package:kkpchatapp/config/routes/marketing_routes.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/models/profile_model.dart';
import 'package:kkpchatapp/l10n/generated/app_localizations.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_button.dart';
import 'package:kkpchatapp/logic/agent/agent_provider.dart';
import 'package:provider/provider.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  late Profile? profile;

  @override
  void initState() {
    super.initState();
    profile = LocalDbHelper.getProfile()!;

    // Use addPostFrameCallback to ensure we're not updating during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Refresh agent list when this page loads
      Provider.of<AgentProvider>(context, listen: false).fetchAgents();
    });
  }

  void _navigateToAddAgent() async {
    // Navigate to add agent page
    final result = await Navigator.pushNamed(context, MarketingRoutes.addAgent);

    // If we return with a successful result, refresh the agent list
    if (result == true) {
      // This will refresh the agent list
      if (mounted) {
        Provider.of<AgentProvider>(context, listen: false).fetchAgents();
      }
    }
  }

  void deleteAgent(String email) async {
    // Show confirmation dialog
    Utils().showDialogWithActions(
      context,
      AppLocalizations.of(context)!.deleteAgent,
      icon: Icons.delete_outline,
      AppLocalizations.of(context)!.confirmDeleteAgent,
      AppLocalizations.of(context)!.deleteAgent,
      () async {
        // Delete agent using provider
        final agentProvider = Provider.of<AgentProvider>(context, listen: false);
        final response = await agentProvider.deleteAgent(email: email);

        if (response["status"] == 200) {
          if (mounted) {
            Utils().showSuccessDialog(
              context,
              AppLocalizations.of(context)!.confirmDeleteAgent,
              true,
            );
          }

          // Refresh agent list after deletion
          agentProvider.fetchAgents();
        } else {
          if (mounted) {
            Utils().showSuccessDialog(
              context,
              "Failed to delete agent. ${response["message"]}",
              false,
            );
          }
        }

        if (mounted) {
          Navigator.pop(context);
        }
      },
    );
  }

  void _navigateToAgentList() {
    // Navigate to agent list page and refresh data when returning
    Navigator.pushNamed(context, MarketingRoutes.agentProfileList).then((_) {
      // Refresh agent list when returning from agent list page
      if (mounted) {
        Provider.of<AgentProvider>(context, listen: false).fetchAgents();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: Text(AppLocalizations.of(context)!.profile),
        actions: [
          PopupMenuButton<int>(
            color: Colors.white,
            surfaceTintColor: Colors.white,
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 1) {
                _navigateToAgentList();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 1,
                child: Text('Agent Profiles'),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildProfileCard(),
            const SizedBox(height: 20),
            _buildDetailsCard(),
            const Spacer(),
            _buildAddAgentButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      child: SizedBox(
        width: double.maxFinite,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Stack(
                children: [
                  Initicon(
                    text: profile!.name!,
                    size: 100,
                  )
                ],
              ),
              const SizedBox(height: 10),
              Text(
                profile?.name ?? "NA",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              Text(
                profile?.role ?? "NA",
                style: AppTextStyles.grey5C5C5C_16_600,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    final l = AppLocalizations.of(context)!;
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInputField(Icons.person, l.fullName, profile?.name ?? "NA"),
            _buildInputField(Icons.email, l.email, profile?.email ?? "NA"),
            _buildInputField(Icons.phone, l.phoneNumber, profile?.mobile.toString() ?? "0"),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 4),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Row(
          children: [
            Icon(icon, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
        const Divider(thickness: 1, color: Colors.grey),
        const SizedBox(height: 8), // Spacing between fields
      ],
    );
  }

  Widget _buildAddAgentButton() {
    return CustomButton(
        onPressed: _navigateToAddAgent,
        image: Icon(
          Icons.person_add_alt_1_rounded,
          color: Colors.white,
          size: 28,
        ),
        backgroundColor: AppColors.blue00ABE9,
        fontSize: 18,
        borderColor: AppColors.blue00ABE9,
        text: AppLocalizations.of(context)!.addAgent);
  }
}
