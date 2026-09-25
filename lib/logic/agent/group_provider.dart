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
  Map<String, int> get groupUnreadCounts =>
      Map.unmodifiable(_groupUnreadCounts);
  Map<String, String> get groupLastMessages =>
      Map.unmodifiable(_groupLastMessages);
  Map<String, DateTime?> get groupLastMessageTimes =>
      Map.unmodifiable(_groupLastMessageTimes);
  int get totalGroupUnreadCount =>
      _groupUnreadCounts.values.fold(0, (sum, c) => sum + c);

  /// Groups ordered by most recent message first — the group that just received
  /// a message rises to the top.
  ///
  /// Derived rather than reordering [_groups] in place, so the underlying list
  /// keeps its server order and nothing else that reads `groups` is affected.
  ///
  /// Groups with no message yet sink to the bottom. Ties (and the no-message
  /// group) fall back to the original index because `List.sort` is not stable
  /// in Dart — without that tiebreaker equal entries could swap places on every
  /// rebuild and the list would visibly jitter.
  List<GroupModel> get groupsByRecentActivity {
    final originalOrder = <String, int>{};
    for (var i = 0; i < _groups.length; i++) {
      originalOrder.putIfAbsent(_groups[i].id, () => i);
    }

    final sorted = List<GroupModel>.from(_groups);
    sorted.sort((a, b) {
      final aTime = _groupLastMessageTimes[a.id];
      final bTime = _groupLastMessageTimes[b.id];
      final tiebreak =
          (originalOrder[a.id] ?? 0).compareTo(originalOrder[b.id] ?? 0);

      if (aTime == null && bTime == null) return tiebreak;
      if (aTime == null) return 1;
      if (bTime == null) return -1;

      final byRecency = bTime.compareTo(aTime);
      return byRecency != 0 ? byRecency : tiebreak;
    });
    return sorted;
  }

  static const cacheValidity = Duration(minutes: 10);

  /// `"name" (id)` when the group is loaded, otherwise just the id — so a
  /// mutation log identifies which group it was about. The bare
  /// "Group deleted successfully" lines could not be tied to anything.
  String _label(String groupId) {
    for (final group in _groups) {
      if (group.id == groupId) return '"${group.groupName}" ($groupId)';
    }
    return groupId;
  }

  // --- Unread count + last message helpers (in-memory + storage) ---

  Future<void> loadUnreadCountsFromStorage() async {
    for (final group in _groups) {
      _groupUnreadCounts[group.id] =
          await LocalDbHelper.getGroupUnreadCount(group.id);
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
  void updateGroupLastMessage(
      String groupId, String message, DateTime timestamp) {
    _groupLastMessages[groupId] = message;
    _groupLastMessageTimes[groupId] = timestamp;
    notifyListeners();
  }

  void incrementUnreadCount(String groupId) {
    _groupUnreadCounts[groupId] = (_groupUnreadCounts[groupId] ?? 0) + 1;
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
          _groups = cachedGroups;
          _state = GroupState.success;
          notifyListeners();
          await loadUnreadCountsFromStorage();
          // Last-message times drive groupsByRecentActivity. Without this the
          // cache-hit path had none, so a cached start rendered in server order
          // and only re-sorted once the background refresh landed.
          await loadLastMessagesFromStorage();
          // Don't hit the API again unless forced
          if (!ConnectivityService.instance.isOnline) {
            return;
          }
          // Background-refresh without showing loading state
          _fetchAllGroupsInBackground();
          return;
        } else {
          _state = GroupState.loading;
          notifyListeners();
        }
      } else {
        _state = GroupState.loading;
        notifyListeners();
      }

      if (!ConnectivityService.instance.isOnline) {
        // Must settle the state, not just leave it. forceRefresh sets
        // GroupState.loading up front, and the old `if (_groups.isEmpty)`
        // guard left it stuck there forever on an offline pull-to-refresh.
        _state = _groups.isEmpty ? GroupState.error : GroupState.success;
        notifyListeners();
        return;
      }

      await _doFetchAllGroups();
    } catch (e, s) {
      _errorMessage = 'Failed to fetch groups: $e';
      _logger.error('GROUP_PROVIDER', 'fetchAllGroups failed',
          error: e, stackTrace: s);
      // Same reasoning as the offline branch: never leave the state on
      // `loading` just because we still have groups to show.
      _state = _groups.isEmpty ? GroupState.error : GroupState.success;
      notifyListeners();
    }
  }

  Future<void> _fetchAllGroupsInBackground() async {
    try {
      await _doFetchAllGroups();
    } catch (e, s) {
      // Non-fatal: the cached groups are already on screen. Still reported —
      // a silent swallow here hides a persistently failing refresh.
      _logger.logNetwork(
        'Background group refresh failed: $e',
        level: LogLevel.warning,
        error: e,
        stackTrace: s,
      );
    }
  }

  Future<void> _doFetchAllGroups() async {
    final response = await _groupService.getAllGroups();
    if (response.success && response.data != null) {
      final List<dynamic> groupsJson =
          response.data!['message'] as List<dynamic>;
      _groups = groupsJson
          .map((json) => GroupModel.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      await LocalDbHelper.saveGroups(_groups);
      await loadUnreadCountsFromStorage();
      await loadLastMessagesFromStorage();
      _state = GroupState.success;
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
        _logger.logGeneral('✅ Group created: "$groupName" '
            '(${members.length} members, ${admins.length} admins)');
        await fetchAllGroups(forceRefresh: true);
        _state = GroupState.success;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        _logger.logGeneral(
          '❌ Failed to create group "$groupName": ${response.message}',
          level: LogLevel.error,
        );
        _state = GroupState.error;
        notifyListeners();
        return false;
      }
    } catch (e, s) {
      _errorMessage = 'Failed to create group: $e';
      _logger.error('GROUP_PROVIDER', 'createGroup failed',
          error: e, stackTrace: s);
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
      final label = _label(id);
      final changed = <String>[
        if (groupName != null) 'name',
        if (groupDescription != null) 'description',
        if (groupImage != null) 'image',
      ];
      final response = await _groupService.updateGroup(
        id: id,
        groupName: groupName,
        groupDescription: groupDescription,
        groupImage: groupImage,
      );
      if (response.success) {
        _logger.logGeneral('✅ Group updated: $label '
            '(${changed.isEmpty ? "no fields" : changed.join(", ")})');
        await fetchAllGroups(forceRefresh: true);
        _state = GroupState.success;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        _logger.logGeneral(
          '❌ Failed to update group $label: ${response.message}',
          level: LogLevel.error,
        );
        _state = GroupState.error;
        notifyListeners();
        return false;
      }
    } catch (e, s) {
      _errorMessage = 'Failed to update group: $e';
      _logger.error('GROUP_PROVIDER', 'updateGroup failed',
          error: e, stackTrace: s);
      _state = GroupState.error;
      notifyListeners();
      return false;
    }
  }

  /// Delete group (soft delete)
  Future<bool> deleteGroup(String id) async {
    _state = GroupState.loading;
    notifyListeners();
    // Resolved up front: fetchAllGroups() below replaces _groups, after which
    // the deleted group is gone and its name is unrecoverable for the log.
    final label = _label(id);
    _logger.logGeneral('🗑️ Deleting group $label');
    try {
      final response = await _groupService.deleteGroup(id);
      if (response.success) {
        _logger.logGeneral('✅ Group deleted: $label');
        await fetchAllGroups(forceRefresh: true);
        _state = GroupState.success;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        _logger.logGeneral(
          '❌ Failed to delete group $label: ${response.message}',
          level: LogLevel.error,
        );
        _state = GroupState.error;
        notifyListeners();
        return false;
      }
    } catch (e, s) {
      _errorMessage = 'Failed to delete group: $e';
      _logger.error('GROUP_PROVIDER', 'deleteGroup failed for $label',
          error: e, stackTrace: s);
      _state = GroupState.error;
      notifyListeners();
      return false;
    }
  }

  /// Fetch user's groups
  Future<void> fetchUsersGroups(String email,
      {bool forceRefresh = false}) async {
    try {
      // ── 1. Serve cache immediately — no shimmer if we have data ────────────
      if (!forceRefresh) {
        final cachedUserGroups = await LocalDbHelper.getUserGroups();
        if (cachedUserGroups != null && cachedUserGroups.isNotEmpty) {
          _userGroups = cachedUserGroups;
          _state = GroupState.success;
          notifyListeners();
          if (!ConnectivityService.instance.isOnline) {
            return;
          }
          _fetchUsersGroupsInBackground(email);
          return;
        } else {
          _state = GroupState.loading;
          notifyListeners();
        }
      } else {
        _state = GroupState.loading;
        notifyListeners();
      }

      if (!ConnectivityService.instance.isOnline) {
        if (_userGroups.isEmpty) _state = GroupState.error;
        notifyListeners();
        return;
      }

      await _doFetchUsersGroups(email);
    } catch (e, s) {
      _errorMessage = 'Failed to fetch user groups: $e';
      _logger.error('GROUP_PROVIDER', 'fetchUsersGroups failed',
          error: e, stackTrace: s);
      if (_userGroups.isEmpty) _state = GroupState.error;
      notifyListeners();
    }
  }

  Future<void> _fetchUsersGroupsInBackground(String email) async {
    try {
      await _doFetchUsersGroups(email);
    } catch (e, s) {
      _logger.logNetwork(
        'Background user-groups refresh failed for $email: $e',
        level: LogLevel.warning,
        error: e,
        stackTrace: s,
      );
    }
  }

  Future<void> _doFetchUsersGroups(String email) async {
    final response = await _groupService.getUsersGroups(email);
    if (response.success && response.data != null) {
      final List<dynamic> userGroupsJson =
          response.data!['message'] as List<dynamic>;
      _userGroups = userGroupsJson
          .map((json) => GroupModel.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      await LocalDbHelper.saveUserGroups(_userGroups);
      _state = GroupState.success;
      _logger
          .logNetwork('✅ User groups refreshed (${_userGroups.length} items)');
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
    // Resolved before the call — fetchAllGroups() below replaces _groups.
    final label = _label(groupId);
    try {
      final response = await _groupService.removeMember(
        groupId: groupId,
        email: email,
      );
      if (response.success) {
        _logger.logGeneral('✅ Member removed: $email from $label');
        await fetchAllGroups(forceRefresh: true);
        _state = GroupState.success;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        _logger.logGeneral(
          '❌ Failed to remove member $email from $label: ${response.message}',
          level: LogLevel.error,
        );
        _state = GroupState.error;
        notifyListeners();
        return false;
      }
    } catch (e, s) {
      _errorMessage = 'Failed to remove member: $e';
      _logger.error('GROUP_PROVIDER', 'removeMember failed: $email from $label',
          error: e, stackTrace: s);
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
    // Resolved before the call — fetchAllGroups() below replaces _groups.
    final label = _label(groupId);
    try {
      final response = await _groupService.addMember(
        groupId: groupId,
        email: email,
      );
      if (response.success) {
        _logger.logGeneral('✅ Member added: $email to $label');
        await fetchAllGroups(forceRefresh: true);
        _state = GroupState.success;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        _logger.logGeneral(
          '❌ Failed to add member $email to $label: ${response.message}',
          level: LogLevel.error,
        );
        _state = GroupState.error;
        notifyListeners();
        return false;
      }
    } catch (e, s) {
      _errorMessage = 'Failed to add member: $e';
      _logger.error('GROUP_PROVIDER', 'addMember failed: $email to $label',
          error: e, stackTrace: s);
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
    // Resolved before the call — fetchAllGroups() below replaces _groups.
    final label = _label(groupId);
    try {
      final response = await _groupService.addAdmin(
        groupId: groupId,
        email: email,
      );
      if (response.success) {
        _logger.logGeneral('✅ Admin added: $email in $label');
        await fetchAllGroups(forceRefresh: true);
        _state = GroupState.success;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        _logger.logGeneral(
          '❌ Failed to add admin $email in $label: ${response.message}',
          level: LogLevel.error,
        );
        _state = GroupState.error;
        notifyListeners();
        return false;
      }
    } catch (e, s) {
      _errorMessage = 'Failed to add admin: $e';
      _logger.error('GROUP_PROVIDER', 'addAdmin failed: $email in $label',
          error: e, stackTrace: s);
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
    // Resolved before the call — fetchAllGroups() below replaces _groups.
    final label = _label(groupId);
    try {
      final response = await _groupService.removeAdmin(
        groupId: groupId,
        email: email,
      );
      if (response.success) {
        _logger.logGeneral('✅ Admin removed: $email in $label');
        await fetchAllGroups(forceRefresh: true);
        _state = GroupState.success;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        _logger.logGeneral(
          '❌ Failed to remove admin $email in $label: ${response.message}',
          level: LogLevel.error,
        );
        _state = GroupState.error;
        notifyListeners();
        return false;
      }
    } catch (e, s) {
      _errorMessage = 'Failed to remove admin: $e';
      _logger.error('GROUP_PROVIDER', 'removeAdmin failed: $email in $label',
          error: e, stackTrace: s);
      _state = GroupState.error;
      notifyListeners();
      return false;
    }
  }
}
