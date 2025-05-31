import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_initicon/flutter_initicon.dart';
import 'package:intl/intl.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/config/theme/image_constants.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/models/form_data_model.dart';
import 'package:kkpchatapp/data/repositories/chat_reopsitory.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_drop_down.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_image.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_search_field.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:excel/excel.dart' hide Border;

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
  // String selectedAgent = 'All Agents';
  String selectedDateRange = 'Last 30 days';
  String selectedStatus = "All";
  bool isFetchingMore = false;
  bool isDownloading = false;

  // List<String> agents = ['All Agents', 'Agent mohd 3', 'Unknown Agent'];
  List<String> dateRanges = [
    'Today',
    'Last Week',
    'Last Month',
    'Last 30 days'
  ];
  List<String> status = ["All", "Confirmed", "Processed", "Declined"];

  List<FormDataModel> allInquiries = [];
  List<FormDataModel> filteredInquiries = [];

  bool isLoading = true;

  late ScrollController _scrollController;
  int visibleItemCount = 10;
  final int itemsPerPage = 10;

  // Map to track the expanded state of each inquiry card
  Map<String, bool> expandedStates = {};

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
    final role = await LocalDbHelper.getUserType();
    final currentUserEmail = LocalDbHelper.getProfile()?.email;
    List<FormDataModel> data = [];
    try {
      if (role == "2" || role == "3" || role == "0") {
        data =
            await _chatRepository.fetchFormDataForEnquiery(currentUserEmail!);
      } else if (role == "1") {
        data = await _chatRepository.fetchFormData();
      }

      setState(() {
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

  String _getFormattedDate(String rawDate) {
    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) return '';
    return DateFormat('MMMM d, yyyy').format(parsed); // e.g., "May 21, 2025"
  }

  String _getFormattedTime(String rawDate) {
    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) return '';
    return DateFormat('h:mm a').format(parsed); // e.g., "3:45 PM"
  }

  void _applyFilters() {
    String search = _searchController.text.toLowerCase();
    final now = DateTime.now();

    filteredInquiries = allInquiries.where((item) {
      final matchQuality =
          selectedStatus == 'All' || item.status.contains(selectedStatus);

      final dateTime = DateTime.tryParse(item.date);
      final formattedDate = dateTime != null
          ? DateFormat('MMMM d, yyyy').format(dateTime).toLowerCase()
          : '';
      final formattedTime = dateTime != null
          ? DateFormat('h:mm a').format(dateTime).toLowerCase()
          : '';

      final matchSearch = item.customerName.toLowerCase().contains(search) ||
          item.agentName.toLowerCase().contains(search) ||
          item.quality.toLowerCase().contains(search) ||
          item.weave.toLowerCase().contains(search) ||
          item.composition.toLowerCase().contains(search) ||
          item.rate.toLowerCase().contains(search) ||
          item.quantity.toLowerCase().contains(search) ||
          item.status.toLowerCase().contains(search) ||
          formattedDate.contains(search) || // 🔍 Match formatted date
          formattedTime.contains(search); // 🔍 Match formatted time

      bool matchDate = true;
      if (dateTime != null) {
        switch (selectedDateRange) {
          case 'Today':
            matchDate = dateTime.day == now.day &&
                dateTime.month == now.month &&
                dateTime.year == now.year;
            break;
          case 'Last Week':
            matchDate = dateTime.isAfter(now.subtract(const Duration(days: 7)));
            break;
          case 'Last Month':
            matchDate =
                dateTime.isAfter(DateTime(now.year, now.month - 1, now.day));
            break;
          case 'Last 30 days':
            matchDate =
                dateTime.isAfter(now.subtract(const Duration(days: 30)));
            break;
        }
      }

      return matchQuality && matchSearch && matchDate;
    }).toList();

    // Sort by date and time
    filteredInquiries.sort((a, b) {
      final dateA = DateTime.tryParse(a.date);
      final dateB = DateTime.tryParse(b.date);
      if (dateA == null || dateB == null) return 0;
      return dateB.compareTo(dateA); // Newest first
    });

    visibleItemCount = filteredInquiries.length > itemsPerPage
        ? itemsPerPage
        : filteredInquiries.length;
    setState(() {});
  }

  void toggleShowFilters() {
    setState(() {
      showFilters = !showFilters;
    });
  }

  void toggleExpandedState(String inquiryId) {
    setState(() {
      expandedStates[inquiryId] = !(expandedStates[inquiryId] ?? false);
    });
  }

  Future<void> downloadAsExcel(List<FormDataModel> inquiries) async {
    setState(() {
      isDownloading = true;
    });

    try {
      // Check Android version
      if (Platform.isAndroid) {
        if (await _checkAndRequestPermissions() == false) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Storage permission denied. Cannot save file.'),
              ),
            );
          }
          setState(() {
            isDownloading = false;
          });
          return;
        }
      }

      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];

      sheet.appendRow([
        TextCellValue('Date'),
        TextCellValue('Quality'),
        TextCellValue('Weave'),
        TextCellValue('Quantity'),
        TextCellValue('Composition'),
        TextCellValue('Rate'),
        TextCellValue('Agent Name'),
        TextCellValue('Customer Name'),
        TextCellValue('Status'),
        TextCellValue('ID'),
        TextCellValue('Time'),
      ]);

      for (var inquiry in inquiries) {
        sheet.appendRow([
          TextCellValue(_getFormattedDate(inquiry.date)),
          TextCellValue(inquiry.quality),
          TextCellValue(inquiry.weave),
          TextCellValue(inquiry.quantity),
          TextCellValue(inquiry.composition),
          TextCellValue(inquiry.rate),
          TextCellValue(inquiry.agentName),
          TextCellValue(inquiry.customerName),
          TextCellValue(inquiry.status),
          TextCellValue(inquiry.id),
          TextCellValue(_getFormattedTime(inquiry.date)),
        ]);
      }

      final bytes = excel.save();
      final formattedDate =
          DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

      final dir = Directory('/storage/emulated/0/Download');
      if (await dir.exists()) {
        final file = File('${dir.path}/inquiries_$formattedDate.xlsx');
        await file.writeAsBytes(bytes!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('File saved to ${file.path}')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Download directory not found')),
          );
        }
      }
    } catch (e) {
      debugPrint('Excel download error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to download file')),
        );
      }
    } finally {
      setState(() {
        isDownloading = false;
      });
    }
  }

  Future<bool> _checkAndRequestPermissions() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 30) {
        // Android 11+ needs MANAGE_EXTERNAL_STORAGE
        if (await Permission.manageExternalStorage.isGranted) {
          return true;
        }
        final result = await Permission.manageExternalStorage.request();
        return result.isGranted;
      } else {
        // Android <11 needs basic storage permission
        if (await Permission.storage.isGranted) {
          return true;
        }
        final result = await Permission.storage.request();
        return result.isGranted;
      }
    }
    // On iOS or other platforms, you may adjust logic if needed
    return true;
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: isDownloading
                  ? null
                  : () async {
                      await downloadAsExcel(filteredInquiries);
                    },
              child: isDownloading
                  ? const SizedBox(
                      width: 35,
                      height: 35,
                      child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(width: 1, color: AppColors.greyB2BACD),
                      ),
                      child: const Icon(Icons.download),
                    ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Row(
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
                            border: Border.all(
                                width: 1, color: AppColors.greyB2BACD),
                          ),
                          child: CustomImage(
                            imagePath: ImageConstants.filterIcon,
                            height: 25,
                            width: 25,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (showFilters) _buildFilters(),
                  Expanded(child: _buildInquiryList()),
                ],
              ),
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // CustomDropDown(
            //   value: selectedAgent,
            //   items: agents,
            //   onChanged: (value) {
            //     setState(() => selectedAgent = value!);
            //     _applyFilters();
            //   },
            // ),
            // const SizedBox(width: 10),
            CustomDropDown(
              value: selectedDateRange,
              items: dateRanges,
              onChanged: (value) {
                setState(() => selectedDateRange = value!);
                _applyFilters();
              },
            ),
            const SizedBox(width: 10),
            CustomDropDown(
              value: selectedStatus,
              items: status,
              onChanged: (value) {
                setState(() => selectedStatus = value!);
                _applyFilters();
              },
            ),
          ],
        ),
      ),
    );
  }

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
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
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
                      child: Initicon(
                        text: inquiry.agentName,
                        size: 35,
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
                    Text(_getFormattedDate(inquiry.date),
                        style: AppTextStyles.black12_400),
                    Text(_getFormattedTime(inquiry.date),
                        style: AppTextStyles.black12_400),
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
                InkWell(
                  onTap: () => toggleExpandedState(inquiry.id),
                  child: Icon(
                    expandedStates[inquiry.id] ?? false
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 20,
                  ),
                ),
              ],
            ),
            if (expandedStates[inquiry.id] ?? false)
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
        const Divider(),
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
          Text(
            label,
            style: AppTextStyles.black14_400,
          ),
          Text(value, style: AppTextStyles.black14_600),
        ],
      ),
    );
  }
}
