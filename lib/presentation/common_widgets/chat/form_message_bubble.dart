import 'package:flutter/material.dart';
import 'package:kkp_chat_app/config/theme/app_colors.dart';
import 'package:kkp_chat_app/config/theme/app_text_styles.dart';

class FormMessageBubble extends StatelessWidget {
  final Map<String, dynamic> formData;
  final bool isMe;
  final String timestamp;

  const FormMessageBubble({
    super.key,
    required this.formData,
    required this.isMe,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 15, left: 10, right: 40),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.6,
      ),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF00ABE9) : const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
          bottomRight: isMe ? Radius.zero : const Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextRow("S.NO.", formData["sNo"] ?? ""),
          _buildTextRow("Quality", formData["quality"] ?? ""),
          _buildTextRow("Weave", formData["weave"] ?? ""),
          _buildTextRow("Quantity", formData["quantity"]?.toString() ?? ""),
          _buildTextRow("Composition", formData["composition"] ?? ""),
          if (formData.containsKey("rate"))
            _buildTextRow("Rate", formData["rate"]?.toString() ?? ""),
          const SizedBox(height: 8),
          Text(
            timestamp,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTextRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 100, // Adjust label width for proper alignment
            child: Text(
              label,
              style: AppTextStyles.black14_600.copyWith(
                color: isMe ? Colors.white : Colors.black.withValues(alpha: .6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                  color:
                      isMe ? Colors.white : Colors.black.withValues(alpha: .6)),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
