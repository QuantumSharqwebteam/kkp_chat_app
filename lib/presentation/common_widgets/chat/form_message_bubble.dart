import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/repositories/chat_reopsitory.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_textfield.dart';

class FormMessageBubble extends StatefulWidget {
  final List<Map<String, dynamic>> forms;
  final bool isMe;
  final String timestamp;
  final String userRole;
  final int? serialNumber;
  final Function(Map<String, dynamic>)? onRateUpdated;
  final Function(String, String)? onStatusUpdated;
  final VoidCallback? onFormUpdateStart;
  final VoidCallback? onFormUpdateEnd;
  final Function(Map<String, dynamic>)? onFormUpdated;
  final Function(Map<String, dynamic>)? onFormEditRequested;
  final bool? read;

  FormMessageBubble({
    super.key,
    required this.forms,
    required this.isMe,
    required this.timestamp,
    required this.userRole,
    this.serialNumber,
    this.read = false,
    this.onRateUpdated,
    this.onStatusUpdated,
    this.onFormUpdateStart,
    this.onFormUpdateEnd,
    this.onFormUpdated,
    this.onFormEditRequested,
  }) : assert(forms.isNotEmpty, 'At least one form entry is required');

  @override
  State<FormMessageBubble> createState() => _FormMessageBubbleState();
}

class _FormMessageBubbleState extends State<FormMessageBubble> {
  final chatRepository = ChatRepository();
  late final PageController _pageController;
  int _currentPage = 0;

  Map<String, dynamic> get _activeForm => widget.forms[_currentPage];

  bool get _isPrivilegedUser =>
      widget.userRole == '2' || widget.userRole == '3';
  bool get _showAllOptions =>
      _activeForm['_formOptionsUnlocked'] == true || _normalizedRate() > 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  num _normalizedRate() {
    final dynamic rateValue = _activeForm['rate'];
    if (rateValue is num) return rateValue;
    if (rateValue is String) return num.tryParse(rateValue.trim()) ?? 0;
    return 0;
  }

