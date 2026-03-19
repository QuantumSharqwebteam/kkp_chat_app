import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/services/excel_export_service.dart';
import 'package:kkpchatapp/core/services/logging_service.dart';
import 'package:kkpchatapp/data/models/extracted_product_data.dart';
import 'package:kkpchatapp/data/repositories/extracted_product_repository.dart';
import 'package:intl/intl.dart';
import 'package:kkpchatapp/presentation/common_widgets/chat/extracted_product_form_overlay.dart';

class ExtractedDataViewerScreen extends StatefulWidget {
  final String agentEmail;

  const ExtractedDataViewerScreen({
    super.key,
    required this.agentEmail,
  });

  @override
  State<ExtractedDataViewerScreen> createState() => _ExtractedDataViewerScreenState();
}

class _ExtractedDataViewerScreenState extends State<ExtractedDataViewerScreen> {
  final ExtractedProductRepository _repository = ExtractedProductRepository();
  final ExcelExportService _excelService = ExcelExportService();
  final LoggingService _logger = LoggingService.instance;

  List<ExtractedProductData> _data = [];
  List<ExtractedProductData> _sentData = [];
  bool _isLoading = true;
  Map<String, dynamic> _summary = {};
  DateTime? _startDate;
  DateTime? _endDate;
  final Set<String> _sentRecordKeys = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _repository.getByAgent(widget.agentEmail);
      final summary = await _excelService.getDataSummary(widget.agentEmail);

      setState(() {
        _data = data;
        _sentData = data.where((record) => record.sent).toList();
        _summary = summary;
        _isLoading = false;
      });

