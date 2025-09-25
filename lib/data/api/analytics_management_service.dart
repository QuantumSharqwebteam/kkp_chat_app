import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/models/activity_model.dart';

class AnalyticsService {
  static var baseUrl = '${dotenv.env["BASE_URL"]}/';
  final http.Client client;

  AnalyticsService({http.Client? client}) : client = client ?? http.Client();
  // Future<List<Activity>> fetchActivities() async {
  //   final response = await http.get(Uri.parse("$baseUrl/activity/list"));

  //   if (response.statusCode == 200) {
  //     final data = jsonDecode(response.body);
  //     final List<dynamic> message = data["message"];
  //     return message.map((e) => Activity.fromJson(e)).toList();
  //   } else {
  //     throw Exception("Failed to load activities");
  //   }
  // }

  Future<List<Activity>> fetchActivities() async {
    final endPoint = "activity/list";
    final url = Uri.parse("$baseUrl$endPoint");
    final token = await LocalDbHelper.getToken();

    try {
      final response = await client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          "Authorization": "Bearer $token",
        },
      );
      final data = jsonDecode(response.body);
      final List<dynamic> message = data["message"];
      return message.map((e) => Activity.fromJson(e)).toList();
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<bool> deleteAllData() async {
    final endPoint = "activity/delete";
    final url = Uri.parse("$baseUrl$endPoint");
    final token = await LocalDbHelper.getToken();

    try {
      final response = await client.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          "Authorization": "Bearer $token",
        },
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        // Success
        return true;
      } else {
        // print("Failed to delete all data. Status: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      // print("Error deleting all data: $e");
      return false;
    }
  }
}
