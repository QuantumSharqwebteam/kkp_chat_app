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
    final token = authorized ? await LocalDbHelper.getToken() : null;

    try {
      final response = await client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (authorized && token != null) 'Authorization': 'Bearer $token',
          ...?headers,
        },
      );
      return _handleResponse(response);
    } on SocketException {
      throw NoInternetException("No Internet connection.");
    } on HttpException {
      throw FetchDataException("Couldn't fetch data.");
    } on FormatException {
      throw FetchDataException("Bad response format.");
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool authorized = false,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final token = authorized ? await LocalDbHelper.getToken() : null;

    try {
      final response = await client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (authorized && token != null) 'Authorization': 'Bearer $token',
          ...?headers,
        },
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } on SocketException {
      throw NoInternetException("No Internet connection.");
    } on HttpException {
      throw FetchDataException("Couldn't fetch data.");
    } on FormatException {
      throw FetchDataException("Bad response format.");
    }
  }

  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool authorized = false,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final token = authorized ? await LocalDbHelper.getToken() : null;

    try {
      final response = await client.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (authorized && token != null) 'Authorization': 'Bearer $token',
          ...?headers,
        },
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } on SocketException {
      throw NoInternetException("No Internet connection.");
    } on HttpException {
      throw FetchDataException("Couldn't update data.");
    } on FormatException {
      throw FetchDataException("Bad response format.");
    }
  }

  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, dynamic>? body,
    bool authorized = false,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final token = authorized ? await LocalDbHelper.getToken() : null;

    try {
      final response = await client.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (authorized && token != null) 'Authorization': 'Bearer $token',
          ...?headers,
        },
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } on SocketException {
      throw NoInternetException("No Internet connection.");
    } on HttpException {
      throw FetchDataException("Couldn't delete resource.");
    } on FormatException {
      throw FetchDataException("Bad response format.");
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final decoded = jsonDecode(response.body);

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
        throw ServerException(
            "Server error: ${decoded['message'] ?? response.body}");
      default:
        throw AppException("Unexpected error: ${response.statusCode}");
    }
  }
}
