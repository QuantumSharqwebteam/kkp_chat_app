import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';

class CustomSearchBar extends StatelessWidget {
  final double width;
  final bool enable;
  final TextEditingController controller;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted; // Called when user submits the query
  final String hintText;
  const CustomSearchBar(
      {super.key,
      required this.width,
      required this.enable,
      required this.controller,
      this.onChanged,
      required this.hintText,
      this.onSubmitted});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: width,
      child: TextFormField(
        controller: controller,
        onChanged: onChanged, // Calls search function dynamically
        onFieldSubmitted:
            onSubmitted, // Handles submission (e.g., pressing "Enter")
        enabled: enable,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.only(top: 20, left: 20),
          fillColor: Colors.white,
          filled: true,
          hintText: hintText,
          hintStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600),
          prefixIcon: Icon(Icons.search_rounded,
              color: AppColors.foregroundMutedGrey, size: 25),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(width: 1, color: Colors.white),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(width: 1, color: Colors.white),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(width: 1, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
