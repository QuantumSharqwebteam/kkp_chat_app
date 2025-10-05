import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kkpchatapp/data/models/complaint_model.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';

class MarketingComplaintCard extends StatefulWidget {
  final ComplaintModel complaint;
  const MarketingComplaintCard({required this.complaint, super.key});

  @override
  State<MarketingComplaintCard> createState() => _MarketingComplaintCardState();
}

class _MarketingComplaintCardState extends State<MarketingComplaintCard> {
  bool toggled = false;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              toggled = !toggled;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Header Row
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor:
                          const Color(0xFFDCFCE7), // Light green background
                      child: Icon(Icons.person,
                          color: Colors.green), // Optional: icon color
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.complaint.subject,
                            style: AppTextStyles.black14_600,
                          ),
                          Text(
                            'Customer: ${widget.complaint.userModel.name}',
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
                          _getFormattedDate(widget.complaint.createdAt),
                          style: AppTextStyles.black12_400
                              .copyWith(color: Colors.black45),
                        ),
                        SizedBox(
                          height: 8,
                        ),
                        // Text(
                        //   _getFormattedTime(inquiry.date),
                        //   style: AppTextStyles.black12_400,
                        // ),
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 1),
                          decoration: BoxDecoration(
                            color: widget.complaint.status == "Confirmed"
                                ? Color(0xFFDCFCE7)
                                : widget.complaint.status == "Declined"
                                    ? AppColors.inActiveRed.withOpacity(0.1)
                                    : AppColors.helperOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.complaint.status,
                            style: AppTextStyles.black12_400.copyWith(
                              color: widget.complaint.status == "Confirmed"
                                  ? const Color.fromARGB(255, 4, 127, 10)
                                  : widget.complaint.status == "Declined"
                                      ? AppColors.inActiveRed
                                      : AppColors.helperOrange,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                  ],
                ),

                if (toggled) ...[
                  const SizedBox(height: 12),
                  _buildInquiryDetails(widget.complaint),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getFormattedDate(DateTime date) {
    return DateFormat('MMMM d, yyyy').format(date); // e.g., "May 21, 2025"
  }
}

Widget _buildInquiryDetails(ComplaintModel complaint) {
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
      _buildDetailRow('Subject', complaint.subject),
      _buildDetailRow('Description', complaint.description),
      _buildDetailRow('Customer Name:', complaint.userModel.name),
      _buildDetailRow('Customer email', complaint.userModel.email),
    ],
  );
}

Widget _buildDetailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
              AppTextStyles.black14_400.copyWith(color: Colors.grey.shade600),
        ),
        Expanded(
          child: Text(value,
              textAlign: TextAlign.right,
              maxLines: 4,
              style: AppTextStyles.black14_600.copyWith(
                  color: Colors.grey.shade700, fontWeight: FontWeight.w100)),
        ),
      ],
    ),
  );
}
