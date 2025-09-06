import 'package:flutter/material.dart';
import 'package:kkpchatapp/data/models/form_data_model.dart';
import 'package:kkpchatapp/data/repositories/chat_reopsitory.dart';

class InquiryProvider with ChangeNotifier {
  final ChatRepository _chatRepository;
  List<FormDataModel> _inquiries = [];
  bool _isLoading = true;
  String? _userEmail;
  String? _userRole;

  InquiryProvider(this._chatRepository);

  List<FormDataModel> get inquiries => _inquiries;
  bool get isLoading => _isLoading;

  Future<void> fetchInquiries({String? userEmail, String? role}) async {
    _isLoading = true;
    notifyListeners();

    // Store the user email and role for refreshing
    _userEmail = userEmail;
    _userRole = role;

    try {
      if (role == "2" || role == "3" || role == "0") {
        _inquiries = await _chatRepository.fetchFormDataForEnquiery(userEmail!);
      } else if (role == "1") {
        _inquiries = await _chatRepository.fetchFormData();
      }
    } catch (e) {
      debugPrint("Failed to fetch inquiries: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Call this method whenever a form is updated (e.g., status, rate, etc.)
  Future<void> refreshInquiries() async {
    // Use the stored user email and role
    await fetchInquiries(userEmail: _userEmail, role: _userRole);
  }
}
