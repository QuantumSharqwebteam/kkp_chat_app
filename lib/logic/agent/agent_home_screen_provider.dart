import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:kkpchatapp/core/services/connectivity_service.dart';
import 'package:kkpchatapp/core/services/socket_service.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/repositories/auth_repository.dart';

class AssignedCustomersProvider extends ChangeNotifier {
  final String agentEmail;
  final String agentName;
  final SocketService socketService;
  List<dynamic> _assignedCustomers = [];
  List<dynamic> _filteredCustomers = [];
  bool _isLoading = false;
  // Tracks whether the first load (cache or API) has completed.
  // isLoading returns true until initialized, preventing the empty-state widget
  // from flashing before cached data arrives.
  bool _isInitialized = false;
  late StreamSubscription _unreadCountsSubscription;
  late StreamSubscription _statusSubscription;
  late Box<int> _unreadCountsBox;

  AssignedCustomersProvider({
    required this.agentEmail,
    required this.agentName,
    required this.socketService,
  }) {
    fetchAssignedCustomers();
    _setupUnreadCountsListener();
    _setupStatusListener();
  }

  Future<void> _setupUnreadCountsListener() async {
    _unreadCountsBox = await Hive.openBox<int>(
        '${LocalDbHelper.unreadCountsBoxKey}_$agentEmail');
    _unreadCountsSubscription = _unreadCountsBox.watch().listen((event) async {
      await _updateUnreadCountsFromBox();
    });
  }

  void _setupStatusListener() {
    _statusSubscription = socketService.statusStream.listen((onlineUsers) {
      _handleOnlineStatusUpdate(onlineUsers);
    });
  }

  @override
  void dispose() {
    _unreadCountsSubscription.cancel();
    _statusSubscription.cancel();
    _unreadCountsBox.close();
    super.dispose();
  }

  Future<void> handleNewMessage(Map<String, dynamic> data) async {
    final senderId = data['senderId']?.toString();
    final targetId = data['targetId']?.toString();
    if (senderId == null || targetId == null) return;

    // If this is a message to our agent
    if (targetId == agentEmail) {
      // Find the customer with this senderId in our list
      final customerIndex = _assignedCustomers
          .indexWhere((c) => c['email']?.toString() == senderId);

      if (customerIndex != -1) {
        // Get the current count from Hive
        final count = await LocalDbHelper.getUnreadCount(agentEmail, senderId);

        // Update the count in our local list
        _assignedCustomers[customerIndex]['notificationCount'] = count;

        // Also update in filtered list if present
        final filteredIndex = _filteredCustomers
            .indexWhere((c) => c['email']?.toString() == senderId);
        if (filteredIndex != -1) {
          _filteredCustomers[filteredIndex]['notificationCount'] = count;
        }

        // Sort the lists again to maintain order
        _sortCustomers();

        // Notify listeners to update UI
        notifyListeners();
      }
    }
  }

  // Handle online status updates
  void _handleOnlineStatusUpdate(List<String> onlineUsers) {
    bool needsSorting = false;

    // Update online status in our local lists
    for (var customer in _assignedCustomers) {
      final email = customer['email']?.toString();
      if (email != null) {
        final wasOnline = customer['isOnline'] ?? false;
        final isOnline = onlineUsers.contains(email);

        if (wasOnline != isOnline) {
          customer['isOnline'] = isOnline;
          needsSorting = true;
        }
      }
    }

    // Also update filtered customers
    for (var customer in _filteredCustomers) {
      final email = customer['email']?.toString();
      if (email != null) {
        final wasOnline = customer['isOnline'] ?? false;
        final isOnline = onlineUsers.contains(email);

        if (wasOnline != isOnline) {
          customer['isOnline'] = isOnline;
        }
      }
    }

    // Only sort and notify if something actually changed
    if (needsSorting) {
      _sortCustomers();
      notifyListeners();
    }
  }

  Future<void> _updateUnreadCountsFromBox() async {
    bool needsUpdate = false;

    // Update counts for all customers
    for (var customer in _assignedCustomers) {
      final email = customer['email']?.toString();
      if (email != null) {
        final count = await LocalDbHelper.getUnreadCount(agentEmail, email);
        final currentCount = customer['notificationCount'] ?? 0;

        if (count != currentCount) {
          customer['notificationCount'] = count;
          needsUpdate = true;
        }
      }
    }

    // Also update filtered customers
    for (var customer in _filteredCustomers) {
      final email = customer['email']?.toString();
      if (email != null) {
        final count = await LocalDbHelper.getUnreadCount(agentEmail, email);
        customer['notificationCount'] = count;
      }
    }

    if (needsUpdate) {
      _sortCustomers();
      notifyListeners();
    }
  }

  void _sortCustomers() {
    int compare(dynamic a, dynamic b) {
      // 1. Assigned users (canMessage == true) always appear first.
      final isAAssigned = a['canMessage'] == true;
      final isBAssigned = b['canMessage'] == true;
      if (isAAssigned && !isBAssigned) return -1;
      if (!isAAssigned && isBAssigned) return 1;

      // 2. Within the same assignment group, online users next.
      final isAOnline = a['isOnline'] ?? false;
      final isBOnline = b['isOnline'] ?? false;
      if (isAOnline && !isBOnline) return -1;
      if (!isAOnline && isBOnline) return 1;

      // 3. Then by unread count descending.
      final countA = a['notificationCount'] ?? 0;
      final countB = b['notificationCount'] ?? 0;
      if (countA != countB) return countB.compareTo(countA);

      // 4. Finally by last message time descending.
      final timeA = a['lastMessageTime'] ?? DateTime.fromMillisecondsSinceEpoch(0);
      final timeB = b['lastMessageTime'] ?? DateTime.fromMillisecondsSinceEpoch(0);
      return timeB.compareTo(timeA);
    }

    _assignedCustomers.sort(compare);
    _filteredCustomers.sort(compare);
  }

