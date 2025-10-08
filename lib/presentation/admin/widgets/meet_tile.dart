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

  const MeetingTile(
      {super.key, required this.meeting, required this.showButtons});

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final meetingManagement =
        Provider.of<MeetingManagement>(context, listen: false);

    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  meeting.title,
                  style: AppTextStyles.black16_700
                      .copyWith(color: AppColors.grey5C5C5C),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: meeting.status == "cancelled"
                        ? AppColors.errorRed.withOpacity(0.8)
                        : meeting.status == "completed"
                            ? AppColors.activeGreen
                            : meeting.status == "scheduled"
                                ? Colors.amber
                                : Colors.amber,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    meeting.status,
                    style: TextStyle(
                      fontSize: 12,
                      color: meeting.status == meeting.status
                          ? Colors.white
                          : Colors.white70.withOpacity(1.0),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Location and Platform
            Row(
              children: [
                const Icon(Icons.location_searching_rounded,
                    size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  meeting.location,
                  style: AppTextStyles.black14_600,
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Start Time
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  "Starts at: ${_formatDateTime(meeting.startTime)}",
                  style: AppTextStyles.grey12_600.copyWith(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Scheduled By
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  "Scheduled by: ${meeting.scheduledPerson.name}",
                  style: AppTextStyles.black12_700,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Meeting Link (Clickable)
            GestureDetector(
              onTap: () => _launchUrl(meeting.link),
              child: Row(
                children: [
                  const Icon(Icons.link, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      meeting.link,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.blue00ABE9,
                        decoration: TextDecoration.underline,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Participants
            // Row(
            //   children: [
            //     const Icon(Icons.people, size: 16, color: Colors.grey),
            //     const SizedBox(width: 4),
            //     Text(
            //       "Participants: ${meeting.participants.length}",
            //       style: AppTextStyles.black10_500,
            //     ),
            //   ],
            // ),

            // Actions (Update, Delete)
            Visibility(
              visible: showButtons,
              child: Row(
                spacing: 8,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () {
                      // Navigate to update screen or show update dialog
                      _showUpdateDialog(context, meetingManagement, meeting);
                    },
                    child: Image.asset(
                      'assets/icons/updated.png',
                      height: 40,
                      width: 40,
                    ),
                    // CustomButton(
                    //   height: 40,
                    //   image: Image.asset('assets/icons/updated.png'),
                    //   text: "",
                    //   backgroundColor: Colors.white,
                    //   textColor: AppColors.activeGreen.withValues(alpha: 0.3),
                    //   borderColor: AppColors.greyD9D9D9,
                    //   onPressed: () {
                    //     // Navigate to update screen or show update dialog
                    //     _showUpdateDialog(context, meetingManagement, meeting);
                    //   },
                    // ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Delete Meeting"),
                          content: const Text(
                              "Are you sure you want to delete this meeting?"),
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
                    },
                    child: Image.asset(
                      'assets/icons/delete.png',
                      height: 40,
                      width: 40,
                    ),
                    // child: CustomButton(
                    //   height: 40,
                    //   text: "Delete",
                    //   backgroundColor: Colors.white,
                    //   borderColor: AppColors.redF11515,
                    //   textColor: AppColors.redF11515,
                    // onPressed: () async {
                    //   final confirmed = await showDialog<bool>(
                    //     context: context,
                    //     builder: (context) => AlertDialog(
                    //       title: const Text("Delete Meeting"),
                    //       content: const Text(
                    //           "Are you sure you want to delete this meeting?"),
                    //       actions: [
                    //         TextButton(
                    //           onPressed: () => Navigator.pop(context, false),
                    //           child: const Text("Cancel"),
                    //         ),
                    //         TextButton(
                    //           onPressed: () => Navigator.pop(context, true),
                    //           child: const Text("Delete"),
                    //         ),
                    //       ],
                    //     ),
                    //   );
                    //   if (confirmed == true) {
                    //     await meetingManagement.deleteMeeting(meeting.id);
                    //   }
                    // },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(String isoDateTime) {
    final dateTime = DateTime.parse(isoDateTime);
    return "${ChatUtils().formatDateHeader(dateTime)} at ${ChatUtils().formatTimestamp(isoDateTime)}";
    //  return "${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
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
          initialTime:
              TimeOfDay.fromDateTime(DateTime.parse(meeting.startTime)),
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
          startTimeController.text =
              _formatDateTime(combined.toIso8601String());
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
                        )),
                    DropdownMenuItem<String>(
                        value: 'completed',
                        child: Text(
                          "Completed",
                          style: AppTextStyles.black10_500,
                        )),
                    DropdownMenuItem<String>(
                        value: 'scheduled',
                        child: Text(
                          "Scheduled",
                          style: AppTextStyles.black10_500,
                        )),
                  ],
                  onChanged: (value) {
                    status = value!;
                  }),
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
                          startTime: updatedTime?.toIso8601String() ??
                              meeting.startTime,
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
