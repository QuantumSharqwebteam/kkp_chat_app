import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AdminChatService {
  final String baseUrl = "https://kkp-chat.onrender.com/chat";

  final http.Client client;

  AdminChatService({http.Client? httpClient})
      : client = httpClient ?? http.Client();

  /// ** Get Previous Chat Messages**
  Future<List<Map<String, dynamic>>> getPreviousChats(
      String mailId1, String mailId2) async {
    final url =
        Uri.parse("https://kkp-chat.onrender.com/api/chat/$mailId2/$mailId1");

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

  /// **Get Agent-wise User List**
  Future<List<Map<String, dynamic>>> getAgentUserList(String agentId) async {
    final url = Uri.parse("$baseUrl/getAgentUserList/$agentId");

    try {
      final response = await client.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        // Case : If users are found, return the list
        if (jsonResponse["message"] ==
            "Chatted user profiles retrieved successfully") {
          return List<Map<String, dynamic>>.from(jsonResponse["data"]);
        }
        // Case 2: If no users are available, return an empty list
        else if (jsonResponse["message"] == "No user profiles found") {
          return [];
        }
        //  Case 3: Handle any unexpected response message
        else {
          throw Exception(
              "Unexpected response message: ${jsonResponse["message"]}");
        }
      }
      //  Case 4: Handle 404 when no users are found
      else if (response.statusCode == 404) {
        return [];
      }
      //  Case 5: Handle other response errors
      else {
        throw Exception('Failed to fetch agent user list: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching agent user list: ${e.toString()}');
      }
      throw Exception('Error fetching agent user list: $e');
    }
  }

  /// **Get Chatted User List**
  Future<List<Map<String, dynamic>>> getChattedUserList() async {
    final url = Uri.parse("$baseUrl/getUserList");

    try {
      final response = await client.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        // Ensure the message matches and data exists
        if (jsonResponse["message"] ==
                "Chatted user profiles retrieved successfully" &&
            jsonResponse.containsKey("data")) {
          return List<Map<String, dynamic>>.from(jsonResponse["data"]);
        }
        return []; // Return empty list if no data found
      } else if (response.statusCode == 404) {
        if (kDebugMode) {
          print("No chatted users found.");
        }
        return [];
      } else {
        throw Exception('Failed to fetch chatted user list: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching chatted user list: $e');
    }
  }
}