  Future<void> fetchAssignedCustomers() async {
    // ── 1. Synchronous cache read — no yield before first notifyListeners ─────
    // getAssignedCustomers() is synchronous (_box.get on an already-open box).
    // We set _isInitialized = true and notify BEFORE any await so the widget
    // builds with real data on the very first frame — zero shimmer for
    // returning users.
    final cached = LocalDbHelper.getAssignedCustomers(agentEmail);
    if (cached.isNotEmpty) {
      debugPrint('📦 [AssignedCustomers] Cache HIT — ${cached.length} customers (instant, no shimmer)');
      _assignedCustomers = List.from(cached);
      _filteredCustomers = List.from(cached);
      _sortCustomers();
      _isInitialized = true;
      notifyListeners(); // ← data on frame 1, before any await
      // Enrich silently: unread counts, online status, last-message time
      await _applyLocalState(cached);
      _assignedCustomers = List.from(cached);
      _filteredCustomers = List.from(cached);
      _sortCustomers();
      notifyListeners();
    } else {
      debugPrint('📭 [AssignedCustomers] Cache MISS — showing shimmer until API returns');
      _isLoading = true;
      _isInitialized = true;
      notifyListeners();
    }

    // ── 2. Background-fetch from API only when online ────────────────────────
    if (!ConnectivityService.instance.isOnline) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final raw = await AuthRepository().fetchUsersByRole('User');
      // Keep only active users; strip large/sensitive server fields before
      // caching so jsonEncode stays small and never leaks credentials.
      final customers = raw
          .where((u) => u['isDeleted'] != true)
          .map((u) {
            final m = Map<String, dynamic>.from(u as Map);
            m.remove('password');
            m.remove('activeToken');
            m.remove('token'); // FCM token — sensitive, large
            // Whether this agent is the assigned agent for this user.
            m['canMessage'] = (m['agentId']?.toString() ?? '') == agentEmail;
            return m;
          })
          .toList();
      // Save raw (stripped) data BEFORE _applyLocalState enriches it with
      // DateTime/bool/int fields that jsonEncode cannot serialize.
      await LocalDbHelper.saveAssignedCustomers(agentEmail, customers);
      await _applyLocalState(customers);
      _assignedCustomers = List.from(customers);
      _filteredCustomers = List.from(customers);
      _sortCustomers();
    } catch (e) {
      debugPrint("Error fetching assigned customers: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Called by AgentHomeScreen when a chat message arrives while the agent is
  /// inside a chat screen. Re-applies local Hive state (last message, unread
  /// counts, timestamps) from the cache that the socket service already wrote —
  /// no API call, no shimmer, no full reload.
  Future<void> refreshFromSocket() async {
    if (_assignedCustomers.isEmpty) return;
    final snapshot = List<dynamic>.from(_assignedCustomers);
    await _applyLocalState(snapshot);
    _assignedCustomers = snapshot;
    _filteredCustomers = List.from(snapshot);
    _sortCustomers();
    notifyListeners();
  }

  /// Enriches each customer map with online status, unread count, last message
  /// and last-message time — all sourced from local storage / socket state.
  Future<void> _applyLocalState(List<dynamic> customers) async {
    final onlineUsers = socketService.onlineUsers;
    for (var customer in customers) {
      final email = customer['email']?.toString();
      if (email == null) continue;
      customer['isOnline'] = onlineUsers.contains(email);
      customer['notificationCount'] =
          await LocalDbHelper.getUnreadCount(agentEmail, email) ?? 0;
      customer['lastMessage'] =
          LocalDbHelper.getLastMessage(email) ?? 'last message';
      try {
        final timeBox =
            await Hive.openBox<String>('$agentEmail${email}lastMessageTime');
        final timeStr = timeBox.get('lastMessageTime');
        customer['lastMessageTime'] =
            timeStr != null ? DateTime.tryParse(timeStr) : null;
      } catch (_) {
        customer['lastMessageTime'] = null;
      }
    }
  }

  Future<void> resetNotificationCount(String customerEmail) async {
    // Clear count in both boxes for consistency
    await LocalDbHelper.clearUnreadCount(agentEmail, customerEmail);

    try {
      final boxName = '$agentEmail${customerEmail}count';
      final box = await Hive.openBox<int>(boxName);
      await box.put('count', 0);
    } catch (e) {
      debugPrint("Error resetting notification count: $e");
    }

    // Update local lists
    final index = _assignedCustomers
        .indexWhere((c) => c['email']?.toString() == customerEmail);
    if (index != -1) {
      _assignedCustomers[index]['notificationCount'] = 0;
    }
    final filteredIndex = _filteredCustomers
        .indexWhere((c) => c['email']?.toString() == customerEmail);
    if (filteredIndex != -1) {
      _filteredCustomers[filteredIndex]['notificationCount'] = 0;
    }

    // Resort since notification count affects ordering
    _sortCustomers();
    notifyListeners();
  }

  // Public methods
  List<dynamic> get assignedCustomers => _assignedCustomers;
  List<dynamic> get filteredCustomers => _filteredCustomers;
  // Returns true until the first load (cache or API) completes, preventing the
  // empty-state widget from flashing before cached data has been applied.
  bool get isLoading => !_isInitialized || _isLoading;

  void updateSearchQuery(String query) {
    final lowerQuery = query.toLowerCase();
    _filteredCustomers = _assignedCustomers.where((customer) {
      final name = customer["name"]?.toString().toLowerCase() ?? '';
      return name.contains(lowerQuery);
    }).toList();
    notifyListeners();
  }
}
