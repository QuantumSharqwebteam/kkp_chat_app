import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:kkpchatapp/data/api/api_client.dart';
import 'package:kkpchatapp/core/services/logging_service.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/models/meet_model.dart';

class MeetingService {
  final String? baseUrl = dotenv.env['BASE_URL'];
  final http.Client client;
  final LoggingService _logger = LoggingService.instance;

  MeetingService({http.Client? httpClient})
      : client = httpClient ?? ApiClient.create();

  /// Fetches all meetings from the backend
  Future<List<MeetingModel>> getAllMeetings() async {
    final url = Uri.parse('$baseUrl/meet/getAll');
    final token = await LocalDbHelper.getToken();

    _logger.logNetwork('Fetching all meetings | GET $url',
        level: LogLevel.info);

    if (token == null) {
      _logger.logNetwork(
        'Token not found. Returning empty meeting list.',
        level: LogLevel.warning,
      );
      return [];
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await client.get(url, headers: headers);

      _logger.logNetwork(
        'Get meetings response status: ${response.statusCode}',
        level: LogLevel.debug,
      );
      _logger.logNetwork(
        'Get meetings response body: ${response.body}',
        level: LogLevel.debug,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['message'];

        if (data is List) {
          _logger.logNetwork(
            'Fetched meetings successfully | Count: ${data.length}',
            level: LogLevel.info,
          );
          return data.map((e) => MeetingModel.fromJson(e)).toList();
        } else {
          _logger.logNetwork(
            'Unexpected response format while fetching meetings: $body',
            level: LogLevel.warning,
          );
          return [];
        }
      } else {
        _logger.logNetwork(
          'Failed to fetch meetings. Status: ${response.statusCode}, Body: ${response.body}',
          level: LogLevel.warning,
        );
        return [];
      }
    } catch (e, stackTrace) {
      _logger.logNetwork(
        'Exception while fetching meetings',
        level: LogLevel.error,
        error: e,
        stackTrace: stackTrace,
      );
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

    _logger.logNetwork('Creating meeting | POST $url', level: LogLevel.info);

    if (token == null) {
      _logger.logNetwork(
        'Token not found. Cannot create meeting.',
        level: LogLevel.warning,
      );
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

    _logger.logNetwork('Create meeting payload: $body', level: LogLevel.debug);

    try {
      final response = await client.post(url, headers: headers, body: body);

      _logger.logNetwork(
        'Create meeting response status: ${response.statusCode}',
        level: LogLevel.debug,
      );
      _logger.logNetwork(
        'Create meeting response body: ${response.body}',
        level: LogLevel.debug,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _logger.logNetwork('Meeting created successfully.',
            level: LogLevel.info);
        return true;
      }

      _logger.logNetwork(
        'Failed to create meeting. Status: ${response.statusCode}, Body: ${response.body}',
        level: LogLevel.warning,
      );
      return false;
    } catch (e, stackTrace) {
      _logger.logNetwork(
        'Exception while creating meeting',
        level: LogLevel.error,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Updates a meeting by its ID (all fields)
  Future<bool> updateMeeting({
    required String id,
    String? title,
    String? location,
    String? link,
    String? startTime,
    String? status,
  }) async {
    final url = Uri.parse('$baseUrl/meet/update/$id');
    final token = await LocalDbHelper.getToken();

    _logger.logNetwork('Updating meeting | ID: $id', level: LogLevel.info);

    if (token == null) {
      _logger.logNetwork(
        'Token not found. Cannot update meeting.',
        level: LogLevel.warning,
      );
      return false;
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (location != null) body['location'] = location;
    if (link != null) body['link'] = link;
    if (startTime != null) body['startTime'] = startTime;
    if (status != null) body['status'] = status;

    _logger.logNetwork('Update meeting payload: $body', level: LogLevel.debug);

    try {
      final response = await client.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      _logger.logNetwork(
        'Update meeting response status: ${response.statusCode}',
        level: LogLevel.debug,
      );
      _logger.logNetwork(
        'Update meeting response body: ${response.body}',
        level: LogLevel.debug,
      );

      if (response.statusCode == 200) {
        _logger.logNetwork('Meeting updated successfully.',
            level: LogLevel.info);
        return true;
      } else {
        _logger.logNetwork(
          'Failed to update meeting. Status: ${response.statusCode}, Body: ${response.body}',
          level: LogLevel.warning,
        );
        return false;
      }
    } catch (e, stackTrace) {
      _logger.logNetwork(
        'Exception while updating meeting',
        level: LogLevel.error,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Deletes a meeting by its ID
  Future<bool> deleteMeeting(String id) async {
    final url = Uri.parse('$baseUrl/meet/delete/$id');
    final token = await LocalDbHelper.getToken();

    _logger.logNetwork('Deleting meeting | ID: $id', level: LogLevel.info);

    if (token == null) {
      _logger.logNetwork(
        'Token not found. Cannot delete meeting.',
        level: LogLevel.warning,
      );
      return false;
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await client.delete(url, headers: headers);

      _logger.logNetwork(
        'Delete meeting response status: ${response.statusCode}',
        level: LogLevel.debug,
      );
      _logger.logNetwork(
        'Delete meeting response body: ${response.body}',
        level: LogLevel.debug,
      );

      if (response.statusCode == 200) {
        _logger.logNetwork('Meeting deleted successfully.',
            level: LogLevel.info);
        return true;
      } else {
        _logger.logNetwork(
          'Failed to delete meeting. Status: ${response.statusCode}, Body: ${response.body}',
          level: LogLevel.warning,
        );
        return false;
      }
    } catch (e, stackTrace) {
      _logger.logNetwork(
        'Exception while deleting meeting',
        level: LogLevel.error,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
