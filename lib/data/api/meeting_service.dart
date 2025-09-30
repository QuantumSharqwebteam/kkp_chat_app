import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/models/meet_model.dart';

class MeetingService {
  final String? baseUrl = dotenv.env['BASE_URL'];
  final http.Client client;

  MeetingService({http.Client? httpClient}) : client = httpClient ?? http.Client();

  /// Fetches all meetings from the backend
  Future<List<MeetingModel>> getAllMeetings() async {
    final url = Uri.parse('$baseUrl/meet/getAll');
    final token = await LocalDbHelper.getToken();
    if (token == null) {
      debugPrint('⚠️ Token not found. Returning empty meeting list.');
      return [];
    }
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    try {
      final response = await client.get(url, headers: headers);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        debugPrint("${response.body}");
        final data = body['message'];
        if (data is List) {
          return data.map((e) => MeetingModel.fromJson(e)).toList();
        } else {
          debugPrint('⚠️ Unexpected response format: $body');
          return [];
        }
      } else {
        debugPrint(
            '❌ Failed to fetch meetings. Status: ${response.statusCode}, Body: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Exception while fetching meetings: $e');
      return [];
    }
  }

  /// Creates a new meeting
  Future<bool> createMeeting({
    required String title,
    required String location,
    required String link,
    required String startTime,
  }) async {
    final url = Uri.parse('$baseUrl/meet/add');
    final token = await LocalDbHelper.getToken();
    if (token == null) {
      debugPrint('⚠️ Token not found. Cannot create meeting.');
      return false;
    }
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final body = jsonEncode({
      'title': title,
      'location': location,
      'link': link,
      'startTime': startTime,
    });
    try {
      final response = await client.post(url, headers: headers, body: body);
      if (response.statusCode == 201) {
        debugPrint('✅ Meeting created successfully.');
        return true;
      } else {
        debugPrint(
            '❌ Failed to create meeting. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Exception while creating meeting: $e');
      return false;
    }
  }

  /// Updates a meeting by its ID (only startTime in the body as per your example)
  /// Updates a meeting by its ID (all fields)
  Future<bool> updateMeeting({
    required String id,
    String? title,
    String? location,
    String? link,
    String? startTime,
  }) async {
    final url = Uri.parse('$baseUrl/meet/update/$id');
    final token = await LocalDbHelper.getToken();
    if (token == null) {
      debugPrint('⚠️ Token not found. Cannot update meeting.');
      return false;
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    // Only include fields that are provided (not null)
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (location != null) body['location'] = location;
    if (link != null) body['link'] = link;
    if (startTime != null) body['startTime'] = startTime;

    try {
      final response = await client.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        debugPrint('✅ Meeting updated successfully.');
        return true;
      } else {
        debugPrint(
            '❌ Failed to update meeting. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Exception while updating meeting: $e');
      return false;
    }
  }

  /// Deletes a meeting by its ID
  Future<bool> deleteMeeting(String id) async {
    final url = Uri.parse('$baseUrl/meet/delete/$id');
    final token = await LocalDbHelper.getToken();
    if (token == null) {
      debugPrint('⚠️ Token not found. Cannot delete meeting.');
      return false;
    }
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    try {
      final response = await client.delete(url, headers: headers);
      if (response.statusCode == 200) {
        debugPrint('✅ Meeting deleted successfully.');
        return true;
      } else {
        debugPrint(
            '❌ Failed to delete meeting. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Exception while deleting meeting: $e');
      return false;
    }
  }
}
