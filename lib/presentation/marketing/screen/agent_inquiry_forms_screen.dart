import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import 'package:kkpchatapp/data/api/api_client.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/models/form_data_model.dart';
import 'package:kkpchatapp/logic/agent/inquiry_provider.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_button.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_search_field.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_textfield.dart';

/// "buying name : karan quality: 500 meters quantity : 200 pcs ..." -> fields.
final _labelRe = RegExp(
    r"(?<![a-z])(buy(?:er|ing)?'?s?\s*name|buyer|customer\s*name|quality|weave|quantity|qty|composition|rate|price)\s*[:=\-–—]+\s*",
    caseSensitive: false);

/// Strips leading/trailing separators like "---", ":-", " , " from a value.
/// Hyphens inside a value (e.g. "poly-cotton") are kept.
final _junkRe = RegExp(r'^[\s,;:=\-–—]+|[\s,;:=\-–—.]+$');
String cleanField(String v) => v.replaceAll(_junkRe, '');

String _keyFor(String l) => switch (l.toLowerCase()) {
      final k when k.startsWith('buy') => 'buyerName',
      final k when k.startsWith('customer') => 'customerName',
      'qty' => 'quantity',
      'price' => 'rate',
      final k => k,
    };

Map<String, String> parseInquiryText(String t) {
  final m = _labelRe.allMatches(t).toList();
  return {
    for (var i = 0; i < m.length; i++)
      _keyFor(m[i].group(1)!): cleanField(
          t.substring(m[i].end, i + 1 < m.length ? m[i + 1].start : t.length))
  }..removeWhere((_, v) => v.isEmpty);
}

Map<String, String> parseFormFields(FormDataModel f) {
  final out = {
    'buyerName': f.buyerName,
    'customerName': f.customerName,
    'quality': f.quality,
    'weave': f.weave,
    'quantity': f.quantity,
    'composition': f.composition,
    'rate': f.rate,
  };
  for (final e in Map.of(out).entries) {
    final p = parseInquiryText(e.value);
    if (p.isEmpty) continue;
    out[e.key] = '';
    out.addAll(p);
  }
  // Backend sometimes merges quality into composition:
  // "100% linen / 100% cotton" -> quality "100% linen", composition "100% cotton".
  if (out['quality']!.trim().isEmpty) {
    final parts = out['composition']!.split(RegExp(r'\s+/\s+'));
    if (parts.length == 2) {
      out['quality'] = parts[0];
      out['composition'] = parts[1];
    }
  }
  // Clean already-saved values like "---10% cotton" -> "10% cotton".
  out.updateAll((_, v) => cleanField(v));
  return out;
}

class AgentInquiryFormsScreen extends StatefulWidget {
  final String customerEmail;
  final String customerName;
  const AgentInquiryFormsScreen(
      {super.key, required this.customerEmail, required this.customerName});

  @override
  State<AgentInquiryFormsScreen> createState() =>
      _AgentInquiryFormsScreenState();
}

