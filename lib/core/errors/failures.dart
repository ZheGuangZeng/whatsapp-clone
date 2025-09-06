import 'package:equatable/equatable.dart';

/// Abstract base class for all failures in the application
abstract class Failure extends Equatable {
  const Failure({required this.message});

  final String message;

  @override
  List<Object> get props => [message];
}

/// Server-related failures
class ServerFailure extends Failure {
  const ServerFailure({required super.message});
}

/// Authentication-related failures
class AuthFailure extends Failure {
  const AuthFailure({required super.message});
}

/// Network-related failures
class NetworkFailure extends Failure {
  const NetworkFailure({required super.message});
}

/// Cache-related failures
class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

/// Permission-related failures
class PermissionFailure extends Failure {
  const PermissionFailure({required super.message});
}

/// Validation-related failures
class ValidationFailure extends Failure {
  const ValidationFailure({required super.message});
}

/// Authorization-related failures
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({required super.message});
}

/// Unknown/unexpected failures
class UnknownFailure extends Failure {
  const UnknownFailure({required super.message});
}

/// Storage-related failures (file operations)
class StorageFailure extends Failure {
  const StorageFailure(String message) : super(message: message);
}

/// Database-related failures
class DatabaseFailure extends Failure {
  const DatabaseFailure(String message) : super(message: message);
}

/// Processing-related failures (image/video processing)
class ProcessingFailure extends Failure {
  const ProcessingFailure(String message) : super(message: message);
}

/// Not implemented functionality failures
class NotImplementedFailure extends Failure {
  const NotImplementedFailure(String message) : super(message: message);
}

/// Service-related failures (external services)
class ServiceFailure extends Failure {
  const ServiceFailure(String message) : super(message: message);
}

/// Conflict-related failures (resource conflicts)
class ConflictFailure extends Failure {
  const ConflictFailure(String message) : super(message: message);
}