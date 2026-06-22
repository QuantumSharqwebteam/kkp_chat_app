import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:kkpchatapp/core/services/logging_service.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/models/call_log_model.dart';
import 'package:kkpchatapp/data/models/form_data_model.dart';
import 'package:kkpchatapp/data/models/group_message_model.dart';
import 'package:kkpchatapp/data/models/message_model.dart';

class ChatService {
  final String? baseUrl = dotenv.env["BASE_URL"];

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

    final token = await LocalDbHelper.getToken();
    try {
      final response = await client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          "Authorization": "Bearer $token",
        },
      );

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

    final token = await LocalDbHelper.getToken();
    try {
      final response = await client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          "Authorization": "Bearer $token",
        },
      );
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 && jsonResponse["message"] is List) {
        // Success: Return the list of assigned users
        debugPrint("📌 ${response.body}");
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

    final token = await LocalDbHelper.getToken();
    try {
      final response = await client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          "Authorization": "Bearer $token",
        },
      );

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

    final token = await LocalDbHelper.getToken();
    try {
      final response = await client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          "Authorization": "Bearer $token",
        },
      );

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
    final token = await LocalDbHelper.getToken();

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

    /// 🔍 DEBUG LOGS (REQUEST)
    debugPrint("📤 API REQUEST");
    debugPrint("➡️ URL: $url");
    debugPrint("📧 Customer Email: $customerEmail");
    debugPrint("🧑‍💼 Agent Email: $agentEmail");
    debugPrint("📦 Body: ${jsonEncode(body)}");

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
    final token = await LocalDbHelper.getToken();
    final response = await client.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      LoggingService.instance.logNetwork("Form Data: ${data.toString()}");

      List<FormDataModel> formList = (data['formData'] as List)
          .map((item) => FormDataModel.fromJson(item))
          .toList();

      return formList;
    } else {
      throw Exception('Failed to load form data');
    }
  }

  Future<List<FormDataModel>> getFormDataForEnquiery(
      {required String email}) async {
    final url = Uri.parse('$baseUrl/chat/getFormData?email=$email');
    final token = await LocalDbHelper.getToken();
    final response = await client.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        "Authorization": "Bearer $token",
      },
    );
    // print(response.body);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      LoggingService.instance.logNetwork("Form Data: ${data.toString()}");

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

    final token = await LocalDbHelper.getToken();
    try {
      final response = await client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"channelName": channelName, "uid": uid}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["status"] == 200 && data["token"] != null) {
          LoggingService.instance.info('AgoraToken', 'token obtained for channel=$channelName uid=$uid');
          return data["token"];
        } else {
          LoggingService.instance.warning('AgoraToken',
              'backend rejected token request — status=${data["status"]}  '
              'body=${response.body.length > 200 ? response.body.substring(0, 200) : response.body}');
          return null;
        }
      } else {
        LoggingService.instance.warning('AgoraToken',
            'HTTP ${response.statusCode} for channel=$channelName uid=$uid  '
            'body=${response.body.length > 200 ? response.body.substring(0, 200) : response.body}');
        return null;
      }
    } catch (e, st) {
      LoggingService.instance.error('AgoraToken',
          'exception fetching token for channel=$channelName uid=$uid',
          error: e, stackTrace: st);
      return null;
    }
  }

  /// **Get Admin Home Page Traffic Data**
  Future<List<Map<String, dynamic>>> getAdminGraphData() async {
    final url = Uri.parse("$baseUrl/chat/getadminGraphData");
    final token = await LocalDbHelper.getToken();

    try {
      final response = await client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse["status"] == 200 && jsonResponse["traffic"] is List) {
          return List<Map<String, dynamic>>.from(jsonResponse["traffic"]);
        } else {
          throw Exception("Failed to fetch admin graph data: ${response.body}");
        }
      } else {
        throw Exception("Failed to fetch admin graph data: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error fetching admin graph data: $e");
    }
  }

  Future<void> updateFormStatus({
    required String formId,
    required String status,
    String? reason,
  }) async {
    final token = await LocalDbHelper.getToken();
    try {
      final url = Uri.parse("$baseUrl/chat/updateForm/$formId");
      final normalizedReason = reason?.trim();
      final body = <String, dynamic>{
        "status": status,
      };

      if (status.toLowerCase() == 'declined') {
        if (normalizedReason == null || normalizedReason.isEmpty) {
          throw ArgumentError(
              'Decline reason is required when status is Declined');
        }
        body["reason"] = normalizedReason;
      }

      final response = await client.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        if (kDebugMode) {
          debugPrint('Failed to update form status: ${response.body}');
        }
        throw Exception('Failed to update form status: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating form status: $e');
    }
  }

  /// Update form rate
  Future<void> updateFormRate(
      {required String formId, required String rate}) async {
    final token = await LocalDbHelper.getToken();
    try {
      final url = Uri.parse("$baseUrl/chat/updateForm/$formId");
      final response = await client.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"rate": rate}),
      );

      final responseBody = jsonDecode(response.body);

      if (responseBody['status'] != 200) {
        if (kDebugMode) {
          debugPrint("Failed to update form rate: ${response.body}");
        }
        throw Exception('Failed to update form rate: ${response.body}');
      }
      // No need to throw an exception if the status is 200
    } catch (e) {
      throw Exception('Error updating form rate: $e');
    }
  }

  Future<void> updateFormDetails({
    required String formId,
    required Map<String, dynamic> updates,
  }) async {
    if (updates.isEmpty) return;
    final token = await LocalDbHelper.getToken();
    try {
      final url = Uri.parse("$baseUrl/chat/updateForm/$formId");
      final response = await client.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(updates),
      );
      final responseBody = jsonDecode(response.body);

      if (responseBody['status'] != 200) {
        if (kDebugMode) {
          debugPrint("Failed to update form: ${response.body}");
        }
        throw Exception('Failed to update form: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating form: $e');
    }
  }

  /// Update inquiry form by order ID (supports status/rate updates)
  Future<void> updateFormByOrderId({
    required String orderId,
    String? status,
    num? rate,
    String? quality,
    String? weave,
    String? quantity,
    String? composition,
    String? buyerName,
  }) async {
    final token = await LocalDbHelper.getToken();
    try {
      final url = Uri.parse("$baseUrl/chat/updateFormByOrderId/$orderId");
      final Map<String, dynamic> body = {};
      if (status != null) body['status'] = status;
      if (rate != null) body['rate'] = rate;
      if (quality != null) body['quality'] = quality;
      if (weave != null) body['weave'] = weave;
      if (quantity != null) body['quantity'] = quantity;
      if (composition != null) body['composition'] = composition;
      if (buyerName != null) body['buyerName'] = buyerName;

      if (body.isEmpty) {
        return;
      }

      final response = await client.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      final responseBody = jsonDecode(response.body);
      if (response.statusCode != 200 || responseBody['status'] != 200) {
        if (kDebugMode) {
          debugPrint("Failed to update form by order id: ${response.body}");
        }
        throw Exception('Failed to update form by order: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating form by order id: $e');
    }
  }

  /// Update Call Data
  Future<void> updateCallData(String messageId, String callStatus,
      {String? callDuration}) async {
    final url = Uri.parse('$baseUrl/chat/updateCall/$messageId');
    final body = callDuration != null
        ? {'callStatus': callStatus, 'callDuration': callDuration}
        : {'callStatus': callStatus};

    final token = await LocalDbHelper.getToken();
    try {
      final response = await client.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          debugPrint(
              '✅ Call data updated successfully:${response.statusCode} with status marked as:$callStatus');
        }
      } else {
        if (kDebugMode) {
          debugPrint('Failed to update call data: ${response.body}');
        } else {}
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("❌ Error updating call data: $e ");
      }
    }
  }

  //  get all call logs of user :
  Future<List<CallLogModel>> getCallLogs(String email) async {
    final url = Uri.parse("$baseUrl/chat/getCallLog/$email");
    final token = await LocalDbHelper.getToken();
    try {
      final response = await client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List<dynamic> callLogsJson = json['callLogs'];
        return callLogsJson.map((log) => CallLogModel.fromJson(log)).toList();
      } else {
        throw Exception("Failed to get call logs: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error fetching call logs: $e");
    }
  }

  Future<List<MessageModel>> fetchAgentMessages({
    required String agentEmail,
    required String customerEmail,
    int limit = 20,
    String? before,
  }) async {
    final url = Uri.parse(
        "$baseUrl/chat/getAgentMessages/$customerEmail/$agentEmail?limit=$limit${before != null ? '&before=$before' : ''}");
    final token = await LocalDbHelper.getToken();
    try {
      final response = await client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        final List<dynamic> messagesJson = json['messages'];
        return messagesJson
            .map((msg) => MessageModel.fromJson(msg, agentEmail))
            .toList();
      } else if (response.statusCode == 404) {
        // 404 = no conversation yet — normal for new agent↔customer pairs.
        return [];
      }
      if (kDebugMode) {
        print("Unexpected response (${response.statusCode}): ${response.body}");
      }
      return [];
    } catch (e) {
      throw Exception("Error fetching agent messages: $e");
    }
  }

  Future<List<MessageModel>> fetchCustomerMessages({
    required String customerEmail,
    int limit = 20,
    String? before,
  }) async {
    final url = Uri.parse(
      "$baseUrl/chat/getUserMessages/$customerEmail?limit=$limit${before != null ? '&before=$before' : ''}",
    );

    final token = await LocalDbHelper.getToken();
    try {
      final response = await client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List<dynamic> messagesJson = json['messages'];
        return messagesJson
            .map((msg) => MessageModel.fromJson(msg, customerEmail))
            .toList();
      } else if (response.statusCode == 404) {
        // 404 = no conversation yet — normal for new customer↔agent pairs.
        return [];
      }

      if (kDebugMode) {
        print("Unexpected response (${response.statusCode}): ${response.body}");
      }
      return [];
    } catch (e) {
      throw Exception("Error fetching messages: $e");
    }
  }

  // ignore: body_might_complete_normally_nullable
  Future<DateTime?> getAgentLastTimestampForCustomer(
      String customerEmail) async {
    final url = Uri.parse("$baseUrl/chat/getUserLastTimestamp/$customerEmail");

    final token = await LocalDbHelper.getToken();
    try {
      final response = await client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse["status"] == 200 &&
            jsonResponse.containsKey("lastUserReadTimestamp")) {
          final String lastMessageTimestampStr =
              jsonResponse["lastUserReadTimestamp"];
          return DateTime.parse(lastMessageTimestampStr);
        } else {
          debugPrint(
              "Failed to retrieve last message timestamp: ${response.body}");
        }
      } else {
        debugPrint(
            "Failed to retrieve last message timestamp: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error retrieving last message timestamp: $e");
    }
  }

  /// Get Last Message Timestamp for a Specific Email and Agent Email Combination
  Future<Map<String, dynamic>?> getCustomerLastMessageTimestampForAgent(
      String userEmail, String agentEmail) async {
    final url = Uri.parse("$baseUrl/chat/getTimestamp/$userEmail/$agentEmail");

    final token = await LocalDbHelper.getToken();
    try {
      final response = await client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse["status"] == 200 &&
            jsonResponse.containsKey("lastUserReadTimestamp") &&
            jsonResponse.containsKey("messageId")) {
          final String lastUserReadTimestampStr =
              jsonResponse["lastUserReadTimestamp"];
          final DateTime lastUserReadTimestamp =
              DateTime.parse(lastUserReadTimestampStr);
          final String messageId = jsonResponse["messageId"];

          return {
            'lastUserReadTimestamp': lastUserReadTimestamp,
            'messageId': messageId,
          };
        } else if (jsonResponse["status"] == 404) {
          debugPrint(
              "No read messages from this user found in this conversation");
          return null;
        } else {
          debugPrint(
              "Failed to retrieve last user read timestamp: ${response.body}");
          return null;
        }
      } else if (response.statusCode == 404) {
        // 404 = no read history yet — normal for new conversations.
        return null;
      } else {
        debugPrint(
            "Failed to retrieve last user read timestamp: ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("Error retrieving last user read timestamp: $e");
      return null;
    }
  }

  // Fetch group messages from API
  Future<Map<String, dynamic>> fetchGroupMessages({
    int limit = 20,
    String? before,
    required String groupId,
  }) async {
    final url = Uri.parse(
      "$baseUrl/chat/groupMessages?limit=$limit&groupId=$groupId${before != null ? '&before=$before' : ''}",
    );
    final token = await LocalDbHelper.getToken();

    debugPrint("📡 [ChatService] fetchGroupMessages → GET $url");
    debugPrint(
        "📡 [ChatService] Params: groupId=$groupId, limit=$limit, before=$before");

    try {
      final response = await client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          "Authorization": "Bearer $token",
        },
      );

      debugPrint(
          "📡 [ChatService] fetchGroupMessages ← status ${response.statusCode}");

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final msgs = (json['messages'] as List)
            .map((msg) => GroupMessageModel.fromApiJson(msg))
            .toList();
        final nextCursor = json['nextCursor'];
        debugPrint(
            "📡 [ChatService] Received ${msgs.length} messages, nextCursor: $nextCursor");
        for (final m in msgs) {
          debugPrint(
              "   ↳ [${m.messageId}] type=${m.type} from=${m.senderId} at=${m.timestamp}");
        }
        return {'messages': msgs, 'nextCursor': nextCursor};
      } else if (response.statusCode == 404) {
        final json = jsonDecode(response.body);
        if (json['message'] == 'No group messages found') {
          debugPrint("📡 [ChatService] No messages found for group $groupId");
          return {'messages': [], 'nextCursor': null};
        }
      }

      debugPrint(
          "📡 [ChatService] Unexpected response (${response.statusCode}): ${response.body}");
      return {'messages': [], 'nextCursor': null};
    } catch (e) {
      debugPrint("❌ [ChatService] fetchGroupMessages error: $e");
      throw Exception("Error fetching group messages: $e");
    }
  }
}
