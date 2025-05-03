import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';

class CustomerDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> customer;

  const CustomerDetailsDialog({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shadowColor: AppColors.shadowColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      title: Text(
        'Customer Details',
        style: AppTextStyles.black16_700,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Name', customer['name']),
          _buildDetailRow('Email', customer['email']),
          _buildDetailRow('Role', customer['role']),
          _buildDetailRow(
              'Mobile',
              customer['mobile'] != null
                  ? customer['mobile'].toString()
                  : 'N/A'),
          _buildDetailRow('GST No', customer['GSTno'] ?? 'N/A'),
          _buildDetailRow('PAN No', customer['PANno'] ?? 'N/A'),
          _buildDetailRow('Customer Type', customer['customerType'] ?? 'N/A'),
          // Add more fields as needed
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            'Close',
            style:
                AppTextStyles.black16_600.copyWith(color: AppColors.blue0056FB),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: AppTextStyles.black14_600,
          ),
          SizedBox(width: 10), // Add some space between label and value
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.grey12_600,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