      _logger
          .logStorage('Loaded ${_data.length} extracted product records for ${widget.agentEmail}');
    } catch (e) {
      setState(() => _isLoading = false);
      _logger.logStorage('Error loading extracted data: $e', level: LogLevel.error);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _exportToExcel() async {
    try {
      await _excelService.exportToExcel(
        widget.agentEmail,
        startDate: _startDate,
        endDate: _endDate,
      );

      _logger.logStorage('Excel export completed for ${widget.agentEmail}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Excel file exported successfully')),
        );
      }
    } catch (e) {
      _logger.logStorage('Excel export failed: $e', level: LogLevel.error);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadFilteredData();
    }
  }

  Future<void> _loadFilteredData() async {
    if (_startDate == null || _endDate == null) return;

    setState(() => _isLoading = true);
    try {
      final data = await _repository.getByDateRange(widget.agentEmail, _startDate!, _endDate!);
      final summary = await _excelService.getDataSummary(widget.agentEmail,
          startDate: _startDate, endDate: _endDate);

      setState(() {
        _data = data;
        _sentData = data.where((record) => record.sent).toList();
        _summary = summary;
        _isLoading = false;
      });

      _logger.logStorage('Loaded ${data.length} filtered records for date range');
    } catch (e) {
      setState(() => _isLoading = false);
      _logger.logStorage('Error loading filtered data: $e', level: LogLevel.error);
    }
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: Platform.isAndroid,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar: AppBar(
            title: Text(
              'Extracted Product Data',
              style: AppTextStyles.black12_700,
            ),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 2,
            actions: [
              IconButton(
                onPressed: _exportToExcel,
                icon: const Icon(Icons.download),
                tooltip: 'Export to Excel',
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: Colors.white,
                child: TabBar(
                  labelColor: Colors.black,
                  indicatorColor: Colors.blue,
                  tabs: const [
                    Tab(text: 'All Records'),
                    Tab(text: 'Sent Forms'),
                  ],
                ),
              ),
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Container(
                  color: Colors.grey.shade100,
                  child: Column(
                    children: [
                      if (_summary.isNotEmpty) _buildSummaryCard(),
                      _buildFilters(),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _data.isEmpty ? _buildEmptyState() : _buildDataList(),
                            _buildSentDataTab(),
                            const SizedBox(
                              height: 20,
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildSummaryItem('Total Records', '${_summary['totalRecords'] ?? 0}'),
                const SizedBox(width: 16),
                _buildSummaryItem('Avg Confidence', '${_summary['averageConfidence'] ?? 0}%'),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Date Range: ${_summary['dateRange'] ?? 'All time'}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final filterLabel = _startDate != null && _endDate != null
        ? 'Filtered: ${DateFormat('MMM dd').format(_startDate!)} - ${DateFormat('MMM dd').format(_endDate!)}'
        : 'Showing all records';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                filterLabel,
                style:
                    Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
              ),
            ),
            TextButton.icon(
              onPressed: _selectDateRange,
              icon: const Icon(Icons.date_range),
              label: const Text('Filter'),
            ),
            if (_startDate != null)
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Clear'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No extracted data found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Product data will appear here as it\'s extracted from chat messages',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDataList() {
    return ListView.builder(
      itemCount: _data.length,
      itemBuilder: (context, index) {
        final item = _data[index];
        final recordKey = _keyForRecord(item);
        final isSent = _sentRecordKeys.contains(recordKey);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        DateFormat('MMM dd, yyyy hh:mm a').format(item.extractedAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                    ),
                    if (isSent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Sent',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getConfidenceColor(item.confidence),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(item.confidence * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showSendToCustomerDialog(item),
                      icon: const Icon(Icons.send),
                      tooltip: 'Send to Customer',
                      color: Colors.blue,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _buildConfidenceBar(item.confidence),
                const SizedBox(height: 6),
                if (item.extractionTimeMs != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Extraction time: ${item.extractionTimeMs}ms',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person, size: 14, color: Colors.blueGrey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Customer: ${item.customerName?.trim().isNotEmpty == true ? item.customerName : item.customerEmail}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (item.customerName != null && item.customerName!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Email: ${item.customerEmail}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey.shade600),
                    ),
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (item.quality != null) _buildDataChip('Quality', item.quality!),
                    if (item.weave != null) _buildDataChip('Weave', item.weave!),
                    if (item.quantity != null) _buildDataChip('Quantity', item.quantity!),
                    if (item.composition != null) _buildDataChip('Composition', item.composition!),
                    if (item.rate != null) _buildDataChip('Rate', '₹${item.rate}'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSentDataTab() {
    if (_sentData.isEmpty) {
      return const Center(child: Text('No sent orders yet.'));
    }
    return ListView.builder(
      itemCount: _sentData.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final item = _sentData[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(
                      'Order ID: ${item.orderId ?? 'N/A'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: item.status?.toLowerCase() == 'confirmed'
                            ? Colors.green
                            : item.status?.toLowerCase() == 'declined'
                                ? Colors.red
                                : Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.status ?? 'Pending',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person, size: 14, color: Colors.blueGrey),
                    const SizedBox(width: 4),
                    Text(
                      item.customerName ?? item.customerEmail,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildDataChip('Quality', item.quality ?? '-'),
                    _buildDataChip('Weave', item.weave ?? '-'),
                    _buildDataChip('Qty', item.quantity ?? '-'),
                    _buildDataChip('Rate', item.rate != null ? '₹${item.rate}' : '-'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showSendToCustomerDialog(ExtractedProductData item) async {
    final Map<String, dynamic>? formData = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: ExtractedProductFormOverlay(
            extractedData: {
              'quality': item.quality,
              'weave': item.weave,
              'quantity': item.quantity,
              'composition': item.composition,
              'rate': item.rate,
              'confidence': item.confidence,
              'extractionTimeMs': item.extractionTimeMs,
            },
            customerName: item.customerName ?? item.customerEmail,
            onSubmit: (formData) {
              Navigator.of(context).pop(formData);
            },
          ),
        );
      },
    );

    if (formData != null) {
      final orderId = formData['orderId']?.toString().trim().isNotEmpty == true
          ? formData['orderId'].toString().trim()
          : 'ORD-${DateTime.now().millisecondsSinceEpoch}';
      formData['orderId'] = orderId;

      final updatePayload = {
        'sent': 1,
        'sent_at': DateTime.now().toIso8601String(),
        'order_id': orderId,
        'status': 'Pending',
      };
      if (item.id != null) {
        await _repository.update(item.id!, updatePayload);
      }

      final updatedItem = item.copyWith(
        sent: true,
        sentAt: DateTime.now(),
        orderId: orderId,
        status: 'Pending',
      );

      final recordKey = _keyForRecord(updatedItem);
      setState(() {
        _sentRecordKeys.add(recordKey);
        final index = _data.indexWhere((e) => e.id == item.id);
        if (index != -1) {
          _data[index] = updatedItem;
        }
        _sentData = _data.where((record) => record.sent).toList();
      });

      if (mounted) {
        Navigator.of(context).pop({
          'success': true,
          'formData': formData,
          'customerEmail': item.customerEmail,
          'extractedAt': item.extractedAt.toIso8601String(),
          'id': item.id,
        });
      }
    }
  }

  Widget _buildDataChip(String label, String value) {
    return Chip(
      label: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: Colors.grey.shade100,
      side: BorderSide(color: Colors.grey.shade300),
    );
  }

  Widget _buildConfidenceBar(double confidence) {
    final normalizedConfidence = confidence.clamp(0.0, 1.0);
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: normalizedConfidence,
              valueColor: AlwaysStoppedAnimation(_getConfidenceColor(confidence)),
              backgroundColor: Colors.grey.shade200,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${(confidence * 100).round()}%',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  String _keyForRecord(ExtractedProductData item) {
    return '${item.chatId}_${item.extractedAt.toIso8601String()}';
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }
}
