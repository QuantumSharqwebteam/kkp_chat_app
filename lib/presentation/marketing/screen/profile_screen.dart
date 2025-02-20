import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("My Account",
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          _buildProfileSection(),
          _buildStatsSection(),
          _buildSettingsSection(context),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Column(
      children: [
        CircleAvatar(
          radius: 80,
          backgroundImage: AssetImage("assets/images/user1.png"),
        ),
        const SizedBox(height: 10),
        const Text(
          "Ruchita Mehra",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Text(
          "Marketing Agent",
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatCard("128", "Total chats"),
          _buildStatCard("45", "Active Inquiries"),
          _buildStatCard("83", "Resolved"),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Column(
      children: [
        _buildSettingsTile(context, Icons.notifications, "Notification"),
        _buildSettingsTile(context, Icons.privacy_tip, "Privacy"),
        _buildSettingsTile(context, Icons.settings, "Settings"),
      ],
    );
  }

  Widget _buildSettingsTile(BuildContext context, IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: () {
        // Navigate to respective settings pages if needed
      },
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ElevatedButton(
        onPressed: () {
          // Implement logout functionality
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Center(
          child: Text(
            "Logout",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
