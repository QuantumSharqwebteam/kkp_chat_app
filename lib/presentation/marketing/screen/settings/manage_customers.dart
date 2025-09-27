import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/repositories/auth_repository.dart';
import 'package:kkpchatapp/l10n/generated/app_localizations.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_search_field.dart';
import 'package:kkpchatapp/presentation/marketing/widget/settings/customer_details_dialog.dart';
import 'package:kkpchatapp/presentation/marketing/widget/settings/manage_customer_list_item.dart';

import 'dart:io';
import 'package:excel/excel.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class ManageCustomers extends StatefulWidget {
  const ManageCustomers({super.key});

  @override
  State<ManageCustomers> createState() => _ManageCustomersState();
}

class _ManageCustomersState extends State<ManageCustomers> {
  final _authRepo = AuthRepository();
  List<dynamic> customers = [];
  List<dynamic> filteredCustomers = [];
  bool isLoading = true;
  bool isCustomerDownloading = false;

  final _customerSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _customerSearchController.addListener(_applyCustomerSearch); // ✅
    fetchCustomers();
  }

  Future<void> fetchCustomers() async {
    final role = await LocalDbHelper.getUserType();
    final email = LocalDbHelper.getEmail();
    List<dynamic> fetchedCustomers;
    try {
      if (role == "2") {
        fetchedCustomers = await _authRepo.fetchUsersByAgentId(email!);
      } else {
        fetchedCustomers = await _authRepo.fetchUsersByRole('User');
      }
      setState(() {
        customers = fetchedCustomers;
        filteredCustomers = customers;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint('Error fetching customers: $e');
    }
  }

  void _applyCustomerSearch() {
    final query = _customerSearchController.text.toLowerCase();
    setState(() {
      filteredCustomers = customers.where((customer) {
        final name = (customer['name'] ?? '').toLowerCase();
        final email = (customer['email'] ?? '').toLowerCase();
        return name.contains(query) || email.contains(query);
      }).toList();
    });
  }

  Future<void> downloadCustomerDetailsAsExcel() async {
    setState(() => isCustomerDownloading = true);
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];

      // Define bold & larger style
      final headerStyle = CellStyle(
        bold: true,
        fontSize: 11,
      );

      // Set header cells with style
      final headers = [
        'Name',
        'Email',
        'Phone',
        'GSTNo',
        'PanNo',
        'Customer Type'
      ];
      for (int i = 0; i < headers.length; i++) {
        final cell =
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      // Fill customer data
      for (int i = 0; i < filteredCustomers.length; i++) {
        final customer = filteredCustomers[i];
        sheet.appendRow([
          TextCellValue(customer['name'] ?? ''),
          TextCellValue(customer['email'] ?? ''),
          TextCellValue(customer['mobile'] != null
              ? customer['mobile'].toString()
              : 'N/A'),
          TextCellValue(customer['GSTno'] ?? ''),
          TextCellValue(customer['PANno'] ?? ''),
          TextCellValue(customer['customerType'] ?? ""),
        ]);
      }

      // Adjust column widths
      sheet.setColumnWidth(1, 40); // Email
      sheet.setColumnWidth(3, 30); // GSTNo
      sheet.setColumnWidth(4, 30); // PanNo

      final bytes = excel.save();
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/customers_${DateTime.now().millisecondsSinceEpoch}.xlsx');
      await file.writeAsBytes(bytes!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Excel file saved: ${file.path}')),
        );
      }

      await OpenFile.open(file.path);
    } catch (e) {
      debugPrint('Error exporting customers: $e');
    } finally {
      setState(() => isCustomerDownloading = false);
    }
  }

  void showCustomerDetails(Map<String, dynamic> customer) {
    showDialog(
      context: context,
      builder: (context) {
        return CustomerDetailsDialog(customer: customer);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(locale.manage, style: AppTextStyles.black16_500),
        backgroundColor: Colors.white,
        bottom: isLoading
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(65),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomSearchBar(
                          controller: _customerSearchController,
                          hintText: locale.searchCustomer,
                          onChanged: (_) => _applyCustomerSearch(),
                          enable: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: isCustomerDownloading
                            ? null
                            : downloadCustomerDetailsAsExcel,
                        child: isCustomerDownloading
                            ? const SizedBox(
                                width: 30,
                                height: 30,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.download),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
      body: buildCustomerList(), // ✅ No more tabs
    );
  }

  Widget buildCustomerList() {
    final locale = AppLocalizations.of(context)!;
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filteredCustomers.isEmpty) {
      return Center(
        child: Text(
          locale.noCustomersAvailable,
          style: AppTextStyles.grey12_600.copyWith(fontSize: 16),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(10),
      itemCount: filteredCustomers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final customer = filteredCustomers[index];
        return ManageCustomerListItem(
          customer: customer,
          onMoreDetails: () => showCustomerDetails(customer),
        );
      },
    );
  }

  @override
  void dispose() {
    _customerSearchController.dispose();
    super.dispose();
  }
}
