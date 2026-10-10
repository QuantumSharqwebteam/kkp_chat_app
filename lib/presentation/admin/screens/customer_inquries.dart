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

  /// Removes the minus sign from any negative number in a value so quantity
  /// and rate always display as positive.
  ///   "-500"      → "500"
  ///   "-500 m"    → "500 m"
  ///   "Rs -120.5" → "Rs 120.5"
  ///   "- 45"      → "45"
  /// A hyphen between two numbers (a range such as "100-200") is kept, because
  /// it is preceded by a digit rather than being a sign.
  String _positive(String value) {
    return value.replaceAll(RegExp(r'(?<![\w.])-\s*(?=\d)'), '');
  }

  // ─── Packed-field parsing ─────────────────────────────────────────────────

  /// Matches a field label followed by a separator (":", "=", or " - ").
  /// `\b` stops a key matching inside a longer word (e.g. "rate" in
  /// "accurate"). Aliases such as "count", "fabric quality", "qty" and "price"
  /// map onto the canonical keys in [_canonicalKey].
  static final _fieldKeyPattern = RegExp(
    r'\b(buyer\s*name|buyer|fabric\s*quality|quality|count|weave|quantity|qty|composition|rate|price)\s*(?:[:=]|-\s)',
    caseSensitive: false,
  );

  String _canonicalKey(String name) {
    final n = name.toLowerCase();
    if (n.startsWith('buyer')) return 'buyer';
    if (n.contains('quality') || n == 'count') return 'quality';
    if (n == 'qty') return 'quantity';
    if (n == 'price') return 'rate';
    return n;
  }

  /// Trims whitespace and stray separators from both ends of a value.
  String _clean(String s) => s.replaceAll(RegExp(r'^[\s,;|]+|[\s,;|]+$'), '');

  /// Some customer messages arrive with every field packed into `quality`, e.g.
  /// "buyer name : karan testing , Quality : 60s , weave : banaras".
  /// This splits that string back into separate fields. A dedicated field that
  /// already has a value wins over the packed one.
  ///
  /// If quality is still empty after parsing, any text that appears BEFORE the
  /// first "key :" is used as the quality — previously that text was dropped,
  /// which is why Quality showed N/A.
  Map<String, String> _fields(FormDataModel inquiry) {
    final fields = <String, String>{
      'buyer': inquiry.buyerName,
      'quality': inquiry.quality,
      'weave': inquiry.weave,
      'quantity': inquiry.quantity,
      'composition': inquiry.composition,
      'rate': inquiry.rate,
    };

    final raw = inquiry.quality;
    final matches = _fieldKeyPattern.allMatches(raw).toList();

    // Only unpack when the quality string actually holds packed keys.
    if (matches.isNotEmpty) {
      // The packed string itself isn't a real quality value.
      fields['quality'] = '';

      for (var i = 0; i < matches.length; i++) {
        final m = matches[i];
        final end = i + 1 < matches.length ? matches[i + 1].start : raw.length;
        final value = _clean(raw.substring(m.end, end));
        final key = _canonicalKey(m.group(1)!);
        if (value.isNotEmpty && fields[key]!.trim().isEmpty) {
          fields[key] = value;
        }
      }

      // Recover leading text that sits before the first key.
      if (fields['quality']!.trim().isEmpty) {
        final lead = _clean(raw.substring(0, matches.first.start));
        if (lead.isNotEmpty) fields['quality'] = lead;
      }
    }

    // Backend merges quality into composition as "quality / composition",
    // e.g. "100% linen / 100% cotton" → quality "100% linen",
    // composition "100% cotton". Same rule the agent Inquiry forms screen
    // uses, so both screens show identical values.
    if (fields['quality']!.trim().isEmpty) {
      final parts = fields['composition']!.split(RegExp(r'\s+/\s+'));
      if (parts.length == 2) {
        fields['quality'] = parts[0].trim();
        fields['composition'] = parts[1].trim();
      }
    }

    // Strip leftover separators such as "---10% cotton" → "10% cotton".
    fields
        .updateAll((_, v) => _clean(v.replaceAll(RegExp(r'^[\s:=\-–—]+'), '')));

    return fields;
  }

  // ──────────────────────────────────────────────────────────────────────────

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
        TextCellValue('Buyer'),
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
        final f = _fields(inquiry);
        sheet.appendRow([
          TextCellValue(_getFormattedDate(inquiry.date)),
          TextCellValue(f['buyer']!),
          TextCellValue(f['quality']!),
          TextCellValue(f['weave']!),
          TextCellValue(_positive(f['quantity']!)),
          TextCellValue(f['composition']!),
          TextCellValue(_positive(f['rate']!)),
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
            const SnackBar(content: Text('Unable to open the file')),
          );
        }
      }
    } catch (e) {
      debugPrint('Excel generation error: $e');
    } finally {
      if (mounted) setState(() => isDownloading = false);
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

    if (!_inquiryProvider.hasAnyInquiries || inquiries.isEmpty) {
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
    final f = _fields(inquiry);
    final hasReason = inquiry.reason.trim().isNotEmpty;
    final summaryChips = <MapEntry<String, String>>[
      MapEntry('Buyer', f['buyer']!),
      MapEntry('Quality', f['quality']!),
      MapEntry('Quantity', _positive(f['quantity']!)),
      MapEntry('Rate', _positive(f['rate']!)),
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (f['buyer']!.trim().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Buyer: ${f['buyer']}',
                              style: AppTextStyles.black12_400.copyWith(
                                  fontSize: 14, color: Colors.black45),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
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
                        const SizedBox(height: 8),
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
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 200),
                      turns: (expandedStates[inquiry.id] ?? false) ? 0.5 : 0,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.grey.shade500,
                        size: 22,
                      ),
                    ),
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
                  _buildInquiryDetails(inquiry, f),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInquiryDetails(FormDataModel inquiry, Map<String, String> f) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DottedLine(
          dashLength: 7.0,
          dashGapLength: 4.0,
          lineThickness: 1.5,
          dashColor: Color(0xFFCBD5E1),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Buyer', f['buyer']!),
              _buildDetailRow('Quality', f['quality']!),
              _buildDetailRow('Weave', f['weave']!),
              _buildDetailRow('Quantity', _positive(f['quantity']!)),
              _buildDetailRow('Composition', f['composition']!),
              _buildDetailRow('Rate', _positive(f['rate']!)),
              if (inquiry.reason.trim().isNotEmpty)
                _buildDetailRow('Reason', inquiry.reason),
            ],
          ),
        ),
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

  /// Label on the left, value on the right — the label column is fixed width so
  /// every row in a card lines up. Long values wrap within their own column.
  Widget _buildDetailRow(String label, String value) {
    final isEmpty = value.trim().isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: AppTextStyles.black14_400.copyWith(
                color: Colors.grey.shade600,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isEmpty ? 'N/A' : value,
              softWrap: true,
              overflow: TextOverflow.visible,
              textAlign: TextAlign.right,
              style: AppTextStyles.black14_600.copyWith(
                color: isEmpty ? Colors.grey.shade400 : const Color(0xFF0F172A),
                fontWeight: isEmpty ? FontWeight.w400 : FontWeight.w600,
                fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
