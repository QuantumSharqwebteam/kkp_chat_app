import 'package:kkpchatapp/core/services/chat_service.dart';
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

  //get agora token which is required for making call for that channel name
  Future<String?> fetchAgoraToken(String channelName, int uid) async {
    return await chatService.getAgoraToken(channelName: channelName, uid: uid);
  }
}
