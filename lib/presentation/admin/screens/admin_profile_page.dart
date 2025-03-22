import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/routes/marketing_routes.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';
import 'package:kkp_chat_app/config/theme/image_constants.dart';
import 'package:kkp_chat_app/core/network/auth_api.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';
import 'package:kkp_chat_app/data/models/profile_model.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_button.dart';
import 'package:shimmer/shimmer.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  Profile? adminProfile;
  final _authApi = AuthApi();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchProfileDetails();
  }

  void _fetchProfileDetails() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final profile = await _authApi.getUserInfo();
      setState(() {
        adminProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Failed to get user details : ${e.toString()} ");
      setState(() {
        _isLoading = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
            _isLoading ? _buildShimmerProfileCard() : _buildProfileCard(),
            const SizedBox(height: 20),
            _isLoading ? _buildShimmerInfoFields() : _buildInfoFields(),
            const Spacer(),
            if (!_isLoading) _buildAddAgentButton(),
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
                adminProfile?.name ?? "NA",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              Text(
                adminProfile?.role ?? "NA",
                style: AppTextStyles.grey5C5C5C_16_600,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoFields() {
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInputField(Icons.person, 'Name', adminProfile?.name ?? "NA"),
            _buildInputField(Icons.email, 'Email', adminProfile?.email ?? "NA"),
            _buildInputField(Icons.phone, 'Enter Your Mobile No.',
                adminProfile?.mobile.toString() ?? "NA"),
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

  /// Shimmer effect for profile card
  Widget _buildShimmerProfileCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: double.maxFinite,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                CircleAvatar(radius: 40, backgroundColor: Colors.grey[300]),
                const SizedBox(height: 10),
                Container(
                  width: 100,
                  height: 20,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 5),
                Container(
                  width: 80,
                  height: 16,
                  color: Colors.grey[300],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerInfoFields() {
    return Card(
      color: Colors.white,
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(3, (index) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 14,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 5),
                Container(
                  width: double.infinity,
                  height: 20,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 10),
              ],
            );
          }),
        ),
      ),
    );
  }
}
