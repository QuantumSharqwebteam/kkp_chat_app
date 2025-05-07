import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/repositories/chat_reopsitory.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_button.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_textfield.dart';

class FormMessageBubble extends StatefulWidget {
  final Map<String, dynamic> formData;
  final bool isMe;
  final String timestamp;
  final String userRole;
  final Function(Map<String, dynamic>)? onRateUpdated;
  final Function(String, String)? onStatusUpdated;
  final VoidCallback?
      onFormUpdateStart; // Callback to start the loading indicator
  final VoidCallback? onFormUpdateEnd; // Callback to end the loading indicator

  const FormMessageBubble({
    super.key,
    required this.formData,
    required this.isMe,
    required this.timestamp,
    required this.userRole,
    this.onRateUpdated,
    this.onStatusUpdated,
    this.onFormUpdateStart,
    this.onFormUpdateEnd,
  });

  @override
  State<FormMessageBubble> createState() => _FormMessageBubbleState();
}

class _FormMessageBubbleState extends State<FormMessageBubble> {
  final chatRepository = ChatRepository();
  final rateController = TextEditingController();

  Future<void> _updateFormRate(BuildContext context) async {
    if (widget.onFormUpdateStart != null) {
      widget
          .onFormUpdateStart!(); // Notify the parent to start the loading indicator
    }

    final formData = widget.formData;
    final id = widget.formData['_id']?.toString();
    final rate = rateController.text;
    if (id == null) {
      debugPrint(
          "No form id is found to update  : $id in the ${formData.toString()} ");
    }
    try {
      await chatRepository.updateInquiryFormRate(id!, rate);
      if (context.mounted) {
        Utils().showSuccessDialog(context, "Rate is updated :$rate", true);
        await Future.delayed(Duration(seconds: 2), () {
          if (context.mounted) {
            Navigator.pop(context);
          }
        });
        if (context.mounted) {
          Navigator.pop(context);
        }
      }
      // Call the callback function with the updated form data
      if (widget.onRateUpdated != null) {
        final updatedFormData = Map<String, dynamic>.from(widget.formData);
        updatedFormData['rate'] = rate;
        widget.onRateUpdated!(updatedFormData);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating rate of the form : $e');
      }
      if (context.mounted) {
        Utils().showSuccessDialog(
            context, "Cannot Update , send new form!", false);
      }
    } finally {
      if (widget.onFormUpdateEnd != null) {
        widget
            .onFormUpdateEnd!(); // Notify the parent to end the loading indicator
      }
    }
  }

  Future<void> _updateFormStatus(BuildContext context, String status) async {
    if (widget.onFormUpdateStart != null) {
      widget
          .onFormUpdateStart!(); // Notify the parent to start the loading indicator
    }

    final formData = widget.formData;
    final id = widget.formData['_id']?.toString();
    if (id == null) {
      debugPrint(
          "Form id required : $id in the form data: ${formData.toString()} ");
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
        final sNo = widget.formData["S.No"] ?? "";
        widget.onStatusUpdated!(status, sNo);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating form data status: $e');
      }
    } finally {
      if (widget.onFormUpdateEnd != null) {
        widget
            .onFormUpdateEnd!(); // Notify the parent to end the loading indicator
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          margin:
              const EdgeInsets.only(top: 20, bottom: 4, left: 10, right: 40),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.6,
          ),
          decoration: BoxDecoration(
            color:
                widget.isMe ? const Color(0xFF00ABE9) : const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: widget.isMe ? const Radius.circular(16) : Radius.zero,
              bottomRight:
                  widget.isMe ? Radius.zero : const Radius.circular(16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: PopupMenuButton<String>(
                  onSelected: (value) {
                    _handleMenuSelection(context, value);
                  },
                  itemBuilder: (BuildContext context) {
                    List<String> options = ['update_rate'];
                    if (widget.userRole == "2" || widget.userRole == "3") {
                      options.addAll(['confirm', 'decline']);
                    }
                    return options.map((String choice) {
                      return PopupMenuItem<String>(
                        value: choice,
                        child: Text(
                          choice == 'update_rate'
                              ? 'Update Rate'
                              : choice == 'confirm'
                                  ? 'Confirm'
                                  : 'Decline',
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              _buildTextRow("S.No", widget.formData["S.No"] ?? ""),
              _buildTextRow("Quality", widget.formData["quality"] ?? ""),
              _buildTextRow("Weave", widget.formData["weave"] ?? ""),
              _buildTextRow(
                  "Quantity", widget.formData["quantity"]?.toString() ?? ""),
              _buildTextRow(
                  "Composition", widget.formData["composition"] ?? ""),
              if (widget.formData.containsKey("rate"))
                _buildTextRow(
                    "Rate", widget.formData["rate"]?.toString() ?? ""),
              const SizedBox(height: 8),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Text(
            widget.timestamp,
            style: AppTextStyles.greyAAAAAA_10_400,
          ),
        ),
      ],
    );
  }

  void _handleMenuSelection(BuildContext context, String value) {
    if (value == 'update_rate') {
      _showRateDialog(context);
    } else if (value == 'confirm') {
      _updateFormStatus(context, 'Confirmed');
    } else if (value == 'decline') {
      _updateFormStatus(context, 'Declined');
    }
  }

  void _showRateDialog(BuildContext context) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 10,
          title: Text(
            'Update Rate',
            style: AppTextStyles.black14_600,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: rateController,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: <Widget>[
            CustomButton(
              text: 'Cancel',
              backgroundColor: Colors.white,
              width: 90,
              fontSize: 11,
              textColor: AppColors.blue0056FB,
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            CustomButton(
              onPressed: () => _updateFormRate(context),
              text: 'Update',
              fontSize: 12,
              width: 100,
            ),
          ],
        );
      },
    );
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
                color:
                    widget.isMe ? Colors.white : Colors.black.withOpacity(0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color:
                    widget.isMe ? Colors.white : Colors.black.withOpacity(0.6),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
