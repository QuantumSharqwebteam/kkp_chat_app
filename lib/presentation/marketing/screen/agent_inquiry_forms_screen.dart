import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';

import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/models/form_data_model.dart';
import 'package:kkpchatapp/logic/agent/inquiry_provider.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_button.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_search_field.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_textfield.dart';

class AgentInquiryFormsScreen extends StatefulWidget {
  final String customerEmail;
  final String customerName;

  const AgentInquiryFormsScreen({
    super.key,
    required this.customerEmail,
    required this.customerName,
  });

  @override
  State<AgentInquiryFormsScreen> createState() => _AgentInquiryFormsScreenState();
}

class _AgentInquiryFormsScreenState extends State<AgentInquiryFormsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _busyForms = {};
  final Set<String> _expandedForms = {};
  String? _currentRole;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadForms());
  }

  Future<void> _loadForms() async {
    final role = await LocalDbHelper.getUserType();
    if (!mounted) return;
    setState(() => _currentRole = role);
    await context.read<InquiryProvider>().fetchInquiries(
          userEmail: widget.customerEmail,
          role: role,
        );
  }

  bool get _canManageForms => _currentRole != null && _currentRole != '0';

  void _setBusy(String formId, bool busy) {
    setState(() {
      if (busy) {
        _busyForms.add(formId);
      } else {
        _busyForms.remove(formId);
      }
    });
  }

  void _toggleExpansion(String formId) {
    setState(() {
      if (_expandedForms.contains(formId)) {
        _expandedForms.remove(formId);
      } else {
        _expandedForms.add(formId);
      }
    });
  }

  bool _hasValidRate(String? rawRate) {
    final normalizedRate = (rawRate ?? '').trim();
    if (normalizedRate.isEmpty) {
      return false;
    }

    final parsedRate = double.tryParse(normalizedRate.replaceAll(',', ''));
    return parsedRate != null && parsedRate > 0;
  }

  Future<void> _handleStatusSelection(String formId, String status, {String? reason}) async {
    _setBusy(formId, true);
    try {
      await context.read<InquiryProvider>().updateFormStatus(
            formId,
            status,
            reason: reason,
          );
      if (mounted) {
        _showStatusToast('Status updated to $status', success: true);
      }
    } catch (e) {
      if (mounted) {
        _showStatusToast('Unable to update status: $e', success: false);
      }
    } finally {
      _setBusy(formId, false);
    }
  }

  Future<String?> _askDeclineReason({String initialValue = ''}) async {
    final controller = TextEditingController(text: initialValue);
    String? errorText;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Reason for decline', style: AppTextStyles.black18_600),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Please enter the reason before declining this inquiry.',
                    style: AppTextStyles.grey12_400.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: controller,
                    hintText: 'Reason for declining',
                    minLines: 3,
                    maxLines: 4,
                    errorText: errorText,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final reason = controller.text.trim();
                    if (reason.isEmpty) {
                      setDialogState(() {
                        errorText = 'Reason is required';
                      });
                      return;
                    }
                    Navigator.of(dialogContext).pop(reason);
                  },
                  child: const Text('Decline'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
    return result;
  }

  Future<void> _handleDecline(FormDataModel form) async {
    final reason = await _askDeclineReason(initialValue: form.reason);
    if (reason == null || reason.isEmpty) return;
    await _handleStatusSelection(form.id, 'Declined', reason: reason);
  }

  Future<void> _openEditFormSheet(FormDataModel form) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return InquiryFormEditSheet(
          form: form,
          onSubmit: (updates) => _handleFormUpdate(form.id, updates),
        );
      },
    );
  }

  Future<bool> _handleFormUpdate(String formId, Map<String, dynamic> updates) async {
    _setBusy(formId, true);
    try {
      await context.read<InquiryProvider>().updateFormDetails(formId, updates);
      if (mounted) {
        _showStatusToast('Inquiry updated', success: true);
      }
      return true;
    } catch (e) {
      if (mounted) {
        _showStatusToast('Unable to update inquiry: $e', success: false);
      }
      return false;
    } finally {
      _setBusy(formId, false);
    }
  }

  void _showStatusToast(String message, {required bool success}) {
    final overlay = Overlay.of(context);
    late final OverlayEntry entry;
    entry = OverlayEntry(builder: (context) {
      return Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 250),
            offset: const Offset(0, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: success ? AppColors.green22C55E : AppColors.inActiveRed,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    success ? Icons.check_circle : Icons.error_outline,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: AppTextStyles.black12_500.copyWith(color: Colors.white),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => entry.remove(),
                    child: const Icon(Icons.close, color: Colors.white),
                  )
                ],
              ),
            ),
          ),
        ),
      );
    });

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 2), () {
      entry.remove();
    });
  }

  Widget _buildFilterChips(InquiryProvider provider) {
    const statuses = ['All', 'Processed', 'Confirmed', 'Declined'];
    const dateRanges = ['All', 'Today', 'Last Week', 'Last Month', 'Last 30 days'];

    Widget buildStatusChips() {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: statuses.map((status) {
            final isSelected = provider.selectedStatus.toLowerCase() == status.toLowerCase();
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildOvalFilterChip(
                label: status,
                selected: isSelected,
                selectedColor: AppColors.blue.withOpacity(0.2),
                unselectedColor: Colors.white,
                onTap: () {
                  if (_searchController.text.isNotEmpty) _searchController.clear();
                  provider.updateStatus(status);
                },
              ),
            );
          }).toList(),
        ),
      );
    }

    Widget buildDateChips() {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: dateRanges.map((range) {
            final isSelected = provider.selectedDateRange.toLowerCase() == range.toLowerCase();
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildOvalFilterChip(
                label: range,
                selected: isSelected,
                selectedColor: AppColors.blue.withOpacity(0.2),
                unselectedColor: Colors.white,
                labelColor: isSelected ? AppColors.blue : Colors.black54,
                onTap: () {
                  if (_searchController.text.isNotEmpty) _searchController.clear();
                  provider.updateDateRange(range);
                },
              ),
            );
          }).toList(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Status', style: AppTextStyles.black14_400),
        const SizedBox(height: 6),
        buildStatusChips(),
        const SizedBox(height: 12),
        Text('Date', style: AppTextStyles.black14_400),
        const SizedBox(height: 6),
        buildDateChips(),
      ],
    );
  }

  Widget _buildOvalFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Color? selectedColor,
    Color? unselectedColor,
    Color? labelColor,
  }) {
    final backgroundColor = selected
        ? (selectedColor ?? AppColors.blue.withOpacity(0.2))
        : (unselectedColor ?? Colors.white);
    final textColor = labelColor ?? (selected ? AppColors.blue : Colors.black87);
    final borderColor = selected ? AppColors.blue : Colors.grey.shade300;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          label,
          style: AppTextStyles.black12_500.copyWith(color: textColor),
        ),
      ),
    );
  }

  Widget _buildInquiryCard(FormDataModel form) {
    final busy = _busyForms.contains(form.id);
    final isExpanded = _expandedForms.contains(form.id);
    final hasReason = form.reason.trim().isNotEmpty;
    final detailChips = <MapEntry<String, String>>[
      MapEntry('Quality', form.quality),
      MapEntry('Quantity', form.quantity),
      MapEntry('Rate', form.rate),
    ].where((entry) => entry.value.trim().isNotEmpty).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Color(0xFFF6FAFF),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _statusTextColor(form.status).withOpacity(0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _toggleExpansion(form.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                      child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF0F766E)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            form.buyerName.isNotEmpty ? form.buyerName : 'Buyer not available',
                            style: AppTextStyles.black16_600,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            form.customerName.isNotEmpty
                                ? 'Customer: ${form.customerName}'
                                : 'Requested on ${_formatDate(form.date)}',
                            style: AppTextStyles.grey12_400.copyWith(fontSize: 13),
                          ),
                          if (form.customerName.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              'Requested on ${_formatDate(form.date)}',
                              style: AppTextStyles.grey12_400.copyWith(fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusBackground(form.status),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            form.status,
                            style: AppTextStyles.black12_400.copyWith(
                              color: _statusTextColor(form.status),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatTime(form.date),
                          style: AppTextStyles.grey12_400.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    if (_canManageForms)
                      busy
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : PopupMenuButton<String>(
                              onSelected: (value) => _onMenuSelection(value, form),
                              itemBuilder: (_) {
                                final options = <String>['confirm', 'decline', 'edit'];
                                return options.map((choice) {
                                  final text = choice == 'edit'
                                      ? 'Edit form'
                                      : choice == 'confirm'
                                          ? 'Confirm'
                                          : 'Decline';
                                  return PopupMenuItem(
                                    value: choice,
                                    child: Text(text),
                                  );
                                }).toList();
                              },
                            ),
                  ],
                ),
                if (detailChips.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        detailChips.map((entry) => _buildInfoChip(entry.key, entry.value)).toList(),
                  ),
                ],
                if (hasReason) ...[
                  const SizedBox(height: 14),
                  _buildReasonBanner(form.reason),
                ],
                if (isExpanded) ...[
                  const SizedBox(height: 14),
                  const DottedLine(
                    dashLength: 6,
                    dashGapLength: 4,
                    lineThickness: 1.2,
                    dashColor: Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Buyer name', form.buyerName),
                  _buildDetailRow('Quality', form.quality),
                  _buildDetailRow('Weave', form.weave),
                  _buildDetailRow('Quantity', form.quantity),
                  _buildDetailRow('Composition', form.composition),
                  _buildDetailRow('Rate', form.rate),
                  if (hasReason) _buildDetailRow('Reason', form.reason),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
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
              style: AppTextStyles.black12_500.copyWith(color: Colors.grey.shade600),
            ),
            TextSpan(
              text: value,
              style: AppTextStyles.black14_600.copyWith(color: const Color(0xFF0F172A)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonBanner(String reason) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.info_outline, color: Color(0xFFDC2626), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reason',
                  style: AppTextStyles.black12_500.copyWith(color: const Color(0xFF991B1B)),
                ),
                const SizedBox(height: 2),
                Text(
                  reason,
                  style: AppTextStyles.black14_400.copyWith(color: const Color(0xFF7F1D1D)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.black14_400.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? 'N/A' : value,
            style: AppTextStyles.black14_600.copyWith(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  void _onMenuSelection(String value, FormDataModel form) {
    if (value == 'confirm') {
      if (!_hasValidRate(form.rate)) {
        _showStatusToast(
          'Please update the rate before confirming the order',
          success: false,
        );
        return;
      }
      _handleStatusSelection(form.id, 'Confirmed');
    } else if (value == 'decline') {
      _handleDecline(form);
    } else if (value == 'edit') {
      _openEditFormSheet(form);
    }
  }

  String _formatDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('MMM d, yyyy • h:mm a').format(parsed);
  }

  String _formatTime(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return '';
    return DateFormat('h:mm a').format(parsed);
  }

  Color _statusBackground(String status) {
    final normalized = status.toLowerCase();
    if (normalized == 'confirmed') return AppColors.green22C55E.withOpacity(0.15);
    if (normalized == 'declined') return AppColors.inActiveRed.withOpacity(0.15);
    return AppColors.helperOrange.withOpacity(0.15);
  }

  Color _statusTextColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized == 'confirmed') return AppColors.green22C55E;
    if (normalized == 'declined') return AppColors.inActiveRed;
    return AppColors.helperOrange;
  }

  Widget _buildShimmerList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: 4,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'No inquiry forms found yet.',
        style: AppTextStyles.grey12_600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        title: Text('Inquiry forms', style: AppTextStyles.black20_600),
        backgroundColor: Colors.white.withOpacity(0.95),
        elevation: 0,
        centerTitle: false,
      ),
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFEDF4FF),
                  Colors.white,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Consumer<InquiryProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.inquiries.isEmpty) {
                  return _buildShimmerList();
                }

                final inquiries = provider.inquiries;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: CustomSearchBar(
                        enable: true,
                        controller: _searchController,
                        hintText: 'Search forms, buyers, statuses...',
                        onChanged: (value) => provider.updateSearch(value),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 25,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _buildFilterChips(provider),
                    ),
                    if (provider.isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
                        child: LinearProgressIndicator(),
                      ),
                    Expanded(
                      child: inquiries.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: provider.refreshInquiries,
                              child: ListView.builder(
                                padding:
                                    const EdgeInsets.only(top: 12, bottom: 32, left: 4, right: 4),
                                itemCount: inquiries.length,
                                itemBuilder: (context, index) {
                                  return _buildInquiryCard(inquiries[index]);
                                },
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class InquiryFormEditSheet extends StatefulWidget {
  final FormDataModel form;
  final Future<bool> Function(Map<String, dynamic>) onSubmit;

  const InquiryFormEditSheet({
    super.key,
    required this.form,
    required this.onSubmit,
  });

  @override
  State<InquiryFormEditSheet> createState() => _InquiryFormEditSheetState();
}

class _InquiryFormEditSheetState extends State<InquiryFormEditSheet> {
  late final TextEditingController buyerController =
      TextEditingController(text: widget.form.buyerName);
  late final TextEditingController customerController =
      TextEditingController(text: widget.form.customerName);
  late final TextEditingController qualityController =
      TextEditingController(text: widget.form.quality);
  late final TextEditingController weaveController = TextEditingController(text: widget.form.weave);
  late final TextEditingController quantityController =
      TextEditingController(text: widget.form.quantity);
  late final TextEditingController compositionController =
      TextEditingController(text: widget.form.composition);
  late final TextEditingController rateController = TextEditingController(text: widget.form.rate);
  late final TextEditingController reasonController =
      TextEditingController(text: widget.form.reason);

  final List<String> _statuses = ['Processed', 'Confirmed', 'Declined'];
  late String _selectedStatus;
  bool isSubmitting = false;
  String? _quantityError;
  String? _rateError;
  String? _reasonError;

  @override
  void initState() {
    super.initState();
    _selectedStatus = _statuses.contains(widget.form.status) ? widget.form.status : _statuses.first;
  }

  @override
  void dispose() {
    buyerController.dispose();
    customerController.dispose();
    qualityController.dispose();
    weaveController.dispose();
    quantityController.dispose();
    compositionController.dispose();
    rateController.dispose();
    reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (isSubmitting) return;
    // validate decline reason inline
    if (_selectedStatus == 'Declined' && reasonController.text.trim().isEmpty) {
      setState(() => _reasonError = 'Reason is required when declining an inquiry');
      return;
    }
    setState(() {
      _reasonError = null;
      _quantityError = null;
      _rateError = null;
    });
    // Prevent negative values for quantity (supports "1000 metres", "100 m", etc.)
    final qtyText = quantityController.text.trim();
    if (qtyText.isNotEmpty) {
      final numericMatch = RegExp(r'\d+').firstMatch(qtyText.replaceAll(',', ''));
      if (numericMatch != null) {
        final q = int.tryParse(numericMatch.group(0)!);
        if (q != null && q < 0) {
          setState(() => _quantityError = 'Quantity cannot be negative');
          return;
        }
      }
    }
    setState(() => isSubmitting = true);
    final updates = <String, dynamic>{
      'buyerName': buyerController.text.trim(),
      'customerName': customerController.text.trim(),
      'quality': qualityController.text.trim(),
      'weave': weaveController.text.trim(),
      'quantity': quantityController.text.trim(),
      'composition': compositionController.text.trim(),
      'rate': rateController.text.trim(),
      'status': _selectedStatus,
      'reason': _selectedStatus == 'Declined' ? reasonController.text.trim() : '',
    };
    final success = await widget.onSubmit(updates);
    if (!mounted) return;
    setState(() => isSubmitting = false);
    if (success) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: Theme.of(context).platform == TargetPlatform.android,
      bottom: true,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        padding: EdgeInsets.only(
          top: 16,
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Update Inquiry', style: AppTextStyles.black18_600),
              const SizedBox(height: 12),
              CustomTextField(
                controller: buyerController,
                hintText: 'Buyer name / requested customer',
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: customerController,
                hintText: 'Customer name',
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: qualityController,
                hintText: 'Quality',
                maxLines: 2,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.deny(RegExp(r'-')),
                ],
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: weaveController,
                hintText: 'Weave',
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: quantityController,
                hintText: 'Quantity',
                // allow text like "2 metres" but block minus sign
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.deny(RegExp(r'-'))
                ],
                errorText: _quantityError,
                onChanged: (_) {
                  if (_quantityError != null) setState(() => _quantityError = null);
                },
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: compositionController,
                hintText: 'Composition',
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: rateController,
                hintText: 'Final rate',
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                errorText: _rateError,
                onChanged: (_) {
                  if (_rateError != null) setState(() => _rateError = null);
                },
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedStatus,
                    isExpanded: true,
                    items: _statuses.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedStatus = value);
                    },
                  ),
                ),
              ),
              if (_selectedStatus == 'Declined') ...[
                const SizedBox(height: 12),
                CustomTextField(
                  controller: reasonController,
                  hintText: 'Reason for declining',
                  minLines: 3,
                  maxLines: 4,
                  errorText: _reasonError,
                  onChanged: (_) {
                    if (_reasonError != null) setState(() => _reasonError = null);
                  },
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Cancel',
                      backgroundColor: Colors.white,
                      textColor: AppColors.blue,
                      borderColor: AppColors.blue,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: 'Save changes',
                      isLoading: isSubmitting,
                      loaderColor: Colors.white,
                      onPressed: _submit,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
