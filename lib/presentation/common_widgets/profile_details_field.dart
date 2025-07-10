import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';

class ProfileDetailsField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final List<String>? options;
  final void Function(String?)? onChanged;
  const ProfileDetailsField({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.options,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.grey707070),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 4),
              child: Text(
                label,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
          ],
        ),
        Container(
            width: double.infinity, // or a fixed width if needed
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white, // light background color
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.dividerColor,
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                value,
                style:
                    const TextStyle(fontSize: 16, color: AppColors.greyAAAAAA),
              ),
            )),
        const SizedBox(height: 8), // Spacing between fields
      ],
    );
  }
}
