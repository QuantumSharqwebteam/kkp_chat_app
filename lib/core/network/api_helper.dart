import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:kkpchatapp/core/network/app_exception.dart';

class ApiHelper {
  static Future<T> safeRequest<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on SocketException {
      throw NetworkException("No internet connection.");
    } on TimeoutException {
      throw NetworkException("Request timed out.");
    } on http.ClientException catch (e) {
      throw NetworkException("Connection issue: ${e.message}");
    } catch (e) {
      throw AppException("Unexpected error: $e");
    }
  }
}
