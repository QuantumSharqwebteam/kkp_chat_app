import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';

class CustomDropDown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const CustomDropDown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 5),
      decoration: BoxDecoration(
          //border: Border.all(color: AppColors.greyE5E7EB),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              spreadRadius: 0,
              blurRadius: 4,
              offset: Offset(0, 1),
              color: Colors.black.withValues(alpha: 0.25),
            )
          ]),
      child: DropdownButton<String>(
        value: value,
        isExpanded: false,
        menuWidth: 160,
        elevation: 5,
        icon: Icon(Icons.keyboard_arrow_down_outlined),
        style: AppTextStyles.black12_400,
        underline: const SizedBox(), // Remove default underline
        items: items.map((item) {
          return DropdownMenuItem(value: item, child: Text(item));
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
