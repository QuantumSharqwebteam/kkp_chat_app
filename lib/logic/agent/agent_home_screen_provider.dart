import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:kkpchatapp/data/repositories/chat_reopsitory.dart';

class AgentHomeScreenProvider with ChangeNotifier {
  final _chatRepo = ChatRepository();
  final Map<String, int> _notificationCounts = {};
  final List<dynamic> _customers = [];
  String _searchQuery = "";
  bool _isLoading = false;

  List<dynamic> get customers => _customers;
  bool get isLoading => _isLoading;
  int getCount(String email) => _notificationCounts[email] ?? 0;

  List<dynamic> get filteredCustomers {
    if (_searchQuery.isEmpty) return _customers;
    return _customers
        .where((c) => c["name"]
            .toString()
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> fetchCustomers(String agentEmail) async {
    _isLoading = true;
    notifyListeners();

    try {
      final fetched = await _chatRepo.fetchAssignedCustomerList(agentEmail);
      _customers
        ..clear()
        ..addAll(fetched);
      await _loadNotificationCounts(agentEmail, fetched);
    } catch (e) {
      debugPrint("Error fetching customers: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadNotificationCounts(
      String agentEmail, List<dynamic> customers) async {
    for (var customer in customers) {
      final boxName = '$agentEmail${customer["email"]}count';
      final box = await Hive.openBox<int>(boxName);
      _notificationCounts[customer["email"]] =
          box.get('count', defaultValue: 0)!;
    }
    notifyListeners(); // Notify after loading counts
  }

  Future<void> resetCount(String agentEmail, String customerEmail) async {
    final boxName = '$agentEmail${customerEmail}count';
    final box = await Hive.openBox<int>(boxName);
    await box.put('count', 0);
    _notificationCounts[customerEmail] = 0;
    notifyListeners();
  }

  Future<void> incrementCount(String agentEmail, String customerEmail) async {
    final boxName = '$agentEmail${customerEmail}count';
    final box = await Hive.openBox<int>(boxName);
    int currentCount = box.get('count', defaultValue: 0)!;
    int newCount = currentCount + 1;
    await box.put('count', newCount);
    _notificationCounts[customerEmail] = newCount;
    notifyListeners();
  }
}
