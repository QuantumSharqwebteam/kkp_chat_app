import 'package:flutter/material.dart';
import 'package:flutter_initicon/flutter_initicon.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/data/repositories/chat_reopsitory.dart';
//import 'package:kkpchatapp/main.dart';
import 'package:kkpchatapp/presentation/common_widgets/shimmer_list.dart';
//import 'package:kkpchatapp/presentation/marketing/screen/agent_chat_screen.dart';
import 'package:kkpchatapp/presentation/marketing/screen/agent_customer_messages_screen.dart';
import 'package:kkpchatapp/presentation/marketing/widget/no_customer_assigned_widget.dart';

class AgentCustomersListScreen extends StatefulWidget {
  final String agentName;

  final String agentEmail;

  const AgentCustomersListScreen({
    super.key,
    required this.agentName,
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
            Initicon(
              text: widget.agentName,
              size: 30,
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
                    ? NoCustomerAssignedWidget()
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
                              leading: Initicon(
                                text: customer['name'],
                                size: 40,
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
                                // final result = await Navigator.push(
                                //   context,
                                //   MaterialPageRoute(
                                //     builder: (context) => AgentChatScreen(
                                //       navigatorKey: navigatorKey,
                                //       customerName: customer["name"],
                                //       customerEmail: customer['email'],
                                //       agentEmail: widget.agentEmail,
                                //       agentName: widget.agentName,
                                //     ),
                                //   ),
                                // );
                                // if (result == true) {
                                //   await fetchCustomers();
                                // }
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) {
                                  return AgentCustomerMessagesScreen(
                                    agentEmail: widget.agentEmail,
                                    agentName: widget.agentName,
                                    customerEmail: customer['email'],
                                    customerName: customer["name"],
                                  );
                                }));
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
