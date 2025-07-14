import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:kkpchatapp/core/services/socket_service.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/repositories/chat_reopsitory.dart';

class AssignedCustomersProvider extends ChangeNotifier {
  final String agentEmail;
  final String agentName;
  final SocketService socketService;
  List<dynamic> _assignedCustomers = [];
  List<dynamic> _filteredCustomers = [];
  bool _isLoading = true;
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
    _unreadCountsBox = await Hive.openBox<int>('${LocalDbHelper.unreadCountsBoxKey}_$agentEmail');
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

  Future<void> _handleNewMessage(Map<String, dynamic> data) async {
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
    _assignedCustomers.sort((a, b) {
      final isAOnline = a['isOnline'] ?? false;
      final isBOnline = b['isOnline'] ?? false;
      if (isAOnline && !isBOnline) return -1;
      if (!isAOnline && isBOnline) return 1;

      // Also consider unread counts in sorting
      final countA = a['notificationCount'] ?? 0;
      final countB = b['notificationCount'] ?? 0;
      if (countA != countB) return countB.compareTo(countA);

      final timeA = a['lastMessageTime'] ?? DateTime.fromMillisecondsSinceEpoch(0);
      final timeB = b['lastMessageTime'] ?? DateTime.fromMillisecondsSinceEpoch(0);
      return timeB.compareTo(timeA);
    });

    _filteredCustomers.sort((a, b) {
      final isAOnline = a['isOnline'] ?? false;
      final isBOnline = b['isOnline'] ?? false;
      if (isAOnline && !isBOnline) return -1;
      if (!isAOnline && isBOnline) return 1;

      // Also consider unread counts in sorting
      final countA = a['notificationCount'] ?? 0;
      final countB = b['notificationCount'] ?? 0;
      if (countA != countB) return countB.compareTo(countA);

      final timeA = a['lastMessageTime'] ?? DateTime.fromMillisecondsSinceEpoch(0);
      final timeB = b['lastMessageTime'] ?? DateTime.fromMillisecondsSinceEpoch(0);
      return timeB.compareTo(timeA);
    });
  }

  Future<void> fetchAssignedCustomers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final chatRepo = ChatRepository();
      final customers = await chatRepo.fetchAssignedCustomerList(agentEmail);
      final onlineUsers = socketService.onlineUsers; // Get current online status

      for (var customer in customers) {
        final email = customer['email']?.toString();
        if (email == null) continue;

        // Initialize isOnline flag
        customer['isOnline'] = onlineUsers.contains(email);

        // Get count from the central unread box
        final count = await LocalDbHelper.getUnreadCount(agentEmail, email);
        customer['notificationCount'] = count;

        // Open the time box for this customer
        try {
          final timeBox = await Hive.openBox<String>('$agentEmail${email}lastMessageTime');
          final timeStr = timeBox.get('lastMessageTime');
          final lastTime = timeStr != null ? DateTime.tryParse(timeStr) : null;
          customer['lastMessageTime'] = lastTime;
        } catch (e) {
          debugPrint("Error opening time box for $email: $e");
          customer['lastMessageTime'] = null;
        }

        // Get the last message
        final lastMessage = LocalDbHelper.getLastMessage(email);
        customer['lastMessage'] = lastMessage ?? "last message";
      }

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
  bool get isLoading => _isLoading;

  void updateSearchQuery(String query) {
    final lowerQuery = query.toLowerCase();
    _filteredCustomers = _assignedCustomers.where((customer) {
      final name = customer["name"]?.toString().toLowerCase() ?? '';
      return name.contains(lowerQuery);
    }).toList();
    notifyListeners();
  }
}
