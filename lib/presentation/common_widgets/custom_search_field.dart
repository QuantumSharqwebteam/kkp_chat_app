import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';

class CustomSearchBar extends StatelessWidget {
  final double? width;
  final bool enable;
  final TextEditingController controller;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted; // Called when user submits the query
  final String hintText;
  const CustomSearchBar(
      {super.key,
      this.width = double.maxFinite,
      required this.enable,
      required this.controller,
      this.onChanged,
      required this.hintText,
      this.onSubmitted});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 3,
            spreadRadius: 0,
            offset: Offset(0, 1),
          ),
        ],
      ),
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
