import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/image_constants.dart';
import 'package:kkp_chat_app/core/utils/utils.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_button.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_drop_down.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_image.dart';
import 'package:kkp_chat_app/presentation/common_widgets/custom_search_bar.dart';

class CustomerInquiriesPage extends StatefulWidget {
  const CustomerInquiriesPage({super.key});

  @override
  State<CustomerInquiriesPage> createState() => _CustomerInquiriesPageState();
}

class _CustomerInquiriesPageState extends State<CustomerInquiriesPage> {
  bool showFilters = false;
  String selectedAgent = 'All Agents';
  String selectedDateRange = 'Last 30 days';
  String selectedQuality = "Quality";
  int currentIndex = 0; // For pagination

  List<String> agents = ['All Agents', 'Agent Sam', 'Agent Sammy'];
  List<String> dateRanges = [
    'Today',
    'Last Week',
    'Last Month',
    'Last 30 days'
  ];
  List<String> qualities = ["Quality", "Standard", "Premium"];

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
      'agent': 'Agent Sam',
      'customer': 'Alice',
      'date': 'Feb 5, 2025',
      'status': 'Confirmed',
      'sNo': '03',
      'quality': 'Silk',
      'weave': 'Satin',
      'quantity': '300 pcs',
      'composition': '100% Silk',
      'rate': 'Rs. 70,000'
    },
    {
      'agent': 'Agent Sammy',
      'customer': 'Bob',
      'date': 'Feb 10, 2025',
      'status': 'Pending',
      'sNo': '04',
      'quality': 'Linen',
      'weave': 'Twill',
      'quantity': '600 pcs',
      'composition': '80% Cotton, 20% Linen',
      'rate': 'Rs. 60,000'
    },
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
      'agent': 'Agent Sam',
      'customer': 'Alice',
      'date': 'Feb 5, 2025',
      'status': 'Confirmed',
      'sNo': '03',
      'quality': 'Silk',
      'weave': 'Satin',
      'quantity': '300 pcs',
      'composition': '100% Silk',
      'rate': 'Rs. 70,000'
    },
    {
      'agent': 'Agent Sammy',
      'customer': 'Bob',
      'date': 'Feb 10, 2025',
      'status': 'Pending',
      'sNo': '04',
      'quality': 'Linen',
      'weave': 'Twill',
      'quantity': '600 pcs',
      'composition': '80% Cotton, 20% Linen',
      'rate': 'Rs. 60,000'
    },
  ];

  void toggleShowFilters() {
    setState(() {
      showFilters = !showFilters;
    });
  }

  void loadMore() {
    setState(() {
      if (currentIndex + 2 < inquiries.length) {
        currentIndex += 2;
      }
    });
  }

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
        padding: const EdgeInsets.all(12.0),
        child: Column(
          spacing: 10, // Flutter 3.29+ feature
          children: [
            _buildSearchRow(),
            if (showFilters) _buildFilters(),
            Expanded(child: _buildInquiryList()),
            if (currentIndex + 2 < inquiries.length) _buildNextButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchRow() {
    return Row(
      spacing: 10,
      children: [
        Expanded(child: CustomSearchBar()),
        GestureDetector(
          onTap: toggleShowFilters,
          child: Container(
            width: 50,
            height: 42,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(width: 1, color: AppColors.greyB2BACD)),
            child: CustomImage(
              imagePath: ImageConstants.filterIcon,
              height: 25,
              width: 25,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        spacing: 10,
        children: [
          CustomDropDown(
            value: selectedAgent,
            items: agents,
            onChanged: (value) => setState(() => selectedAgent = value!),
          ),
          CustomDropDown(
            value: selectedDateRange,
            items: dateRanges,
            onChanged: (value) => setState(() => selectedDateRange = value!),
          ),
          CustomDropDown(
            value: selectedQuality,
            items: qualities,
            onChanged: (value) => setState(() => selectedQuality = value!),
          ),
        ],
      ),
    );
  }

  Widget _buildInquiryList() {
    return ListView.builder(
      itemCount: currentIndex + 2 <= inquiries.length
          ? currentIndex + 2
          : inquiries.length,
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
          spacing: 10, // Flutter 3.29+ feature
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
                  spacing: 5, // Flutter 3.29+ feature
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
      spacing: 5, // Flutter 3.29+ feature
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildNextButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: CustomButton(
        width: Utils().width(context) * 0.35,
        onPressed: loadMore,
        text: "Next",
        fontSize: 16,
      ),
    );
  }
}
