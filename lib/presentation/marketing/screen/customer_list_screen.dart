import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';
import 'package:kkp_chat_app/presentation/common_widgets/profile_avatar.dart';
import 'package:kkp_chat_app/presentation/marketing/screen/agent_chat_screen.dart';

class CustomersListScreen extends StatefulWidget {
  final String agentName;
  final String agentImage;
  final String agentEmail;

  const CustomersListScreen({
    super.key,
    required this.agentName,
    required this.agentImage,
    required this.agentEmail,
  });

  @override
  State<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends State<CustomersListScreen> {
  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> customers = [
      {
        "name": "Shyam Mohan",
        "role": "Customer",
        "image": "assets/images/user1.png",
        "isActive": true,
        "email": "shyam.mohan@example.com" // Use email for identification
      },
      {
        "name": "Krishna Deor",
        "role": "Customer",
        "image": "assets/images/user2.png",
        "isActive": false,
        "email": "krishna.deor@example.com"
      },
      {
        "name": "Ramesh Textile",
        "role": "Customer",
        "image": "assets/images/user3.png",
        "isActive": true,
        "email": "ramesh.textile@example.com"
      },
      {
        "name": "K.N Cottons",
        "role": "Customer",
        "image": "assets/images/user4.png",
        "isActive": false,
        "email": "kn.cottons@example.com"
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Colors.white,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundImage: AssetImage(widget.agentImage),
              radius: 20,
            ),
            const SizedBox(width: 10),
            Text(
              widget.agentName,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: 60,
              bottom: 30,
            ),
            child: Text(
              "Customers List",
              style: AppTextStyles.blue4A76CD_24_600.copyWith(
                color: AppColors.grey525252,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: customers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final customer = customers[index];
                return ListTile(
                  tileColor: Colors.white,
                  leading: ProfileAvatar(
                      image: customer["image"], isActive: customer["isActive"]),
                  title: Text(
                    customer['name'],
                    style: AppTextStyles.black14_600,
                  ),
                  subtitle: Text(
                    customer['role'],
                    style: AppTextStyles.grey12_600,
                  ),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AgentChatScreen(
                          customerName: customer['name'],
                          customerImage: customer['image'],
                          agentName: widget.agentName,
                          agentImage: widget.agentImage,
                          customerEmail:
                              customer['email'], // Pass the customer's email
                          agentEmail:
                              widget.agentEmail, // Pass the agent's email
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
