import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/config/theme/image_constants.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/models/form_data_model.dart';
import 'package:kkpchatapp/data/repositories/chat_reopsitory.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_button.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_drop_down.dart';
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
  int currentIndex = 0;

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

  @override
  void initState() {
    super.initState();
    fetchInquiries();
    _searchController.addListener(_applyFilters);
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
          item.quantity.toLowerCase().contains(search);

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

    currentIndex = 0;
    setState(() {});
  }

  void toggleShowFilters() {
    setState(() {
      showFilters = !showFilters;
    });
  }

  void loadMore() {
    setState(() {
      if (currentIndex + 2 < filteredInquiries.length) {
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
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                spacing: 10,
                children: [
                  _buildSearchRow(),
                  if (showFilters) _buildFilters(),
                  Expanded(child: _buildInquiryList()),
                  if (currentIndex + 2 < filteredInquiries.length)
                    _buildNextButton(),
                ],
              ),
      ),
    );
  }

  Widget _buildSearchRow() {
    return Row(
      spacing: 10,
      children: [
        Expanded(
          child: CustomSearchBar(
            enable: true,
            controller: _searchController,
            hintText: "Search by anything...",
            onChanged: (value) => _applyFilters(),
          ),
        ),
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
            onChanged: (value) {
              setState(() => selectedAgent = value!);
              _applyFilters();
            },
          ),
          CustomDropDown(
            value: selectedDateRange,
            items: dateRanges,
            onChanged: (value) {
              setState(() => selectedDateRange = value!);
              _applyFilters();
            },
          ),
          CustomDropDown(
            value: selectedQuality,
            items: qualities,
            onChanged: (value) {
              setState(() => selectedQuality = value!);
              _applyFilters();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInquiryList() {
    final displayList = filteredInquiries.take(currentIndex + 2).toList();

    if (displayList.isEmpty) {
      return const Center(child: Text("No inquiries found."));
    }

    return ListView.builder(
      itemCount: displayList.length,
      itemBuilder: (context, index) {
        final inquiry = displayList[index];
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
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
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
                      '${inquiry.agentName}\nCustomer: ${inquiry.customerName}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  spacing: 5,
                  children: [
                    Text(inquiry.dateOnly, style: AppTextStyles.black12_400),
                    Text(inquiry.timeOnly, style: AppTextStyles.black12_400),
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
      spacing: 5,
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
