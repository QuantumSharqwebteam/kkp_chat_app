import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';

class ProfileDetailsField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const ProfileDetailsField(
      {super.key,
      required this.icon,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 4),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Row(
          children: [
            Icon(icon, color: AppColors.grey707070),
            const SizedBox(width: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 16, color: AppColors.greyAAAAAA),
            ),
          ],
        ),
        const Divider(thickness: 1, color: AppColors.greyD9D9D9),
        const SizedBox(height: 8), // Spacing between fields
      ],
    );
  }
}
