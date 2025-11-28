import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:kkpchatapp/core/network/app_exception.dart';
import 'package:kkpchatapp/core/services/logging_service.dart';

class ApiHelper {
  static const String _defaultBaseUrl = "https://api.boomiboutique.com/";
  //"https://kkp-chat.onrender.com/";
  // static String baseUrl2 = "https://hrms-socket.onrender.com";

  static const String otherBaseUrl = "https://kkp-chat.onrender.com";
  final LoggingService _logger = LoggingService.instance;

  String _currentBaseUrl; // Global base URL for the current service

  ApiHelper({String? baseUrl}) : _currentBaseUrl = baseUrl ?? _defaultBaseUrl;

  // Set the base URL for the current service
  void setBaseUrl(String baseUrl) {
    _currentBaseUrl = baseUrl;
  }

  Future<ApiResponse<T>> get<T>(String endpoint, {Map<String, String>? headers}) async {
    return _request<T>('GET', endpoint, headers: headers);
  }

  Future<ApiResponse<T>> post<T>(
    String endpoint,
    dynamic body, {
    Map<String, String>? headers,
  }) async {
    return _request<T>('POST', endpoint, body: body, headers: headers);
  }

  Future<ApiResponse<T>> put<T>(
    String endpoint,
    dynamic body, {
    Map<String, String>? headers,
  }) async {
    return _request<T>('PUT', endpoint, body: body, headers: headers);
  }

  Future<ApiResponse<T>> patch<T>(
    String endpoint,
    Map<String, String>? body, {
    Map<String, String>? headers,
  }) async {
    return _request<T>('PATCH', endpoint, body: body, headers: headers);
  }

  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    return _request<T>('DELETE', endpoint, headers: headers, body: body);
  }

  Future<ApiResponse<T>> _request<T>(
    String method,
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$_currentBaseUrl$endpoint');
    http.Response response;
    final sanitizedBody = body != null ? _sanitizeRequestBody(jsonEncode(body)) : null;

    _logger.logApi(
        '=== REQUEST START ===\nMethod: $method\nURL: $url\nHeaders: ${_sanitizeHeaders(headers ?? {})}\nBody: $sanitizedBody');

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: _defaultHeaders(headers));
          break;
        case 'POST':
          response = await http.post(
            url,
            headers: _defaultHeaders(headers),
            body: jsonEncode(body),
          );
          break;
        case 'PUT':
          response = await http.put(url, headers: _defaultHeaders(headers), body: jsonEncode(body));
          break;
        case 'PATCH':
          response = await http.patch(
            url,
            headers: _defaultHeaders(headers),
            body: jsonEncode(body),
          );
          break;
        case 'DELETE':
          response = await http.delete(url, body: body, headers: _defaultHeaders(headers));
          break;
        default:
          throw BadRequestException('Invalid HTTP method');
      }

      final result = _handleResponse<T>(response);
      _logger.logApi(
        '=== RESPONSE ===\nStatus Code: ${response.statusCode}\nBody: ${_sanitizeResponseBody(response.body)}',
      );

      return result;
    } on SocketException catch (e, s) {
      _logger.error('NETWORK', 'No Internet Connection', error: e, stackTrace: s);
      return ApiResponse.error('No Internet Connection');
    } on AppException catch (e, s) {
      _logger.error('API_EXCEPTION', e.message, error: e, stackTrace: s);
      return ApiResponse.error(e.message);
    } catch (e, s) {
      _logger.error('UNEXPECTED', 'Unexpected error: $e', error: e, stackTrace: s);
      return ApiResponse.error('Something went wrong. Please try again later.');
    }
  }

  Map<String, String> _defaultHeaders(Map<String, String>? customHeaders) {
    return {'Content-Type': 'application/json', ...?customHeaders};
  }

  Map<String, String> _sanitizeHeaders(Map<String, String> headers) {
    final sanitized = Map<String, String>.from(headers);
    const sensitiveHeaders = ['authorization', 'x-api-key', 'cookie', 'set-cookie'];
    for (final key in sanitized.keys.toList()) {
      if (sensitiveHeaders.contains(key.toLowerCase())) {
        sanitized[key] = '***REDACTED***';
      }
    }
    return sanitized;
  }

  String _sanitizeRequestBody(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map<String, dynamic>) {
        final sanitized = Map<String, dynamic>.from(data);
        const sensitiveFields = ['password', 'token', 'secret', 'key', 'otp'];
        for (final field in sensitiveFields) {
          if (sanitized.containsKey(field)) sanitized[field] = '***REDACTED***';
        }
        return jsonEncode(sanitized);
      }
    } catch (_) {}
    return body;
  }

  String _sanitizeResponseBody(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map<String, dynamic>) {
        final sanitized = Map<String, dynamic>.from(data);
        const sensitiveFields = ['token', 'secret', 'key', 'password'];
        for (final field in sensitiveFields) {
          if (sanitized.containsKey(field)) sanitized[field] = '***REDACTED***';
        }
        return jsonEncode(sanitized);
      }
    } catch (_) {}
    return body.length > 1000 ? '${body.substring(0, 1000)}...[TRUNCATED]' : body;
  }

  ApiResponse<T> _handleResponse<T>(http.Response response) {
    final statusCode = response.statusCode;
    final dynamic body = jsonDecode(response.body);

    if (statusCode >= 200 && statusCode < 300) {
      return ApiResponse.success(body as T, statusCode: statusCode);
    }

    switch (statusCode) {
      case 400:
        throw BadRequestException(body['message']);
      case 401:
        throw UnauthorizedException(body['message']);
      case 403:
        throw ForbiddenException(body['message']);
      case 404:
        throw NotFoundException(body['message']);
      case 500:
        throw ServerException(body['message']);
      default:
        throw FetchDataException('Error occurred with StatusCode: $statusCode');
    }
  }
}

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;

  ApiResponse({required this.success, this.data, this.message, this.statusCode});

  factory ApiResponse.success(T data, {String? message, int? statusCode}) {
    return ApiResponse(success: true, data: data, message: message, statusCode: statusCode ?? 200);
  }

  factory ApiResponse.error(String message, {int? statusCode}) {
    return ApiResponse(success: false, message: message, statusCode: statusCode ?? 500);
  }
}
