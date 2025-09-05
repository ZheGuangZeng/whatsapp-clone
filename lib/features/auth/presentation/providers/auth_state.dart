import 'package:equatable/equatable.dart';

import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user.dart';

/// Base class for authentication states
sealed class AuthState extends Equatable {
  const AuthState();

  /// Initial state when app starts
  const factory AuthState.initial() = InitialState;

  /// Loading state during auth operations
  const factory AuthState.loading() = LoadingState;

  /// Authenticated state when user is logged in
  const factory AuthState.authenticated(AuthSession session) = AuthenticatedState;

  /// Unauthenticated state when user is not logged in
  const factory AuthState.unauthenticated() = UnauthenticatedState;

  /// Verification required state after registration
  const factory AuthState.verificationRequired({
    String? email,
    String? phone,
    AuthSession? tempSession,
  }) = VerificationRequiredState;

  /// Error state when something goes wrong
  const factory AuthState.error(String message) = ErrorState;

  /// Whether the state is loading
  bool get isLoading => this is LoadingState || (this is! ErrorState && this is! UnauthenticatedState && this is! AuthenticatedState && this is! VerificationRequiredState);

  /// Whether the user is authenticated
  bool get isAuthenticated => this is AuthenticatedState;

  /// Get the current user if authenticated
  User? get user {
    return switch (this) {
      AuthenticatedState(session: final session) => session.user,
      _ => null,
    };
  }

  /// Get the current session if authenticated
  AuthSession? get session {
    return switch (this) {
      AuthenticatedState(session: final session) => session,
      _ => null,
    };
  }

  /// Get error message if in error state
  String? get errorMessage {
    return switch (this) {
      ErrorState(message: final message) => message,
      _ => null,
    };
  }

  /// Copy with new values
  AuthState copyWith({
    bool? isLoading,
    String? error,
  }) {
    if (isLoading == true) {
      return const AuthState.loading();
    }
    
    if (error != null) {
      return AuthState.error(error);
    }
    
    return this;
  }
}

/// Initial state when the app starts
final class InitialState extends AuthState {
  const InitialState();

  @override
  List<Object?> get props => [];
}

/// Loading state during authentication operations
final class LoadingState extends AuthState {
  const LoadingState();

  @override
  List<Object?> get props => [];
}

/// State when user is successfully authenticated
final class AuthenticatedState extends AuthState {
  const AuthenticatedState(this.session);

  final AuthSession session;

  @override
  List<Object?> get props => [session];
}

/// State when user is not authenticated
final class UnauthenticatedState extends AuthState {
  const UnauthenticatedState();

  @override
  List<Object?> get props => [];
}

/// State when email/phone verification is required
final class VerificationRequiredState extends AuthState {
  const VerificationRequiredState({
    this.email,
    this.phone,
    this.tempSession,
  });

  final String? email;
  final String? phone;
  final AuthSession? tempSession;

  @override
  List<Object?> get props => [email, phone, tempSession];
}

/// State when an error occurs
final class ErrorState extends AuthState {
  const ErrorState(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}