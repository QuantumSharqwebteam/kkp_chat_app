import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
//import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/repositories/chat_reopsitory.dart';
// import 'package:kkpchatapp/presentation/common_widgets/custom_button.dart';
// import 'package:kkpchatapp/presentation/common_widgets/custom_textfield.dart';

class FormMessageBubble extends StatefulWidget {
  final Map<String, dynamic> formData;
  final bool isMe;
  final String timestamp;
  final String userRole;
  final int? serialNumber;
  final Function(Map<String, dynamic>)? onRateUpdated;
  final Function(String, String)? onStatusUpdated;
  final VoidCallback? onFormUpdateStart; // Callback to start the loading indicator
  final VoidCallback? onFormUpdateEnd; // Callback to end the loading indicator
  final Function(Map<String, dynamic>)? onAskForRateUpdate;

  const FormMessageBubble({
    super.key,
    required this.formData,
    required this.isMe,
    required this.timestamp,
    required this.userRole,
    this.serialNumber,
    this.onRateUpdated,
    this.onStatusUpdated,
    this.onFormUpdateStart,
    this.onFormUpdateEnd,
    this.onAskForRateUpdate,
  });

  @override
  State<FormMessageBubble> createState() => _FormMessageBubbleState();
}

class _FormMessageBubbleState extends State<FormMessageBubble> {
  final chatRepository = ChatRepository();
  final rateController = TextEditingController();

  num _normalizedRate() {
    final dynamic rateValue = widget.formData["rate"];
    if (rateValue is num) return rateValue;
    if (rateValue is String) return num.tryParse(rateValue.trim()) ?? 0;
    return 0;
  }

  bool get _isPrivilegedUser => widget.userRole == "2" || widget.userRole == "3";
  bool get _showAllOptions =>
      widget.formData['_formOptionsUnlocked'] == true || _normalizedRate() > 0;

  Future<void> _updateFormStatus(BuildContext context, String status) async {
    if (widget.onFormUpdateStart != null) {
      widget.onFormUpdateStart!(); // Notify the parent to start the loading indicator
    }

    final formData = widget.formData;
    final id = widget.formData['_id']?.toString();
    if (id == null) {
      debugPrint("Form id required : $id in the form data: ${formData.toString()} ");
    }
    try {
      await chatRepository.updateInquiryFormStatus(id!, status);
      if (context.mounted) {
        Utils().showSuccessDialog(context, "Status updated to $status", true);
        await Future.delayed(Duration(seconds: 2), () {
          if (context.mounted) {
            Navigator.pop(context);
          }
        });
      }
      // Call the callback function with the status and S.No
      if (widget.onStatusUpdated != null) {
        final formId = widget.formData["_id"] ?? "";
        widget.onStatusUpdated!(status, formId);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating form data status: $e');
      }
    } finally {
      if (widget.onFormUpdateEnd != null) {
        widget.onFormUpdateEnd!(); // Notify the parent to end the loading indicator
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formData = widget.formData;
    final id = widget.formData['_id']?.toString();
    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 20, bottom: 4, left: 10, right: 40),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.65,
        ),
        decoration: BoxDecoration(
          color: widget.isMe ? const Color(0xFF00ABE9) : const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: widget.isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: widget.isMe ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isPrivilegedUser && id != null)
              Align(
                alignment: Alignment.topRight,
                child: PopupMenuButton<String>(
                  onSelected: (value) {
                    _handleMenuSelection(context, value);
                  },
                  itemBuilder: (BuildContext context) {
                    final List<String> options = _showAllOptions
                        ? ['Ask for rate update', 'confirm', 'decline']
                        : ['Ask for rate update'];
                    return options.map((String choice) {
                      return PopupMenuItem<String>(
                        value: choice,
                        child: Text(
                          choice == 'Ask for rate update'
                              ? 'Ask for rate update'
                              : choice == 'confirm'
                                  ? 'Confirm'
                                  : 'Decline',
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            if (widget.serialNumber != null)
              Container(
                margin: const EdgeInsets.only(bottom: 5),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      widget.isMe ? Colors.white.withOpacity(0.22) : Colors.black.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Form #${widget.serialNumber}",
                  style: AppTextStyles.black10_500.copyWith(
                    color: widget.isMe ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            if (widget.formData.containsKey("_id"))
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Id:  ',
                      style: AppTextStyles.black14_600.copyWith(
                        color: widget.isMe ? Colors.white : null,
                      ),
                    ),
                    TextSpan(
                      text: widget.formData["_id"],
                      style: AppTextStyles.grey12_600.copyWith(
                        color: widget.isMe ? Colors.white : null,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 15),
            _buildTextRow("BuyerName", widget.formData["buyerName"] ?? ""),
            _buildTextRow("Quality", widget.formData["quality"] ?? ""),
            _buildTextRow("Weave", widget.formData["weave"] ?? ""),
            _buildTextRow("Quantity", widget.formData["quantity"]?.toString() ?? ""),
            _buildTextRow("Composition", widget.formData["composition"] ?? ""),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Text(
                widget.timestamp,
                style: widget.isMe
                    ? AppTextStyles.white8_600.copyWith(fontSize: 10)
                    : AppTextStyles.greyAAAAAA_10_400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuSelection(BuildContext context, String value) {
    final formData = widget.formData;
    if (value == 'Ask for rate update') {
      widget.onAskForRateUpdate?.call(formData);
    } else if (value == 'confirm') {
      _updateFormStatus(context, 'Confirmed');
    } else if (value == 'decline') {
      _updateFormStatus(context, 'Declined');
    }
  }

  Widget _buildTextRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTextStyles.black14_600.copyWith(
                color: widget.isMe ? Colors.white : Colors.black.withOpacity(0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: widget.isMe ? Colors.white : Colors.black.withOpacity(0.6),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
