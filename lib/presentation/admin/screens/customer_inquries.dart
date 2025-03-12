import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/image_constants.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_search_bar.dart';

class CustomerInquiriesPage extends StatefulWidget {
  const CustomerInquiriesPage({super.key});

  @override
  State<CustomerInquiriesPage> createState() => _CustomerInquiriesPageState();
}

class _CustomerInquiriesPageState extends State<CustomerInquiriesPage> {
  bool showFilters = false;
  String selectedAgent = 'All';
  String selectedDateRange = 'Last 30 days';

  List<String> agents = ['All', 'Agent Sam', 'Agent Sammy'];
  List<String> dateRanges = [
    'Today',
    'Last Week',
    'Last Month',
    'Last 30 days'
  ];

  List<Map<String, dynamic>> inquiries = [
    {
      'agent': 'Agent Sam',
      'customer': 'Sarah',
      'date': 'Jan 15, 2025',
      'status': 'Confirmed',
      'sNo': '01',
      'quality': 'Premium Cotton',
      'weave': 'Plain',
      'quantity': '500 pcs',
      'composition': '100% Cotton',
      'rate': 'Rs. 50,000'
    },
    {
      'agent': 'Agent Sammy',
      'customer': 'John',
      'date': 'Jan 15, 2025',
      'status': 'Declined',
      'sNo': '02',
      'quality': 'Premium Cotton',
      'weave': 'Plain',
      'quantity': '500 pcs',
      'composition': '100% Cotton',
      'rate': 'Rs. 50,000'
    },
    {
      'agent': 'Agent Sammy',
      'customer': 'John',
      'date': 'Jan 15, 2025',
      'status': 'Declined',
      'sNo': '02',
      'quality': 'Premium Cotton',
      'weave': 'Plain',
      'quantity': '500 pcs',
      'composition': '100% Cotton',
      'rate': 'Rs. 50,000'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Customer Inquiries'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 10),
            _buildFilters(),
            const SizedBox(height: 10),
            Expanded(child: _buildInquiryList()),
            // _buildNextButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return CustomSearchBar();
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          DropdownButton<String>(
            dropdownColor: Colors.white,
            value: selectedAgent,
            items: agents.map((agent) {
              return DropdownMenuItem(value: agent, child: Text(agent));
            }).toList(),
            onChanged: (value) => setState(() => selectedAgent = value!),
          ),
          DropdownButton<String>(
            dropdownColor: Colors.white,
            value: selectedDateRange,
            items: dateRanges.map((range) {
              return DropdownMenuItem(value: range, child: Text(range));
            }).toList(),
            onChanged: (value) => setState(() => selectedDateRange = value!),
          ),
        ],
      ),
    );
  }

  Widget _buildInquiryList() {
    return ListView.builder(
      itemCount: inquiries.length,
      itemBuilder: (context, index) {
        final inquiry = inquiries[index];
        return _buildInquiryCard(inquiry);
      },
    );
  }

  Widget _buildInquiryCard(Map<String, dynamic> inquiry) {
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  spacing: 5,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        ImageConstants.userImage,
                        height: 40,
                        width: 40,
                      ),
                    ),
                    Text(
                        '${inquiry['agent']}\nCustomer: ${inquiry['customer']}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  children: [
                    Text(inquiry['date']),
                    Text(inquiry['status'],
                        style: TextStyle(
                          color: inquiry['status'] == 'Confirmed'
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        )),
                  ],
                ),
              ],
            ),
            const Divider(),
            _buildInquiryDetails(inquiry),
          ],
        ),
      ),
    );
  }

  Widget _buildInquiryDetails(Map<String, dynamic> inquiry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow('S.No.', inquiry['sNo']),
        _buildDetailRow('Quality', inquiry['quality']),
        _buildDetailRow('Weave', inquiry['weave']),
        _buildDetailRow('Quantity', inquiry['quantity']),
        _buildDetailRow('Composition', inquiry['composition']),
        _buildDetailRow('Rate', inquiry['rate']),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Widget _buildNextButton() {
  //   return ElevatedButton(
  //     onPressed: () {},
  //     child: const Text('Next'),
  //   );
  // }
}
