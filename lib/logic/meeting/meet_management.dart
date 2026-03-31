import 'package:flutter/material.dart';
import 'package:kkpchatapp/core/services/logging_service.dart';
import 'package:kkpchatapp/data/api/meeting_service.dart';
import 'package:kkpchatapp/data/models/meet_model.dart';

class MeetingManagement with ChangeNotifier {
  final MeetingService _meetingService;
  final LoggingService _logger = LoggingService.instance;
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

  bool _isPrivilegedMeetingEditor({
    String? userType,
    String? roleName,
  }) {
    final normalizedRole = (roleName ?? '').toLowerCase().trim();
    return userType == "1" ||
        userType == "3" ||
        normalizedRole == "admin" ||
        normalizedRole == "agenthead" ||
        normalizedRole == "agent head";
  }

  bool canEditMeeting({
    required MeetingModel meeting,
    required String currentUserEmail,
    String? userType,
    String? roleName,
  }) {
    final isScheduledPerson = meeting.scheduledPerson.email == currentUserEmail;
    return isScheduledPerson ||
        _isPrivilegedMeetingEditor(userType: userType, roleName: roleName);
  }

  // Fetch all meetings
  Future<void> fetchAllMeetings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    _logger.logUi('MeetingManagement.fetchAllMeetings started', level: LogLevel.info);

    try {
      _meetings = await _meetingService.getAllMeetings();
      _logger.logUi(
        'MeetingManagement.fetchAllMeetings success | Count: ${_meetings.length}',
        level: LogLevel.info,
      );
      // debugPrint("Total meetings fetched: ${_meetings.length}"); // Debug print

      // Print details of all meetings
      // for (var meeting in _meetings) {
      //   debugPrint("Meeting: ${meeting.title}, Time: ${meeting.startTime}");
      // }
    } catch (e, stackTrace) {
      _error = "Failed to fetch meetings: $e";
      _logger.logUi(
        'MeetingManagement.fetchAllMeetings failed',
        level: LogLevel.error,
        error: e,
        stackTrace: stackTrace,
      );
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

        // debugPrint("Checking meeting: ${meeting.title} - Today and future: $isTodayAndFuture");
        // debugPrint("Checking meeting: ${meeting.title} - Today and future: $isTodayAndFuture");
        return isTodayAndFuture;
      } catch (e) {
        //   debugPrint("Error parsing meeting time for ${meeting.title}: $e");
        return false;
      }
    }).toList()
      ..sort((a, b) => DateTime.parse(a.startTime).compareTo(DateTime.parse(b.startTime)));

    // debugPrint("Found ${todaysMeetings.length} upcoming meetings for today");

    // Print details of today's upcoming meetings
    // for (var meeting in todaysMeetings) {
    //   debugPrint("Upcoming meeting: ${meeting.title}, Time: ${meeting.startTime}");
    // }
    // for (var meeting in todaysMeetings) {
    //   debugPrint("Upcoming meeting: ${meeting.title}, Time: ${meeting.startTime}");
    // }

    return todaysMeetings;
  }

  // Get the next upcoming meeting (if any)
  // Get the next upcoming meetings for today (MAX 2)
// Returns null when there are NO upcoming meetings
  List<MeetingModel>? getNextUpcomingMeeting() {
    final todaysMeetings = getTodaysUpcomingMeetings();

    // ✅ IMPORTANT: Return null when no meetings exist
    if (todaysMeetings.isEmpty) {
      // debugPrint("No upcoming meetings found for today");
      return null;
    }

    // ✅ Take only first 2 meetings safely
    final upcomingMeetings = todaysMeetings.take(2).toList();

    // debugPrint(
    //     "Next upcoming meeting: ${upcomingMeetings.first.title} at ${upcomingMeetings.first.startTime}");

    return upcomingMeetings;
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
    _logger.logUi(
      'MeetingManagement.createMeeting started | title: $title',
      level: LogLevel.info,
    );
    try {
      final success = await _meetingService.createMeeting(
        title: title,
        location: location,
        link: link,
        startTime: startTime,
      );
      if (success) {
        _logger.logUi('MeetingManagement.createMeeting success', level: LogLevel.info);
        await fetchAllMeetings(); // Refresh the list
      } else {
        _logger.logUi('MeetingManagement.createMeeting failed', level: LogLevel.warning);
      }
      return success;
    } catch (e, stackTrace) {
      _error = "Failed to create meeting: $e";
      _logger.logUi(
        'MeetingManagement.createMeeting exception',
        level: LogLevel.error,
        error: e,
        stackTrace: stackTrace,
      );
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
    _logger.logUi('MeetingManagement.updateMeeting started | id: $id', level: LogLevel.info);
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
        _logger.logUi('MeetingManagement.updateMeeting success | id: $id', level: LogLevel.info);
        await fetchAllMeetings(); // Refresh the list
      } else {
        _logger.logUi('MeetingManagement.updateMeeting failed | id: $id', level: LogLevel.warning);
      }
      return success;
    } catch (e, stackTrace) {
      _error = "Failed to update meeting: $e";
      _logger.logUi(
        'MeetingManagement.updateMeeting exception | id: $id',
        level: LogLevel.error,
        error: e,
        stackTrace: stackTrace,
      );
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
    _logger.logUi('MeetingManagement.deleteMeeting started | id: $id', level: LogLevel.info);
    try {
      final success = await _meetingService.deleteMeeting(id);
      if (success) {
        _logger.logUi('MeetingManagement.deleteMeeting success | id: $id', level: LogLevel.info);
        await fetchAllMeetings(); // Refresh the list
      } else {
        _logger.logUi('MeetingManagement.deleteMeeting failed | id: $id', level: LogLevel.warning);
      }
      return success;
    } catch (e, stackTrace) {
      _error = "Failed to delete meeting: $e";
      _logger.logUi(
        'MeetingManagement.deleteMeeting exception | id: $id',
        level: LogLevel.error,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
