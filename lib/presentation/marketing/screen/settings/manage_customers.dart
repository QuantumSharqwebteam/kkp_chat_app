import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/config/theme/image_constants.dart';
import 'package:kkpchatapp/core/network/auth_api.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/presentation/common_widgets/profile_avatar.dart';

class ManageCustomers extends StatefulWidget {
  const ManageCustomers({super.key});

  @override
  State<ManageCustomers> createState() => _ManageCustomersState();
}

class _ManageCustomersState extends State<ManageCustomers> {
  final _auth = AuthApi();
  List<dynamic> customers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCustomers();
  }

  Future<void> fetchCustomers() async {
    try {
      final fetchedCustomers = await _auth.getUsersByRole('User');
      setState(() {
        customers = fetchedCustomers;
        isLoading = false;
      });
    } catch (e) {
      // Handle error
      setState(() {
        isLoading = false;
      });
      print('Error fetching customers: $e');
    }
  }

  void showCustomerDetails(Map<String, dynamic> customer) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name: ${customer['name']}',
                  style: AppTextStyles.black14_600),
              Text('Email: ${customer['email']}',
                  style: AppTextStyles.grey12_600),
              Text('Role: ${customer['role']}',
                  style: AppTextStyles.grey12_600),
              Text('Mobile: ${customer['mobile'] ?? 'N/A'}',
                  style: AppTextStyles.grey12_600),
              Text('GST No: ${customer['GSTno'] ?? 'N/A'}',
                  style: AppTextStyles.grey12_600),
              Text('PAN No: ${customer['PANno'] ?? 'N/A'}',
                  style: AppTextStyles.grey12_600),
              Text('Customer Type: ${customer['customerType'] ?? 'N/A'}',
                  style: AppTextStyles.grey12_600),
              // Add more fields as needed
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close', style: AppTextStyles.black14_600),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Colors.white,
        title: Text(
          "View and manage customers",
          style: AppTextStyles.black16_500,
        ),
        // actions: [
        //   CircleAvatar(
        //     backgroundImage: AssetImage(ImageConstants.userImage),
        //     radius: 20,
        //   ),
        // ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 10),
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
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return Card(
                        color: Colors.white,
                        surfaceTintColor: Colors.white,
                        elevation: 5,
                        child: ListTile(
                          tileColor: Colors.white,
                          leading: CircleAvatar(
                            backgroundImage: customer['profileUrl'] != null &&
                                    customer['profileUrl'].isNotEmpty
                                ? NetworkImage(customer['profileUrl'])
                                : AssetImage(ImageConstants.profileAvatar)
                                    as ImageProvider, // Replace with your placeholder image path
                          ),
                          title: Text(
                            customer['name'],
                            style: AppTextStyles.black14_600,
                          ),
                          subtitle: Text(
                            customer['role'],
                            style: AppTextStyles.grey12_600,
                          ),
                          trailing: PopupMenuButton<int>(
                            color: Colors.white,
                            surfaceTintColor: Colors.white,
                            icon: const Icon(Icons.more_vert),
                            onSelected: (value) {
                              if (value == 1) {
                                Utils().showSuccessDialog(
                                    context, "Blocked", true);
                              } else if (value == 2) {
                                // Handle remove chat
                              } else if (value == 3) {
                                showCustomerDetails(customer);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 1,
                                child: Text('Block Chat'),
                              ),
                              const PopupMenuItem(
                                value: 2,
                                child: Text('Remove Chat'),
                              ),
                              const PopupMenuItem(
                                value: 3,
                                child: Text('More details'),
                              ),
                            ],
                          ),
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
