import 'package:flutter/material.dart';
import 'package:kkpchatapp/core/services/connectivity_service.dart';
import 'package:kkpchatapp/data/models/complaint_model.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/complaint_repository.dart';

enum DataStatus { loading, successful, failed, reloading }

class ComplaintsProvider extends ChangeNotifier {
  List<ComplaintModel>? complaints;
  DataStatus status = DataStatus.loading;
  final _complaintRepository = ComplaintRepository();
  bool complaintSubmitting = false;

  Future<void> loaddata() async {
    if (status == DataStatus.loading || status == DataStatus.reloading) {
      if (!ConnectivityService.instance.isOnline) {
        debugPrint('📴 [ComplaintsProvider] Offline — skipping fetch'
            '${complaints != null ? " (${complaints!.length} cached items available)" : ", no cache"}');
        status = complaints != null ? DataStatus.successful : DataStatus.failed;
        notifyListeners();
        return;
      }
      debugPrint('🌐 [ComplaintsProvider] Fetching complaints from API');
      try {
        if (status == DataStatus.reloading) {
          notifyListeners();
        }
        complaints = await _complaintRepository.getAllComplaints();
        debugPrint('✅ [ComplaintsProvider] Loaded ${complaints?.length ?? 0} complaints');
        status = DataStatus.successful;
        notifyListeners();
      } catch (e) {
        debugPrint('❌ [ComplaintsProvider] Fetch failed: $e');
        status = DataStatus.failed;
        notifyListeners();
      }
    }
  }

  Future<bool> submitComplaint({required String subject, required String description}) async {
    complaintSubmitting = true;
    notifyListeners();
    try {
      final result =
          await _complaintRepository.submitComplaint(subject: subject, description: description);
      return result;
    } catch (_) {
      return false;
    } finally {
      complaintSubmitting = false;
      notifyListeners();
    }
  }
}

final marketingComplaintsProvider = ChangeNotifierProvider<ComplaintsProvider>(
  create: (context) => ComplaintsProvider(),
);
