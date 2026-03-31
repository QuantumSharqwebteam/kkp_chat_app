import 'package:flutter/material.dart';
import 'package:kkpchatapp/core/services/logging_service.dart';
import 'package:kkpchatapp/data/api/analytics_management_service.dart';
import 'package:kkpchatapp/data/models/activity_model.dart';

class AnalyticsManagementProvider extends ChangeNotifier {
  final AnalyticsService _analyticsService;
  final LoggingService _logger = LoggingService.instance;

  AnalyticsManagementProvider({AnalyticsService? analyticsService})
      : _analyticsService = analyticsService ?? AnalyticsService() {
    fetchActivities();
  }

  List<Activity> _activities = [];
  bool _isLoading = true;
  bool _isDownloading = false;
  bool _isDeleting = false;
  String? _errorMessage;

  List<Activity> get activities => _activities;
  bool get isLoading => _isLoading;
  bool get isDownloading => _isDownloading;
  bool get isDeleting => _isDeleting;
  String? get errorMessage => _errorMessage;

  int get totalActivities => _activities.length;
  int get uniqueUsersCount =>
      _activities.map((activity) => activity.user.id).where((id) => id.isNotEmpty).toSet().length;
  DateTime? get latestActivityTime => _activities.isEmpty
      ? null
      : _activities.map((activity) => activity.timestamp).reduce(
            (a, b) => a.isAfter(b) ? a : b,
          );

  Future<void> fetchActivities() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _activities = await _analyticsService.fetchActivities();
      _logger.logNetwork(
        'Analytics provider fetched activities: ${_activities.length}',
        level: LogLevel.info,
      );
    } catch (e, stackTrace) {
      _errorMessage = e.toString();
      _logger.logNetwork(
        'Analytics provider failed to fetch activities',
        level: LogLevel.error,
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteAllData() async {
    _isDeleting = true;
    notifyListeners();

    try {
      final success = await _analyticsService.deleteAllData();
      if (success) {
        await fetchActivities();
      }
      return success;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  void setDownloading(bool value) {
    _isDownloading = value;
    notifyListeners();
  }
}
