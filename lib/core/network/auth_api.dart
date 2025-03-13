import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kkp_chat_app/data/models/address_model.dart';

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

  Future<Map<String, dynamic>> updateDetails(String name, String number,
      String customerType, String gstNo, Address address) async {
    const endPoint = 'user/updateUserDetails';
    final url = Uri.parse("$baseUrl$endPoint");
    final body = {
      "name": name,
      "mobile": number,
      "address": [
        {
          "houseNo": address.houseNo,
          "streetName": address.streetName,
          "city": address.city,
          "pincode": address.pincode,
        }
      ],
      "customerType": customerType,
      "GSTno": gstNo,
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
}
