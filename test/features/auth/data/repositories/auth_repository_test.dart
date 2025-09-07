import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:whatsapp_clone/core/errors/failures.dart';
import 'package:whatsapp_clone/core/utils/result.dart';
import 'package:whatsapp_clone/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:whatsapp_clone/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:whatsapp_clone/features/auth/data/models/auth_session_model.dart';
import 'package:whatsapp_clone/features/auth/data/models/user_model.dart';
import 'package:whatsapp_clone/features/auth/data/repositories/auth_repository.dart';
import 'package:whatsapp_clone/features/auth/domain/entities/auth_session.dart';

import '../../../../fixtures/auth_fixtures.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}
class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

void main() {
  group('AuthRepository', () {
    late AuthRepository repository;
    late MockAuthRemoteDataSource mockRemoteDataSource;
    late MockAuthLocalDataSource mockLocalDataSource;
    late AuthSessionModel testSessionModel;
    late UserModel testUserModel;

    setUp(() {
      mockRemoteDataSource = MockAuthRemoteDataSource();
      mockLocalDataSource = MockAuthLocalDataSource();
      repository = AuthRepository(mockRemoteDataSource, mockLocalDataSource);
      
      testSessionModel = AuthFixtures.createAuthSessionModel();
      testUserModel = AuthFixtures.createUserModel();

      // Register fallback values for mocks
      registerFallbackValue(testSessionModel);
    });

    group('Constructor', () {
      test('should create AuthRepository with valid datasources', () {
        expect(repository, isA<AuthRepository>());
      });
    });

    group('getCurrentSession', () {
      test('should return remote session when available and cache it locally', () async {
        // Arrange
        when(() => mockRemoteDataSource.getCurrentSession())
            .thenAnswer((_) async => testSessionModel);
        when(() => mockLocalDataSource.saveSession(any()))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.getCurrentSession();

        // Assert
        expect(result, isA<Success>());
        final session = (result as Success).data!;
        expect(session.accessToken, equals(testSessionModel.accessToken));
        expect(session.user.id, equals(testSessionModel.user.id));
        verify(() => mockRemoteDataSource.getCurrentSession()).called(1);
        verify(() => mockLocalDataSource.saveSession(testSessionModel)).called(1);
      });

      test('should return cached session when remote is null and session is not expired', () async {
        // Arrange
        final nonExpiredSession = AuthFixtures.createAuthSessionModel(
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );
        when(() => mockRemoteDataSource.getCurrentSession())
            .thenAnswer((_) async => null);
        when(() => mockLocalDataSource.getCachedSession())
            .thenAnswer((_) async => nonExpiredSession);

        // Act
        final result = await repository.getCurrentSession();

        // Assert
        expect(result, isA<Success>());
        final session = (result as Success).data!;
        expect(session.accessToken, equals(nonExpiredSession.accessToken));
        verify(() => mockRemoteDataSource.getCurrentSession()).called(1);
        verify(() => mockLocalDataSource.getCachedSession()).called(1);
      });

      test('should refresh token when cached session is expired and refresh token available', () async {
        // Arrange
        final expiredSession = AuthFixtures.createAuthSessionModel(
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        );
        const refreshToken = 'cached_refresh_token';
        when(() => mockRemoteDataSource.getCurrentSession())
            .thenAnswer((_) async => null);
        when(() => mockLocalDataSource.getCachedSession())
            .thenAnswer((_) async => expiredSession);
        when(() => mockLocalDataSource.getCachedRefreshToken())
            .thenAnswer((_) async => refreshToken);
        when(() => mockRemoteDataSource.refreshToken(refreshToken: refreshToken))
            .thenAnswer((_) async => testSessionModel);
        when(() => mockLocalDataSource.saveSession(any()))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.getCurrentSession();

        // Assert
        expect(result, isA<Success>());
        verify(() => mockRemoteDataSource.getCurrentSession()).called(1);
        verify(() => mockLocalDataSource.getCachedSession()).called(1);
        verify(() => mockLocalDataSource.getCachedRefreshToken()).called(1);
        verify(() => mockRemoteDataSource.refreshToken(refreshToken: refreshToken)).called(1);
        verify(() => mockLocalDataSource.saveSession(testSessionModel)).called(1);
      });

      test('should return null when no sessions available', () async {
        // Arrange
        when(() => mockRemoteDataSource.getCurrentSession())
            .thenAnswer((_) async => null);
        when(() => mockLocalDataSource.getCachedSession())
            .thenAnswer((_) async => null);
        when(() => mockLocalDataSource.getCachedRefreshToken())
            .thenAnswer((_) async => null);

        // Act
        final result = await repository.getCurrentSession();

        // Assert
        expect(result, isA<Success>());
        expect((result as Success).data, isNull);
        verify(() => mockRemoteDataSource.getCurrentSession()).called(1);
        verify(() => mockLocalDataSource.getCachedSession()).called(1);
        verify(() => mockLocalDataSource.getCachedRefreshToken()).called(1);
      });

      test('should return failure when exception occurs', () async {
        // Arrange
        when(() => mockRemoteDataSource.getCurrentSession())
            .thenThrow(Exception('Remote error'));

        // Act
        final result = await repository.getCurrentSession();

        // Assert
        expect(result, isA<ResultFailure>());
        final failure = (result as ResultFailure).failure;
        expect(failure, isA<AuthFailure>());
        expect(failure.message, contains('Failed to get current session'));
      });
    });

    group('signInWithEmail', () {
      test('should return session on successful email sign in', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';
        when(() => mockRemoteDataSource.signInWithEmail(
              email: email,
              password: password,
            )).thenAnswer((_) async => testSessionModel);
        when(() => mockLocalDataSource.saveSession(any()))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.signInWithEmail(
          email: email,
          password: password,
        );

        // Assert
        expect(result, isA<Success>());
        final session = (result as Success).data;
        expect(session.accessToken, equals(testSessionModel.accessToken));
        verify(() => mockRemoteDataSource.signInWithEmail(
              email: email,
              password: password,
            )).called(1);
        verify(() => mockLocalDataSource.saveSession(testSessionModel)).called(1);
      });

      test('should return AuthFailure on AuthException', () async {
        // Arrange
        const email = 'wrong@example.com';
        const password = 'wrongpassword';
        when(() => mockRemoteDataSource.signInWithEmail(
              email: email,
              password: password,
            )).thenThrow(const supabase.AuthException('Invalid credentials'));

        // Act
        final result = await repository.signInWithEmail(
          email: email,
          password: password,
        );

        // Assert
        expect(result, isA<ResultFailure>());
        final failure = (result as ResultFailure).failure;
        expect(failure, isA<AuthFailure>());
        expect(failure.message, equals('Invalid credentials'));
      });

      test('should return AuthFailure on generic exception', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';
        when(() => mockRemoteDataSource.signInWithEmail(
              email: email,
              password: password,
            )).thenThrow(Exception('Network error'));

        // Act
        final result = await repository.signInWithEmail(
          email: email,
          password: password,
        );

        // Assert
        expect(result, isA<ResultFailure>());
        final failure = (result as ResultFailure).failure;
        expect(failure, isA<AuthFailure>());
        expect(failure.message, contains('Failed to sign in with email'));
      });
    });

    group('signInWithPhone', () {
      test('should return session on successful phone sign in', () async {
        // Arrange
        const phone = '+1234567890';
        const password = 'password123';
        when(() => mockRemoteDataSource.signInWithPhone(
              phone: phone,
              password: password,
            )).thenAnswer((_) async => testSessionModel);
        when(() => mockLocalDataSource.saveSession(any()))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.signInWithPhone(
          phone: phone,
          password: password,
        );

        // Assert
        expect(result, isA<Success>());
        final session = (result as Success).data;
        expect(session.accessToken, equals(testSessionModel.accessToken));
        verify(() => mockRemoteDataSource.signInWithPhone(
              phone: phone,
              password: password,
            )).called(1);
        verify(() => mockLocalDataSource.saveSession(testSessionModel)).called(1);
      });

      test('should return AuthFailure on phone sign in failure', () async {
        // Arrange
        const phone = '+1234567890';
        const password = 'wrongpassword';
        when(() => mockRemoteDataSource.signInWithPhone(
              phone: phone,
              password: password,
            )).thenThrow(const supabase.AuthException('Invalid phone or password'));

        // Act
        final result = await repository.signInWithPhone(
          phone: phone,
          password: password,
        );

        // Assert
        expect(result, isA<ResultFailure>());
        final failure = (result as ResultFailure).failure;
        expect(failure, isA<AuthFailure>());
        expect(failure.message, equals('Invalid phone or password'));
      });
    });

    group('signUpWithEmail', () {
      test('should return session and cache it when access token is not empty', () async {
        // Arrange
        const email = 'new@example.com';
        const password = 'password123';
        const displayName = 'New User';
        when(() => mockRemoteDataSource.signUpWithEmail(
              email: email,
              password: password,
              displayName: displayName,
            )).thenAnswer((_) async => testSessionModel);
        when(() => mockLocalDataSource.saveSession(any()))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.signUpWithEmail(
          email: email,
          password: password,
          displayName: displayName,
        );

        // Assert
        expect(result, isA<Success>());
        final session = (result as Success).data;
        expect(session.accessToken, equals(testSessionModel.accessToken));
        verify(() => mockRemoteDataSource.signUpWithEmail(
              email: email,
              password: password,
              displayName: displayName,
            )).called(1);
        verify(() => mockLocalDataSource.saveSession(testSessionModel)).called(1);
      });

      test('should not cache session when access token is empty (verification required)', () async {
        // Arrange
        const email = 'new@example.com';
        const password = 'password123';
        const displayName = 'New User';
        final verificationSession = AuthFixtures.createVerificationSession();
        when(() => mockRemoteDataSource.signUpWithEmail(
              email: email,
              password: password,
              displayName: displayName,
            )).thenAnswer((_) async => verificationSession);

        // Act
        final result = await repository.signUpWithEmail(
          email: email,
          password: password,
          displayName: displayName,
        );

        // Assert
        expect(result, isA<Success>());
        final session = (result as Success).data;
        expect(session.accessToken, isEmpty);
        verify(() => mockRemoteDataSource.signUpWithEmail(
              email: email,
              password: password,
              displayName: displayName,
            )).called(1);
        verifyNever(() => mockLocalDataSource.saveSession(any()));
      });

      test('should return AuthFailure on sign up failure', () async {
        // Arrange
        const email = 'invalid@example.com';
        const password = 'password123';
        const displayName = 'Test User';
        when(() => mockRemoteDataSource.signUpWithEmail(
              email: email,
              password: password,
              displayName: displayName,
            )).thenThrow(const supabase.AuthException('Email already in use'));

        // Act
        final result = await repository.signUpWithEmail(
          email: email,
          password: password,
          displayName: displayName,
        );

        // Assert
        expect(result, isA<ResultFailure>());
        final failure = (result as ResultFailure).failure;
        expect(failure, isA<AuthFailure>());
        expect(failure.message, equals('Email already in use'));
      });
    });

    group('signUpWithPhone', () {
      test('should return session and cache it when access token is not empty', () async {
        // Arrange
        const phone = '+1234567890';
        const password = 'password123';
        const displayName = 'New User';
        when(() => mockRemoteDataSource.signUpWithPhone(
              phone: phone,
              password: password,
              displayName: displayName,
            )).thenAnswer((_) async => testSessionModel);
        when(() => mockLocalDataSource.saveSession(any()))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.signUpWithPhone(
          phone: phone,
          password: password,
          displayName: displayName,
        );

        // Assert
        expect(result, isA<Success>());
        verify(() => mockLocalDataSource.saveSession(testSessionModel)).called(1);
      });

      test('should not cache session when verification is required', () async {
        // Arrange
        const phone = '+1234567890';
        const password = 'password123';
        const displayName = 'New User';
        final verificationSession = AuthFixtures.createVerificationSession(phone: phone);
        when(() => mockRemoteDataSource.signUpWithPhone(
              phone: phone,
              password: password,
              displayName: displayName,
            )).thenAnswer((_) async => verificationSession);

        // Act
        final result = await repository.signUpWithPhone(
          phone: phone,
          password: password,
          displayName: displayName,
        );

        // Assert
        expect(result, isA<Success>());
        verifyNever(() => mockLocalDataSource.saveSession(any()));
      });
    });

    group('Verification Operations', () {
      test('should send email verification successfully', () async {
        // Arrange
        const email = 'test@example.com';
        when(() => mockRemoteDataSource.sendEmailVerification(email: email))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.sendEmailVerification(email: email);

        // Assert
        expect(result, isA<Success>());
        verify(() => mockRemoteDataSource.sendEmailVerification(email: email)).called(1);
      });

      test('should send phone verification successfully', () async {
        // Arrange
        const phone = '+1234567890';
        when(() => mockRemoteDataSource.sendPhoneVerification(phone: phone))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.sendPhoneVerification(phone: phone);

        // Assert
        expect(result, isA<Success>());
        verify(() => mockRemoteDataSource.sendPhoneVerification(phone: phone)).called(1);
      });

      test('should verify email and cache session', () async {
        // Arrange
        const email = 'test@example.com';
        const otp = '123456';
        when(() => mockRemoteDataSource.verifyEmail(
              email: email,
              otp: otp,
            )).thenAnswer((_) async => testSessionModel);
        when(() => mockLocalDataSource.saveSession(any()))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.verifyEmail(email: email, otp: otp);

        // Assert
        expect(result, isA<Success>());
        verify(() => mockRemoteDataSource.verifyEmail(
              email: email,
              otp: otp,
            )).called(1);
        verify(() => mockLocalDataSource.saveSession(testSessionModel)).called(1);
      });

      test('should verify phone and cache session', () async {
        // Arrange
        const phone = '+1234567890';
        const otp = '123456';
        when(() => mockRemoteDataSource.verifyPhone(
              phone: phone,
              otp: otp,
            )).thenAnswer((_) async => testSessionModel);
        when(() => mockLocalDataSource.saveSession(any()))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.verifyPhone(phone: phone, otp: otp);

        // Assert
        expect(result, isA<Success>());
        verify(() => mockLocalDataSource.saveSession(testSessionModel)).called(1);
      });

      test('should return failure on verification error', () async {
        // Arrange
        const email = 'test@example.com';
        const otp = 'wrong_otp';
        when(() => mockRemoteDataSource.verifyEmail(
              email: email,
              otp: otp,
            )).thenThrow(const supabase.AuthException('Invalid OTP'));

        // Act
        final result = await repository.verifyEmail(email: email, otp: otp);

        // Assert
        expect(result, isA<ResultFailure>());
        final failure = (result as ResultFailure).failure;
        expect(failure, isA<AuthFailure>());
        expect(failure.message, equals('Invalid OTP'));
      });
    });

    group('Token Management', () {
      test('should refresh token and cache new session', () async {
        // Arrange
        const refreshTokenValue = 'refresh_token_value';
        when(() => mockRemoteDataSource.refreshToken(
              refreshToken: refreshTokenValue,
            )).thenAnswer((_) async => testSessionModel);
        when(() => mockLocalDataSource.saveSession(any()))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.refreshToken(
          refreshToken: refreshTokenValue,
        );

        // Assert
        expect(result, isA<Success>());
        verify(() => mockRemoteDataSource.refreshToken(
              refreshToken: refreshTokenValue,
            )).called(1);
        verify(() => mockLocalDataSource.saveSession(testSessionModel)).called(1);
      });

      test('should return failure on refresh token error', () async {
        // Arrange
        const refreshTokenValue = 'invalid_refresh_token';
        when(() => mockRemoteDataSource.refreshToken(
              refreshToken: refreshTokenValue,
            )).thenThrow(const supabase.AuthException('Invalid refresh token'));

        // Act
        final result = await repository.refreshToken(
          refreshToken: refreshTokenValue,
        );

        // Assert
        expect(result, isA<ResultFailure>());
        final failure = (result as ResultFailure).failure;
        expect(failure, isA<AuthFailure>());
        expect(failure.message, equals('Invalid refresh token'));
      });
    });

    group('Sign Out', () {
      test('should sign out from remote and clear local session', () async {
        // Arrange
        when(() => mockRemoteDataSource.signOut()).thenAnswer((_) async {});
        when(() => mockLocalDataSource.clearSession()).thenAnswer((_) async {});

        // Act
        final result = await repository.signOut();

        // Assert
        expect(result, isA<Success>());
        verify(() => mockRemoteDataSource.signOut()).called(1);
        verify(() => mockLocalDataSource.clearSession()).called(1);
      });

      test('should return failure on sign out error', () async {
        // Arrange
        when(() => mockRemoteDataSource.signOut())
            .thenThrow(const supabase.AuthException('Sign out failed'));

        // Act
        final result = await repository.signOut();

        // Assert
        expect(result, isA<ResultFailure>());
        final failure = (result as ResultFailure).failure;
        expect(failure, isA<AuthFailure>());
        expect(failure.message, equals('Sign out failed'));
      });
    });

    group('Password Management', () {
      test('should send password reset successfully', () async {
        // Arrange
        const email = 'test@example.com';
        when(() => mockRemoteDataSource.sendPasswordReset(email: email))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.sendPasswordReset(email: email);

        // Assert
        expect(result, isA<Success>());
        verify(() => mockRemoteDataSource.sendPasswordReset(email: email)).called(1);
      });

      test('should return failure for resetPassword as it is not implemented', () async {
        // Act
        final result = await repository.resetPassword(
          token: 'token',
          newPassword: 'newPassword',
        );

        // Assert
        expect(result, isA<ResultFailure>());
        final failure = (result as ResultFailure).failure;
        expect(failure, isA<AuthFailure>());
        expect(failure.message, equals('Password reset is handled through email flow'));
      });
    });

    group('Profile Management', () {
      test('should update profile and update cached session', () async {
        // Arrange
        const userId = 'user123';
        const displayName = 'Updated Name';
        const status = 'Busy';
        const avatarUrl = 'https://example.com/avatar.jpg';

        when(() => mockRemoteDataSource.updateProfile(
              userId: userId,
              displayName: displayName,
              status: status,
              avatarUrl: avatarUrl,
            )).thenAnswer((_) async => testUserModel);
        when(() => mockLocalDataSource.getCachedSession())
            .thenAnswer((_) async => testSessionModel);
        when(() => mockLocalDataSource.saveSession(any()))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.updateProfile(
          userId: userId,
          displayName: displayName,
          status: status,
          avatarUrl: avatarUrl,
        );

        // Assert
        expect(result, isA<Success>());
        final user = (result as Success).data;
        expect(user.id, equals(testUserModel.id));
        verify(() => mockRemoteDataSource.updateProfile(
              userId: userId,
              displayName: displayName,
              status: status,
              avatarUrl: avatarUrl,
            )).called(1);
        verify(() => mockLocalDataSource.getCachedSession()).called(1);
        verify(() => mockLocalDataSource.saveSession(any())).called(1);
      });

      test('should update profile without updating cache when no cached session', () async {
        // Arrange
        const userId = 'user123';
        when(() => mockRemoteDataSource.updateProfile(userId: userId))
            .thenAnswer((_) async => testUserModel);
        when(() => mockLocalDataSource.getCachedSession())
            .thenAnswer((_) async => null);

        // Act
        final result = await repository.updateProfile(userId: userId);

        // Assert
        expect(result, isA<Success>());
        verify(() => mockLocalDataSource.getCachedSession()).called(1);
        verifyNever(() => mockLocalDataSource.saveSession(any()));
      });

      test('should update online status', () async {
        // Arrange
        const userId = 'user123';
        const isOnline = true;
        when(() => mockRemoteDataSource.updateOnlineStatus(
              userId: userId,
              isOnline: isOnline,
            )).thenAnswer((_) async {});

        // Act
        final result = await repository.updateOnlineStatus(
          userId: userId,
          isOnline: isOnline,
        );

        // Assert
        expect(result, isA<Success>());
        verify(() => mockRemoteDataSource.updateOnlineStatus(
              userId: userId,
              isOnline: isOnline,
            )).called(1);
      });

      test('should get user profile', () async {
        // Arrange
        const userId = 'user123';
        when(() => mockRemoteDataSource.getUserProfile(userId))
            .thenAnswer((_) async => testUserModel);

        // Act
        final result = await repository.getUserProfile(userId: userId);

        // Assert
        expect(result, isA<Success>());
        final user = (result as Success).data;
        expect(user.id, equals(testUserModel.id));
        verify(() => mockRemoteDataSource.getUserProfile(userId)).called(1);
      });

      test('should return failure on profile update error', () async {
        // Arrange
        const userId = 'user123';
        when(() => mockRemoteDataSource.updateProfile(userId: userId))
            .thenThrow(Exception('Profile update failed'));

        // Act
        final result = await repository.updateProfile(userId: userId);

        // Assert
        expect(result, isA<ResultFailure>());
        final failure = (result as ResultFailure).failure;
        expect(failure, isA<AuthFailure>());
        expect(failure.message, contains('Failed to update profile'));
      });
    });

    group('Auth State Changes Stream', () {
      test('should map remote auth state changes to domain entities', () async {
        // Arrange
        final streamController = StreamController<AuthSessionModel?>();
        when(() => mockRemoteDataSource.authStateChanges)
            .thenAnswer((_) => streamController.stream);

        // Act
        final stream = repository.authStateChanges;

        // Emit test data
        streamController.add(testSessionModel);
        streamController.add(null);

        // Assert
        await expectLater(
          stream,
          emitsInOrder([
            isA<AuthSession>().having((s) => s.accessToken, 'accessToken', testSessionModel.accessToken),
            isNull,
          ]),
        );

        streamController.close();
      });
    });

    group('Error Handling', () {
      test('should handle all types of exceptions properly', () async {
        // Test different exception types for various methods
        when(() => mockRemoteDataSource.getCurrentSession())
            .thenThrow(const supabase.PostgrestException(message: 'Database error'));

        final result = await repository.getCurrentSession();

        expect(result, isA<ResultFailure>());
        final failure = (result as ResultFailure).failure;
        expect(failure, isA<AuthFailure>());
        expect(failure.message, contains('Failed to get current session'));
      });
    });
  });
}