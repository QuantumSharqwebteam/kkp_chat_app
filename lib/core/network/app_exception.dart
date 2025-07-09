class AppException implements Exception {
  final String message;
  final String? prefix;

  AppException(this.message, [this.prefix]);

  @override
  String toString() => '${prefix ?? ''}$message';
}

class FetchDataException extends AppException {
  FetchDataException(String message) : super(message, "Fetch Error: ");
}

class BadRequestException extends AppException {
  BadRequestException(String message) : super(message, "Bad Request: ");
}

class UnauthorizedException extends AppException {
  UnauthorizedException(String message) : super(message, "Unauthorized: ");
}

class NotFoundException extends AppException {
  NotFoundException(String message) : super(message, "Not Found: ");
}

class ServerException extends AppException {
  ServerException(String message) : super(message, "Server Error: ");
}

class NoInternetException extends AppException {
  NoInternetException(String message) : super(message, "No Internet: ");
}

class TimeoutException extends AppException {
  TimeoutException(String message) : super(message, "Timeout: ");
}
