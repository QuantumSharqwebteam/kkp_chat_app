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
  bool _disposed = false;
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

  /// True once dispose() has run. Every notifyListeners() in this provider is
  /// reached from an async continuation, so without this a screen that pops
  /// while a fetch is in flight crashes with "used after being disposed".
  bool get isDisposed => _disposed;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  // ================= FETCH =================
  Future<void> fetchInquiries({
    String? userEmail,
    String? role,
    bool forceRefresh = false,
  }) async {
    if (_disposed) return;
    _userEmail = userEmail;
    _userRole = role;
    final cacheKey = userEmail ?? 'all_forms';
    _cacheKey = cacheKey;

    // ── 1. Serve cache immediately — no shimmer if we have data ──────────────
    var servedFromCache = false;
    if (!forceRefresh) {
      final cached = await LocalDbHelper.getInquiryForms(cacheKey);
      if (_disposed) return;
      if (cached.isNotEmpty) {
        _allInquiries = cached;
        servedFromCache = true;
        _isLoading = false;
        _applyActiveFilters();
        LoggingService.instance.logNetwork(
          'Loaded ${cached.length} cached inquiry forms for $cacheKey',
        );
      }
    }

    // Only show the loader on a genuinely cold cache.
    if (!servedFromCache && _allInquiries.isEmpty) {
      _isLoading = true;
      _safeNotify();
    }

    try {
      final fetched =
          (role == "2" || role == "3" || role == "0") && userEmail != null
              ? await _chatRepository.fetchFormDataForEnquiery(userEmail)
              : await _chatRepository.fetchFormData();

      if (_disposed) return;

      _allInquiries = fetched;
      _applyActiveFilters();
      await LocalDbHelper.saveInquiryForms(cacheKey, _allInquiries);
      LoggingService.instance.logNetwork(
        'Fetched ${fetched.length} inquiry forms for $cacheKey',
      );
    } catch (e, stack) {
      LoggingService.instance.logNetwork(
        'Failed to fetch inquiry forms for $cacheKey: $e',
        level: LogLevel.error,
        error: e,
        stackTrace: stack,
      );
    } finally {
      _isLoading = false;
      _safeNotify();
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
    if (_disposed) return;
    final now = DateTime.now().toLocal();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    _filteredInquiries = _allInquiries.where((e) {
      bool matchesStatus = true;
      if (_statusFilterActive && _selectedStatus.toLowerCase() != 'all') {
        matchesStatus = e.status.trim().toLowerCase() ==
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
              matchesDate = normalizedDate.isAfter(
                    todayStart.subtract(const Duration(milliseconds: 1)),
                  ) &&
                  normalizedDate.isBefore(todayEnd);
              break;
            case 'Last Week':
              final sevenDaysAgo = todayStart.subtract(const Duration(days: 7));
              matchesDate = normalizedDate.isAfter(sevenDaysAgo) ||
                  normalizedDate.isAtSameMomentAs(sevenDaysAgo);
              break;
            case 'Last Month':
            case 'Last 30 days':
              final thirtyDaysAgo = todayStart.subtract(
                const Duration(days: 30),
              );
              matchesDate = normalizedDate.isAfter(thirtyDaysAgo) ||
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

    _filteredInquiries = _sortLatestFirst(_filteredInquiries);
    _safeNotify();
  }

  /// Newest inquiry first.
  ///
  /// Status used to be the primary key (processed → confirmed → declined) with
  /// date only breaking ties, which pushed old processed inquiries above
  /// today's. Date now dominates; an unparseable date sinks to the bottom
  /// rather than sorting as the epoch and jumping to the end unpredictably.
  List<FormDataModel> _sortLatestFirst(List<FormDataModel> data) {
    final sorted = List<FormDataModel>.from(data);
    sorted.sort((a, b) {
      final dateA = DateTime.tryParse(a.date);
      final dateB = DateTime.tryParse(b.date);
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
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
        'reason':
            status.toLowerCase() == 'declined' ? (reason ?? '').trim() : '',
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
      final response = await _chatRepository.updateInquiryForm(formId, updates);
      LoggingService.instance.logNetwork('Inquiry $formId details updated');
      _warnAboutDroppedFields(formId, updates, response);
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

  /// The server echoes the stored form back as `updatedMessage.form[0]`.
  /// Anything we submitted that is missing from that document was accepted with
  /// a 200 but not actually persisted — the update will appear to work and then
  /// revert on the next fetch. Naming those fields makes that visible instead
  /// of silent.
  void _warnAboutDroppedFields(
    String formId,
    Map<String, dynamic> updates,
    Map<String, dynamic> response,
  ) {
    final stored = _storedFormFrom(response);
    if (stored == null) return;

    final dropped =
        updates.keys.where((key) => !stored.containsKey(key)).toList();
    if (dropped.isEmpty) return;

    LoggingService.instance.logNetwork(
      'Inquiry $formId: server returned 200 but did not persist '
      '${dropped.join(', ')} — these keys are absent from the form it echoed '
      'back, so they will revert on the next fetch.',
      level: LogLevel.warning,
    );
  }

  /// Pulls `updatedMessage.form[0]` (or `updatedMessage.form`) out of an update
  /// response, tolerating both the list and single-object shapes.
  static Map<String, dynamic>? _storedFormFrom(Map<String, dynamic> response) {
    final message = response['updatedMessage'];
    if (message is! Map) return null;
    final form = message['form'];
    if (form is List) {
      if (form.isEmpty) return null;
      final first = form.first;
      return first is Map ? Map<String, dynamic>.from(first) : null;
    }
    if (form is Map) return Map<String, dynamic>.from(form);
    return null;
  }

  void _applyFieldUpdates(String formId, Map<String, dynamic> updates) {
    final index = _allInquiries.indexWhere((form) => form.id == formId);
    if (index == -1) return;

    // Normalize exactly as FormDataModel.fromJson does — otherwise an edited
    // row (e.g. buyerName left as the backend's "Unknown Buyer" placeholder)
    // renders differently from the same row after a refetch.
    String? field(String key) =>
        updates.containsKey(key) ? FormDataModel.normalize(updates[key]) : null;

    final current = _allInquiries[index];
    final updated = current.copyWith(
      date: field('date'),
      quality: field('quality'),
      weave: field('weave'),
      quantity: field('quantity'),
      composition: field('composition'),
      rate: field('rate'),
      agentName: field('agentName'),
      customerName: field('customerName'),
      buyerName: field('buyerName'),
      status: field('status'),
      reason: field('reason'),
      orderId: field('orderId'),
      id: field('_id') ?? field('id'),
    );
    _allInquiries[index] = updated;
    _applyActiveFilters();
  }

  Future<void> _persistCache() async {
    await LocalDbHelper.saveInquiryForms(_cacheKey, _allInquiries);
  }
}
