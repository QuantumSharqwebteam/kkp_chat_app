import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:kkpchatapp/data/api/api_client.dart';
import 'package:kkpchatapp/core/services/logging_service.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/models/activity_model.dart';

class AnalyticsService {
  static var baseUrl = '${dotenv.env["BASE_URL"]}/';
  final http.Client client;
  final LoggingService _logger = LoggingService.instance;

  AnalyticsService({http.Client? client})
      : client = client ?? ApiClient.create();
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

    _logger.logNetwork(
      'Fetching activities | GET $url',
      level: LogLevel.info,
    );

    try {
      final response = await client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          "Authorization": "Bearer $token",
        },
      );

      _logger.logNetwork(
        'Fetch activities response status: ${response.statusCode}',
        level: LogLevel.debug,
      );
      _logger.logNetwork(
        'Fetch activities response body: ${response.body}',
        level: LogLevel.debug,
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to fetch activities. Status: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final message = data["message"];
      if (message is! List) {
        throw Exception('Invalid activities response format');
      }

      _logger.logNetwork(
        'Fetched activities successfully | Count: ${message.length}',
        level: LogLevel.info,
      );

      return message
          .whereType<Map<String, dynamic>>()
          .map((e) => Activity.fromJson(e))
          .toList();
    } catch (e, stackTrace) {
      _logger.logNetwork(
        'Exception while fetching activities : ${e.toString()}',
        level: LogLevel.error,
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception(e);
    }
  }

  Future<bool> deleteAllData() async {
    final endPoint = "activity/delete";
    final url = Uri.parse("$baseUrl$endPoint");
    final token = await LocalDbHelper.getToken();

    _logger.logNetwork(
      'Deleting all activity data | DELETE $url',
      level: LogLevel.info,
    );

    try {
      final response = await client.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          "Authorization": "Bearer $token",
        },
      );

      _logger.logNetwork(
        'Delete all activity data response status: ${response.statusCode}',
        level: LogLevel.debug,
      );
      _logger.logNetwork(
        'Delete all activity data response body: ${response.body}',
        level: LogLevel.debug,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        _logger.logNetwork(
          'Deleted all activity data successfully',
          level: LogLevel.info,
        );
        return true;
      } else {
        _logger.logNetwork(
          'Failed to delete all activity data | Status: ${response.statusCode}',
          level: LogLevel.warning,
        );
        return false;
      }
    } catch (e, stackTrace) {
      _logger.logNetwork(
        'Exception while deleting all activity data',
        level: LogLevel.error,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
