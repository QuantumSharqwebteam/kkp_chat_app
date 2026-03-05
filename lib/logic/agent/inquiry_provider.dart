import 'package:flutter/material.dart';
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

  // ================= FILTER STATE =================

  String _searchText = '';
  String _selectedStatus = 'All';
  String _selectedDateRange = 'Last 30 days';

  // ================= GETTERS =================

  List<FormDataModel> get inquiries => _filteredInquiries;
  bool get isLoading => _isLoading;

  // ================= FETCH =================

  Future<void> fetchInquiries({String? userEmail, String? role}) async {
    _isLoading = true;
    notifyListeners();

    _userEmail = userEmail;
    _userRole = role;

    try {
      if (role == "2" || role == "3" || role == "0") {
        _allInquiries = await _chatRepository.fetchFormDataForEnquiery(userEmail!);
      } else {
        _allInquiries = await _chatRepository.fetchFormData();
      }

      /// Show ALL data initially
      _filteredInquiries = List.from(_allInquiries);
    } catch (e) {
      debugPrint("❌ Failed to fetch inquiries: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshInquiries() async {
    await fetchInquiries(userEmail: _userEmail, role: _userRole);
  }

  // ================= FILTER ACTIONS =================

  /// SEARCH (clears other filters)
  void updateSearch(String value) {
    _searchText = value;
    _selectedStatus = 'All';
    _selectedDateRange = 'Last 30 days';

    _applySearchFilter();
  }

  /// STATUS (clears other filters)
  void updateStatus(String status) {
    _selectedStatus = status;
    _searchText = '';
    _selectedDateRange = 'Last 30 days';

    _applyStatusFilter();
  }

  /// DATE RANGE (clears other filters)
  void updateDateRange(String range) {
    _selectedDateRange = range;
    _searchText = '';
    _selectedStatus = 'All';

    _applyDateFilterOnly();
  }

  /// Reset everything
  void resetAllFilters() {
    _searchText = '';
    _selectedStatus = 'All';
    _selectedDateRange = 'Last 30 days';

    _filteredInquiries = List.from(_allInquiries);
    notifyListeners();
  }

  // ================= FILTER IMPLEMENTATIONS =================

  void _applySearchFilter() {
    if (_searchText.isEmpty) {
      _filteredInquiries = List.from(_allInquiries);
    } else {
      final query = _searchText.toLowerCase();

      _filteredInquiries = _allInquiries.where((e) {
        return e.agentName.toLowerCase().contains(query) ||
            e.customerName.toLowerCase().contains(query) ||
            e.quality.toLowerCase().contains(query) ||
            e.weave.toLowerCase().contains(query) ||
            e.status.toLowerCase().contains(query) ||
            e.id.toLowerCase().contains(query);
      }).toList();
    }

    notifyListeners();
  }

  void _applyStatusFilter() {
    if (_selectedStatus == 'All') {
      _filteredInquiries = List.from(_allInquiries);
    } else {
      _filteredInquiries = _allInquiries.where((e) => e.status == _selectedStatus).toList();
    }

    notifyListeners();
  }

  void _applyDateFilterOnly() {
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

    notifyListeners();
  }
}
