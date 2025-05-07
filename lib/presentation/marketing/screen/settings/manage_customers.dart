import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/models/call_log_model.dart';
import 'package:kkpchatapp/data/repositories/auth_repository.dart';
import 'package:kkpchatapp/data/repositories/chat_reopsitory.dart';
import 'package:kkpchatapp/presentation/marketing/widget/settings/call_log_tile.dart';
import 'package:kkpchatapp/presentation/marketing/widget/settings/customer_details_dialog.dart';
import 'package:kkpchatapp/presentation/marketing/widget/settings/manage_customer_list_item.dart';

class ManageCustomers extends StatefulWidget {
  const ManageCustomers({super.key});

  @override
  State<ManageCustomers> createState() => _ManageCustomersState();
}

class _ManageCustomersState extends State<ManageCustomers>
    with SingleTickerProviderStateMixin {
  final _authRepo = AuthRepository();
  final _chatRepo = ChatRepository();
  List<dynamic> customers = [];
  List<CallLogModel> callLogs = [];
  bool isLoading = true;
  bool isCallLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchCustomers();
    fetchCallLogs();
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
      setState(() {
        isLoading = false;
      });
      debugPrint('Error fetching customers: $e');
    }
  }

  Future<void> fetchCallLogs() async {
    final email = LocalDbHelper.getEmail();
    try {
      final fetchedLogs =
          await _chatRepo.fetchCallLogs(email!); // Adjust this method if needed
      setState(() {
        callLogs = fetchedLogs;
        isCallLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching call logs: $e');
      setState(() {
        isCallLoading = false;
      });
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
        title: Text("Manage", style: AppTextStyles.black16_500),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          tabs: const [
            Tab(text: 'Customers'),
            Tab(text: 'Call History'),
          ],
        ),
        backgroundColor: Colors.white,
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildCustomerList(),
          buildCallLogList(),
        ],
      ),
    );
  }

  Widget buildCustomerList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (customers.isEmpty) {
      return Center(
        child: Text(
          "No customers available",
          style: AppTextStyles.grey12_600.copyWith(fontSize: 16),
        ),
      );
    }

    return ListView.separated(
      itemCount: customers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final customer = customers[index];
        return ManageCustomerListItem(
          customer: customer,
          onMoreDetails: () => showCustomerDetails(customer),
        );
      },
    );
  }

  Widget buildCallLogList() {
    if (isCallLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (callLogs.isEmpty) {
      return Center(
        child: Text(
          "No call logs available",
          style: AppTextStyles.grey12_600.copyWith(fontSize: 16),
        ),
      );
    }

    final Map<String, List<CallLogModel>> groupedLogs = {};

    for (var log in callLogs) {
      final date = log.timestamp;
      final now = DateTime.now();
      String key;

      if (DateUtils.isSameDay(date, now)) {
        key = "Today";
      } else if (DateUtils.isSameDay(
          date, now.subtract(const Duration(days: 1)))) {
        key = "Yesterday";
      } else {
        key = "${date.day}/${date.month}/${date.year}";
      }

      groupedLogs.putIfAbsent(key, () => []).add(log);
    }
    final currentUserId = LocalDbHelper.getEmail();
    return ListView(
      children: groupedLogs.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.maxFinite,
              color: Colors.grey[200],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                entry.key,
                style: AppTextStyles.grey12_600,
              ),
            ),
            ...entry.value.map(
              (log) => CallLogTile(
                log: log,
                currentUserId: currentUserId!,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
