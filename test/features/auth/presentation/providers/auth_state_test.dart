import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_clone/features/auth/domain/entities/auth_session.dart';
import 'package:whatsapp_clone/features/auth/domain/entities/user.dart';
import 'package:whatsapp_clone/features/auth/presentation/providers/auth_state.dart';

void main() {
  group('AuthState Factory Constructors', () {
    test('should create initial state', () {
      // Act
      const state = AuthState.initial();
      
      // Assert
      expect(state, isA<InitialState>());
      expect(state.isLoading, isFalse);
      expect(state.isAuthenticated, isFalse);
      expect(state.user, isNull);
      expect(state.session, isNull);
      expect(state.errorMessage, isNull);
    });

    test('should create loading state', () {
      // Act
      const state = AuthState.loading();
      
      // Assert
      expect(state, isA<LoadingState>());
      expect(state.isLoading, isTrue);
      expect(state.isAuthenticated, isFalse);
      expect(state.user, isNull);
      expect(state.session, isNull);
      expect(state.errorMessage, isNull);
    });

    test('should create authenticated state with session', () {
      // Arrange
      final user = User(
        id: '123',
        email: 'test@example.com',
        phone: null,
        displayName: 'Test User',
        avatarUrl: null,
        createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
      );
      final session = AuthSession(
        accessToken: 'access_token',
        refreshToken: 'refresh_token',
        expiresAt: DateTime.parse('2023-01-01T01:00:00.000Z'),
        user: user,
        tokenType: 'Bearer',
      );
      
      // Act
      final state = AuthState.authenticated(session);
      
      // Assert
      expect(state, isA<AuthenticatedState>());
      expect(state.isLoading, isFalse);
      expect(state.isAuthenticated, isTrue);
      expect(state.user, equals(user));
      expect(state.session, equals(session));
      expect(state.errorMessage, isNull);
    });

    test('should create unauthenticated state with default values', () {
      // Act
      const state = AuthState.unauthenticated();
      
      // Assert
      expect(state, isA<UnauthenticatedState>());
      expect((state as UnauthenticatedState).isFirstTime, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.isAuthenticated, isFalse);
      expect(state.user, isNull);
      expect(state.session, isNull);
      expect(state.errorMessage, isNull);
    });

    test('should create unauthenticated state with isFirstTime true', () {
      // Act
      const state = AuthState.unauthenticated(isFirstTime: true);
      
      // Assert
      expect(state, isA<UnauthenticatedState>());
      expect((state as UnauthenticatedState).isFirstTime, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.isAuthenticated, isFalse);
      expect(state.user, isNull);
      expect(state.session, isNull);
      expect(state.errorMessage, isNull);
    });

    test('should create verification required state with all parameters', () {
      // Arrange
      final user = User(
        id: '123',
        email: 'test@example.com',
        phone: '+1234567890',
        displayName: 'Test User',
        avatarUrl: null,
        createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
      );
      final tempSession = AuthSession(
        accessToken: 'temp_token',
        refreshToken: 'temp_refresh',
        expiresAt: DateTime.parse('2023-01-01T01:00:00.000Z'),
        user: user,
        tokenType: 'Bearer',
      );
      
      // Act
      final state = AuthState.verificationRequired(
        email: 'test@example.com',
        phone: '+1234567890',
        tempSession: tempSession,
      );
      
      // Assert
      expect(state, isA<VerificationRequiredState>());
      final verificationState = state as VerificationRequiredState;
      expect(verificationState.email, equals('test@example.com'));
      expect(verificationState.phone, equals('+1234567890'));
      expect(verificationState.tempSession, equals(tempSession));
      expect(state.isLoading, isFalse);
      expect(state.isAuthenticated, isFalse);
      expect(state.user, isNull);
      expect(state.session, isNull);
      expect(state.errorMessage, isNull);
    });

    test('should create verification required state with minimal parameters', () {
      // Act
      const state = AuthState.verificationRequired();
      
      // Assert
      expect(state, isA<VerificationRequiredState>());
      const verificationState = state as VerificationRequiredState;
      expect(verificationState.email, isNull);
      expect(verificationState.phone, isNull);
      expect(verificationState.tempSession, isNull);
      expect(state.isLoading, isFalse);
      expect(state.isAuthenticated, isFalse);
      expect(state.user, isNull);
      expect(state.session, isNull);
      expect(state.errorMessage, isNull);
    });

    test('should create error state', () {
      // Act
      const state = AuthState.error('Something went wrong');
      
      // Assert
      expect(state, isA<ErrorState>());
      expect(state.isLoading, isFalse);
      expect(state.isAuthenticated, isFalse);
      expect(state.user, isNull);
      expect(state.session, isNull);
      expect(state.errorMessage, equals('Something went wrong'));
    });
  });

  group('AuthState Properties', () {
    test('isLoading should be correct for different states', () {
      expect(const AuthState.initial().isLoading, isFalse);
      expect(const AuthState.loading().isLoading, isTrue);
      expect(const AuthState.error('error').isLoading, isFalse);
      expect(const AuthState.verificationRequired().isLoading, isFalse);
      
      final user = User(
        id: '123',
        email: 'test@example.com',
        phone: null,
        displayName: 'Test User',
        avatarUrl: null,
        createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
      );
      final session = AuthSession(
        accessToken: 'access_token',
        refreshToken: 'refresh_token',
        expiresAt: DateTime.parse('2023-01-01T01:00:00.000Z'),
        user: user,
        tokenType: 'Bearer',
      );
      expect(AuthState.authenticated(session).isLoading, isFalse);
    });

    test('isAuthenticated should only be true for authenticated state', () {
      expect(const AuthState.initial().isAuthenticated, isFalse);
      expect(const AuthState.loading().isAuthenticated, isFalse);
      expect(const AuthState.error('error').isAuthenticated, isFalse);
      expect(const AuthState.verificationRequired().isAuthenticated, isFalse);
      
      final user = User(
        id: '123',
        email: 'test@example.com',
        phone: null,
        displayName: 'Test User',
        avatarUrl: null,
        createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
      );
      final session = AuthSession(
        accessToken: 'access_token',
        refreshToken: 'refresh_token',
        expiresAt: DateTime.parse('2023-01-01T01:00:00.000Z'),
        user: user,
        tokenType: 'Bearer',
      );
      expect(AuthState.authenticated(session).isAuthenticated, isTrue);
    });
  });

  group('AuthState Equality', () {
    test('should be equal when states are the same', () {
      // Arrange & Act
      const state1 = AuthState.initial();
      const state2 = AuthState.initial();
      
      // Assert
      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));
    });

    test('should be equal for unauthenticated states with same parameters', () {
      // Arrange & Act
      const state1 = AuthState.unauthenticated(isFirstTime: true);
      const state2 = AuthState.unauthenticated(isFirstTime: true);
      
      // Assert
      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));
    });

    test('should not be equal for unauthenticated states with different parameters', () {
      // Arrange & Act
      const state1 = AuthState.unauthenticated(isFirstTime: true);
      const state2 = AuthState.unauthenticated(isFirstTime: false);
      
      // Assert
      expect(state1, isNot(equals(state2)));
      expect(state1.hashCode, isNot(equals(state2.hashCode)));
    });

    test('should be equal for unauthenticated states using default values', () {
      // Arrange & Act
      const state1 = AuthState.unauthenticated();
      const state2 = AuthState.unauthenticated(isFirstTime: false);
      
      // Assert
      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));
    });
  });

  group('AuthState copyWith', () {
    test('should return loading state when isLoading is true', () {
      // Arrange
      const initialState = AuthState.initial();
      
      // Act
      final newState = initialState.copyWith(isLoading: true);
      
      // Assert
      expect(newState, isA<LoadingState>());
      expect(newState.isLoading, isTrue);
    });

    test('should return error state when error is provided', () {
      // Arrange
      const initialState = AuthState.initial();
      
      // Act
      final newState = initialState.copyWith(error: 'Test error');
      
      // Assert
      expect(newState, isA<ErrorState>());
      expect(newState.errorMessage, equals('Test error'));
    });

    test('should return same state when no parameters provided', () {
      // Arrange
      const initialState = AuthState.initial();
      
      // Act
      final newState = initialState.copyWith();
      
      // Assert
      expect(newState, equals(initialState));
    });
  });
}