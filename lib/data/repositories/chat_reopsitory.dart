import 'package:kkpchatapp/core/services/chat_service.dart';
import 'package:kkpchatapp/data/models/call_log_model.dart';
import 'package:kkpchatapp/data/models/form_data_model.dart';
import 'package:kkpchatapp/data/models/message_model.dart';

class ChatRepository {
  final ChatService chatService = ChatService();

  /// Get previous chat messages
  Future<List<MessageModel>> fetchPreviousChats(
      String agentEmail, String customerEmail) async {
    return await chatService.fetchPreviousMessages(
        agentEmail: agentEmail, customerEmail: customerEmail);
  }

  /// Fetch agent messages with pagination

  /// Get the list of assigned customers to that agent
  Future<List<Map<String, dynamic>>> fetchAssignedCustomerList(
      String agentId) async {
    return await chatService.getAssignedCustomers(agentId);
  }

  /// Get list of users who have talked to a particular agent
  Future<List<Map<String, dynamic>>> fetchAgentUserList(String agentId) async {
    return await chatService.getAgentUserList(agentId);
  }

  /// Get list of all users who have chatted
  Future<List<Map<String, dynamic>>> fetchChattedUserList() async {
    return await chatService.getChattedUserList();
  }

  // Get form data of inquiry forms during agent customer chat
  Future<List<FormDataModel>> fetchFormData() async {
    return await chatService.getFormData();
  }

  // Fetch form data for a specific agent
  Future<List<FormDataModel>> fetchFormDataForEnquiery(
      String agentEmail) async {
    return await chatService.getFormDataForEnquiery(email: agentEmail);
  }

  // Get Agora token which is required for making a call for that channel name
  Future<String?> fetchAgoraToken(String channelName, int uid) async {
    return await chatService.getAgoraToken(channelName: channelName, uid: uid);
  }

  // Fetch admin home traffic chart data
  Future<List<Map<String, dynamic>>> fetchTrafficChartData() async {
    return await chatService.getAdminGraphData();
  }

  Future<void> updateInquiryFormStatus(String formId, String status) async {
    return chatService.updateFormStatus(formId: formId, status: status);
  }

  Future<void> updateInquiryFormRate(String formId, String rate) async {
    return chatService.updateFormRate(formId: formId, rate: rate);
  }

  /// Update Call Data
  Future<void> updateCallData(String messageId, String callStatus,
      {String? callDuration}) async {
    return chatService.updateCallData(messageId, callStatus,
        callDuration: callDuration);
  }

  /// Get call logs for a given email
  Future<List<CallLogModel>> fetchCallLogs(String email) async {
    return await chatService.getCallLogs(email);
  }

  Future<List<MessageModel>> fetchAgentMessages({
    required String agentEmail,
    required String customerEmail,
    int limit = 20,
    String? before,
  }) async {
    return await chatService.fetchAgentMessages(
      agentEmail: agentEmail,
      customerEmail: customerEmail,
      before: before,
      limit: limit,
    );
  }

  Future<List<MessageModel>> fetchCustomerMessages({
    required String customerEmail,
    int limit = 20,
    String? before,
  }) async {
    return await chatService.fetchCustomerMessages(
      customerEmail: customerEmail,
      before: before,
      limit: limit,
    );
  }
}
