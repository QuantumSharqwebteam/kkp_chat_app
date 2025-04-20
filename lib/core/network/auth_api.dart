import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kkp_chat_app/data/models/address_model.dart';
import 'package:kkp_chat_app/data/models/agent.dart';
import 'package:kkp_chat_app/data/models/profile_model.dart';
import 'package:kkp_chat_app/data/local_storage/local_db_helper.dart';

class AuthApi {
  static const baseUrl = 'https://kkp-chat.onrender.com/';
  final http.Client client;

  AuthApi({http.Client? client}) : client = client ?? http.Client();
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

    final token = LocalDbHelper.getToken();

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

      final token = LocalDbHelper.getToken();

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

  // get particular user profile detaiils api admin , agent , customer
  Future<Profile> getUserInfo() async {
    const endPoint = "user/getInfo";
    final url = Uri.parse('$baseUrl$endPoint');
    final token = LocalDbHelper.getToken();

    try {
      final response = await http.get(url, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Parse the JSON response into a Profile object
        final jsonResponse = jsonDecode(response.body);
        return Profile.fromJson(jsonResponse['message']);
      } else {
        // Handle error response
        throw Exception('Failed to load user info: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching user info: $e');
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
    final Uri url = Uri.parse("https://kkp-chat.onrender.com/user/assignAgent");
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
      debugPrint("❌ Error assigning agent: $e");
      throw Exception(
          "Failed to add agent in the Assigned agent list:${e.toString()}");
    }
  }

  Future<bool> removeAssignedAgent({required String email}) async {
    final Uri url = Uri.parse("https://kkp-chat.onrender.com/user/removeAgent");
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
        debugPrint("⚠️ ${jsonResponse["message"]}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error: $e");
      return false;
    }
  }

  // to fetch list of users, admin , agent
  Future<List<dynamic>> getUsersByRole(String role) async {
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
}
