import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminChatService {
  final String baseUrl = "https://kkp-chat.onrender.com/api/chat";

  final http.Client client;

  AdminChatService({http.Client? httpClient})
      : client = httpClient ?? http.Client();

  /// ** Get Previous Chat Messages**
  Future<List<Map<String, dynamic>>> getPreviousChats(
      String mailId1, String mailId2) async {
    final url = Uri.parse("$baseUrl/$mailId2/$mailId1");

    try {
      final response = await client.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to fetch previous chats: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching previous chats: $e');
    }
  }

  /// ** Get Agent-wise User List**
  Future<List<Map<String, dynamic>>> getAgentUserList(String agentId) async {
    final url = Uri.parse("$baseUrl/getAgentUserList/$agentId");

    try {
      final response = await client.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to fetch agent user list: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching agent user list: $e');
    }
  }

  /// **Get Chatted User List**
  Future<List<Map<String, dynamic>>> getChattedUserList() async {
    final url = Uri.parse("$baseUrl/getUserList");

    try {
      final response = await client.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to fetch chatted user list: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching chatted user list: $e');
    }
  }
}
