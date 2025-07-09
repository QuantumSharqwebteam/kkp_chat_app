import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:kkpchatapp/core/network/app_exception.dart';
import 'dart:convert';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';

class ApiHelper {
  final http.Client client;
  final String baseUrl;

  ApiHelper({required this.baseUrl, http.Client? client})
      : client = client ?? http.Client();

  Future<Map<String, dynamic>> get(
    String endpoint, {
    bool authorized = false,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final resolvedHeaders = await _buildHeaders(authorized, headers);

    try {
      final response = await client.get(uri, headers: resolvedHeaders);
      return _handleResponse(response);
    } on SocketException {
      throw NoInternetException("No Internet connection.");
    } on FormatException {
      throw FetchDataException("Invalid response format.");
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool authorized = false,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final resolvedHeaders = await _buildHeaders(authorized, headers);

    try {
      final response = await client.post(
        uri,
        headers: resolvedHeaders,
        body: jsonEncode(body ?? {}),
      );
      return _handleResponse(response);
    } on SocketException {
      throw NoInternetException("No Internet connection.");
    } on FormatException {
      throw FetchDataException("Invalid response format.");
    }
  }

  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool authorized = false,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final resolvedHeaders = await _buildHeaders(authorized, headers);

    try {
      final response = await client.put(
        uri,
        headers: resolvedHeaders,
        body: jsonEncode(body ?? {}),
      );
      return _handleResponse(response);
    } on SocketException {
      throw NoInternetException("No Internet connection.");
    } on FormatException {
      throw FetchDataException("Invalid response format.");
    }
  }

  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, dynamic>? body,
    bool authorized = false,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final resolvedHeaders = await _buildHeaders(authorized, headers);

    try {
      final response = await client.delete(
        uri,
        headers: resolvedHeaders,
        body: jsonEncode(body ?? {}),
      );
      return _handleResponse(response);
    } on SocketException {
      throw NoInternetException("No Internet connection.");
    } on FormatException {
      throw FetchDataException("Invalid response format.");
    }
  }

  // Optional: Use this for multipart/form-data if needed
  Future<http.StreamedResponse> sendMultipartRequest(
    http.MultipartRequest request, {
    bool authorized = false,
  }) async {
    if (authorized) {
      final token = await LocalDbHelper.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }
    return await request.send();
  }

  Future<Map<String, String>> _buildHeaders(
    bool authorized,
    Map<String, String>? additionalHeaders,
  ) async {
    final token = authorized ? await LocalDbHelper.getToken() : null;
    return {
      'Content-Type': 'application/json',
      if (authorized && token != null) 'Authorization': 'Bearer $token',
      ...?additionalHeaders,
    };
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw FetchDataException("Non-JSON response: ${response.body}");
    }

    switch (response.statusCode) {
      case 200:
      case 201:
        return decoded;
      case 400:
        throw BadRequestException(decoded['message'] ?? "Bad request");
      case 401:
      case 403:
        throw UnauthorizedException(decoded['message'] ?? "Unauthorized");
      case 404:
        throw NotFoundException(decoded['message'] ?? "Not found");
      case 500:
      case 502:
      case 503:
        throw ServerException(decoded['message'] ?? 'Internal Server Error');
      default:
        throw AppException("Unexpected error: ${response.statusCode}");
    }
  }
}
