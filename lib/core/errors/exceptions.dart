/// Base class for all exceptions in the application
abstract class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Server-related exceptions
class ServerException extends AppException {
  const ServerException(super.message);
}

/// Authentication-related exceptions
class AuthException extends AppException {
  const AuthException(super.message);
}

/// Network-related exceptions
class NetworkException extends AppException {
  const NetworkException(super.message);
}

/// Cache-related exceptions
class CacheException extends AppException {
  const CacheException(super.message);
}

/// Permission-related exceptions
class PermissionException extends AppException {
  const PermissionException(super.message);
}

/// Validation-related exceptions
class ValidationException extends AppException {
  const ValidationException(super.message);
}