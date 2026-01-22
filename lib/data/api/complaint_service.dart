import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:kkpchatapp/core/services/logging_service.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/data/models/complaint_model.dart';

class ComplaintService {
  final String baseUrl = dotenv.env["BASE_URL"]!;

  /// Fetches all complaints from the server
  Future<List<ComplaintModel>> getAllComplaints() async {
    try {
      final token = await LocalDbHelper.getToken();
      LoggingService.instance.logAuth(
        'AuthToken: $token',
        level: LogLevel.debug,
      );

      LoggingService.instance.logNetwork(
        'Fetching all complaints from $baseUrl/complaint/getAll',
        level: LogLevel.info,
      );

      final response = await http.get(
        Uri.parse('$baseUrl/complaint/getAll'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      LoggingService.instance.logNetwork(
        'Response status: ${response.statusCode}',
        level: LogLevel.debug,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['message'] as List<dynamic>;
        LoggingService.instance.logNetwork(
          'Successfully fetched ${data.length} complaints',
          level: LogLevel.info,
        );
        return data.map((e) => ComplaintModel.fromJson(e)).toList();
      } else {
        final errorMessage = "Failed to load complaints: ${response.statusCode}";
        LoggingService.instance.logNetwork(
          errorMessage,
          level: LogLevel.error,
          error: response.body,
        );
        throw Exception(errorMessage);
      }
    } catch (e, stackTrace) {
      LoggingService.instance.logNetwork(
        'Exception in getAllComplaints',
        level: LogLevel.fatal,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Submits a new complaint to the server
  Future<bool> submitComplaint({
    required String subject,
    required String description,
  }) async {
    try {
      final token = await LocalDbHelper.getToken();
      LoggingService.instance.logAuth(
        'AuthToken: $token',
        level: LogLevel.debug,
      );

      LoggingService.instance.logNetwork(
        'Submitting complaint: $subject',
        level: LogLevel.info,
      );

      final response = await http.post(
        Uri.parse('$baseUrl/complaint/add'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "subject": subject,
          "description": description,
        }),
      );

      LoggingService.instance.logNetwork(
        'Response status: ${response.statusCode}',
        level: LogLevel.debug,
      );

      final parsedBody = jsonDecode(response.body);
      final isSuccess = response.statusCode == 201 ||
          parsedBody["status"] == 201 ||
          parsedBody["message"] == "Item saved successfully";

      if (!isSuccess) {
        LoggingService.instance.logNetwork(
          'Failed to submit complaint: ${parsedBody["message"]}',
          level: LogLevel.error,
          error: parsedBody,
        );
      }

      return isSuccess;
    } catch (e, stackTrace) {
      LoggingService.instance.logNetwork(
        'Exception in submitComplaint',
        level: LogLevel.fatal,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