  void _goToPage(int delta) {
    final target = (_currentPage + delta).clamp(0, widget.forms.length - 1);
    if (target == _currentPage) return;
    _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _updateFormStatus(BuildContext context, String status,
      {String? reason}) async {
    if (widget.onFormUpdateStart != null) {
      widget.onFormUpdateStart!();
    }

    final id = _activeForm['_id']?.toString();
    if (id == null || id.isEmpty) {
      debugPrint(
          'Form id required : $id in the form data: ${_activeForm.toString()} ');
    }
    try {
      await chatRepository.updateInquiryFormStatus(id!, status, reason: reason);
      if (context.mounted) {
        Utils().showSuccessDialog(context, 'Status updated to $status', true);
        await Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted) {
            Navigator.pop(context);
          }
        });
      }
      if (widget.onStatusUpdated != null) {
        final formId = _activeForm['_id'] ?? '';
        widget.onStatusUpdated!(status, formId.toString());
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating form data status: $e');
      }
    } finally {
      if (widget.onFormUpdateEnd != null) {
        widget.onFormUpdateEnd!();
      }
    }
  }

  void _handleMenuSelection(
      BuildContext context, String value, Map<String, dynamic> formData) {
    if (value == 'confirm') {
      _updateFormStatus(context, 'Confirmed');
    } else if (value == 'decline') {
      _promptDecline(context);
    } else if (value == 'update_form') {
      _showFormEditSheet(formData);
    }
  }

  Future<void> _promptDecline(BuildContext context) async {
    final controller = TextEditingController();
    String? errorText;

    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Reason for decline'),
              content: CustomTextField(
                controller: controller,
                hintText: 'Reason for declining',
                minLines: 3,
                maxLines: 4,
                errorText: errorText,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final value = controller.text.trim();
                    if (value.isEmpty) {
                      setDialogState(() {
                        errorText = 'Reason is required';
                      });
                      return;
                    }
                    Navigator.of(dialogContext).pop(value);
                  },
                  child: const Text('Decline'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
    if (!mounted || !context.mounted || reason == null || reason.isEmpty) {
      return;
    }
    await _updateFormStatus(context, 'Declined', reason: reason);
  }

  void _showFormEditSheet(Map<String, dynamic> formData) {
    widget.onFormEditRequested?.call(formData);
  }

  String _menuLabel(String choice) {
    switch (choice) {
      case 'confirm':
        return 'Confirm';
      case 'decline':
        return 'Decline';
      case 'update_form':
        return 'Update form';
      default:
        return choice;
    }
  }

  Widget _buildPager() {
    if (widget.forms.length <= 1) return const SizedBox.shrink();
    final currentSno = _activeForm['s_no']?.toString() ?? '${_currentPage + 1}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            iconSize: 18,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            onPressed: () => _goToPage(-1),
            icon: const Icon(Icons.arrow_back_ios),
          ),
          Text(
            'S.No $currentSno · ${_currentPage + 1}/${widget.forms.length}',
            style: TextStyle(
              color: widget.isMe ? Colors.white70 : Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            iconSize: 18,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            onPressed: () => _goToPage(1),
            icon: const Icon(Icons.arrow_forward_ios),
          ),
        ],
      ),
    );
  }

  Widget _buildFormPage(Map<String, dynamic> formData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (formData.containsKey('_id'))
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
                  text: formData['_id'],
                  style: AppTextStyles.grey12_600.copyWith(
                    color: widget.isMe ? Colors.white : null,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 15),
        _buildTextRow('BuyerName', formData['buyerName'] ?? ''),
        _buildTextRow('Quality', formData['quality'] ?? ''),
        _buildTextRow('Weave', formData['weave'] ?? ''),
        _buildTextRow('Quantity', formData['quantity']?.toString() ?? ''),
        _buildTextRow('Composition', formData['composition'] ?? ''),
      ],
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

  @override
  Widget build(BuildContext context) {
    final formId = _activeForm['_id']?.toString();
    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 20, bottom: 4, left: 10, right: 40),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.65,
        ),
        decoration: BoxDecoration(
          color:
              widget.isMe ? const Color(0xFF00ABE9) : const Color(0xFFF2F2F2),
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
            if (_isPrivilegedUser && formId != null)
              Align(
                alignment: Alignment.topRight,
                child: PopupMenuButton<String>(
                  onSelected: (value) =>
                      _handleMenuSelection(context, value, _activeForm),
                  itemBuilder: (BuildContext context) {
                    final List<String> options = [];
                    if (_showAllOptions) {
                      options.addAll(['confirm', 'decline']);
                    }
                    options.add('update_form');
                    return options.map((String choice) {
                      return PopupMenuItem<String>(
                        value: choice,
                        child: Text(
                          _menuLabel(choice),
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
                  color: widget.isMe
                      ? Colors.white.withOpacity(0.22)
                      : Colors.black.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Form #${widget.serialNumber}',
                  style: AppTextStyles.black10_500.copyWith(
                    color: widget.isMe ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            _buildPager(),
            LayoutBuilder(
              builder: (context, constraints) {
                final double screenMaxHeight =
                    MediaQuery.of(context).size.height * 0.35;
                final double availableMax = constraints.maxHeight.isFinite
                    ? constraints.maxHeight
                    : screenMaxHeight;
                final double height = math.min(screenMaxHeight, availableMax);
                return SizedBox(
                  height: height,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.forms.length,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return SingleChildScrollView(
                        child: _buildFormPage(widget.forms[index]),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.timestamp,
                    style: widget.isMe
                        ? AppTextStyles.white8_600.copyWith(fontSize: 10)
                        : AppTextStyles.greyAAAAAA_10_400,
                  ),
                  if (widget.isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      (widget.read ?? false) ? Icons.done_all : Icons.done,
                      color: (widget.read ?? false) ? Colors.blue : Colors.grey,
                      size: 14,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
