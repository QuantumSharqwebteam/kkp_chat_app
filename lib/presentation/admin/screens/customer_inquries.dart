import 'dart:math';

import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/config/theme/image_constants.dart';

import 'package:kkpchatapp/data/models/form_data_model.dart';
import 'package:kkpchatapp/data/repositories/chat_reopsitory.dart';

//import 'package:kkpchatapp/presentation/common_widgets/custom_drop_down.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_image.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_search_field.dart';

class CustomerInquiriesPage extends StatefulWidget {
  const CustomerInquiriesPage({super.key});

  @override
  State<CustomerInquiriesPage> createState() => _CustomerInquiriesPageState();
}

class _CustomerInquiriesPageState extends State<CustomerInquiriesPage>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _chatRepository = ChatRepository();

  bool showFilters = false;
  String selectedAgent = 'All Agents';
  String selectedDateRange = 'Last 30 days';
  String selectedQuality = "Quality";
  bool isFetchingMore = false;

  List<String> agents = ['All Agents', 'Agent mohd 3', 'Unknown Agent'];
  List<String> dateRanges = [
    'Today',
    'Last Week',
    'Last Month',
    'Last 30 days'
  ];
  List<String> qualities = ["Quality", "Standard", "Premium"];

  List<FormDataModel> allInquiries = [];
  List<FormDataModel> filteredInquiries = [];

  bool isLoading = true;

  late ScrollController _scrollController;
  int visibleItemCount = 10;
  final int itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    fetchInquiries();
    _searchController.addListener(_applyFilters);
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchInquiries() async {
    try {
      final data = await _chatRepository.fetchFormData();
      setState(() {
        isLoading = false;
        allInquiries = data;
        _applyFilters();
      });
    } catch (e) {
      debugPrint("Failed to fetch inquiries: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onScroll() async {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isFetchingMore &&
        visibleItemCount < filteredInquiries.length) {
      setState(() => isFetchingMore = true);
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate fetch
      setState(() {
        visibleItemCount = (visibleItemCount + itemsPerPage)
            .clamp(0, filteredInquiries.length);
        isFetchingMore = false;
      });
    }
  }

  void _applyFilters() {
    String search = _searchController.text.toLowerCase();
    final now = DateTime.now();

    filteredInquiries = allInquiries.where((item) {
      final matchAgent =
          selectedAgent == 'All Agents' || item.agentName == selectedAgent;

      final matchQuality = selectedQuality == 'Quality' ||
          item.quality.contains(selectedQuality);

      final matchSearch = item.customerName.toLowerCase().contains(search) ||
          item.agentName.toLowerCase().contains(search) ||
          item.quality.toLowerCase().contains(search) ||
          item.weave.toLowerCase().contains(search) ||
          item.composition.toLowerCase().contains(search) ||
          item.rate.toLowerCase().contains(search) ||
          item.quantity.toLowerCase().contains(search) ||
          item.status.toLowerCase().contains(search);

      bool matchDate = true;
      final date = item.parsedDate;

      switch (selectedDateRange) {
        case 'Today':
          matchDate = date?.day == now.day &&
              date?.month == now.month &&
              date?.year == now.year;
          break;
        case 'Last Week':
          matchDate = date!.isAfter(now.subtract(const Duration(days: 7)));
          break;
        case 'Last Month':
          matchDate = date!.isAfter(DateTime(now.year, now.month - 1, now.day));
          break;
        case 'Last 30 days':
          matchDate = date!.isAfter(now.subtract(const Duration(days: 30)));
          break;
      }

      return matchAgent && matchQuality && matchSearch && matchDate;
    }).toList();

    visibleItemCount = min(itemsPerPage, filteredInquiries.length);
    setState(() {});
  }

  void toggleShowFilters() {
    setState(() {
      showFilters = !showFilters;
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
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildSearchRow(),
                  const SizedBox(height: 20),
                  //  if (showFilters) _buildFilters(),
                  Expanded(child: _buildInquiryList()),
                ],
              ),
      ),
    );
  }

  Widget _buildSearchRow() {
    return Row(
      children: [
        Expanded(
          child: CustomSearchBar(
            enable: true,
            controller: _searchController,
            hintText: "Search by anything...",
            onChanged: (value) => _applyFilters(),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: toggleShowFilters,
          child: Container(
            width: 50,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(width: 1, color: AppColors.greyB2BACD),
            ),
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

  // Widget _buildFilters() {
  //   return SingleChildScrollView(
  //     scrollDirection: Axis.horizontal,
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.start,
  //       children: [
  //         // CustomDropDown(
  //         //   value: selectedAgent,
  //         //   items: agents,
  //         //   onChanged: (value) {
  //         //     setState(() => selectedAgent = value!);
  //         //     _applyFilters();
  //         //   },
  //         // ),
  //         // const SizedBox(width: 10),
  //         CustomDropDown(
  //           value: selectedDateRange,
  //           items: dateRanges,
  //           onChanged: (value) {
  //             setState(() => selectedDateRange = value!);
  //             _applyFilters();
  //           },
  //         ),
  //         const SizedBox(width: 10),
  //         CustomDropDown(
  //           value: selectedQuality,
  //           items: qualities,
  //           onChanged: (value) {
  //             setState(() => selectedQuality = value!);
  //             _applyFilters();
  //           },
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildInquiryList() {
    if (filteredInquiries.isEmpty) {
      return const Center(child: Text("No related inquiries found."));
    }

    final visibleItems = filteredInquiries.take(visibleItemCount).toList();

    return ListView.builder(
      controller: _scrollController,
      itemCount: visibleItems.length + (isFetchingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == visibleItems.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final inquiry = visibleItems[index];
        return AnimatedOpacity(
          opacity: 1,
          duration: Duration(milliseconds: 400 + (index * 100)),
          child: _buildInquiryCard(inquiry),
        );
      },
    );
  }

  Widget _buildInquiryCard(FormDataModel inquiry) {
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        ImageConstants.userImage,
                        height: 40,
                        width: 40,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${inquiry.agentName}\nCustomer: ${inquiry.customerName}',
                      style: AppTextStyles.black10_500,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(inquiry.dateOnly, style: AppTextStyles.black12_400),
                    Text(inquiry.timeOnly, style: AppTextStyles.black12_400),
                    Text(
                      inquiry.status,
                      style: AppTextStyles.black12_400.copyWith(
                        color: inquiry.status == "Confirmed"
                            ? AppColors.activeGreen
                            : inquiry.status == "Declined"
                                ? AppColors.inActiveRed
                                : AppColors.helperOrange,
                      ),
                    ),
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

  Widget _buildInquiryDetails(FormDataModel inquiry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow('Quality', inquiry.quality),
        _buildDetailRow('Weave', inquiry.weave),
        _buildDetailRow('Quantity', inquiry.quantity),
        _buildDetailRow('Composition', inquiry.composition),
        _buildDetailRow('Rate', inquiry.rate),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
