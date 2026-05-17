// ─── Base Exception ────────────────────────────────────────────────────────

class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, {this.statusCode});

  @override
  String toString() => 'AppException: $message (status: $statusCode)';
}

// ─── Network ───────────────────────────────────────────────────────────────

class NetworkException extends AppException {
  const NetworkException([
    String message = 'No internet connection. Please check your network.',
  ]) : super(message);

  @override
  String toString() => 'NetworkException: $message';
}

// ─── Timeout ───────────────────────────────────────────────────────────────

class TimeoutException extends AppException {
  const TimeoutException([
    String message = 'Request timed out. Please try again.',
  ]) : super(message);

  @override
  String toString() => 'TimeoutException: $message';
}

// ─── Authentication ────────────────────────────────────────────────────────

class UnauthorizedException extends AppException {
  const UnauthorizedException([
    String message = 'Session expired. Please login again.',
  ]) : super(message, statusCode: 401);

  @override
  String toString() => 'UnauthorizedException: $message';
}

class ForbiddenException extends AppException {
  const ForbiddenException([
    String message = 'You do not have permission to perform this action.',
  ]) : super(message, statusCode: 403);

  @override
  String toString() => 'ForbiddenException: $message';
}

// ─── Validation / Business Logic ───────────────────────────────────────────

class ValidationException extends AppException {
  const ValidationException(String message) : super(message, statusCode: 400);

  @override
  String toString() => 'ValidationException: $message';
}

// ─── Not Found ─────────────────────────────────────────────────────────────

class NotFoundException extends AppException {
  const NotFoundException([
    String message = 'The requested resource was not found.',
  ]) : super(message, statusCode: 404);

  @override
  String toString() => 'NotFoundException: $message';
}

// ─── Server ────────────────────────────────────────────────────────────────

class ServerException extends AppException {
  const ServerException([
    String message = 'A server error occurred. Please try again later.',
  ]) : super(message, statusCode: 500);

  @override
  String toString() => 'ServerException: $message';
}

// ─── Unknown ───────────────────────────────────────────────────────────────

class UnknownException extends AppException {
  const UnknownException([
    String message = 'An unexpected error occurred. Please try again.',
  ]) : super(message);

  @override
  String toString() => 'UnknownException: $message';
}

// ─── Helper: map HTTP status to typed exception ────────────────────────────

AppException exceptionFromStatusCode(int statusCode, [String? message]) {
  switch (statusCode) {
    case 400:
      return ValidationException(message ?? 'Bad request.');
    case 401:
      return UnauthorizedException(message ?? 'Unauthorized.');
    case 403:
      return ForbiddenException(message ?? 'Forbidden.');
    case 404:
      return NotFoundException(message ?? 'Not found.');
    case >= 500:
      return ServerException(message ?? 'Server error ($statusCode).');
    default:
      return AppException(
        message ?? 'Unexpected error (status $statusCode).',
        statusCode: statusCode,
      );
  }
}
