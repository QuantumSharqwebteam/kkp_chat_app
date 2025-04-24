import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/routes/marketing_routes.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/config/theme/image_constants.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/models/profile_model.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_button.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: const Text('Profile'),
        actions: [
          PopupMenuButton<int>(
            color: Colors.white,
            surfaceTintColor: Colors.white,
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 1) {
                Navigator.pushNamed(context, MarketingRoutes.agentProfileList);
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
                  Container(
                    height: Utils().height(context) * 0.15,
                    width: Utils().width(context) * 0.32,
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              spreadRadius: 0,
                              blurRadius: 6,
                              offset: Offset(0, 4)),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            spreadRadius: 0,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          )
                        ]),
                    child: const CircleAvatar(
                      backgroundImage: AssetImage(ImageConstants.userImage),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: Colors.blue,
                      radius: 16,
                      child: Icon(
                        Icons.lock,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
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
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInputField(Icons.person, 'Name', profile?.name ?? "NA"),
            _buildInputField(Icons.email, 'Email', profile?.email ?? "NA"),
            _buildInputField(Icons.phone, 'Enter Your Mobile No.',
                profile?.mobile.toString() ?? "0"),
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
        onPressed: () {
          Navigator.pushNamed(context, MarketingRoutes.addAgent);
        },
        image: Icon(
          Icons.person_add_alt_1_rounded,
          color: Colors.white,
          size: 28,
        ),
        backgroundColor: AppColors.blue00ABE9,
        fontSize: 18,
        borderColor: AppColors.blue00ABE9,
        text: "Add new agent");
  }
}
