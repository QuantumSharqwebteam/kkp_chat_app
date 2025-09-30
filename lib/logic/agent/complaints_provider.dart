import 'package:flutter/material.dart';
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
      try {
        if (status == DataStatus.reloading) {
          notifyListeners();
        }
        complaints = await _complaintRepository.getAllComplaints();
        status = DataStatus.successful;
        notifyListeners();
      } catch (e) {
        status = DataStatus.failed;
        notifyListeners();
      }
    }
  }

  Future<bool> submitComplaint(
      {required String subject, required String description}) async {
    complaintSubmitting = true;
    notifyListeners();
    final result = await _complaintRepository.submitComplaint(
        subject: subject, description: description);
    complaintSubmitting = false;
    notifyListeners();
    return result;
  }
}

final marketingComplaintsProvider = ChangeNotifierProvider<ComplaintsProvider>(
  create: (context) => ComplaintsProvider(),
);
