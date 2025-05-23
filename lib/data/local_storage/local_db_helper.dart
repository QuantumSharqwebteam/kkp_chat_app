import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:kkpchatapp/data/models/call_log_model.dart';
import 'package:kkpchatapp/data/models/profile_model.dart';

class LocalDbHelper {
  static const String _keyToken = 'token';
  static const String _userType = 'userType';
  static const String _name = 'name';
  static const String _email = 'email';
  static const String _profile = 'profile';
  static const String _fCMToken = "FCMTOKEN";
  static const String _lastRefreshTime = 'lastRefreshTime';

  // feed
  static const String _pinnedAgentsKey = 'pinnedAgents';
  static const String _lastSeenMapKey = 'lastSeenMap';

  static Box<dynamic> get _box => Hive.box('CREDENTIALS');
  // for storing user last seen time or when he/ she came online
  static Box<dynamic> get _lastSeenBoxInstance => Hive.box("lastSeenTimeBox");

  static Box<dynamic> get _feedBox => Hive.box('feedBox');

  static Future<void> saveToken(String token) async {
    await _box.put(_keyToken, token);
  }

  static Future<String?> getToken() async {
    return _box.get(_keyToken);
  }

  static Future<void> removeToken() async {
    await _box.delete(_keyToken);
  }

  static Future<void> saveEmail(String email) async {
    await _box.put(_email, email);
  }

  static String? getEmail() {
    return _box.get(_email);
  }

  static Future<void> removeEmail() async {
    await _box.delete(_email);
  }

  static Future<void> saveUserType(String userType) async {
    await _box.put(_userType, userType);
  }

  static Future<String?> getUserType() async {
    return _box.get(_userType);
  }

  static Future<void> removeUserType() async {
    await _box.delete(_userType);
  }

  static Future<void> saveName(String name) async {
    await _box.put(_name, name);
  }

  static String? getName() {
    return _box.get(_name);
  }

  static Future<void> removeName() async {
    await _box.delete(_name);
  }

  static Future<void> saveProfile(Profile profile) async {
    await _box.put(_profile, profile.toMap());
  }

  static Profile? getProfile() {
    final profileMap = _box.get(_profile);
    if (profileMap != null && profileMap is Map<String, dynamic>) {
      return Profile.fromMap(profileMap);
    }
    return null;
  }

  static Future<void> removeProfile() async {
    await _box.delete(_profile);
  }

  // Methods to handle last seen times
  static Future<void> updateLastSeenTime(String email) async {
    await _lastSeenBoxInstance.put(email, DateTime.now().toIso8601String());
  }

  static DateTime? getLastSeenTime(String email) {
    String? lastSeen = _lastSeenBoxInstance.get(email);
    if (lastSeen != null) {
      DateTime parsedDate = DateTime.parse(lastSeen);
      return parsedDate;
    }
    return null;
  }

  static Future<void> clearLastSeenMap() async {
    await _lastSeenBoxInstance.delete(_lastSeenMapKey);
  }

  // pinned agents
  static Future<void> savePinnedAgents(Set<String> agentEmails) async {
    await _feedBox.put(_pinnedAgentsKey, agentEmails.toList());
  }

  static Set<String> getPinnedAgents() {
    final List<dynamic>? emails = _feedBox.get(_pinnedAgentsKey);
    return emails != null ? Set<String>.from(emails) : {};
  }

  static Future<void> clearPinnedAgents() async {
    await _feedBox.delete(_pinnedAgentsKey);
  }

  static Future<void> saveFCMToken(String fcmToken) async {
    await _box.put(_fCMToken, fcmToken);
  }

  static String? getFCMToken() {
    return _box.get(_fCMToken);
  }

  static Future<void> clearFCMToken() async {
    await _box.delete(_fCMToken);
  }

  static Future<void> saveLastRefreshTime(int time) async {
    await _box.put(_lastRefreshTime, time);
  }

  static Future<int?> getLastRefreshTime() async {
    return _box.get(_lastRefreshTime);
  }

  static Future<void> saveCallLogs(List<CallLogModel> callLogs) async {
    final email = getProfile()?.email;
    if (email != null) {
      final box = await Hive.openBox<String>('callLogs_$email');
      await box.clear();
      for (var log in callLogs) {
        await box.add(jsonEncode(log.toJson()));
      }
    }
  }

  static Future<List<CallLogModel>> getCallLogs() async {
    final email = getProfile()?.email;
    if (email != null) {
      final box = await Hive.openBox<String>('callLogs_$email');
      return box.values
          .map((log) => CallLogModel.fromJson(jsonDecode(log)))
          .toList();
    }
    return [];
  }

  static Future<void> updateCallLogs(List<CallLogModel> newCallLogs) async {
    final email = getProfile()?.email;
    if (email != null) {
      final box = await Hive.openBox<String>('callLogs_$email');
      final existingLogs = box.values
          .map((log) => CallLogModel.fromJson(jsonDecode(log)))
          .toList();
      final updatedLogs = [...existingLogs, ...newCallLogs];
      await box.clear();
      for (var log in updatedLogs) {
        await box.add(jsonEncode(log.toJson()));
      }
    }
  }
}
