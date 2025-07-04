import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:kkpchatapp/data/models/address_model.dart';
import 'package:kkpchatapp/data/models/agent.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';

class AuthApi {
  static var baseUrl = '${dotenv.env["BASE_URL"]}/';
  final http.Client client;

  AuthApi({http.Client? client}) : client = client ?? http.Client();

  Future<Map<String, dynamic>> updateFCMToken(String fcmToken) async {
    final endPoint = "user/updateUserDetails";
    final url = Uri.parse('$baseUrl$endPoint');
    final body = json.encode({
      "token": fcmToken,
    });
    final token = await LocalDbHelper.getToken();
    try {
      final response = await client.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          "Authorization": "Bearer $token",
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update FCM token');
      }
    } catch (e) {
      debugPrint("Error updating FCM token: $e");
      throw Exception(e);
    }
  }

  Future<Map<String, dynamic>> refreshToken(String oldToken) async {
    final endPoint = "user/getRefreshToken";
    final url = Uri.parse("$baseUrl$endPoint");

    try {
      final response = await client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          "Authorization": "Bearer $oldToken",
        },
      );
      return json.decode(response.body);
    } catch (e) {
      throw Exception(e);
    }
  }

  // login
  Future<Map<String, dynamic>> login(
      {required String email, required String password}) async {
    const endPoint = 'user/login';
    final url = Uri.parse("$baseUrl$endPoint");
    final body = {
      'email': email,
      'password': password,
    };

    try {
      final response = await client.post(url,
          headers: {
            "Content-Type": "application/json",
          },
          body: jsonEncode(body));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 400 || response.statusCode == 401) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to login: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error during login: $e');
    }
  }

  //signup
  Future<Map<String, dynamic>> signup(
      {required String email, required String password}) async {
    const endPoint = 'user/signup';
    final url = Uri.parse("$baseUrl$endPoint");
    final body = {
      'email': email,
      'password': password,
    };

    try {
      final response = await client.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 400) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to signup: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error during signup: $e');
    }
  }

  //update user details
  Future<Map<String, dynamic>> updateDetails({
    String? name,
    String? number,
    String? customerType,
    String? gstNo,
    String? panNo,
    String? profileUrl,
    Address? address,
  }) async {
    const endPoint = 'user/updateUserDetails';
    final url = Uri.parse("$baseUrl$endPoint");

    final String? token = await LocalDbHelper.getToken();

    if (token == null) {
      throw Exception('Token not found. Please log in again.');
    }

    final body = <String, dynamic>{};

    if (name != null) {
      body["name"] = name;
    }

    if (number != null) {
      body["mobile"] = int.parse(number);
    }

    if (address != null) {
      body["address"] = [
        {
          if (address.houseNo != null) "houseNo": address.houseNo,
          if (address.streetName != null) "streetName": address.streetName,
          if (address.city != null) "city": address.city,
          if (address.pincode != null) "pincode": address.pincode,
        }
      ];
    }

    if (customerType != null) {
      body["customerType"] = customerType;
    }

    if (gstNo != null) {
      body["GSTno"] = gstNo;
    }

    if (panNo != null) {
      body["PANno"] = panNo;
    }

    if (profileUrl != null) {
      body["profileUrl"] = profileUrl;
    }

    try {
      final response = await client.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update details: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error during update: $e');
    }
  }

