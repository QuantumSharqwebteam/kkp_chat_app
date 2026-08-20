import 'package:flutter/material.dart';
import 'package:kkpchatapp/core/services/connectivity_service.dart';
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
    _userEmail = userEmail;
    _userRole = role;
    final cacheKey = userEmail ?? 'all_forms';
    _cacheKey = cacheKey;

    // ── 1. Serve cache immediately — no shimmer if we have data ──────────────
    if (!forceRefresh) {
      final cached = await LocalDbHelper.getInquiryForms(cacheKey);
      if (cached.isNotEmpty) {
        _allInquiries = cached;
        _applyActiveFilters();
        LoggingService.instance.logNetwork(
          'Loaded ${cached.length} cached inquiry forms for $cacheKey',
        );
      }
    }

    try {
      LoggingService.instance.logNetwork(
        'Fetching inquiry forms for $cacheKey',
      );
      final fetched =
          (role == "2" || role == "3" || role == "0") && userEmail != null
          ? await _chatRepository.fetchFormDataForEnquiery(userEmail)
          : await _chatRepository.fetchFormData();

      _allInquiries = fetched;
      _applyActiveFilters();
      await LocalDbHelper.saveInquiryForms(cacheKey, _allInquiries);
      LoggingService.instance.logNetwork(
        'Fetched ${fetched.length} inquiry forms for $cacheKey',
      );
    } catch (e, stack) {
      debugPrint('❌ [InquiryProvider] API fetch failed for $cacheKey: $e');
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
    await fetchInquiries(
      userEmail: _userEmail,
      role: _userRole,
      forceRefresh: true,
    );
  }

  // ================= FILTER ACTIONS =================
  void updateSearch(String value) {
    _searchText = value;
    _searchFilterActive = value.trim().isNotEmpty;
    _applyActiveFilters();
  }

  void updateStatus(String status) {
    _selectedStatus = status;
    _statusFilterActive = status.toLowerCase() != 'all';
    _applyActiveFilters();
  }

  void updateDateRange(String range) {
    _selectedDateRange = range;
    _dateFilterActive = range.toLowerCase() != 'all';
    _applyActiveFilters();
  }

  void applyFilters({String? dateRange, String? status, String? search}) {
    if (dateRange != null) {
      _selectedDateRange = dateRange;
      _dateFilterActive = dateRange.toLowerCase() != 'all';
    }
    if (status != null) {
      _selectedStatus = status;
      _statusFilterActive = status.toLowerCase() != 'all';
    }
    if (search != null) {
      _searchText = search;
      _searchFilterActive = search.trim().isNotEmpty;
    }
    _applyActiveFilters();
  }

  void resetAllFilters() {
    _searchText = '';
    _selectedStatus = 'All';
    _selectedDateRange = 'All';
    _searchFilterActive = false;
    _statusFilterActive = false;
    _dateFilterActive = false;
    _applyActiveFilters();
  }

  // ================= FILTER IMPLEMENTATION =================
  void _applyActiveFilters() {
    final now = DateTime.now().toLocal();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    _filteredInquiries = _allInquiries.where((e) {
      bool matchesStatus = true;
      if (_statusFilterActive && _selectedStatus.toLowerCase() != 'all') {
        matchesStatus =
            e.status.trim().toLowerCase() ==
            _selectedStatus.trim().toLowerCase();
      }

      bool matchesDate = true;
      if (_dateFilterActive && _selectedDateRange.toLowerCase() != 'all') {
        DateTime? date = DateTime.tryParse(e.date);

        if (date == null && e.date.isNotEmpty) {
          final cleanDate = e.date.trim();
          final delimiter = cleanDate.contains('/')
              ? '/'
              : (cleanDate.contains('-') ? '-' : null);
          if (delimiter != null) {
            try {
              final parts = cleanDate.split(delimiter);
              if (parts.length == 3) {
                if (parts[0].length <= 2 && parts[2].length == 4) {
                  final day = int.parse(parts[0]);
                  final month = int.parse(parts[1]);
                  final year = int.parse(parts[2]);
                  date = DateTime(year, month, day);
                } else if (parts[0].length == 4 && parts[2].length <= 2) {
                  final year = int.parse(parts[0]);
                  final month = int.parse(parts[1]);
                  final day = int.parse(parts[2]);
                  date = DateTime(year, month, day);
                }
              }
            } catch (_) {}
          }
        }

        if (date == null) {
          matchesDate = true;
        } else {
          final normalizedDate = date.toLocal();

          switch (_selectedDateRange) {
            case 'Today':
              matchesDate =
                  normalizedDate.isAfter(
                    todayStart.subtract(const Duration(milliseconds: 1)),
                  ) &&
                  normalizedDate.isBefore(todayEnd);
              break;
            case 'Last Week':
              final sevenDaysAgo = todayStart.subtract(const Duration(days: 7));
              matchesDate =
                  normalizedDate.isAfter(sevenDaysAgo) ||
                  normalizedDate.isAtSameMomentAs(sevenDaysAgo);
              break;
            case 'Last Month':
            case 'Last 30 days':
              final thirtyDaysAgo = todayStart.subtract(
                const Duration(days: 30),
              );
              matchesDate =
                  normalizedDate.isAfter(thirtyDaysAgo) ||
                  normalizedDate.isAtSameMomentAs(thirtyDaysAgo);
              break;
            default:
              matchesDate = true;
              break;
          }
        }
      }

      // 3. Search Query Check
      bool matchesSearch = true;
      if (_searchFilterActive && _searchText.trim().isNotEmpty) {
        final query = _searchText.toLowerCase();
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
        matchesSearch = searchableValues.any(
          (value) => value.toLowerCase().contains(query),
        );
      }

      return matchesStatus && matchesDate && matchesSearch;
    }).toList();

    _filteredInquiries = _sortByStatus(_filteredInquiries);
    notifyListeners();
  }

  List<FormDataModel> _sortByStatus(List<FormDataModel> data) {
    final priority = {'processed': 0, 'confirmed': 1, 'declined': 2};
    final sorted = List<FormDataModel>.from(data);
    sorted.sort((a, b) {
      final pa = priority[a.status.toLowerCase()] ?? 3;
      final pb = priority[b.status.toLowerCase()] ?? 3;
      if (pa != pb) return pa.compareTo(pb);
      final dateA =
          DateTime.tryParse(a.date) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateB =
          DateTime.tryParse(b.date) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dateB.compareTo(dateA);
    });
    return sorted;
  }

  // ================= MUTATIONS =================
  Future<void> updateFormStatus(
    String formId,
    String status, {
    String? reason,
  }) async {
    try {
      await _chatRepository.updateInquiryFormStatus(
        formId,
        status,
        reason: reason,
      );
      LoggingService.instance.logNetwork(
        'Inquiry $formId status updated to $status',
      );
      _applyFieldUpdates(formId, {
        'status': status,
        'reason': status.toLowerCase() == 'declined'
            ? (reason ?? '').trim()
            : '',
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
      LoggingService.instance.logNetwork(
        'Inquiry $formId rate updated to $rate',
      );
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

  Future<void> updateFormDetails(
    String formId,
    Map<String, dynamic> updates,
  ) async {
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
