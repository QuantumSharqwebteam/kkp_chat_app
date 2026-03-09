// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/utils/chat_utils.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/data/models/meet_model.dart';
import 'package:kkpchatapp/logic/meeting/meet_management.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_button.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_textfield.dart';
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

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
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
            child: const Text("Delete"),
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

    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: AppColors.blue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.event_available_rounded,
                    color: AppColors.blue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meeting.title,
                        style: AppTextStyles.black16_700.copyWith(color: AppColors.grey5C5C5C),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDateTime(meeting.startTime),
                        style: AppTextStyles.grey12_600.copyWith(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (showButtons) ...[
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
                            Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete Meeting'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildStatusChip(meeting.status),
                _buildMetaChip(
                  icon: Icons.groups_2_outlined,
                  label: "${meeting.participants.length} Participants",
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                    label: "Location",
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final normalizedStatus = status.trim().toLowerCase();
    final displayStatus = normalizedStatus.isEmpty
        ? "Unknown"
        : "${normalizedStatus[0].toUpperCase()}${normalizedStatus.substring(1)}";
    final Color color = normalizedStatus == "cancelled"
        ? AppColors.errorRed
        : normalizedStatus == "completed"
            ? AppColors.activeGreen
            : Colors.amber.shade700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        displayStatus,
        style: AppTextStyles.black12_700.copyWith(color: color),
      ),
    );
  }

  Widget _buildMetaChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.greyD9D9D9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.grey5C5C5C),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.black10_500.copyWith(
              color: AppColors.grey5C5C5C,
            ),
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

  String _formatDateTime(String isoDateTime) {
    final dateTime = DateTime.parse(isoDateTime);
    return "${ChatUtils().formatDateHeader(dateTime)} at ${ChatUtils().formatTimestamp(isoDateTime)}";
  }

  Future<void> _showUpdateDialog(
    BuildContext context,
    MeetingManagement meetingManagement,
    MeetingModel meeting,
  ) async {
    final titleController = TextEditingController(text: meeting.title);
    final locationController = TextEditingController(text: meeting.location);
    final linkController = TextEditingController(text: meeting.link);
    final startTimeController = TextEditingController(text: _formatDateTime(meeting.startTime));
    String status = meeting.status;
    DateTime? updatedTime;

    Future<void> selectDateTime(BuildContext context) async {
      final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.parse(meeting.startTime),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );

      if (pickedDate != null) {
        final TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(DateTime.parse(meeting.startTime)),
        );

        if (pickedTime != null) {
          final DateTime combined = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          updatedTime = combined;
          startTimeController.text = _formatDateTime(combined.toIso8601String());
        }
      }
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text("Update Meeting"),
        content: SingleChildScrollView(
          child: Column(
            spacing: 5,
            children: [
              CustomTextField(
                controller: titleController,
                hintText: "Enter title",
                prefixIcon: const Icon(Icons.title),
              ),
              CustomTextField(
                controller: locationController,
                hintText: "Enter location",
                prefixIcon: const Icon(Icons.location_on),
              ),
              CustomTextField(
                controller: linkController,
                hintText: "Enter link",
                prefixIcon: const Icon(Icons.link),
              ),
              CustomTextField(
                controller: startTimeController,
                hintText: "Select start time",
                prefixIcon: const Icon(Icons.calendar_today),
                readOnly: true,
                onTap: () => selectDateTime(context),
              ),
              DropdownButton<String>(
                isExpanded: true,
                value: status,
                items: [
                  DropdownMenuItem<String>(
                    value: 'cancelled',
                    child: Text(
                      "Cancelled",
                      style: AppTextStyles.black10_500,
                    ),
                  ),
                  DropdownMenuItem<String>(
                    value: 'completed',
                    child: Text(
                      "Completed",
                      style: AppTextStyles.black10_500,
                    ),
                  ),
                  DropdownMenuItem<String>(
                    value: 'scheduled',
                    child: Text(
                      "Scheduled",
                      style: AppTextStyles.black10_500,
                    ),
                  ),
                ],
                onChanged: (value) {
                  status = value!;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          Consumer<MeetingManagement>(
            builder: (context, meetingManagement, child) {
              return meetingManagement.isUpdating
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : CustomButton(
                      width: Utils().width(context) * 0.3,
                      onPressed: () async {
                        await meetingManagement.updateMeeting(
                          id: meeting.id,
                          title: titleController.text,
                          location: locationController.text,
                          link: linkController.text,
                          startTime: updatedTime?.toIso8601String() ?? meeting.startTime,
                          status: status,
                        );
                        if (context.mounted) Navigator.pop(context);
                      },
                      text: "Update",
                    );
            },
          ),
        ],
      ),
    );
  }
}
