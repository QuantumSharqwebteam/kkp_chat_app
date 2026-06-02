import 'package:flutter/material.dart';
import 'package:kkpchatapp/core/services/logging_service.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/models/form_data_model.dart';
import 'package:kkpchatapp/data/repositories/chat_reopsitory.dart';

class InquiryProvider with ChangeNotifier {
  final ChatRepository _chatRepository;

  InquiryProvider(this._chatRepository);

  /// Master list (never filtered)
  List<FormDataModel> _allInquiries = [];

  /// UI list
  List<FormDataModel> _filteredInquiries = [];

  bool _isLoading = false;
  String? _userEmail;
  String? _userRole;
  String _cacheKey = 'all_forms';

  // ================= FILTER STATE =================
  String _searchText = '';
  String _selectedStatus = 'All';
  String _selectedDateRange = 'All';
  bool _searchFilterActive = false;
  bool _statusFilterActive = false;
  bool _dateFilterActive = false;

  // ================= GETTERS =================
  List<FormDataModel> get inquiries => _filteredInquiries;
  bool get hasAnyInquiries => _allInquiries.isNotEmpty;
  bool get isLoading => _isLoading;
  String get selectedStatus => _selectedStatus;
  String get selectedDateRange => _selectedDateRange;
  bool get isStatusFilterActive => _statusFilterActive;
  bool get isDateFilterActive => _dateFilterActive;
  bool get isSearchActive => _searchFilterActive;

