import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../../lib/core/errors/failures.dart';
import '../../../lib/core/services/real_supabase_auth_service.dart';
import '../../../lib/core/utils/result.dart';
import '../../../lib/features/auth/domain/entities/auth_session.dart';
import '../../../lib/features/auth/domain/entities/user.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockAuthResponse extends Mock implements AuthResponse {}
class MockSession extends Mock implements Session {}
class MockGoTrueUser extends Mock implements GoTrueUser {}

void main() {
  group('RealSupabaseAuthService', () {
    late RealSupabaseAuthService authService;
    late MockSupabaseClient mockClient;
    late MockGoTrueClient mockAuth;

    setUp(() {
      mockClient = MockSupabaseClient();
      mockAuth = MockGoTrueClient();
      
      when(() => mockClient.auth).thenReturn(mockAuth);
      
      authService = RealSupabaseAuthService(client: mockClient);
    });

    tearDown(() {
      authService.dispose();
    });

    group('getCurrentSession', () {
      test('should return null when no session exists', () async {
        // Arrange
        when(() => mockAuth.currentSession).thenReturn(null);

        // Act
        final result = await authService.getCurrentSession();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull, isNull);
      });

      test('should return AuthSession when session exists', () async {
        // Arrange
        final mockSession = MockSession();
        final mockUser = MockGoTrueUser();
        
        when(() => mockAuth.currentSession).thenReturn(mockSession);
        when(() => mockSession.user).thenReturn(mockUser);
        when(() => mockSession.accessToken).thenReturn('access_token');
        when(() => mockSession.refreshToken).thenReturn('refresh_token');
        when(() => mockSession.expiresAt).thenReturn(1234567890);
        when(() => mockSession.tokenType).thenReturn('bearer');
        
        when(() => mockUser.id).thenReturn('user_id');
        when(() => mockUser.email).thenReturn('test@example.com');
        when(() => mockUser.phone).thenReturn(null);
        when(() => mockUser.createdAt).thenReturn('2023-01-01T00:00:00Z');
        when(() => mockUser.userMetadata).thenReturn({'display_name': 'Test User'});

        // Act
        final result = await authService.getCurrentSession();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull, isA<AuthSession>());
        expect(result.dataOrNull!.user.email, equals('test@example.com'));
      });

      test('should return failure when exception occurs', () async {
        // Arrange
        when(() => mockAuth.currentSession).thenThrow(Exception('Session error'));

        // Act
        final result = await authService.getCurrentSession();

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<AuthFailure>());
      });
    });

    group('signInWithEmail', () {
      test('should return success when sign in is successful', () async {
        // Arrange
        final mockResponse = MockAuthResponse();
        final mockSession = MockSession();
        final mockUser = MockGoTrueUser();
        
        when(() => mockAuth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => mockResponse);
        
        when(() => mockResponse.session).thenReturn(mockSession);
        when(() => mockSession.user).thenReturn(mockUser);
        when(() => mockSession.accessToken).thenReturn('access_token');
        when(() => mockSession.refreshToken).thenReturn('refresh_token');
        when(() => mockSession.expiresAt).thenReturn(1234567890);
        when(() => mockSession.tokenType).thenReturn('bearer');
        
        when(() => mockUser.id).thenReturn('user_id');
        when(() => mockUser.email).thenReturn('test@example.com');
        when(() => mockUser.phone).thenReturn(null);
        when(() => mockUser.createdAt).thenReturn('2023-01-01T00:00:00Z');
        when(() => mockUser.userMetadata).thenReturn({'display_name': 'Test User'});

        // Act
        final result = await authService.signInWithEmail(
          email: 'test@example.com',
          password: 'password123',
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull, isA<AuthSession>());
        expect(result.dataOrNull!.user.email, equals('test@example.com'));
        
        verify(() => mockAuth.signInWithPassword(
          email: 'test@example.com',
          password: 'password123',
        )).called(1);
      });

      test('should return failure when session is null', () async {
        // Arrange
        final mockResponse = MockAuthResponse();
        
        when(() => mockAuth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => mockResponse);
        
        when(() => mockResponse.session).thenReturn(null);

        // Act
        final result = await authService.signInWithEmail(
          email: 'test@example.com',
          password: 'password123',
        );

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<UnknownFailure>());
      });

      test('should retry on failure and eventually succeed', () async {
        // Arrange
        final mockResponse = MockAuthResponse();
        final mockSession = MockSession();
        final mockUser = MockGoTrueUser();
        
        when(() => mockAuth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(Exception('Network error')).thenAnswer((_) async => mockResponse);
        
        when(() => mockResponse.session).thenReturn(mockSession);
        when(() => mockSession.user).thenReturn(mockUser);
        when(() => mockSession.accessToken).thenReturn('access_token');
        when(() => mockSession.refreshToken).thenReturn('refresh_token');
        when(() => mockSession.expiresAt).thenReturn(1234567890);
        when(() => mockSession.tokenType).thenReturn('bearer');
        
        when(() => mockUser.id).thenReturn('user_id');
        when(() => mockUser.email).thenReturn('test@example.com');
        when(() => mockUser.phone).thenReturn(null);
        when(() => mockUser.createdAt).thenReturn('2023-01-01T00:00:00Z');
        when(() => mockUser.userMetadata).thenReturn({'display_name': 'Test User'});

        // Act
        final result = await authService.signInWithEmail(
          email: 'test@example.com',
          password: 'password123',
        );

        // Assert
        expect(result.isSuccess, isTrue);
        verify(() => mockAuth.signInWithPassword(
          email: 'test@example.com',
          password: 'password123',
        )).called(2); // First call fails, second succeeds
      });
    });

    group('signOut', () {
      test('should successfully sign out', () async {
        // Arrange
        when(() => mockAuth.signOut()).thenAnswer((_) async {});

        // Act
        final result = await authService.signOut();

        // Assert
        expect(result.isSuccess, isTrue);
        verify(() => mockAuth.signOut()).called(1);
      });

      test('should return failure when sign out fails', () async {
        // Arrange
        when(() => mockAuth.signOut()).thenThrow(AuthException('Sign out failed'));

        // Act
        final result = await authService.signOut();

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<AuthFailure>());
      });
    });

    group('updateProfile', () {
      test('should successfully update user profile', () async {
        // Arrange
        final mockUser = MockGoTrueUser();
        
        when(() => mockAuth.updateUser(any())).thenAnswer((_) async => UserResponse());
        when(() => mockAuth.currentUser).thenReturn(mockUser);
        when(() => mockClient.from(any())).thenReturn(MockPostgrestQueryBuilder());
        
        when(() => mockUser.id).thenReturn('user_id');
        when(() => mockUser.email).thenReturn('test@example.com');
        when(() => mockUser.phone).thenReturn(null);
        when(() => mockUser.createdAt).thenReturn('2023-01-01T00:00:00Z');
        when(() => mockUser.userMetadata).thenReturn({'display_name': 'Updated User'});
        when(() => mockUser.toJson()).thenReturn({
          'id': 'user_id',
          'email': 'test@example.com',
          'created_at': '2023-01-01T00:00:00Z',
        });

        // Act
        final result = await authService.updateProfile(
          userId: 'user_id',
          displayName: 'Updated User',
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull, isA<User>());
        expect(result.dataOrNull!.displayName, equals('Updated User'));
      });
    });
  });
}

class MockPostgrestQueryBuilder extends Mock implements PostgrestQueryBuilder {}

extension on MockPostgrestQueryBuilder {
  PostgrestQueryBuilder update(Map<String, dynamic> values) {
    return this;
  }
  
  PostgrestQueryBuilder eq(String column, dynamic value) {
    return this;
  }
  
  Future<Map<String, dynamic>> single() async {
    return {
      'id': 'user_id',
      'display_name': 'Updated User',
      'email': 'test@example.com',
      'created_at': '2023-01-01T00:00:00Z',
    };
  }
  
  PostgrestQueryBuilder select([String columns = '*']) {
    return this;
  }
}