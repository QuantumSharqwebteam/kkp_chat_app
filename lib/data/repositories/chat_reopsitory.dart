import 'package:kkp_chat_app/core/services/chat_service.dart';
import 'package:kkp_chat_app/data/models/form_data_model.dart';

class ChatRepository {
  final ChatService chatService = ChatService();

  /// Get previous chat messages
  Future<List<Map<String, dynamic>>> fetchPreviousChats(
      String mailId1, String mailId2) async {
    return await chatService.getPreviousChats(mailId1, mailId2);
  }

  /// get the list of assigned customers to that agent
  Future<List<Map<String, dynamic>>> fetchAssignedCustomerList(
      String agentId) async {
    return await chatService.getAssignedCustomers(agentId);
  }

  /// Get list of users who have talked to an particular  agent
  Future<List<Map<String, dynamic>>> fetchAgentUserList(String agentId) async {
    return await chatService.getAgentUserList(agentId);
  }

  /// Get list of all users who have chatted
  Future<List<Map<String, dynamic>>> fetchChattedUserList() async {
    return await chatService.getChattedUserList();
  }

  // get form data of inqury foms during agent customer chat
  Future<List<FormDataModel>> fetchFormData() async {
    return await chatService.getFormData();
  }
}
