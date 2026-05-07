// ignore_for_file: use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/utils/chat_utils.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/models/meet_model.dart';
import 'package:kkpchatapp/logic/meeting/meet_management.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_button.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_textfield.dart';
import 'package:kkpchatapp/presentation/common_widgets/required_field_label.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class MeetingTile extends StatelessWidget {
  final MeetingModel meeting;
  final bool showButtons;

  const MeetingTile({
    super.key,
    required this.meeting,
    required this.showButtons,
  });

  bool _isValidFutureMeetingTime(DateTime selectedDateTime) {
    return selectedDateTime.isAfter(DateTime.now());
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      if (kDebugMode) {
        print('Could not launch $url');
      }
    }
  }

  Future<void> _confirmAndDelete(
    BuildContext context,
    MeetingManagement meetingManagement,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Meeting"),
        content: const Text("Are you sure you want to delete this meeting?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await meetingManagement.deleteMeeting(meeting.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final meetingManagement = Provider.of<MeetingManagement>(context, listen: false);
    final statusColor = _statusColor(meeting.status);

    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left accent bar
              Container(width: 4, color: statusColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row: icon + title + time + menu
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 44,
                            width: 44,
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.event_available_rounded,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  meeting.title,
                                  style: AppTextStyles.black16_700
                                      .copyWith(color: AppColors.grey5C5C5C),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 5),
                                // Date row
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: 12,
                                      color: AppColors.grey707070,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDate(meeting.startTime),
                                      style: AppTextStyles.grey12_600
                                          .copyWith(fontSize: 12),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                // Time row
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      size: 12,
                                      color: AppColors.grey707070,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatTime(meeting.startTime),
                                      style: AppTextStyles.grey12_600.copyWith(
                                        fontSize: 12,
                                        color: statusColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (showButtons)
                            PopupMenuButton<String>(
                              surfaceTintColor: Colors.white,
                              tooltip: "Meeting actions",
                              icon: const Icon(Icons.more_vert),
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  _showUpdateDialog(context, meetingManagement, meeting);
                                } else if (value == 'delete') {
                                  await _confirmAndDelete(context, meetingManagement);
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem<String>(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined, size: 18),
                                      SizedBox(width: 8),
                                      Text('Edit Meeting'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline,
                                          size: 18, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete Meeting'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Status chip
                      _buildStatusChip(meeting.status),
                      const SizedBox(height: 12),
                      // Details section
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.greyE5E7EB.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            _detailRow(
                              icon: Icons.location_on_outlined,
                              label: "Platform",
                              value: meeting.location,
                            ),
                            const SizedBox(height: 8),
                            _detailRow(
                              icon: Icons.person_outline,
                              label: "Scheduled by",
                              value: meeting.scheduledPerson.name,
                            ),
                            const SizedBox(height: 8),
                            _detailRow(
                              icon: Icons.link_rounded,
                              label: "Meeting Link",
                              value: meeting.link,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Open link button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _launchUrl(meeting.link),
                          icon: const Icon(
                            Icons.open_in_new_rounded,
                            size: 18,
                            color: AppColors.blue,
                          ),
                          label: Text(
                            "Open Meeting Link",
                            style: AppTextStyles.black12_700.copyWith(
                              color: AppColors.blue,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: AppColors.blue.withOpacity(0.35),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    final s = status.trim().toLowerCase();
    if (s == 'cancelled') return AppColors.errorRed;
    if (s == 'completed') return AppColors.activeGreen;
    return Colors.amber.shade700;
  }

  Widget _buildStatusChip(String status) {
    final normalizedStatus = status.trim().toLowerCase();
    final displayStatus = normalizedStatus.isEmpty
        ? "Unknown"
        : "${normalizedStatus[0].toUpperCase()}${normalizedStatus.substring(1)}";
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            displayStatus,
            style: AppTextStyles.black12_700.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.grey707070),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              text: "$label: ",
              style: AppTextStyles.black12_700.copyWith(
                color: AppColors.grey474747,
              ),
              children: [
                TextSpan(
                  text: value,
                  style: AppTextStyles.black12_400.copyWith(
                    color: AppColors.grey5C5C5C,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Returns just the date part, e.g. "Today" / "Yesterday" / "07/05/2026"
  String _formatDate(String isoDateTime) {
    final dateTime = DateTime.parse(isoDateTime).toLocal();
    return ChatUtils().formatDateHeader(dateTime);
  }

  /// Returns just the time part, e.g. "09:30 PM"
  String _formatTime(String isoDateTime) {
    return ChatUtils().formatTimestamp(isoDateTime);
  }

  /// Returns "Today at 09:30 PM" — used for the edit dialog text field
  String _formatDateTime(String isoDateTime) {
    return "${_formatDate(isoDateTime)} at ${_formatTime(isoDateTime)}";
  }

  Future<void> _showUpdateDialog(
    BuildContext context,
    MeetingManagement meetingManagement,
    MeetingModel meeting,
  ) async {
    final titleController = TextEditingController(text: meeting.title);
    final locationController = TextEditingController(text: meeting.location);
    final linkController = TextEditingController(text: meeting.link);
    final startTimeController =
        TextEditingController(text: _formatDateTime(meeting.startTime));
    String status = meeting.status;
    DateTime? updatedTime;
    String? titleError;
    String? locationError;
    String? linkError;
    String? startTimeError;

    Future<void> selectDateTime(BuildContext ctx, StateSetter setState) async {
      final now = DateTime.now();
      final initialMeetingTime = DateTime.parse(meeting.startTime).toLocal();
      final DateTime? pickedDate = await showDatePicker(
        context: ctx,
        initialDate: initialMeetingTime.isAfter(now) ? initialMeetingTime : now,
        firstDate: DateTime(now.year, now.month, now.day),
        lastDate: DateTime(2100),
      );

      if (pickedDate != null) {
        final TimeOfDay? pickedTime = await showTimePicker(
          context: ctx,
          initialTime: TimeOfDay.fromDateTime(
            initialMeetingTime.isAfter(now) ? initialMeetingTime : now,
          ),
        );

        if (pickedTime != null) {
          final DateTime combined = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          if (!_isValidFutureMeetingTime(combined)) {
            setState(() {
              startTimeError = "Please choose a future time";
            });
            return;
          }
          updatedTime = combined;
          setState(() {
            startTimeController.text = _formatDateTime(combined.toIso8601String());
            startTimeError = null;
          });
        }
      }
    }

    bool validateFields(StateSetter setState) {
      final title = titleController.text.trim();
      final location = locationController.text.trim();
      final link = linkController.text.trim();
      final selectedStartTime =
          updatedTime ?? DateTime.tryParse(meeting.startTime)?.toLocal();

      setState(() {
        titleError = title.isEmpty ? "Please enter a title" : null;
        locationError = location.isEmpty ? "Please enter a platform" : null;
        linkError =
            link.isEmpty ? "Please enter a meeting link" : MeetingManagement.validateMeetingUrl(link);
        if (selectedStartTime == null) {
          startTimeError = "Please select a start time";
        } else if (!_isValidFutureMeetingTime(selectedStartTime)) {
          startTimeError = "Please choose a future time";
        } else {
          startTimeError = null;
        }
      });

      return titleError == null &&
          locationError == null &&
          linkError == null &&
          startTimeError == null;
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.blue.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_calendar_rounded,
                    color: AppColors.blue, size: 20),
              ),
              const SizedBox(width: 10),
              const Text("Update Meeting"),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                const RequiredFieldLabel("Title"),
                CustomTextField(
                  controller: titleController,
                  hintText: "Enter title",
                  prefixIcon: const Icon(Icons.title),
                  errorText: titleError,
                  onChanged: (_) {
                    if (titleError != null) setState(() => titleError = null);
                  },
                ),
                const SizedBox(height: 6),
                const RequiredFieldLabel("Platform"),
                CustomTextField(
                  controller: locationController,
                  hintText: "Platform (Zoom, Meet, Teams)",
                  prefixIcon: const Icon(Icons.location_on),
                  errorText: locationError,
                  onChanged: (_) {
                    if (locationError != null) setState(() => locationError = null);
                  },
                ),
                const SizedBox(height: 6),
                const RequiredFieldLabel("Link"),
                CustomTextField(
                  controller: linkController,
                  hintText: "Enter meeting link",
                  prefixIcon: const Icon(Icons.link),
                  errorText: linkError,
                  keyboardType: TextInputType.url,
                  maxLength: MeetingManagement.meetingUrlMaxLength,
                  helperText: "Supported: Zoom, Google Meet, Microsoft Teams. HTTPS only.",
                  onChanged: (_) {
                    final value = linkController.text.trim();
                    setState(() {
                      linkError = value.isEmpty
                          ? null
                          : MeetingManagement.validateMeetingUrl(value);
                    });
                  },
                ),
                const SizedBox(height: 6),
                const RequiredFieldLabel("Start Time"),
                CustomTextField(
                  controller: startTimeController,
                  hintText: "Select start time",
                  prefixIcon: const Icon(Icons.access_time_rounded),
                  errorText: startTimeError,
                  readOnly: true,
                  onTap: () => selectDateTime(context, setState),
                ),
                const SizedBox(height: 6),
                Text(
                  "Status",
                  style: AppTextStyles.black12_700.copyWith(
                    color: AppColors.grey474747,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.greyD9D9D9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: status,
                    underline: const SizedBox.shrink(),
                    borderRadius: BorderRadius.circular(10),
                    items: const [
                      DropdownMenuItem(
                        value: 'scheduled',
                        child: Text("Scheduled"),
                      ),
                      DropdownMenuItem(
                        value: 'completed',
                        child: Text("Completed"),
                      ),
                      DropdownMenuItem(
                        value: 'cancelled',
                        child: Text("Cancelled"),
                      ),
                    ],
                    onChanged: (value) => setState(() => status = value!),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            Consumer<MeetingManagement>(
              builder: (context, mm, _) => mm.isUpdating
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : CustomButton(
                      width: Utils().width(context) * 0.3,
                      onPressed: () async {
                        if (!validateFields(setState)) return;
                        await mm.updateMeeting(
                          id: meeting.id,
                          title: titleController.text.trim(),
                          location: locationController.text.trim(),
                          link: linkController.text.trim(),
                          startTime: updatedTime?.toUtc().toIso8601String() ??
                              meeting.startTime,
                          status: status,
                        );
                        if (context.mounted) Navigator.pop(context);
                      },
                      text: "Update",
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
