import 'package:flutter/material.dart';
import 'package:kkpchatapp/core/services/connectivity_service.dart';
import 'package:kkpchatapp/core/services/logging_service.dart';
import 'package:kkpchatapp/data/api/group_service.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/models/group_model.dart';

enum GroupState { idle, loading, success, error }

class GroupProvider extends ChangeNotifier {
  final GroupService _groupService = GroupService();
  final LoggingService _logger = LoggingService.instance;

  GroupState _state = GroupState.idle;
  String? _errorMessage;
  List<GroupModel> _groups = [];
  List<GroupModel> _userGroups = [];
  final Map<String, int> _groupUnreadCounts = {};
  final Map<String, String> _groupLastMessages = {};
  final Map<String, DateTime?> _groupLastMessageTimes = {};

  GroupState get state => _state;
  String? get errorMessage => _errorMessage;
  List<GroupModel> get groups => _groups;
  List<GroupModel> get userGroups => _userGroups;
  Map<String, int> get groupUnreadCounts => Map.unmodifiable(_groupUnreadCounts);
  Map<String, String> get groupLastMessages => Map.unmodifiable(_groupLastMessages);
  Map<String, DateTime?> get groupLastMessageTimes => Map.unmodifiable(_groupLastMessageTimes);
  int get totalGroupUnreadCount =>
      _groupUnreadCounts.values.fold(0, (sum, c) => sum + c);

  static const cacheValidity = Duration(minutes: 10);

  // --- Unread count + last message helpers (in-memory + storage) ---

  Future<void> loadUnreadCountsFromStorage() async {
    for (final group in _groups) {
      _groupUnreadCounts[group.id] = await LocalDbHelper.getGroupUnreadCount(group.id);
    }
    notifyListeners();
  }

  Future<void> loadLastMessagesFromStorage() async {
    for (final group in _groups) {
      final info = await LocalDbHelper.getGroupLastMessage(group.id);
      if (info.message.isNotEmpty || info.timestamp != null) {
        _groupLastMessages[group.id] = info.message;
        _groupLastMessageTimes[group.id] = info.timestamp;
      }
    }
    notifyListeners();
  }

  /// Called from socket notification path for an instant in-memory update
  /// without waiting for a full Hive read on the next `loadLastMessagesFromStorage`.
  void updateGroupLastMessage(String groupId, String message, DateTime timestamp) {
    _groupLastMessages[groupId] = message;
    _groupLastMessageTimes[groupId] = timestamp;
    notifyListeners();
  }

  void incrementUnreadCount(String groupId) {
    _groupUnreadCounts[groupId] = (_groupUnreadCounts[groupId] ?? 0) + 1;
    debugPrint('🔴 [GroupProvider] incrementUnreadCount $groupId → ${_groupUnreadCounts[groupId]}');
    notifyListeners();
  }

  Future<void> clearUnreadCount(String groupId) async {
    _groupUnreadCounts[groupId] = 0;
    notifyListeners();
    await LocalDbHelper.clearGroupUnreadCount(groupId);
  }

  // GroupProvider() {
  //   _initialize();
  // }

  // Future<void> _initialize() async {
  //   await fetchAllGroups();
  // }

  /// Fetch all groups
  Future<void> fetchAllGroups({bool forceRefresh = false}) async {
    try {
      // ── 1. Serve cache immediately — no shimmer if we have data ────────────
      if (!forceRefresh) {
        final cachedGroups = await LocalDbHelper.getGroups();
        if (cachedGroups != null && cachedGroups.isNotEmpty) {
          debugPrint('📦 [GroupProvider] Cache HIT — ${cachedGroups.length} groups (no shimmer)');
          _groups = cachedGroups;
          _state = GroupState.success;
          notifyListeners();
          await loadUnreadCountsFromStorage();
          // Don't hit the API again unless forced
          if (!ConnectivityService.instance.isOnline) {
            debugPrint('📴 [GroupProvider] Offline — using cached groups');
            return;
          }
          // Background-refresh without showing loading state
          _fetchAllGroupsInBackground();
          return;
        } else {
          debugPrint('📭 [GroupProvider] Cache MISS — showing shimmer');
          _state = GroupState.loading;
          notifyListeners();
        }
      } else {
        _state = GroupState.loading;
        notifyListeners();
      }

      if (!ConnectivityService.instance.isOnline) {
        debugPrint('📴 [GroupProvider] Offline, no cache — staying in error state');
        if (_groups.isEmpty) _state = GroupState.error;
        notifyListeners();
        return;
      }

      await _doFetchAllGroups();
    } catch (e, s) {
      _errorMessage = 'Failed to fetch groups: $e';
      _logger.error('GROUP_PROVIDER', 'fetchAllGroups failed', error: e, stackTrace: s);
      if (_groups.isEmpty) _state = GroupState.error;
      notifyListeners();
    }
  }

