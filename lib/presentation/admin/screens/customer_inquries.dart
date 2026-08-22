import 'dart:io';
import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/config/theme/image_constants.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/models/form_data_model.dart';
import 'package:kkpchatapp/data/repositories/chat_reopsitory.dart';
import 'package:kkpchatapp/l10n/generated/app_localizations.dart';
import 'package:kkpchatapp/logic/agent/inquiry_provider.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_drop_down.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_image.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_search_field.dart';
import 'package:kkpchatapp/presentation/common_widgets/empty_inquries_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart' hide Border, TextSpan;
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';

class CustomerInquiriesPage extends StatefulWidget {
  const CustomerInquiriesPage({super.key});

  @override
  State<CustomerInquiriesPage> createState() => _CustomerInquiriesPageState();
}

class _CustomerInquiriesPageState extends State<CustomerInquiriesPage>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final chatRepository = ChatRepository();
  late InquiryProvider _inquiryProvider;

  bool showFilters = false;
  String selectedDateRange = 'Last 30 days';
  String selectedStatus = "All";

  bool isDownloading = false;

  List<String> dateRanges = [
    'Today',
    'Last Week',
    'Last Month',
    'Last 30 days'
  ];
  List<String> status = ["All", "Confirmed", "Processed", "Declined"];

  // Map to track the expanded state of each inquiry card
  Map<String, bool> expandedStates = {};

  @override
  void initState() {
    super.initState();
    _inquiryProvider = Provider.of<InquiryProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchInitialData());
  }

  Future<void> _fetchInitialData() async {
    final role = await LocalDbHelper.getUserType();
    final currentUserEmail = LocalDbHelper.getProfile()?.email;
    await _inquiryProvider.fetchInquiries(
      userEmail: currentUserEmail,
      role: role,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // didPush() and didPopNext() intentionally removed.
  //
  // didPush() duplicated the initState fetch (both fire when MarketingHost is
  // first pushed as a PageRoute).
  //
  // didPopNext() fired every time any route on top of the MarketingHost was
  // popped — including the chat screen — causing a full API re-fetch on every
  // navigation back. The inquiry screen has no child routes of its own that
  // could mutate inquiry data, so there is nothing to refresh on return.

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
        TextCellValue('Reason'),
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
          TextCellValue(inquiry.reason),
          TextCellValue(inquiry.status),
          TextCellValue(inquiry.id),
          TextCellValue(_getFormattedTime(inquiry.date)),
        ]);
      }

      final bytes = excel.save();
      final formattedDate =
          DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/inquiries_$formattedDate.xlsx');
      await file.writeAsBytes(bytes!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File generated: ${file.path}')),
        );
      }

      final result = await OpenFile.open(file.path);
      if (result.type != ResultType.done) {
        debugPrint("⚠️ Could not open Excel file: ${result.message}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unable to open the file')),
          );
        }
      }
    } catch (e) {
      debugPrint('Excel generation error: $e');
    } finally {
      setState(() => isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InquiryProvider>(
      builder: (context, provider, child) {
        final hasInquiries = provider.hasAnyInquiries;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.background,
            title: Text(AppLocalizations.of(context)!.customerInquiries),
            actions: [
              // Refresh button
              // if (hasInquiries)
              //   IconButton(
              //     onPressed: () => provider.refreshInquiries(),
              //     icon: const Icon(Icons.refresh),
              //   ),
              if (hasInquiries && !provider.isLoading)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: isDownloading
                        ? null
                        : () async {
                            await downloadAsExcel(_inquiryProvider.inquiries);
                          },
                    child: isDownloading
                        ? const SizedBox(
                            width: 35,
                            height: 35,
                            child: Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  width: 1, color: AppColors.greyB2BACD),
                            ),
                            child: const Icon(Icons.download),
                          ),
                  ),
                ),
            ],
          ),
          body: provider.isLoading && provider.inquiries.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          if (hasInquiries)
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade400,
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: CustomSearchBar(
                                      enable: true,
                                      controller: _searchController,
                                      hintText: AppLocalizations.of(context)!
                                          .searchByAnything,
                                      onChanged: (value) {
                                        _inquiryProvider.updateSearch(value);
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: toggleShowFilters,
                                  child: Container(
                                    width: 56,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        width: 1,
                                        color: AppColors.greyB2BACD,
                                      ),
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
                          if (hasInquiries) const SizedBox(height: 10),
                          if (showFilters && hasInquiries) _buildFilters(),
                          if (showFilters && hasInquiries)
                            const Divider(
                              color: AppColors.greyE5E7EB,
                              thickness: 0.6,
                              height: 0,
                            ),
                          if (showFilters && hasInquiries)
                            Container(
                              height: 5,
                              color: AppColors.greyD9D9D9.withOpacity(0.3),
                            ),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),
                    Expanded(child: _buildInquiryList()),
                  ],
                ),
        );
      },
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
            CustomDropDown(
              value: selectedDateRange,
              items: dateRanges,
              onChanged: (value) {
                setState(() => selectedDateRange = value!);
                _inquiryProvider.updateDateRange(value!);
              },
            ),
            const SizedBox(width: 10),
            CustomDropDown(
              value: selectedStatus,
              items: status,
              onChanged: (value) {
                setState(() => selectedStatus = value!);
                _inquiryProvider.updateStatus(value!);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInquiryList() {
    final inquiries = _inquiryProvider.inquiries;

    if (!_inquiryProvider.hasAnyInquiries) {
      return const Center(child: EmptyInquriesWidget());
    }

    if (inquiries.isEmpty) {
      return const Center(child: EmptyInquriesWidget());
    }

    return RefreshIndicator(
      onRefresh: _inquiryProvider.refreshInquiries,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 60),
        itemCount: inquiries.length,
        itemBuilder: (context, index) {
          final inquiry = inquiries[index];
          return _buildInquiryCard(inquiry);
        },
      ),
    );
  }

  Widget _buildInquiryCard(FormDataModel inquiry) {
    final hasReason = inquiry.reason.trim().isNotEmpty;
    final summaryChips = <MapEntry<String, String>>[
      MapEntry('Buyer', inquiry.buyerName),
      MapEntry('Quantity', inquiry.quantity),
      MapEntry('Rate', inquiry.rate),
    ].where((entry) => entry.value.trim().isNotEmpty).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Color(0xFFF8FBFF),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _statusTextColor(inquiry.status).withOpacity(0.14),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => toggleExpandedState(inquiry.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFE0F2FE),
                            Color(0xFFDCFCE7),
                          ],
                        ),
                      ),
                      child: const Icon(Icons.groups_rounded,
                          color: Color(0xFF166534)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inquiry.agentName.isEmpty
                                ? 'Agent not assigned'
                                : inquiry.agentName,
                            style: AppTextStyles.black16_600,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Customer: ${inquiry.customerName}',
                            style: AppTextStyles.black12_400
                                .copyWith(fontSize: 14, color: Colors.black45),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _getFormattedDate(inquiry.date),
                          style: AppTextStyles.black12_400
                              .copyWith(color: Colors.black45),
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusBackground(inquiry.status),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            inquiry.status,
                            style: AppTextStyles.black12_400.copyWith(
                              color: _statusTextColor(inquiry.status),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                if (summaryChips.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: summaryChips
                        .map((entry) =>
                            _buildSummaryChip(entry.key, entry.value))
                        .toList(),
                  ),
                ],
                if (hasReason) ...[
                  const SizedBox(height: 12),
                  _buildReasonCard(inquiry.reason),
                ],
                if (expandedStates[inquiry.id] ?? false) ...[
                  const SizedBox(height: 12),
                  _buildInquiryDetails(inquiry),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInquiryDetails(FormDataModel inquiry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DottedLine(
          dashLength: 7.0,
          dashGapLength: 4.0,
          lineThickness: 1.5,
          dashColor: Colors.grey,
        ),
        SizedBox(
          height: 10,
        ),
        _buildDetailRow('Quality', inquiry.quality),
        _buildDetailRow('Weave', inquiry.weave),
        _buildDetailRow('Quantity', inquiry.quantity),
        _buildDetailRow('Composition', inquiry.composition),
        _buildDetailRow('Rate', inquiry.rate),
        if (inquiry.reason.trim().isNotEmpty)
          _buildDetailRow('Reason', inquiry.reason),
      ],
    );
  }

  Widget _buildSummaryChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label\n',
              style: AppTextStyles.black12_400
                  .copyWith(color: Colors.grey.shade600),
            ),
            TextSpan(
              text: value,
              style: AppTextStyles.black14_600
                  .copyWith(color: const Color(0xFF0F172A)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonCard(String reason) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.report_gmailerrorred_rounded,
                color: Color(0xFFEA580C), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reason',
                  style: AppTextStyles.black12_500
                      .copyWith(color: const Color(0xFF9A3412)),
                ),
                const SizedBox(height: 2),
                Text(
                  reason,
                  style: AppTextStyles.black14_400
                      .copyWith(color: const Color(0xFF7C2D12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusBackground(String status) {
    final normalized = status.toLowerCase();
    if (normalized == 'confirmed') return const Color(0xFFDCFCE7);
    if (normalized == 'declined') return AppColors.inActiveRed.withOpacity(0.1);
    return AppColors.helperOrange.withOpacity(0.1);
  }

  Color _statusTextColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized == 'confirmed') return const Color.fromARGB(255, 4, 127, 10);
    if (normalized == 'declined') return AppColors.inActiveRed;
    return AppColors.helperOrange;
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style:
                AppTextStyles.black14_400.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? 'N/A' : value,
            softWrap: true,
            overflow: TextOverflow.visible,
            style: AppTextStyles.black14_600.copyWith(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w100,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
