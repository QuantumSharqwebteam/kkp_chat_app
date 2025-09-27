import 'package:kkpchatapp/data/api/complaint_service.dart';
import 'package:kkpchatapp/data/models/complaint_model.dart';

class ComplaintRepository {
  final _complaintService = ComplaintService();

  Future<List<ComplaintModel>> getAllComplaints() async {
    return _complaintService.getAllComplaints();
  }

  Future<bool> submitComplaint(
      {required String subject, required String description}) async {
    return _complaintService.submitComplaint(
        subject: subject, description: description);
  }
}
