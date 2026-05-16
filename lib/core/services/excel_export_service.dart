import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:kkpchatapp/data/models/extracted_product_data.dart';
import 'package:kkpchatapp/data/repositories/extracted_product_repository.dart';
import 'package:kkpchatapp/core/services/logging_service.dart';

class ExcelExportService {
  final ExtractedProductRepository _repository = ExtractedProductRepository();
  final LoggingService _logger = LoggingService.instance;

  /// Export extracted product data to Excel and share
  Future<void> exportToExcel(
    String agentEmail, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      _logger.logStorage('Starting Excel export for agent: $agentEmail');

      // Fetch data
      List<ExtractedProductData> data;
      if (startDate != null && endDate != null) {
        data = await _repository.getByDateRange(agentEmail, startDate, endDate);
        _logger.logStorage('Fetched ${data.length} records for date range: $startDate to $endDate');
      } else {
        data = await _repository.getByAgent(agentEmail);
        _logger.logStorage('Fetched ${data.length} records for agent: $agentEmail');
      }

      if (data.isEmpty) {
        throw Exception('No data available for export');
      }

      // Create Excel file
      final excel = Excel.createExcel();
      final sheet = excel['Extracted Products'];

      // Add headers with better formatting
      final headers = [
        'Date',
        'Time',
        'Agent Email',
        'Customer Email',
        'Quality',
        'Weave',
        'Quantity',
        'Composition',
        'Rate (₹)',
        'Confidence (%)',
      ];

      // Style headers
      final headerStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );

      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      // Add data rows
      for (int row = 0; row < data.length; row++) {
        final item = data[row];
        final extractedDate = item.extractedAt;

        final rowData = [
          extractedDate.toString().split(' ')[0], // Date only
          extractedDate.toString().split(' ')[1].split('.')[0], // Time only
          item.agentEmail,
          item.customerEmail,
          item.quality ?? 'N/A',
          item.weave ?? 'N/A',
          item.quantity ?? 'N/A',
          item.composition ?? 'N/A',
          item.rate != null ? item.rate.toString() : 'N/A',
          '${(item.confidence * 100).round()}',
        ];

        for (int col = 0; col < rowData.length; col++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1));
          cell.value = TextCellValue(rowData[col]);

          // Apply different styles based on column
          if (col == 9) {
            // Confidence column
            cell.cellStyle = CellStyle(
              horizontalAlign: HorizontalAlign.Center,
            );
          }
        }
      }

      // Auto-size columns (approximate)
      for (int i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 15.0); // Set reasonable column width
      }

      // Save file
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'extracted_products_$timestamp.xlsx';
      final file = File('${directory.path}/$fileName');

      final bytes = excel.encode();
      if (bytes != null) {
        await file.writeAsBytes(bytes);
        _logger.logStorage('Excel file created successfully: ${file.path}');

        // Share the file
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Extracted Product Data Export',
          text: 'Product data extracted from chat conversations (${data.length} records)',
        );

        _logger.logStorage('Excel file shared successfully');
      } else {
        throw Exception('Failed to encode Excel file');
      }
    } catch (e) {
      _logger.logStorage('Error exporting to Excel: $e', level: LogLevel.error);
      rethrow;
    }
  }

  /// Get data summary for preview
  Future<Map<String, dynamic>> getDataSummary(
    String agentEmail, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      List<ExtractedProductData> data;
      if (startDate != null && endDate != null) {
        data = await _repository.getByDateRange(agentEmail, startDate, endDate);
      } else {
        data = await _repository.getByAgent(agentEmail);
      }

      return {
        'totalRecords': data.length,
        'dateRange': startDate != null && endDate != null
            ? '${startDate.toString().split(' ')[0]} to ${endDate.toString().split(' ')[0]}'
            : 'All time',
        'averageConfidence': data.isNotEmpty
            ? (data.map((e) => e.confidence).reduce((a, b) => a + b) / data.length * 100).round()
            : 0,
        'fieldsExtracted': _getFieldStats(data),
      };
    } catch (e) {
      _logger.logStorage('Error getting data summary: $e', level: LogLevel.error);
      return {};
    }
  }

  Map<String, int> _getFieldStats(List<ExtractedProductData> data) {
    final stats = <String, int>{
      'quality': 0,
      'weave': 0,
      'quantity': 0,
      'composition': 0,
      'rate': 0,
    };

    for (final item in data) {
      if (item.quality != null) stats['quality'] = stats['quality']! + 1;
      if (item.weave != null) stats['weave'] = stats['weave']! + 1;
      if (item.quantity != null) stats['quantity'] = stats['quantity']! + 1;
      if (item.composition != null) stats['composition'] = stats['composition']! + 1;
      if (item.rate != null) stats['rate'] = stats['rate']! + 1;
    }

    return stats;
  }
}
