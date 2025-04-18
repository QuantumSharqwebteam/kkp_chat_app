import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';
import 'package:kkp_chat_app/config/theme/image_constants.dart';
import 'package:kkp_chat_app/data/repositories/chat_reopsitory.dart';
import 'package:kkp_chat_app/presentation/common_widgets/shimmer_list.dart';
import 'package:kkp_chat_app/presentation/marketing/screen/agent_chat_screen.dart';

class AgentCustomersListScreen extends StatefulWidget {
  final String agentName;
  final String agentImage;
  final String agentEmail;

  const AgentCustomersListScreen({
    super.key,
    required this.agentName,
    required this.agentImage,
    required this.agentEmail,
  });

  @override
  State<AgentCustomersListScreen> createState() =>
      _AgentCustomersListScreenState();
}

class _AgentCustomersListScreenState extends State<AgentCustomersListScreen> {
  final _chatRepo = ChatRepository();
  List<dynamic> customers = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchCustomers();
  }

  Future<void> fetchCustomers() async {
    setState(() {
      isLoading = true;
    });

    try {
      final fetchedCustomerList =
          await _chatRepo.fetchAssignedCustomerList(widget.agentEmail);
      setState(() {
        customers = fetchedCustomerList;
      });
    } catch (e) {
      debugPrint("Error loading customer list: ${e.toString()}");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              top: 40,
              bottom: 20,
            ),
            child: Text(
              "Customers List",
              style: AppTextStyles.blue4A76CD_24_600.copyWith(
                color: AppColors.grey525252,
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const ShimmerList(itemCount: 8)
                : customers.isEmpty
                    ? Center(child: Text("No Customers Assigned"))
                    : ListView.separated(
                        itemCount: customers.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 15),
                        itemBuilder: (context, index) {
                          final customer = customers[index];
                          return Container(
                            decoration:
                                BoxDecoration(color: Colors.white, boxShadow: [
                              BoxShadow(
                                blurRadius: 4,
                                spreadRadius: 0,
                                color: Colors.black.withValues(alpha: 0.15),
                                offset: const Offset(0, 1),
                              )
                            ]),
                            child: ListTile(
                              tileColor: Colors.white,
                              leading: CircleAvatar(
                                radius: 30,
                                backgroundImage:
                                    AssetImage(ImageConstants.userImage),
                              ),
                              title: Text(
                                customer['name'] ?? "User",
                                style: AppTextStyles.black14_600,
                              ),
                              subtitle: Text(
                                customer['role'] ?? "Customer",
                                style: AppTextStyles.grey12_600,
                              ),
                              trailing: Icon(Icons.arrow_forward_ios),
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AgentChatScreen(
                                      customerName: customer["name"],
                                      customerEmail: customer['email'],
                                      agentEmail: widget.agentEmail,
                                      agentName: widget.agentName,
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  await fetchCustomers();
                                }
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
