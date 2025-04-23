import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/models/form_data_model.dart';
import 'package:kkpchatapp/data/models/message_model.dart';

class ChatService {
  final String baseUrl = "https://kkp-chat.onrender.com";

  final http.Client client;

  ChatService({http.Client? httpClient}) : client = httpClient ?? http.Client();

  /// ** Get Previous Chat Messages**
  // Future<List<Map<String, dynamic>>> getPreviousChats(
  //     String mailId1, String mailId2) async {
  //   final url = Uri.parse("$baseUrl/api/chat/$mailId2/$mailId1");

  //   try {
  //     final response = await client.get(url);

  //     if (response.statusCode == 200) {
  //       final List<dynamic> data = jsonDecode(response.body);
  //       return data.cast<Map<String, dynamic>>();
  //     } else {
  //       throw Exception('Failed to fetch previous chats: ${response.body}');
  //     }
  //   } catch (e) {
  //     throw Exception('Error fetching previous chats: $e');
  //   }
  // }
  Future<List<MessageModel>> fetchPreviousMessages({
    required String agentEmail,
    required String customerEmail,
  }) async {
    final url = Uri.parse("$baseUrl/api/chat/$customerEmail/$agentEmail");

    try {
      final response = await client.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List<dynamic> messagesJson = json['messages'];
        return messagesJson
            .map((msg) => MessageModel.fromJson(msg, agentEmail))
            .toList();
      } else {
        throw Exception("Failed to load chat: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error fetching chat: $e");
    }
  }

  /// **Get Assigned Customers by Agent Email **
  Future<List<Map<String, dynamic>>> getAssignedCustomers(
      String agentEmail) async {
    final Uri url = Uri.parse("$baseUrl/user/getUsersByAgentId/$agentEmail");

    try {
      final response = await client.get(url);
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 && jsonResponse["message"] is List) {
        // Success: Return the list of assigned users
        return List<Map<String, dynamic>>.from(jsonResponse["message"]);
      } else if (response.statusCode == 404 ||
          jsonResponse["message"] == "No users found for this agent") {
        // No users assigned to this agent
        debugPrint("ℹ️ No users assigned to this agent:$agentEmail");
        return [];
      } else {
        // Unexpected structure or error
        throw Exception("Failed to fetch assigned customers: ${response.body}");
      }
    } catch (e) {
      debugPrint(" Error fetching assigned customers: $e");
      throw Exception("Error fetching assigned customers: $e");
    }
  }

  /// **Get Agent-wise chatted User List(who have started  chatting ) **
  Future<List<Map<String, dynamic>>> getAgentUserList(String agentId) async {
    final url = Uri.parse("$baseUrl/chat/getAgentUserList/$agentId");

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

  /// **Get Chatted User List** users who have inquired to any agnet or started chatted
  Future<List<Map<String, dynamic>>> getChattedUserList() async {
    final url = Uri.parse("$baseUrl/chat/getUserList");

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

  /// **Transfer Customer to Another Agent**
  Future<bool> transferCustomerToAgent({
    required String customerEmail,
    required String agentEmail,
  }) async {
    final Uri url = Uri.parse("$baseUrl/user/updateUser");
    final token = LocalDbHelper.getToken();

    if (token == null) {
      throw Exception('Token not found. Please log in again.');
    }

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final Map<String, dynamic> body = {
      "email": customerEmail,
      "agentId": agentEmail,
    };

    try {
      final response = await client.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint("❌ Failed to transfer: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error transferring user: $e");
      throw Exception("Failed to transfer user: $e");
    }
  }

  /// get inqury form data
  Future<List<FormDataModel>> getFormData() async {
    final url = Uri.parse('$baseUrl/chat/getFormData');
    final response = await client.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      List<FormDataModel> formList = (data['formData'] as List)
          .map((item) => FormDataModel.fromJson(item))
          .toList();

      return formList;
    } else {
      throw Exception('Failed to load form data');
    }
  }

  /// Get Agora Token
  Future<String?> getAgoraToken({
    required String channelName,
    required int uid,
  }) async {
    final url = Uri.parse("$baseUrl/chat/getCallToken");

    try {
      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"channelName": channelName, "uid": uid}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["status"] == 200 && data["token"] != null) {
          debugPrint("✅ Agora token generated:${data["token"]}");
          return data["token"];
        } else {
          debugPrint("❌ Token not present in response: $data");
          return null;
        }
      } else {
        debugPrint("❌ Failed to fetch token: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Exception in getAgoraToken: $e");
      return null;
    }
  }
}
