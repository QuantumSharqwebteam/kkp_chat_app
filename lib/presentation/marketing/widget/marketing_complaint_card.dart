import 'package:flutter/material.dart';
import 'package:kkpchatapp/data/models/complaint_model.dart';

import '../../../config/theme/app_colors.dart';

class MarketingComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;
  const MarketingComplaintCard({required this.complaint, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.grey, blurRadius: 5, offset: Offset(2.5, 2.5))
          ],
          borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Complaint Details',
            style: TextStyle(
                color: AppColors.black2E2E2E,
                fontWeight: FontWeight.w500,
                fontSize: 14),
          ),
          const SizedBox(height: 5),
          headAndContent('Complaint ID', complaint.id),
          headAndContent('Status', complaint.status),
          headAndContent('Subject', complaint.subject),
          headAndContent('Description', complaint.description),
          const SizedBox(height: 8),
          Text(
            'User Details',
            style: TextStyle(
                color: AppColors.black2E2E2E,
                fontWeight: FontWeight.w500,
                fontSize: 14),
          ),
          const SizedBox(height: 5),
          headAndContent('User ID', complaint.userModel.id),
          headAndContent('Name', complaint.userModel.name),
          headAndContent('Email', complaint.userModel.email)
        ],
      ),
    );
  }
}

Widget headAndContent(String heading, String content) {
  return RichText(
    text: TextSpan(children: [
      TextSpan(
        text: '$heading: ',
        style: TextStyle(
            color: AppColors.grey7B7B7B,
            fontWeight: FontWeight.w500,
            fontSize: 12),
      ),
      TextSpan(
          text: content,
          style: TextStyle(
              color: AppColors.black2E2E2E,
              fontWeight: FontWeight.w500,
              fontSize: 12)),
    ]),
  );
}