class _AgentInquiryFormsScreenState extends State<AgentInquiryFormsScreen> {
  final _searchController = TextEditingController();
  final Set<String> _busyForms = {}, _expandedForms = {};
  String? _currentRole;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadForms());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadForms() async {
    final role = await LocalDbHelper.getUserType();
    if (!mounted) return;
    setState(() => _currentRole = role);
    await context
        .read<InquiryProvider>()
        .fetchInquiries(userEmail: widget.customerEmail, role: role);
  }

  bool get _canManageForms => _currentRole != null && _currentRole != '0';

  void _setBusy(String id, bool busy) =>
      setState(() => busy ? _busyForms.add(id) : _busyForms.remove(id));

  void _toggleExpansion(String id) => setState(() => _expandedForms.contains(id)
      ? _expandedForms.remove(id)
      : _expandedForms.add(id));

  bool _hasValidRate(String? raw) =>
      (double.tryParse((raw ?? '').trim().replaceAll(',', '')) ?? 0) > 0;

  Future<bool> _run(
      String id, Future<void> Function() action, String ok, String fail) async {
    _setBusy(id, true);
    try {
      await action();
      if (mounted) _showStatusToast(ok, success: true);
      return true;
    } catch (e) {
      if (mounted)
        _showStatusToast('$fail: ${e is ApiException ? e.message : '$e'}',
            success: false);
      return false;
    } finally {
      if (mounted) _setBusy(id, false);
    }
  }

  Future<void> _handleStatusSelection(String id, String status,
          {String? reason}) =>
      _run(
          id,
          () => context
              .read<InquiryProvider>()
              .updateFormStatus(id, status, reason: reason),
          'Status updated to $status',
          'Unable to update status');

  Future<bool> _handleFormUpdate(String id, Map<String, dynamic> updates) =>
      _run(
          id,
          () => context.read<InquiryProvider>().updateFormDetails(id, updates),
          'Inquiry updated',
          'Unable to update inquiry');

  Future<String?> _askDeclineReason({String initialValue = ''}) async {
    final controller = TextEditingController(text: initialValue);
    String? errorText;
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Reason for decline', style: AppTextStyles.black18_600),
          content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Please enter the reason before declining this inquiry.',
                    style: AppTextStyles.grey12_400.copyWith(fontSize: 14)),
                const SizedBox(height: 12),
                CustomTextField(
                    controller: controller,
                    hintText: 'Reason for declining',
                    minLines: 3,
                    maxLines: 4,
                    errorText: errorText),
              ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final reason = controller.text.trim();
                if (reason.isEmpty)
                  return setDialogState(() => errorText = 'Reason is required');
                Navigator.of(dialogContext).pop(reason);
              },
              child: const Text('Decline'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _handleDecline(FormDataModel form) async {
    final reason = await _askDeclineReason(initialValue: form.reason);
    if (reason == null || reason.isEmpty) return;
    await _handleStatusSelection(form.id, 'Declined', reason: reason);
  }

  Future<void> _openEditFormSheet(FormDataModel form) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => InquiryFormEditSheet(
            form: form, onSubmit: (u) => _handleFormUpdate(form.id, u)),
      );

  void _onMenuSelection(String value, FormDataModel form) {
    if (value == 'confirm') {
      if (!_hasValidRate(parseFormFields(form)['rate'])) {
        return _showStatusToast(
            'Please update the rate before confirming the order',
            success: false);
      }
      _handleStatusSelection(form.id, 'Confirmed');
    } else if (value == 'decline') {
      _handleDecline(form);
    } else if (value == 'edit') {
      _openEditFormSheet(form);
    }
  }

  void _showStatusToast(String message, {required bool success}) {
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: success ? AppColors.green22C55E : AppColors.inActiveRed,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Row(children: [
              Icon(success ? Icons.check_circle : Icons.error_outline,
                  color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(message,
                      style: AppTextStyles.black12_500
                          .copyWith(color: Colors.white))),
              GestureDetector(
                  onTap: () => entry.mounted ? entry.remove() : null,
                  child: const Icon(Icons.close, color: Colors.white)),
            ]),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(entry);
    Future.delayed(const Duration(seconds: 2),
        () => entry.mounted ? entry.remove() : null);
  }

  Widget _chipRow(
          List<String> items, String selected, ValueChanged<String> onSelect) =>
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: items.map((label) {
            final sel = selected.toLowerCase() == label.toLowerCase();
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () {
                  _searchController.clear();
                  onSelect(label);
                },
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.blue.withOpacity(0.2) : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: sel ? AppColors.blue : Colors.grey.shade300),
                  ),
                  child: Text(label,
                      style: AppTextStyles.black12_500.copyWith(
                          color: sel ? AppColors.blue : Colors.black87)),
                ),
              ),
            );
          }).toList(),
        ),
      );

  Widget _buildFilterChips(InquiryProvider p) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Status', style: AppTextStyles.black14_400),
        const SizedBox(height: 6),
        _chipRow(const ['All', 'Processed', 'Confirmed', 'Declined'],
            p.selectedStatus, p.updateStatus),
        const SizedBox(height: 12),
        Text('Date', style: AppTextStyles.black14_400),
        const SizedBox(height: 6),
        _chipRow(
            const ['All', 'Today', 'Last Week', 'Last Month', 'Last 30 days'],
            p.selectedDateRange,
            p.updateDateRange),
      ]);

  Widget _buildInquiryCard(FormDataModel form) {
    final f = parseFormFields(form);
    final busy = _busyForms.contains(form.id);
    final hasReason = form.reason.trim().isNotEmpty;
    final statusColor = _statusTextColor(form.status);
    final chips = ['Quality', 'Quantity', 'Rate']
        .where((k) => f[k.toLowerCase()]!.trim().isNotEmpty)
        .map((k) => _buildInfoChip(k, f[k.toLowerCase()]!))
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFF6FAFF)]),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: statusColor.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 10))
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _toggleExpansion(form.id),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                        colors: [Color(0xFFE0F2FE), Color(0xFFDCFCE7)]),
                  ),
                  child: const Icon(Icons.inventory_2_outlined,
                      color: Color(0xFF0F766E)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            f['buyerName']!.isNotEmpty
                                ? f['buyerName']!
                                : 'Buyer not available',
                            style: AppTextStyles.black16_600),
                        if (f['customerName']!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('Customer: ${f['customerName']}',
                              style: AppTextStyles.grey12_400
                                  .copyWith(fontSize: 13)),
                        ],
                        const SizedBox(height: 3),
                        Text('Requested on ${_formatDate(form.date)}',
                            style: AppTextStyles.grey12_400
                                .copyWith(fontSize: 12)),
                      ]),
                ),
                const SizedBox(width: 6),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14)),
                    child: Text(form.status,
                        style: AppTextStyles.black12_400.copyWith(
                            color: statusColor, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 8),
                  Text(_formatTime(form.date),
                      style: AppTextStyles.grey12_400.copyWith(fontSize: 12)),
                ]),
                const SizedBox(width: 4),
                if (_canManageForms)
                  busy
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : PopupMenuButton<String>(
                          onSelected: (v) => _onMenuSelection(v, form),
                          itemBuilder: (_) => const {
                            'confirm': 'Confirm',
                            'decline': 'Decline',
                            'edit': 'Edit form'
                          }
                              .entries
                              .map((e) => PopupMenuItem(
                                  value: e.key, child: Text(e.value)))
                              .toList(),
                        ),
              ]),
              if (chips.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(spacing: 8, runSpacing: 8, children: chips),
              ],
              if (hasReason) ...[
                const SizedBox(height: 14),
                _buildReasonBanner(form.reason)
              ],
              if (_expandedForms.contains(form.id)) ...[
                const SizedBox(height: 14),
                const DottedLine(
                    dashLength: 6,
                    dashGapLength: 4,
                    lineThickness: 1.2,
                    dashColor: Colors.grey),
                const SizedBox(height: 12),
                for (final e in const {
                  'Buyer name': 'buyerName',
                  'Quality': 'quality',
                  'Weave': 'weave',
                  'Quantity': 'quantity',
                  'Composition': 'composition',
                  'Rate': 'rate',
                }.entries)
                  _buildDetailRow(e.key, f[e.value]!),
                if (hasReason) _buildDetailRow('Reason', form.reason),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: RichText(
          text: TextSpan(children: [
            TextSpan(
                text: '$label\n',
                style: AppTextStyles.black12_500
                    .copyWith(color: Colors.grey.shade600)),
            TextSpan(
                text: value,
                style: AppTextStyles.black14_600
                    .copyWith(color: const Color(0xFF0F172A))),
          ]),
        ),
      );

  Widget _buildReasonBanner(String reason) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.info_outline, color: Color(0xFFDC2626), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Reason',
                  style: AppTextStyles.black12_500
                      .copyWith(color: const Color(0xFF991B1B))),
              const SizedBox(height: 2),
              Text(reason,
                  style: AppTextStyles.black14_400
                      .copyWith(color: const Color(0xFF7F1D1D))),
            ]),
          ),
        ]),
      );

  Widget _buildDetailRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: AppTextStyles.black14_400
                  .copyWith(color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(value.isEmpty ? 'N/A' : value,
              style: AppTextStyles.black14_600
                  .copyWith(color: Colors.grey.shade700)),
        ]),
      );

  String _formatDate(String raw) {
    final d = DateTime.tryParse(raw);
    return d == null ? raw : DateFormat('MMM d, yyyy • h:mm a').format(d);
  }

  String _formatTime(String raw) {
    final d = DateTime.tryParse(raw);
    return d == null ? '' : DateFormat('h:mm a').format(d);
  }

  Color _statusTextColor(String status) => switch (status.toLowerCase()) {
        'confirmed' => AppColors.green22C55E,
        'declined' => AppColors.inActiveRed,
        _ => AppColors.helperOrange,
      };

  Widget _buildShimmerList() => ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
              height: 140,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16))),
        ),
      );

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFEDF4FF), Colors.white]),
        ),
        child: SafeArea(
          child: Consumer<InquiryProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading && provider.inquiries.isEmpty)
                return _buildShimmerList();
              final inquiries = provider.inquiries;
              return Column(children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: CustomSearchBar(
                    enable: true,
                    controller: _searchController,
                    hintText: 'Search forms, buyers, statuses...',
                    onChanged: provider.updateSearch,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 25,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: _buildFilterChips(provider),
                ),
                if (provider.isLoading)
                  const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: LinearProgressIndicator()),
                Expanded(
                  child: inquiries.isEmpty
                      ? Center(
                          child: Text('No inquiry forms found yet.',
                              style: AppTextStyles.grey12_600))
                      : RefreshIndicator(
                          onRefresh: provider.refreshInquiries,
                          child: ListView.builder( 
                            padding: const EdgeInsets.fromLTRB(4, 12, 4, 32),
                            itemCount: inquiries.length,
                            itemBuilder: (_, i) =>
                                _buildInquiryCard(inquiries[i]),
                          ),
                        ),
                ),
              ]);
            },
          ),
        ),
      ),
    );
  }
}

