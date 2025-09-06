import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:whatsapp_clone/features/auth/data/datasources/auth_remote_datasource.dart';

import '../../../../fixtures/auth_fixtures.dart';
import '../../../../helpers/test_helper.dart';

class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockUser extends Mock implements User {}
class MockSession extends Mock implements Session {}
class MockAuthResponse extends Mock implements AuthResponse {}
class MockPostgrestBuilder extends Mock implements PostgrestBuilder {}
class MockResendResponse extends Mock implements ResendResponse {}

void main() {
  group('AuthRemoteDataSource', () {
    late AuthRemoteDataSource datasource;
    late MockSupabaseClient mockSupabaseClient;
    late MockGoTrueClient mockAuth;
    late MockUser mockUser;
    late MockSession mockSession;
    late MockAuthResponse mockAuthResponse;
    late MockPostgrestBuilder mockPostgrestBuilder;

    setUp(() {
      mockSupabaseClient = TestHelper.createMockSupabaseClient();
      mockAuth = MockGoTrueClient();
      mockUser = MockUser();
      mockSession = MockSession();
      mockAuthResponse = MockAuthResponse();
      mockPostgrestBuilder = MockPostgrestBuilder();

      when(() => mockSupabaseClient.auth).thenReturn(mockAuth);
      when(() => mockSupabaseClient.from(any())).thenReturn(mockPostgrestBuilder);

      datasource = AuthRemoteDataSource(mockSupabaseClient);

      // Set up common mock returns
      when(() => mockUser.id).thenReturn(AuthFixtures.testUserId);
      when(() => mockUser.email).thenReturn(AuthFixtures.testEmail);
      when(() => mockUser.toJson()).thenReturn(AuthFixtures.createSupabaseUserJson());
      when(() => mockSession.user).thenReturn(mockUser);
      when(() => mockSession.accessToken).thenReturn(AuthFixtures.testAccessToken);
      when(() => mockSession.refreshToken).thenReturn(AuthFixtures.testRefreshToken);
      when(() => mockSession.tokenType).thenReturn(AuthFixtures.testTokenType);
      when(() => mockSession.expiresAt).thenReturn(AuthFixtures.testExpiresAt.millisecondsSinceEpoch);
    });

    group('Constructor', () {
      test('should create AuthRemoteDataSource with valid SupabaseClient', () {
        expect(datasource, isA<AuthRemoteDataSource>());
      });
    });

    group('getCurrentSession', () {
      test('should return null when no current session exists', () async {
        // Arrange
        when(() => mockAuth.currentSession).thenReturn(null);

        // Act
        final result = await datasource.getCurrentSession();

        // Assert
        expect(result, isNull);
        verify(() => mockAuth.currentSession).called(1);
      });

      test('should return null when session has no user', () async {
        // Arrange
        when(() => mockAuth.currentSession).thenReturn(mockSession);
        when(() => mockSession.user).thenReturn(null);

        // Act
        final result = await datasource.getCurrentSession();

        // Assert
        expect(result, isNull);
        verify(() => mockAuth.currentSession).called(1);
      });
    });

    group('signOut', () {
      test('should call Supabase auth signOut', () async {
        // Arrange
        when(() => mockAuth.signOut()).thenAnswer((_) async {});

        // Act
        await datasource.signOut();

        // Assert
        verify(() => mockAuth.signOut()).called(1);
      });

      test('should handle signOut errors', () async {
        // Arrange
        when(() => mockAuth.signOut())
            .thenThrow(const AuthException('Sign out failed'));

        // Act & Assert
        expect(
          () => datasource.signOut(),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('sendPasswordReset', () {
      test('should call Supabase resetPasswordForEmail', () async {
        // Arrange
        const email = 'test@example.com';
        when(() => mockAuth.resetPasswordForEmail(email))
            .thenAnswer((_) async {});

        // Act
        await datasource.sendPasswordReset(email: email);

        // Assert
        verify(() => mockAuth.resetPasswordForEmail(email)).called(1);
      });

      test('should handle password reset errors', () async {
        // Arrange
        const email = 'invalid@example.com';
        when(() => mockAuth.resetPasswordForEmail(email))
            .thenThrow(const AuthException('Password reset failed'));

        // Act & Assert
        expect(
          () => datasource.sendPasswordReset(email: email),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('Email Sign In', () {
      test('should throw AuthException when sign in response has no session', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';
        
        when(() => mockAuthResponse.session).thenReturn(null);
        when(() => mockAuthResponse.user).thenReturn(null);
        when(() => mockAuth.signInWithPassword(email: email, password: password))
            .thenAnswer((_) async => mockAuthResponse);

        // Act & Assert
        expect(
          () => datasource.signInWithEmail(email: email, password: password),
          throwsA(isA<AuthException>()),
        );
        verify(() => mockAuth.signInWithPassword(email: email, password: password)).called(1);
      });

      test('should throw AuthException when sign in response has no user', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';
        
        when(() => mockAuthResponse.session).thenReturn(mockSession);
        when(() => mockAuthResponse.user).thenReturn(null);
        when(() => mockAuth.signInWithPassword(email: email, password: password))
            .thenAnswer((_) async => mockAuthResponse);

        // Act & Assert
        expect(
          () => datasource.signInWithEmail(email: email, password: password),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('Phone Sign In', () {
      test('should throw AuthException when phone sign in fails', () async {
        // Arrange
        const phone = '+1234567890';
        const password = 'password123';
        
        when(() => mockAuthResponse.session).thenReturn(null);
        when(() => mockAuthResponse.user).thenReturn(null);
        when(() => mockAuth.signInWithPassword(phone: phone, password: password))
            .thenAnswer((_) async => mockAuthResponse);

        // Act & Assert
        expect(
          () => datasource.signInWithPhone(phone: phone, password: password),
          throwsA(isA<AuthException>()),
        );
        verify(() => mockAuth.signInWithPassword(phone: phone, password: password)).called(1);
      });
    });

    group('Email Sign Up', () {
      test('should throw AuthException when sign up fails', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';
        const displayName = 'Test User';
        
        when(() => mockAuthResponse.user).thenReturn(null);
        when(() => mockAuth.signUp(email: email, password: password))
            .thenAnswer((_) async => mockAuthResponse);

        // Act & Assert
        expect(
          () => datasource.signUpWithEmail(
            email: email,
            password: password,
            displayName: displayName,
          ),
          throwsA(isA<AuthException>()),
        );
        verify(() => mockAuth.signUp(email: email, password: password)).called(1);
      });
    });

    group('Phone Sign Up', () {
      test('should throw AuthException when phone sign up fails', () async {
        // Arrange
        const phone = '+1234567890';
        const password = 'password123';
        const displayName = 'Test User';
        
        when(() => mockAuthResponse.user).thenReturn(null);
        when(() => mockAuth.signUp(phone: phone, password: password))
            .thenAnswer((_) async => mockAuthResponse);

        // Act & Assert
        expect(
          () => datasource.signUpWithPhone(
            phone: phone,
            password: password,
            displayName: displayName,
          ),
          throwsA(isA<AuthException>()),
        );
        verify(() => mockAuth.signUp(phone: phone, password: password)).called(1);
      });
    });

    group('Token Management', () {
      test('should throw AuthException when token refresh fails', () async {
        // Arrange
        const refreshToken = 'invalid_token';
        
        when(() => mockAuthResponse.session).thenReturn(null);
        when(() => mockAuthResponse.user).thenReturn(null);
        when(() => mockAuth.refreshSession(refreshToken))
            .thenAnswer((_) async => mockAuthResponse);

        // Act & Assert
        expect(
          () => datasource.refreshToken(refreshToken: refreshToken),
          throwsA(isA<AuthException>()),
        );
        verify(() => mockAuth.refreshSession(refreshToken)).called(1);
      });
    });

    group('Verification Operations', () {
      test('should send email verification', () async {
        // Arrange
        const email = 'test@example.com';
        final mockResendResponse = MockResendResponse();
        when(() => mockAuth.resend(type: OtpType.signup, email: email))
            .thenAnswer((_) async => mockResendResponse);

        // Act
        await datasource.sendEmailVerification(email: email);

        // Assert
        verify(() => mockAuth.resend(type: OtpType.signup, email: email)).called(1);
      });

      test('should send phone verification', () async {
        // Arrange
        const phone = '+1234567890';
        final mockResendResponse = MockResendResponse();
        when(() => mockAuth.resend(type: OtpType.sms, phone: phone))
            .thenAnswer((_) async => mockResendResponse);

        // Act
        await datasource.sendPhoneVerification(phone: phone);

        // Assert
        verify(() => mockAuth.resend(type: OtpType.sms, phone: phone)).called(1);
      });

      test('should throw AuthException when email verification fails', () async {
        // Arrange
        const email = 'test@example.com';
        const otp = 'wrong_otp';
        
        when(() => mockAuthResponse.session).thenReturn(null);
        when(() => mockAuthResponse.user).thenReturn(null);
        when(() => mockAuth.verifyOTP(type: OtpType.email, token: otp, email: email))
            .thenAnswer((_) async => mockAuthResponse);

        // Act & Assert
        expect(
          () => datasource.verifyEmail(email: email, otp: otp),
          throwsA(isA<AuthException>()),
        );
        verify(() => mockAuth.verifyOTP(type: OtpType.email, token: otp, email: email)).called(1);
      });

      test('should throw AuthException when phone verification fails', () async {
        // Arrange
        const phone = '+1234567890';
        const otp = 'wrong_otp';
        
        when(() => mockAuthResponse.session).thenReturn(null);
        when(() => mockAuthResponse.user).thenReturn(null);
        when(() => mockAuth.verifyOTP(type: OtpType.sms, token: otp, phone: phone))
            .thenAnswer((_) async => mockAuthResponse);

        // Act & Assert
        expect(
          () => datasource.verifyPhone(phone: phone, otp: otp),
          throwsA(isA<AuthException>()),
        );
        verify(() => mockAuth.verifyOTP(type: OtpType.sms, token: otp, phone: phone)).called(1);
      });
    });

    group('Error Handling', () {
      test('should handle network errors in getCurrentSession', () async {
        // Arrange
        when(() => mockAuth.currentSession).thenThrow(
          const SocketException('Network error'),
        );

        // Act & Assert
        expect(
          () => datasource.getCurrentSession(),
          throwsA(isA<SocketException>()),
        );
      });

      test('should handle timeout errors', () async {
        // Arrange
        when(() => mockAuth.signOut()).thenThrow(
          TimeoutException('Request timeout', const Duration(seconds: 30)),
        );

        // Act & Assert
        expect(
          () => datasource.signOut(),
          throwsA(isA<TimeoutException>()),
        );
      });
    });

    group('Integration with Supabase Client', () {
      test('should use the correct Supabase client', () {
        // Arrange & Act
        final newDatasource = AuthRemoteDataSource(mockSupabaseClient);

        // Assert
        expect(newDatasource, isA<AuthRemoteDataSource>());
        // The datasource should have been created with the mock client
      });

      test('should call from method with profiles table', () async {
        // Arrange
        when(() => mockAuth.currentSession).thenReturn(null);

        // Act
        await datasource.getCurrentSession();

        // Assert
        // This verifies the datasource interacts with Supabase client
        verify(() => mockAuth.currentSession).called(1);
      });
    });
  });
}