import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kkpchatapp/core/constant.dart';
import 'package:kkpchatapp/core/services/logging_service.dart';

/// A failed API call that carries the server's own message and status code,
/// so the UI can show something readable instead of a nested
/// `Exception: Error during X: Exception: Failed to Y: {json}`.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// The HTTP client every API service should use.
///
/// Wraps [http.Client] and logs, for every single request:
///   → METHOD url
///     request body
///   ← status
///     response body
///
/// in bright yellow and split across as many console lines as the payload
/// needs. Services therefore do not need to hand-log URLs, bodies or responses
/// method by method — this is the one place that knows all three.
///
/// Authorization headers are redacted; a bearer token must never reach the log.
class ApiClient {
  ApiClient._();

  /// Use in place of `http.Client()` when constructing a service.
  static http.Client create() => LoggingHttpClient();
}

class LoggingHttpClient extends http.BaseClient {
  LoggingHttpClient([http.Client? inner]) : _inner = inner ?? http.Client();

  final http.Client _inner;

  /// Header names whose values are never printed.
  static const Set<String> _redactedHeaders = {
    'authorization',
    'cookie',
    'set-cookie',
    'x-api-key',
  };

  /// Body fields whose values are never printed, in requests or responses.
  /// Login and signup post credentials through here.
  static const Set<String> _redactedFields = {
    'password',
    'newpassword',
    'oldpassword',
    'confirmpassword',
    'token',
    'accesstoken',
    'refreshtoken',
    'secret',
    'otp',
    'apikey',
    'secretkey',
    'accesskey',
  };

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final logger = LoggingService.instance;
    final shouldLog = AppConstants.enableLogging;

    if (shouldLog) {
      logger.logApiData(
        '→ ${request.method} ${request.url}',
        {
          'headers': _safeHeaders(request.headers),
          'body': _requestBody(request),
        },
      );
    }

    final http.StreamedResponse streamed;
    try {
      streamed = await _inner.send(request);
    } catch (e, stack) {
      if (shouldLog) {
        logger.logNetwork(
          '✖ ${request.method} ${request.url} — transport failure: $e',
          level: LogLevel.error,
          error: e,
          stackTrace: stack,
        );
      }
      rethrow;
    }

    if (!shouldLog) return streamed;

    // The stream can only be read once, so buffer it and hand back a fresh one.
    // Callers already do this via Response.fromStream, so nothing extra is held.
    final bytes = await streamed.stream.toBytes();

    logger.logApiData(
      '← ${streamed.statusCode} ${request.method} ${request.url}',
      _decodeBody(bytes),
    );

    return http.StreamedResponse(
      Stream<List<int>>.value(bytes),
      streamed.statusCode,
      contentLength: bytes.length,
      request: streamed.request,
      headers: streamed.headers,
      isRedirect: streamed.isRedirect,
      persistentConnection: streamed.persistentConnection,
      reasonPhrase: streamed.reasonPhrase,
    );
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }

  static Map<String, String> _safeHeaders(Map<String, String> headers) {
    return headers.map((key, value) => MapEntry(
          key,
          _redactedHeaders.contains(key.toLowerCase()) ? '<redacted>' : value,
        ));
  }

  /// Decoded JSON when possible so the payload pretty-prints; raw text
  /// otherwise. Never throws — logging must not be able to break a request.
  static Object? _requestBody(http.BaseRequest request) {
    if (request is http.Request) {
      if (request.body.isEmpty) return null;
      return _decodeText(request.body);
    }
    if (request is http.MultipartRequest) {
      return {
        'fields': request.fields,
        'files': request.files
            .map((file) => {
                  'field': file.field,
                  'filename': file.filename,
                  'length': file.length,
                  'contentType': file.contentType.toString(),
                })
            .toList(),
      };
    }
    return '<${request.runtimeType} body not logged>';
  }

  static Object? _decodeBody(List<int> bytes) {
    if (bytes.isEmpty) return null;
    try {
      return _decodeText(utf8.decode(bytes));
    } catch (_) {
      return '<${bytes.length} bytes of non-UTF8 data>';
    }
  }

  static Object? _decodeText(String text) {
    try {
      return _redact(jsonDecode(text));
    } catch (_) {
      return text;
    }
  }

  /// Walks a decoded payload and masks any sensitive field, at any depth.
  static Object? _redact(Object? value) {
    if (value is Map) {
      return value.map((key, val) {
        final normalized = key.toString().toLowerCase().replaceAll('_', '');
        return MapEntry(
          key,
          _redactedFields.contains(normalized) ? '<redacted>' : _redact(val),
        );
      });
    }
    if (value is List) return value.map(_redact).toList();
    return value;
  }
}
