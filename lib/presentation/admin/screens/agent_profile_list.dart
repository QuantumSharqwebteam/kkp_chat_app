import 'package:flutter/material.dart';

class AgentProfilesPage extends StatelessWidget {
  const AgentProfilesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Agent Profiles List"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHighlightedAgent(),
            const SizedBox(height: 20),
            _buildStatsSection(),
            const SizedBox(height: 20),
            const Text("Agent Profiles",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(child: _buildAgentList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightedAgent() {
    return Card(
      surfaceTintColor: Colors.white,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundImage: AssetImage("assets/images/user1.png"),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("Arun",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("Senior Admin",
                    style: TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        Expanded(child: _buildStatCard("Total Agents", "04")),
        SizedBox(width: 10),
        Expanded(child: _buildStatCard("New Agent", "01")),
      ],
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 2,
              blurRadius: 4),
        ],
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Text(value,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAgentList() {
    final List<Map<String, String>> agents = [
      {"name": "Sam", "role": "Marketing Agent 1"},
      {"name": "Shara", "role": "Marketing Agent 2"},
      {"name": "Karan", "role": "Marketing Agent 3"},
      {"name": "Michael", "role": "Marketing Agent 4"},
    ];

    return ListView.builder(
      itemCount: agents.length,
      itemBuilder: (context, index) {
        final agent = agents[index];
        return Card(
          surfaceTintColor: Colors.white,
          color: Colors.white,
          child: ListTile(
            leading: const CircleAvatar(
              backgroundImage: AssetImage("assets/images/user3.png"),
            ),
            title: Text(agent["name"]!),
            subtitle: Text(agent["role"]!),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                // Handle actions here
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                    value: "restrict", child: Text("Restrict Access")),
                const PopupMenuItem(
                    value: "delete", child: Text("Delete Profile")),
              ],
            ),
          ),
        );
      },
    );
  }
}
