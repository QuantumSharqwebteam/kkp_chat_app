import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kkp_chat_app/data/models/address_model.dart';
import 'package:kkp_chat_app/data/models/profile_model.dart';
import 'package:kkp_chat_app/data/sharedpreferences/shared_preference_helper.dart';

class AuthApi {
  static const baseUrl =
      'https://ps4smsnf44.execute-api.us-east-1.amazonaws.com/';
  final http.Client client;

  AuthApi({http.Client? client}) : client = client ?? http.Client();

  Future<Map<String, dynamic>> login(String email, String password) async {
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
      } else {
        throw Exception('Failed to login: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error during login: $e');
    }
  }

  Future<Map<String, dynamic>> signup(String email, String password) async {
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

  Future<Map<String, dynamic>> updateDetails({
    String? name,
    String? number,
    String? customerType,
    String? gstNo,
    String? panNo,
    Address? address,
  }) async {
    const endPoint = 'user/updateUserDetails';
    final url = Uri.parse("$baseUrl$endPoint");

    final token = await SharedPreferenceHelper.getToken();

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
      String password, String email) async {
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

      final token = await SharedPreferenceHelper.getToken();

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

  Future<Map<String, dynamic>> sendOtp(String email) async {
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

  Future<Profile> getUserInfo() async {
    const endPoint = "user/getInfo";
    final url = Uri.parse('$baseUrl$endPoint');
    final token = await SharedPreferenceHelper.getToken();

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

  Future<Map<String, dynamic>> verifyOtp(String email, int otp) async {
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
}
