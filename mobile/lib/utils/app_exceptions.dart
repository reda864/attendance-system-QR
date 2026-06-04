class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException([
    super.message = 'Pas de connexion Internet. Vérifiez votre réseau.',
  ]);
}

class TimeoutException extends AppException {
  const TimeoutException([
    super.message = 'Délai dépassé. Réessayez.',
  ]);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([
    super.message = 'Session expirée. Reconnectez-vous.',
  ]);
}

class ValidationException extends AppException {
  const ValidationException(super.message);
}

class NotFoundException extends AppException {
  const NotFoundException([
    super.message = 'Ressource introuvable.',
  ]);
}

class ServerException extends AppException {
  const ServerException([
    super.message = 'Erreur serveur. Réessayez plus tard.',
  ]);
}

AppException exceptionFromStatusCode(int statusCode, [String? fallback]) {
  final msg = fallback ?? 'Une erreur est survenue';
  switch (statusCode) {
    case 400:
    case 422:
      return ValidationException(msg);
    case 401:
      return UnauthorizedException(msg);
    case 404:
      return NotFoundException(msg);
    case >= 500:
      return ServerException(msg);
    default:
      return AppException(msg);
  }
}
