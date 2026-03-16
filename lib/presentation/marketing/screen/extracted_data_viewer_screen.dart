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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Extracted Product Data',
          style: AppTextStyles.black12_700,
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            onPressed: _exportToExcel,
            icon: const Icon(Icons.download),
            tooltip: 'Export to Excel',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary Card
                if (_summary.isNotEmpty) _buildSummaryCard(),

                // Filters
                _buildFilters(),

                // Data List
                Expanded(
                  child: _data.isEmpty ? _buildEmptyState() : _buildDataList(),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildSummaryItem('Total Records', '${_summary['totalRecords'] ?? 0}'),
                const SizedBox(width: 16),
                _buildSummaryItem('Avg Confidence', '${_summary['averageConfidence'] ?? 0}%'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Date Range: ${_summary['dateRange'] ?? 'All time'}',
              style: Theme.of(context).textTheme.bodyMedium,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _startDate != null && _endDate != null
                  ? 'Filtered: ${DateFormat('MMM dd').format(_startDate!)} - ${DateFormat('MMM dd').format(_endDate!)}'
                  : 'All Records',
              style: Theme.of(context).textTheme.bodyMedium,
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
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        DateFormat('MMM dd, yyyy HH:mm').format(item.extractedAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                    ),
                    if (isSent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Sent',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _showSendToCustomerDialog(item),
                          icon: const Icon(Icons.send),
                          tooltip: 'Send to Customer',
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
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
                  Text(
                    'Email: ${item.customerEmail}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                  ),
                const SizedBox(height: 4),
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
      final recordKey = _keyForRecord(item);
      setState(() {
        _sentRecordKeys.add(recordKey);
      });
      Navigator.of(context).pop({
        'success': true,
        'formData': formData,
        'customerEmail': item.customerEmail,
        'extractedAt': item.extractedAt.toIso8601String(),
      });
    }
  }

  Widget _buildDataChip(String label, String value) {
    return Chip(
      label: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: Colors.blue.shade50,
      side: BorderSide(color: Colors.blue.shade200),
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
