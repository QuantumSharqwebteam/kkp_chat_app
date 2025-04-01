import 'package:kkp_chat_app/core/services/chat_service.dart';

class ChatRepository {
  final ChatService chatService = ChatService();

  /// Get previous chat messages
  Future<List<Map<String, dynamic>>> fetchPreviousChats(
      String mailId1, String mailId2) async {
    return await chatService.getPreviousChats(mailId1, mailId2);
  }

  /// Get list of users assigned to an agent
  Future<List<Map<String, dynamic>>> fetchAgentUserList(String agentId) async {
    return await chatService.getAgentUserList(agentId);
  }

  /// Get list of all users who have chatted
  Future<List<Map<String, dynamic>>> fetchChattedUserList() async {
    return await chatService.getChattedUserList();
  }
}