  // ================= FETCH =================
  Future<void> fetchInquiries({
    String? userEmail,
    String? role,
    bool forceRefresh = false,
  }) async {
    _isLoading = true;
    notifyListeners();

    _userEmail = userEmail;
    _userRole = role;
    final cacheKey = userEmail ?? 'all_forms';
    _cacheKey = cacheKey;

    if (!forceRefresh) {
      final cached = await LocalDbHelper.getInquiryForms(cacheKey);
      if (cached.isNotEmpty) {
        _allInquiries = _sortByStatus(cached);
        _filteredInquiries = List.from(_allInquiries);
        LoggingService.instance
            .logNetwork('Loaded ${cached.length} cached inquiry forms for $cacheKey');
        notifyListeners();
      }
    }

    try {
      LoggingService.instance.logNetwork('Fetching inquiry forms for $cacheKey');
      final fetched = (role == "2" || role == "3" || role == "0") && userEmail != null
          ? await _chatRepository.fetchFormDataForEnquiery(userEmail)
          : await _chatRepository.fetchFormData();

      _allInquiries = _sortByStatus(fetched);
      _filteredInquiries = List.from(_allInquiries);
      await LocalDbHelper.saveInquiryForms(cacheKey, _allInquiries);
      LoggingService.instance.logNetwork('Fetched ${fetched.length} inquiry forms for $cacheKey');
    } catch (e, stack) {
      LoggingService.instance.logNetwork(
        'Failed to fetch inquiry forms for $cacheKey: $e',
        level: LogLevel.error,
        error: e,
        stackTrace: stack,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshInquiries() async {
    await fetchInquiries(userEmail: _userEmail, role: _userRole, forceRefresh: true);
  }

  // ================= FILTER ACTIONS =================
  void updateSearch(String value) {
    _searchText = value;
    _searchFilterActive = value.trim().isNotEmpty;
    _statusFilterActive = false;
    _dateFilterActive = false;
    _selectedStatus = 'All';
    _selectedDateRange = 'All';
    _applySearchFilter();
  }

  void updateStatus(String status) {
    _selectedStatus = status;
    _statusFilterActive = status.toLowerCase() != 'all';
    _searchFilterActive = false;
    _dateFilterActive = false;
    _searchText = '';
    _selectedDateRange = 'All';
    _applyStatusFilter();
  }

  void updateDateRange(String range) {
    _selectedDateRange = range;
    _dateFilterActive = range.toLowerCase() != 'all';
    _searchFilterActive = false;
    _statusFilterActive = false;
    _searchText = '';
    _selectedStatus = 'All';
    _applyDateFilterOnly();
  }

  void resetAllFilters() {
    _searchText = '';
    _selectedStatus = 'All';
    _selectedDateRange = 'All';
    _searchFilterActive = false;
    _statusFilterActive = false;
    _dateFilterActive = false;
    _filteredInquiries = _sortByStatus(List.from(_allInquiries));
    notifyListeners();
  }

  // ================= FILTER IMPLEMENTATIONS =================
  void _applySearchFilter() {
    if (_searchText.isEmpty) {
      _filteredInquiries = List.from(_allInquiries);
    } else {
      final query = _searchText.toLowerCase();
      _filteredInquiries = _allInquiries.where((e) {
        final searchableValues = [
          e.date,
          e.quality,
          e.weave,
          e.quantity,
          e.composition,
          e.rate,
          e.agentName,
          e.customerName,
          e.buyerName,
          e.status,
          e.reason,
          e.id,
          e.orderId,
        ];

        return searchableValues.any((value) => value.toLowerCase().contains(query));
      }).toList();
    }
    _filteredInquiries = _sortByStatus(_filteredInquiries);
    notifyListeners();
  }

  void _applyStatusFilter() {
    if (_selectedStatus.toLowerCase() == 'all') {
      _filteredInquiries = List.from(_allInquiries);
    } else {
      final target = _selectedStatus.toLowerCase();
      _filteredInquiries = _allInquiries
          .where((e) => e.status.trim().toLowerCase() == target)
          .toList();
    }
    _filteredInquiries = _sortByStatus(_filteredInquiries);
    notifyListeners();
  }

  void _applyDateFilterOnly() {
    if (_selectedDateRange.toLowerCase() == 'all') {
      _filteredInquiries = List.from(_allInquiries);
      _filteredInquiries = _sortByStatus(_filteredInquiries);
      notifyListeners();
      return;
    }

    final now = DateTime.now().toLocal();
    _filteredInquiries = _allInquiries.where((e) {
      final date = DateTime.tryParse(e.date);
      if (date == null) return false;
      switch (_selectedDateRange) {
        case 'Today':
          return date.year == now.year && date.month == now.month && date.day == now.day;
        case 'Last Week':
          return date.isAfter(now.subtract(const Duration(days: 7)));
        case 'Last Month':
        case 'Last 30 days':
          return date.isAfter(now.subtract(const Duration(days: 30)));
        default:
          return true;
      }
    }).toList();
    _filteredInquiries = _sortByStatus(_filteredInquiries);
    notifyListeners();
  }

  void _applyActiveFilters() {
    if (_searchFilterActive) {
      _applySearchFilter();
      return;
    }
    if (_statusFilterActive) {
      _applyStatusFilter();
      return;
    }
    if (_dateFilterActive) {
      _applyDateFilterOnly();
      return;
    }

    _filteredInquiries = _sortByStatus(List.from(_allInquiries));
    notifyListeners();
  }

  List<FormDataModel> _sortByStatus(List<FormDataModel> data) {
    final priority = {
      'processed': 0,
      'confirmed': 1,
      'declined': 2,
    };
    final sorted = List<FormDataModel>.from(data);
    sorted.sort((a, b) {
      final pa = priority[a.status.toLowerCase()] ?? 3;
      final pb = priority[b.status.toLowerCase()] ?? 3;
      if (pa != pb) return pa.compareTo(pb);
      final dateA = DateTime.tryParse(a.date) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateB = DateTime.tryParse(b.date) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dateB.compareTo(dateA);
    });
    return sorted;
  }

  Future<void> updateFormStatus(String formId, String status, {String? reason}) async {
    try {
      await _chatRepository.updateInquiryFormStatus(formId, status, reason: reason);
      LoggingService.instance.logNetwork('Inquiry $formId status updated to $status');
      _applyFieldUpdates(formId, {
        'status': status,
        'reason': status.toLowerCase() == 'declined' ? (reason ?? '').trim() : '',
      });
      await _persistCache();
    } catch (e, stack) {
      LoggingService.instance.logNetwork(
        'Failed to update inquiry $formId status: $e',
        level: LogLevel.error,
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<void> updateFormRate(String formId, String rate) async {
    try {
      await _chatRepository.updateInquiryFormRate(formId, rate);
      LoggingService.instance.logNetwork('Inquiry $formId rate updated to $rate');
      _applyFieldUpdates(formId, {'rate': rate});
      await _persistCache();
    } catch (e, stack) {
      LoggingService.instance.logNetwork(
        'Failed to update inquiry $formId rate: $e',
        level: LogLevel.error,
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<void> updateFormDetails(String formId, Map<String, dynamic> updates) async {
    if (updates.isEmpty) return;
    try {
      await _chatRepository.updateInquiryForm(formId, updates);
      LoggingService.instance.logNetwork('Inquiry $formId details updated');
      _applyFieldUpdates(formId, updates);
      await _persistCache();
    } catch (e, stack) {
      LoggingService.instance.logNetwork(
        'Failed to update inquiry $formId details: $e',
        level: LogLevel.error,
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  void _applyFieldUpdates(String formId, Map<String, dynamic> updates) {
    final index = _allInquiries.indexWhere((form) => form.id == formId);
    if (index == -1) return;

    final current = _allInquiries[index];
    final updated = current.copyWith(
      date: updates['date']?.toString(),
      quality: updates['quality']?.toString(),
      weave: updates['weave']?.toString(),
      quantity: updates['quantity']?.toString(),
      composition: updates['composition']?.toString(),
      rate: updates['rate']?.toString(),
      agentName: updates['agentName']?.toString(),
      customerName: updates['customerName']?.toString(),
      buyerName: updates['buyerName']?.toString(),
      status: updates['status']?.toString(),
      reason: updates['reason']?.toString(),
      orderId: updates['orderId']?.toString(),
      id: updates['_id']?.toString() ?? updates['id']?.toString(),
    );
    _allInquiries[index] = updated;
    _applyActiveFilters();
  }

  Future<void> _persistCache() async {
    await LocalDbHelper.saveInquiryForms(_cacheKey, _allInquiries);
  }
}
