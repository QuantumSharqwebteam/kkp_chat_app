// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/logic/meeting/meet_management.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_button.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_textfield.dart';
import 'package:kkpchatapp/presentation/common_widgets/required_field_label.dart';
import 'package:provider/provider.dart';

class ScheduleMeetingScreen extends StatefulWidget {
  const ScheduleMeetingScreen({super.key});

  @override
  State<ScheduleMeetingScreen> createState() => _ScheduleMeetingScreenState();
}

class _ScheduleMeetingScreenState extends State<ScheduleMeetingScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();

  String? _titleError;
  String? _locationError;
  String? _linkError;
  String? _startTimeError;

  bool _isValidFutureMeetingTime(DateTime selectedDateTime) {
    return selectedDateTime.isAfter(DateTime.now());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _linkController.dispose();
    _startTimeController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(now),
      );

      if (pickedTime != null) {
        final combined = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        if (!_isValidFutureMeetingTime(combined)) {
          setState(() {
            _startTimeError = "Invalid time. Please choose a future time for today";
          });
          return;
        }

        setState(() {
          _startTimeController.text = combined.toUtc().toIso8601String();
          _startTimeError = null;
        });
      }
    }
  }

  bool _validateFields() {
    bool isValid = true;

    if (_titleController.text.trim().isEmpty) {
      setState(() => _titleError = "Please enter a title");
      isValid = false;
    } else {
      setState(() => _titleError = null);
    }

    if (_locationController.text.trim().isEmpty) {
      setState(() => _locationError = "Please enter a platform");
      isValid = false;
    } else {
      setState(() => _locationError = null);
    }

    final link = _linkController.text.trim();

    if (link.isEmpty) {
      setState(() => _linkError = "Please enter a meeting link");
      isValid = false;
    } else {
      final linkValidationMessage = MeetingManagement.validateMeetingUrl(link);
      if (linkValidationMessage != null) {
        setState(() => _linkError = linkValidationMessage);
        isValid = false;
      } else {
        setState(() => _linkError = null);
      }
    }

    if (_startTimeController.text.isEmpty) {
      setState(() => _startTimeError = "Please select a start time");
      isValid = false;
    } else {
      try {
        final selectedDateTime = DateTime.parse(_startTimeController.text).toLocal();

        if (!_isValidFutureMeetingTime(selectedDateTime)) {
          setState(() => _startTimeError = "Invalid time. Please choose a future time");
          isValid = false;
        } else {
          setState(() => _startTimeError = null);
        }
      } catch (e) {
        setState(() => _startTimeError = "Invalid start time");
        isValid = false;
      }
    }

    return isValid;
  }

  Future<void> _scheduleMeeting() async {
    if (!_validateFields()) return;

    final meetingManagement = Provider.of<MeetingManagement>(context, listen: false);
    final success = await meetingManagement.createMeeting(
      title: _titleController.text.trim(),
      location: _locationController.text.trim(),
      link: _linkController.text.trim(),
      startTime: _startTimeController.text,
    );

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Meeting scheduled successfully!")),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to schedule meeting.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final meetingManagement = Provider.of<MeetingManagement>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Schedule Meeting"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: meetingManagement.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 40),
                child: Card(
                  color: Colors.white,
                  elevation: 10,
                  surfaceTintColor: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          const RequiredFieldLabel("Title"),
                          CustomTextField(
                            controller: _titleController,
                            hintText: "Enter title",
                            prefixIcon: const Icon(Icons.title),
                            errorText: _titleError,
                            onChanged: (_) {
                              if (_titleError != null) {
                                setState(() => _titleError = null);
                              }
                            },
                          ),
                          const SizedBox(height: 10),
                          const RequiredFieldLabel("Platform"),
                          CustomTextField(
                            controller: _locationController,
                            hintText: "Platform(Zoom, meet, teams) ",
                            prefixIcon: const Icon(Icons.location_on),
                            errorText: _locationError,
                            onChanged: (_) {
                              if (_locationError != null) {
                                setState(() => _locationError = null);
                              }
                            },
                          ),
                          const SizedBox(height: 10),
                          const RequiredFieldLabel("Link"),
                          CustomTextField(
                            controller: _linkController,
                            hintText: "Enter link",
                            prefixIcon: const Icon(Icons.link),
                            errorText: _linkError,
                            keyboardType: TextInputType.url,
                            maxLength: MeetingManagement.meetingUrlMaxLength,
                            helperText:
                                "Supported: Zoom, Google Meet, Microsoft Teams. HTTPS only.",
                            onChanged: (_) {
                              final value = _linkController.text.trim();
                              setState(() {
                                _linkError = value.isEmpty
                                    ? null
                                    : MeetingManagement.validateMeetingUrl(value);
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          const RequiredFieldLabel("Start Time"),
                          CustomTextField(
                            controller: _startTimeController,
                            hintText: "Select start time",
                            prefixIcon: const Icon(Icons.calendar_today),
                            errorText: _startTimeError,
                            readOnly: true,
                            onTap: () => _selectDateTime(context),
                          ),
                          const SizedBox(height: 20),
                          CustomButton(
                            onPressed: _scheduleMeeting,
                            fontSize: 18,
                            backgroundColor: AppColors.bluePrimary,
                            text: "Schedule Meeting",
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