//forget password
  Future<Map<String, dynamic>> forgetPassword(
      {required String password, required String email}) async {
    const endPoint = 'user/changePassword';
    final url = Uri.parse("$baseUrl$endPoint");

    try {
      final body = {
        "email": email,
        "password": password,
      };

      final response = await client.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to change password: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error during password update: $e');
    }
  }

  //change password
  Future<Map<String, dynamic>> updatePasswordFromSettings(
      String currentPassword, String newPassword, String email) async {
    const endPoint = 'user/updatePassword';
    final url = Uri.parse("$baseUrl$endPoint");

    try {
      // Retrieve token from SharedPreferences

      final token = await LocalDbHelper.getToken();

      if (token == null) {
        throw Exception('Token not found. Please log in again.');
      }

      final body = {
        "email": email,
        "newPassword": newPassword,
        "currentPassword": currentPassword,
      };

      final response = await client.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update password: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error during password update: $e');
    }
  }

  //sendotp api
  Future<Map<String, dynamic>> sendOtp({required String email}) async {
    const endPoint = "user/getOTP/";
    final url = Uri.parse('$baseUrl$endPoint$email');

    try {
      final response = await client.get(url, headers: {
        "Content-Type": "application/json",
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return jsonDecode(response.body);
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  // get particular user profile details api admin , agent , customer
  Future<dynamic> getUserInfo() async {
    const endPoint = "user/getInfo";
    final url = Uri.parse('$baseUrl$endPoint');
    final token = await LocalDbHelper.getToken();

    try {
      final response = await http.get(url, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      });

      // Parse the JSON response into a Profile object
      final jsonResponse = jsonDecode(response.body);
      // return Profile.fromJson(jsonResponse['message']);
      return jsonResponse;
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<Map<String, dynamic>> verifyOtp(
      {required String email, required int otp}) async {
    const endPoint = "user/verifyOtp";
    final url = Uri.parse('$baseUrl$endPoint');
    final body = jsonEncode({
      "email": email,
      "otp": otp,
    });

    try {
      final response = await http.Client().post(
        url,
        body: body,
        headers: {
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to verify OTP: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error verifying OTP: $e');
    }
  }

  //get all Agents list
  Future<List<Agent>> getAgent() async {
    const endPoint = 'user/getAgent';
    final url = Uri.parse("$baseUrl$endPoint");

    try {
      final response = await client.get(url);

      if (response.statusCode == 200) {
        return parseAgents(response.body);
      } else {
        throw Exception('Failed to fetch agent details: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching agent details: $e');
    }
  }

  // Fetch assigned agent list
  // Fetch assigned agent list
  Future<List<String>> fetchAssignedAgentList() async {
    const endPoint = 'user/getAssignedAgent';
    final url = Uri.parse("$baseUrl$endPoint");

    try {
      final response = await client.get(url);

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        // Extract and return the list of assigned agents
        return List<String>.from(responseBody['assignedAgents']);
      } else {
        throw Exception('Failed to fetch assigned agent list');
      }
    } catch (e) {
      throw Exception("Error fetching assigned agent list: $e");
    }
  }

  // create new  Agent / add new agent
  Future<Map<String, dynamic>> addAgent(
      {required Map<String, dynamic> body}) async {
    const endPoint = 'user/signup';
    final url = Uri.parse("$baseUrl$endPoint");
    try {
      final response = await client.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 400) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to signup new agent: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error during signup new agent : $e');
    }
  }

  // to assign agent in the assigned agent list who are eligible to get assgigned for chat with customer
  Future<Map<String, dynamic>> assignAgent({required String email}) async {
    final Uri url = Uri.parse("${baseUrl}user/assignAgent");
    final body = {
      "agentNames": [email]
    };

    try {
      final response = await client.post(
        url,
        body: jsonEncode(body),
        headers: {"Content-Type": "application/json"},
      );

      final jsonResponse = jsonDecode(response.body);
      return jsonResponse;
    } catch (e) {
      throw Exception(
          "Failed to add agent in the Assigned agent list:${e.toString()}");
    }
  }

  Future<bool> removeAssignedAgent({required String email}) async {
    final Uri url = Uri.parse("${baseUrl}user/removeAgent");
    final body = {
      "agentNames": [email]
    };

    try {
      final response = await client.put(
        url,
        body: jsonEncode(body),
        headers: {
          "Content-Type": "application/json",
        },
      );

      final jsonResponse = jsonDecode(response.body);

      if (jsonResponse["status"] == 200) {
        debugPrint("✅ ${jsonResponse["message"]}");
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // to fetch list of users, admin , agent if role ="User " then all users list will be shown up
  Future<List<dynamic>> getUsersByRole({required String role}) async {
    const endPoint = 'user/getByRole';
    final url = Uri.parse("$baseUrl$endPoint");
    final body = {"role": role};

    try {
      final response = await client.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return responseData['message'] ?? [];
      } else {
        throw Exception('Failed to fetch users by role: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching users by role: $e');
    }
  }

  // get users by agentId
  Future<List<dynamic>> getUsersByAgentId({required String agentEmail}) async {
    final endPoint = 'user/getUsersByAgentId/$agentEmail';
    final url = Uri.parse("$baseUrl$endPoint");

    try {
      final response = await client.get(
        url,
        headers: {
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return responseData['message'] ?? [];
      } else {
        throw Exception('Failed to fetch users by agent ID: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching users by agent ID: $e');
    }
  }

  Future<Map<String, dynamic>> deleteUserAccount(
    String email, String password , String feedback) async {
    final endPoint = "user/deleteUserAccount";
    final url = Uri.parse("$baseUrl$endPoint");
    final token = await LocalDbHelper.getToken();
    final body = jsonEncode({
      "email": email,
       "password": password,
       "feedback":feedback});
    try {
      final response = await client.delete(url,
          headers: {
            'Content-Type': 'application/json',
            "Authorization": "Bearer $token",
          },
          body: body);
          debugPrint("Response : ${response.body.toString()}");
      return json.decode(response.body);
    } catch (e) {
      throw Exception(e);
    }
  }

  // to delete agent account
  Future<Map<String, dynamic>> deleteAgent(String email) async {
    final endPoint = "agent/delete";
    final url = Uri.parse("$baseUrl$endPoint");
    final token = await LocalDbHelper.getToken();

    try {
      final response = await client.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'email': email}),
      );

      final reponseData = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          reponseData['message'] == "Agent deleted successfully") {
        return reponseData;
      } else {
        throw Exception(
            'Failed to delete agent: ${reponseData['message'] ?? response.body}');
      }
    } catch (e) {
      throw Exception('Delete request failed: $e');
    }
  }

  /// get user notifications
  Future<Map<String, dynamic>> getNotifications() async {
    final endPoint = "user/getNotification";
    final url = Uri.parse("$baseUrl$endPoint");
    final token = await LocalDbHelper
        .getToken(); // Assuming you have a method to get the token

    try {
      final response = await client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get notifications: ${response.body}');
      }
    } catch (e) {
      debugPrint("Error getting notifications: $e");
      throw Exception(e);
    }
  }

  Future<Map<String, dynamic>> updateNotificationRead(
      {required String notificationId}) async {
    final endPoint = "user/updateNotification/$notificationId";
    final url = Uri.parse('$baseUrl$endPoint');
    final token = await LocalDbHelper.getToken();

    try {
      final response = await client.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to mark notification as viewed');
      }
    } catch (e) {
      debugPrint("Error updating notification: $e");
      throw Exception(e);
    }
  }
}