  Future<void> _fetchAllGroupsInBackground() async {
    try {
      debugPrint('🌐 [GroupProvider] Background-refreshing all groups from API');
      await _doFetchAllGroups();
    } catch (e) {
      debugPrint('❌ [GroupProvider] Background group refresh failed: $e');
    }
  }

  Future<void> _doFetchAllGroups() async {
    final response = await _groupService.getAllGroups();
    if (response.success && response.data != null) {
      final List<dynamic> groupsJson = response.data!['message'] as List<dynamic>;
      _groups = groupsJson
          .map((json) => GroupModel.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      await LocalDbHelper.saveGroups(_groups);
      await loadUnreadCountsFromStorage();
      await loadLastMessagesFromStorage();
      _state = GroupState.success;
      debugPrint('✅ [GroupProvider] API fetch complete — ${_groups.length} groups');
      _logger.logNetwork('✅ Groups refreshed (${_groups.length} items)');
    } else {
      throw Exception(response.message);
    }
    notifyListeners();
  }

  /// Create a new group
  Future<bool> createGroup({
    required String groupName,
    required String groupDescription,
    required List<String> admins,
    required List<String> members,
    required String groupImage,
  }) async {
    _state = GroupState.loading;
    notifyListeners();
    try {
      final response = await _groupService.createGroup(
        groupName: groupName,
        groupDescription: groupDescription,
        admins: admins,
        members: members,
        groupImage: groupImage,
      );
      if (response.success) {
        _logger.logGeneral('✅ Group created successfully');
        await fetchAllGroups(forceRefresh: true);
        _state = GroupState.success;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        _logger.logGeneral(
          '❌ Failed to create group: ${response.message}',
          level: LogLevel.error,
        );
        _state = GroupState.error;
        notifyListeners();
        return false;
      }
    } catch (e, s) {
      _errorMessage = 'Failed to create group: $e';
      _logger.error('GROUP_PROVIDER', 'createGroup failed', error: e, stackTrace: s);
      _state = GroupState.error;
      notifyListeners();
      return false;
    }
  }

  /// Update group
  Future<bool> updateGroup({
    required String id,
    String? groupName,
    String? groupDescription,
    String? groupImage,
  }) async {
    _state = GroupState.loading;
    notifyListeners();
    try {
      final response = await _groupService.updateGroup(
        id: id,
        groupName: groupName,
        groupDescription: groupDescription,
        groupImage: groupImage,
      );
      if (response.success) {
        _logger.logGeneral('✅ Group updated successfully');
        await fetchAllGroups(forceRefresh: true);
        _state = GroupState.success;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        _logger.logGeneral(
          '❌ Failed to update group: ${response.message}',
          level: LogLevel.error,
        );
        _state = GroupState.error;
        notifyListeners();
        return false;
      }
    } catch (e, s) {
      _errorMessage = 'Failed to update group: $e';
      _logger.error('GROUP_PROVIDER', 'updateGroup failed', error: e, stackTrace: s);
      _state = GroupState.error;
      notifyListeners();
      return false;
    }
  }

  /// Delete group (soft delete)
  Future<bool> deleteGroup(String id) async {
    _state = GroupState.loading;
    notifyListeners();
    try {
      final response = await _groupService.deleteGroup(id);
      if (response.success) {
        _logger.logGeneral('✅ Group deleted successfully');
        await fetchAllGroups(forceRefresh: true);
        _state = GroupState.success;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        _logger.logGeneral(
          '❌ Failed to delete group: ${response.message}',
          level: LogLevel.error,
        );
        _state = GroupState.error;
        notifyListeners();
        return false;
      }
    } catch (e, s) {
      _errorMessage = 'Failed to delete group: $e';
      _logger.error('GROUP_PROVIDER', 'deleteGroup failed', error: e, stackTrace: s);
      _state = GroupState.error;
      notifyListeners();
      return false;
    }
  }

  /// Fetch user's groups
  Future<void> fetchUsersGroups(String email, {bool forceRefresh = false}) async {
    try {
      // ── 1. Serve cache immediately — no shimmer if we have data ────────────
      if (!forceRefresh) {
        final cachedUserGroups = await LocalDbHelper.getUserGroups();
        if (cachedUserGroups != null && cachedUserGroups.isNotEmpty) {
          debugPrint('📦 [GroupProvider] User groups cache HIT — ${cachedUserGroups.length} items (no shimmer)');
          _userGroups = cachedUserGroups;
          _state = GroupState.success;
          notifyListeners();
          if (!ConnectivityService.instance.isOnline) {
            debugPrint('📴 [GroupProvider] Offline — using cached user groups');
            return;
          }
          _fetchUsersGroupsInBackground(email);
          return;
        } else {
          debugPrint('📭 [GroupProvider] User groups cache MISS for $email — showing shimmer');
          _state = GroupState.loading;
          notifyListeners();
        }
      } else {
        _state = GroupState.loading;
        notifyListeners();
      }

      if (!ConnectivityService.instance.isOnline) {
        debugPrint('📴 [GroupProvider] Offline, no user groups cache');
        if (_userGroups.isEmpty) _state = GroupState.error;
        notifyListeners();
        return;
      }

      await _doFetchUsersGroups(email);
    } catch (e, s) {
      _errorMessage = 'Failed to fetch user groups: $e';
      _logger.error('GROUP_PROVIDER', 'fetchUsersGroups failed', error: e, stackTrace: s);
      if (_userGroups.isEmpty) _state = GroupState.error;
      notifyListeners();
    }
  }

  Future<void> _fetchUsersGroupsInBackground(String email) async {
    try {
      debugPrint('🌐 [GroupProvider] Background-refreshing user groups for $email');
      await _doFetchUsersGroups(email);
    } catch (e) {
      debugPrint('❌ [GroupProvider] Background user groups refresh failed: $e');
    }
  }

  Future<void> _doFetchUsersGroups(String email) async {
    final response = await _groupService.getUsersGroups(email);
    if (response.success && response.data != null) {
      final List<dynamic> userGroupsJson = response.data!['message'] as List<dynamic>;
      _userGroups = userGroupsJson
          .map((json) => GroupModel.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      await LocalDbHelper.saveUserGroups(_userGroups);
      _state = GroupState.success;
      debugPrint('✅ [GroupProvider] User groups API complete — ${_userGroups.length} items');
      _logger.logNetwork('✅ User groups refreshed (${_userGroups.length} items)');
    } else {
      throw Exception(response.message);
    }
    notifyListeners();
  }

  /// Remove member from group
  Future<bool> removeMember({
    required String groupId,
    required String email,
  }) async {
    _state = GroupState.loading;
    notifyListeners();
    try {
      final response = await _groupService.removeMember(
        groupId: groupId,
        email: email,
      );
      if (response.success) {
        _logger.logGeneral('✅ Member removed successfully');
        await fetchAllGroups(forceRefresh: true);
        _state = GroupState.success;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        _logger.logGeneral(
          '❌ Failed to remove member: ${response.message}',
          level: LogLevel.error,
        );
        _state = GroupState.error;
        notifyListeners();
        return false;
      }
    } catch (e, s) {
      _errorMessage = 'Failed to remove member: $e';
      _logger.error('GROUP_PROVIDER', 'removeMember failed', error: e, stackTrace: s);
      _state = GroupState.error;
      notifyListeners();
      return false;
    }
  }

  /// Add member to group
  Future<bool> addMember({
    required String groupId,
    required String email,
  }) async {
    _state = GroupState.loading;
    notifyListeners();
    try {
      final response = await _groupService.addMember(
        groupId: groupId,
        email: email,
      );
      if (response.success) {
        _logger.logGeneral('âœ… Member added successfully');
        await fetchAllGroups(forceRefresh: true);
        _state = GroupState.success;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        _logger.logGeneral(
          'âŒ Failed to add member: ${response.message}',
          level: LogLevel.error,
        );
        _state = GroupState.error;
        notifyListeners();
        return false;
      }
    } catch (e, s) {
      _errorMessage = 'Failed to add member: $e';
      _logger.error('GROUP_PROVIDER', 'addMember failed', error: e, stackTrace: s);
      _state = GroupState.error;
      notifyListeners();
      return false;
    }
  }

  /// Add admin to group
  Future<bool> addAdmin({
    required String groupId,
    required String email,
  }) async {
    _state = GroupState.loading;
    notifyListeners();
    try {
      final response = await _groupService.addAdmin(
        groupId: groupId,
        email: email,
      );
      if (response.success) {
        _logger.logGeneral('✅ Admin added successfully');
        await fetchAllGroups(forceRefresh: true);
        _state = GroupState.success;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        _logger.logGeneral(
          '❌ Failed to add admin: ${response.message}',
          level: LogLevel.error,
        );
        _state = GroupState.error;
        notifyListeners();
        return false;
      }
    } catch (e, s) {
      _errorMessage = 'Failed to add admin: $e';
      _logger.error('GROUP_PROVIDER', 'addAdmin failed', error: e, stackTrace: s);
      _state = GroupState.error;
      notifyListeners();
      return false;
    }
  }

  /// Remove admin from group
  Future<bool> removeAdmin({
    required String groupId,
    required String email,
  }) async {
    _state = GroupState.loading;
    notifyListeners();
    try {
      final response = await _groupService.removeAdmin(
        groupId: groupId,
        email: email,
      );
      if (response.success) {
        _logger.logGeneral('✅ Admin removed successfully');
        await fetchAllGroups(forceRefresh: true);
        _state = GroupState.success;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        _logger.logGeneral(
          '❌ Failed to remove admin: ${response.message}',
          level: LogLevel.error,
        );
        _state = GroupState.error;
        notifyListeners();
        return false;
      }
    } catch (e, s) {
      _errorMessage = 'Failed to remove admin: $e';
      _logger.error('GROUP_PROVIDER', 'removeAdmin failed', error: e, stackTrace: s);
      _state = GroupState.error;
      notifyListeners();
      return false;
    }
  }
}
