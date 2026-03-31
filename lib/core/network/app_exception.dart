class AppException implements Exception {
  final String message;
  final String? prefix;

  AppException(this.message, [this.prefix]);

  @override
  String toString() => '$prefix$message';
}

class FetchDataException extends AppException {
  FetchDataException([String? message])
      : super(message ?? 'Error During Communication', 'FetchData: ');
}

class BadRequestException extends AppException {
  BadRequestException([String? message]) : super(message ?? 'Invalid Request', 'BadRequest: ');
}

class UnauthorizedException extends AppException {
  UnauthorizedException([String? message]) : super(message ?? 'Unauthorized', 'Unauthorized: ');
}

class ForbiddenException extends AppException {
  ForbiddenException([String? message]) : super(message ?? 'Forbidden', 'Forbidden: ');
}

class NotFoundException extends AppException {
  NotFoundException([String? message]) : super(message ?? 'Not Found', 'NotFound: ');
}

class ServerException extends AppException {
  ServerException([String? message]) : super(message ?? 'Internal Server Error', 'ServerError: ');
}

class NoInternetException extends AppException {
  NoInternetException([String? message])
      : super(message ?? 'No Internet Connection', 'NoInternet: ');
}