class InquiryFormEditSheet extends StatefulWidget {
  final FormDataModel form;
  final Future<bool> Function(Map<String, dynamic>) onSubmit;
  const InquiryFormEditSheet(
      {super.key, required this.form, required this.onSubmit});

  @override
  State<InquiryFormEditSheet> createState() => _InquiryFormEditSheetState();
}

class _InquiryFormEditSheetState extends State<InquiryFormEditSheet> {
  static const _statuses = ['Processed', 'Confirmed', 'Declined'];
  late final Map<String, TextEditingController> _c = {
    ...parseFormFields(widget.form)
        .map((k, v) => MapEntry(k, TextEditingController(text: v))),
    'reason': TextEditingController(text: widget.form.reason),
  };
  late String _status = _statuses.contains(widget.form.status)
      ? widget.form.status
      : _statuses.first;
  bool _submitting = false;
  String? _reasonError;

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (_status == 'Declined' && _c['reason']!.text.trim().isEmpty) {
      return setState(
          () => _reasonError = 'Reason is required when declining an inquiry');
    }
    setState(() {
      _reasonError = null;
      _submitting = true;
    });
    final updates = <String, dynamic>{
      for (final e in _c.entries)
        e.key:
            e.key == 'reason' ? e.value.text.trim() : cleanField(e.value.text),
      'status': _status,
      if (_status != 'Declined') 'reason': '',
    };
    final ok = await widget.onSubmit(updates);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) Navigator.of(context).pop();
  }

  Widget _field(String key, String hint,
          {int? maxLines, List<TextInputFormatter>? fmt, TextInputType? kb}) =>
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: CustomTextField(
            controller: _c[key]!,
            hintText: hint,
            maxLines: maxLines ?? 1,
            inputFormatters: [_NoLeadingDashFormatter(), ...?fmt],
            keyboardType: kb),
      );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: Theme.of(context).platform == TargetPlatform.android,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75),
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text('Update Inquiry', style: AppTextStyles.black18_600),
            _field('buyerName', 'Buyer name / requested customer'),
            _field('customerName', 'Customer name'),
            _field('quality', 'Quality', maxLines: 2),
            _field('weave', 'Weave', maxLines: 2),
            _field('quantity', 'Quantity'),
            _field('composition', 'Composition', maxLines: 3),
            _field('rate', 'Final rate',
                kb: const TextInputType.numberWithOptions(decimal: true),
                fmt: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                ]),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _status,
                  isExpanded: true,
                  items: _statuses
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) =>
                      v == null ? null : setState(() => _status = v),
                ),
              ),
            ),
            if (_status == 'Declined') ...[
              const SizedBox(height: 12),
              CustomTextField(
                controller: _c['reason']!,
                hintText: 'Reason for declining',
                minLines: 3,
                maxLines: 4,
                errorText: _reasonError,
                onChanged: (_) => _reasonError != null
                    ? setState(() => _reasonError = null)
                    : null,
              ),
            ],
            const SizedBox(height: 20),
            Row(children: [
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
                    isLoading: _submitting,
                    loaderColor: Colors.white,
                    onPressed: _submit),
              ),
            ]),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }
}

/// Blocks a leading "-", ":", "=" (and spaces) so agents can't enter
/// values like "-500" or "--10% cotton". Hyphens later in the text are fine.
class _NoLeadingDashFormatter extends TextInputFormatter {
  static final _lead = RegExp(r'^[\s\-–—:=]+');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final t = newValue.text.replaceFirst(_lead, '');
    if (t == newValue.text) return newValue;
    final removed = newValue.text.length - t.length;
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(
          offset: (newValue.selection.end - removed).clamp(0, t.length)),
    );
  }
}
