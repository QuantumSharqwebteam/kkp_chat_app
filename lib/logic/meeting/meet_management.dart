import 'package:flutter/material.dart';
import 'package:kkpchatapp/data/api/meeting_service.dart';
import 'package:kkpchatapp/data/models/meet_model.dart';

class MeetingManagement with ChangeNotifier {
  final MeetingService _meetingService;
  List<MeetingModel> _meetings = [];
  bool _isLoading = false;
  String? _error;

  MeetingManagement({MeetingService? meetingService})
      : _meetingService = meetingService ?? MeetingService();

  // Getters
  List<MeetingModel> get meetings => _meetings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch all meetings
  Future<void> fetchAllMeetings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _meetings = await _meetingService.getAllMeetings();
    } catch (e) {
      _error = "Failed to fetch meetings: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _meetingService.updateMeeting(
        id: id,
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
      _error = "Failed to update meeting: $e";
      return false;
    } finally {
      _isLoading = false;
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
