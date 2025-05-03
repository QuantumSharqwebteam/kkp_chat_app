import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';

import 'package:flutter/material.dart';
import 'package:kkpchatapp/data/repositories/chat_reopsitory.dart';
// Adjust the import according to your project structure

class FormMessageBubble extends StatefulWidget {
  final Map<String, dynamic> formData;
  final bool isMe;
  final String timestamp;
  final String userRole;

  const FormMessageBubble({
    super.key,
    required this.formData,
    required this.isMe,
    required this.timestamp,
    required this.userRole,
  });

  @override
  State<FormMessageBubble> createState() => _FormMessageBubbleState();
}

class _FormMessageBubbleState extends State<FormMessageBubble> {
  final chatRepository = ChatRepository();

  Future<void> _updateFormRate(BuildContext context, String rate) async {
    final id = widget.formData['id']?.toString();
    if (id == null || id.isEmpty) {
      print('Missing _id in formData: ${widget.formData}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Form ID is missing or invalid')),
      );
      return;
    }

    try {
      await chatRepository.updateInquiryFormRate(id, rate);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rate updated successfully')),
      );
    } catch (e) {
      print('Error updating rate: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update rate: $e')),
      );
    }
  }

  Future<void> _updateFormStatus(BuildContext context, String status) async {
    final id = widget.formData['id']?.toString();
    if (id == null || id.isEmpty) {
      print('Missing _id in formData: ${widget.formData}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Form ID is missing or invalid')),
      );
      return;
    }

    try {
      await chatRepository.updateInquiryFormStatus(id, status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to $status')),
      );
    } catch (e) {
      print('Error updating status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
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
    TextEditingController rateController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Rate'),
          content: TextField(
            controller: rateController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Enter Rate'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Update'),
              onPressed: () async {
                String rate = rateController.text;
                await _updateFormRate(context, rate);
                Navigator.of(context).pop();
              },
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
