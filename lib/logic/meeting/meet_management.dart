import 'package:flutter/material.dart';
import 'package:kkpchatapp/data/api/meeting_service.dart';
import 'package:kkpchatapp/data/models/meet_model.dart';

class MeetingManagement with ChangeNotifier {
  final MeetingService _meetingService;
  List<MeetingModel> _meetings = [];
  bool _isLoading = false;
  bool _isUpdating = false;
  String? _error;

  MeetingManagement({MeetingService? meetingService})
      : _meetingService = meetingService ?? MeetingService() {
    fetchAllMeetings();
  }
  // Getters
  List<MeetingModel> get meetings => _meetings;
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  String? get error => _error;

  // Fetch all meetings
  Future<void> fetchAllMeetings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _meetings = await _meetingService.getAllMeetings();
      // debugPrint("Total meetings fetched: ${_meetings.length}"); // Debug print

      // Print details of all meetings
      // for (var meeting in _meetings) {
      //   debugPrint("Meeting: ${meeting.title}, Time: ${meeting.startTime}");
      // }
    } catch (e) {
      _error = "Failed to fetch meetings: $e";
      debugPrint("Error fetching meetings: $e"); // Debug print for errors
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get today's upcoming meetings
  List<MeetingModel> getTodaysUpcomingMeetings() {
    final now = DateTime.now();
    final todaysMeetings = _meetings.where((meeting) {
      try {
        final meetingDate = DateTime.parse(meeting.startTime);
        // Check if meeting is today and in the future
        final isTodayAndFuture = meetingDate.year == now.year &&
            meetingDate.month == now.month &&
            meetingDate.day == now.day &&
            meetingDate.isAfter(now);

        debugPrint(
            "Checking meeting: ${meeting.title} - Today and future: $isTodayAndFuture");
        // debugPrint("Checking meeting: ${meeting.title} - Today and future: $isTodayAndFuture");
        return isTodayAndFuture;
      } catch (e) {
        debugPrint("Error parsing meeting time for ${meeting.title}: $e");
        return false;
      }
    }).toList()
      ..sort((a, b) =>
          DateTime.parse(a.startTime).compareTo(DateTime.parse(b.startTime)));

    // debugPrint("Found ${todaysMeetings.length} upcoming meetings for today");

    // Print details of today's upcoming meetings
    // for (var meeting in todaysMeetings) {
    //   debugPrint("Upcoming meeting: ${meeting.title}, Time: ${meeting.startTime}");
    // }
    for (var meeting in todaysMeetings) {
      debugPrint(
          "Upcoming meeting: ${meeting.title}, Time: ${meeting.startTime}");
    }

    return todaysMeetings;
  }

  // Get the next upcoming meeting (if any)
  List<MeetingModel>? getNextUpcomingMeeting() {
    final todaysMeetings = getTodaysUpcomingMeetings();
    final nextMeeting = todaysMeetings.isNotEmpty ? todaysMeetings.first : null;

    if (nextMeeting != null) {
      debugPrint(
          "Next upcoming meeting: ${nextMeeting.title} at ${nextMeeting.startTime}");
      //  debugPrint("Next upcoming meeting: ${nextMeeting.title} at ${nextMeeting.startTime}");
    } else {
      //debugPrint("No upcoming meetings found for today");
    }

    return todaysMeetings.sublist(
        0, todaysMeetings.length > 1 ? 2 : todaysMeetings.length);
  }

  // Create a new meeting
  Future<bool> createMeeting({
    required String title,
    required String location,
    required String link,
    required String startTime,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final success = await _meetingService.createMeeting(
        title: title,
        location: location,
        link: link,
        startTime: startTime,
      );
      if (success) {
        await fetchAllMeetings(); // Refresh the list
      }
      return success;
    } catch (e) {
      _error = "Failed to create meeting: $e";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update a meeting
  Future<bool> updateMeeting({
    required String id,
    String? title,
    String? location,
    String? link,
    String? startTime,
    String? status,
  }) async {
    _isUpdating = true; // Set updating state to true
    _error = null;
    notifyListeners();
    try {
      final success = await _meetingService.updateMeeting(
        id: id,
        title: title,
        location: location,
        link: link,
        startTime: startTime,
        status: status,
      );
      if (success) {
        await fetchAllMeetings(); // Refresh the list
      }
      return success;
    } catch (e) {
      _error = "Failed to update meeting: $e";
      return false;
    } finally {
      _isUpdating = false; // Set updating state to false
      notifyListeners();
    }
  }

  // Delete a meeting
  Future<bool> deleteMeeting(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final success = await _meetingService.deleteMeeting(id);
      if (success) {
        await fetchAllMeetings(); // Refresh the list
      }
      return success;
    } catch (e) {
      _error = "Failed to delete meeting: $e";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
