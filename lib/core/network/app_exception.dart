class AppException implements Exception {
  final String message;
  final String? prefix;

  AppException(this.message, {this.prefix});

  @override
  String toString() => prefix != null ? '$prefix: $message' : message;
}

class NetworkException extends AppException {
  NetworkException(super.message) : super(prefix: "Network Error");
}

class ServerException extends AppException {
  ServerException(super.message) : super(prefix: "Server Error");
}

class ValidationException extends AppException {
  ValidationException(super.message) : super(prefix: "Validation Error");
}
