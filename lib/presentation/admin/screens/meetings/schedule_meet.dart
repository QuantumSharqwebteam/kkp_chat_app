import 'package:flutter/material.dart';
import 'package:kkpchatapp/logic/meeting/meet_management.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_button.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_textfield.dart';
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

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _linkController.dispose();
    _startTimeController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        final DateTime combined = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        _startTimeController.text = combined.toIso8601String();
      }
    }
  }

  bool _validateFields() {
    bool isValid = true;
    if (_titleController.text.isEmpty) {
      setState(() => _titleError = "Please enter a title");
      isValid = false;
    } else {
      setState(() => _titleError = null);
    }
    if (_locationController.text.isEmpty) {
      setState(() => _locationError = "Please enter a location");
      isValid = false;
    } else {
      setState(() => _locationError = null);
    }
    if (_linkController.text.isEmpty) {
      setState(() => _linkError = "Please enter a link");
      isValid = false;
    } else {
      setState(() => _linkError = null);
    }
    if (_startTimeController.text.isEmpty) {
      setState(() => _startTimeError = "Please select a start time");
      isValid = false;
    } else {
      setState(() => _startTimeError = null);
    }
    return isValid;
  }

  Future<void> _scheduleMeeting() async {
    if (!_validateFields()) return;

    final meetingManagement = Provider.of<MeetingManagement>(context, listen: false);
    final success = await meetingManagement.createMeeting(
      title: _titleController.text,
      location: _locationController.text,
      link: _linkController.text,
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
                          const Text("Title"),
                          CustomTextField(
                            controller: _titleController,
                            hintText: "Enter title",
                            prefixIcon: const Icon(Icons.title),
                            errorText: _titleError,
                          ),
                          const SizedBox(height: 10),
                          const Text("Location"),
                          CustomTextField(
                            controller: _locationController,
                            hintText: "Enter location",
                            prefixIcon: const Icon(Icons.location_on),
                            errorText: _locationError,
                          ),
                          const SizedBox(height: 10),
                          const Text("Link"),
                          CustomTextField(
                            controller: _linkController,
                            hintText: "Enter link",
                            prefixIcon: const Icon(Icons.link),
                            errorText: _linkError,
                          ),
                          const SizedBox(height: 10),
                          const Text("Start Time"),
                          InkWell(
                            onTap: () => _selectDateTime(context),
                            child: CustomTextField(
                              controller: _startTimeController,
                              hintText: "Select start time",
                              prefixIcon: const Icon(Icons.calendar_today),
                              errorText: _startTimeError,
                              readOnly: true,
                            ),
                          ),
                          const SizedBox(height: 20),
                          CustomButton(
                            onPressed: _scheduleMeeting,
                            fontSize: 18,
                            backgroundColor: Colors.blue,
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
