import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/repositories/auth_repository.dart';
import 'package:kkpchatapp/presentation/marketing/widget/settings/customer_details_dialog.dart';
import 'package:kkpchatapp/presentation/marketing/widget/settings/manage_customer_list_item.dart';

class ManageCustomers extends StatefulWidget {
  const ManageCustomers({super.key});

  @override
  State<ManageCustomers> createState() => _ManageCustomersState();
}

class _ManageCustomersState extends State<ManageCustomers> {
  final _authRepo = AuthRepository();
  List<dynamic> customers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCustomers();
  }

  Future<void> fetchCustomers() async {
    final role = await LocalDbHelper.getUserType();
    final email = LocalDbHelper.getEmail();
    List<dynamic> fetchedCustomers;
    try {
      if (role == "2") {
        fetchedCustomers = await _authRepo.fetchUsersByAgentId(email!);
      } else {
        fetchedCustomers = await _authRepo.fetchUsersByRole('User');
      }
      setState(() {
        customers = fetchedCustomers;
        isLoading = false;
      });
    } catch (e) {
      // Handle error
      setState(() {
        isLoading = false;
      });
      debugPrint('Error fetching customers: $e');
    }
  }

  void showCustomerDetails(Map<String, dynamic> customer) {
    showDialog(
      context: context,
      builder: (context) {
        return CustomerDetailsDialog(customer: customer);
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
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : customers.isEmpty
              ? Center(
                  child: Text(
                    "No customers available",
                    style: AppTextStyles.grey12_600.copyWith(fontSize: 16),
                  ),
                )
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
                          return ManageCustomerListItem(
                            customer: customer,
                            onMoreDetails: () => showCustomerDetails(customer),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
