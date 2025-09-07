import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_clone/core/config/environment_config.dart';
import 'package:whatsapp_clone/core/providers/service_factory.dart';
import 'package:whatsapp_clone/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:whatsapp_clone/features/auth/presentation/providers/auth_providers.dart';
import 'package:whatsapp_clone/features/auth/presentation/providers/auth_state.dart';

/// Security tests to ensure no authentication bypass is possible
/// These tests verify that the authentication system is secure and cannot be bypassed
void main() {
  group('Authentication Security Tests', () {
    late ProviderContainer container;
    late IAuthRepository authService;

    setUp(() async {
      // Initialize environment for security testing
      EnvironmentConfig.initialize(environment: Environment.development);
      
      container = ProviderContainer();
      authService = await container.read(authRepositoryProvider.future);
    });

    tearDown(() async {
      // Clean up any test sessions
      try {
        await authService.signOut();
      } catch (_) {
        // Ignore errors during cleanup
      }
      container.dispose();
    });

    group('Authentication Bypass Prevention', () {
      test('should not allow access without valid authentication', () async {
        // Ensure no session exists
        await authService.signOut();
        
        final sessionResult = await authService.getCurrentSession();
        sessionResult.when(
          success: (session) => expect(session, isNull),
          failure: (_) => fail('Getting current session should succeed but return null'),
        );
      });

      test('should not allow access with expired tokens', () async {
        // Test with obviously expired token
        final expiredTokenResult = await authService.refreshToken(
          refreshToken: 'expired.token.here',
        );
        
        expect(expiredTokenResult.isFailure, isTrue);
        expiredTokenResult.when(
          success: (_) => fail('Should not succeed with expired token'),
          failure: (error) => expect(error.message, isNotEmpty),
        );
      });

      test('should not allow access with malformed tokens', () async {
        // Test with malformed token
        final malformedTokenResult = await authService.refreshToken(
          refreshToken: 'malformed-token',
        );
        
        expect(malformedTokenResult.isFailure, isTrue);
        malformedTokenResult.when(
          success: (_) => fail('Should not succeed with malformed token'),
          failure: (error) => expect(error.message, isNotEmpty),
        );
      });

      test('should not allow profile updates without authentication', () async {
        // Ensure no session exists
        await authService.signOut();
        
        final updateResult = await authService.updateProfile(
          userId: 'any-user-id',
          displayName: 'Hacker Name',
        );
        
        expect(updateResult.isFailure, isTrue);
        updateResult.when(
          success: (_) => fail('Should not allow profile update without auth'),
          failure: (error) => expect(error.message, isNotEmpty),
        );
      });

      test('should not allow accessing other users\' profiles without proper auth', () async {
        // Ensure no session exists
        await authService.signOut();
        
        final profileResult = await authService.getUserProfile(
          userId: 'other-user-id',
        );
        
        expect(profileResult.isFailure, isTrue);
        profileResult.when(
          success: (_) => fail('Should not allow accessing other profiles without auth'),
          failure: (error) => expect(error.message, isNotEmpty),
        );
      });
    });

    group('Input Validation Security', () {
      test('should reject SQL injection attempts in email', () async {
        const sqlInjectionEmail = "'; DROP TABLE users; --";
        
        final result = await authService.signInWithEmail(
          email: sqlInjectionEmail,
          password: 'password',
        );
        
        expect(result.isFailure, isTrue);
        result.when(
          success: (_) => fail('Should reject SQL injection attempts'),
          failure: (error) => expect(error.message, isNotEmpty),
        );
      });

      test('should reject XSS attempts in display name', () async {
        const xssDisplayName = '<script>alert("xss")</script>';
        
        final result = await authService.signUpWithEmail(
          email: 'test@example.com',
          password: 'password123',
          displayName: xssDisplayName,
        );
        
        // The service should either reject this or sanitize it
        // Either way, it should not execute any scripts
        result.when(
          success: (session) {
            // If registration succeeds, display name should be sanitized
            expect(session.user.displayName, isNot(contains('<script>')));
          },
          failure: (error) {
            // If it fails, that's also acceptable for security
            expect(error.message, isNotEmpty);
          },
        );
      });

      test('should enforce password strength requirements', () async {
        const weakPassword = '123';
        
        final result = await authService.signUpWithEmail(
          email: 'test@example.com',
          password: weakPassword,
          displayName: 'Test User',
        );
        
        expect(result.isFailure, isTrue);
        result.when(
          success: (_) => fail('Should reject weak passwords'),
          failure: (error) => expect(error.message, contains('password')),
        );
      });

      test('should validate email format properly', () async {
        const invalidEmails = [
          'not-an-email',
          '@domain.com',
          'user@',
          'user@domain',
          '',
          'user..user@domain.com',
        ];
        
        for (final invalidEmail in invalidEmails) {
          final result = await authService.signInWithEmail(
            email: invalidEmail,
            password: 'password123',
          );
          
          expect(result.isFailure, isTrue, 
            reason: 'Should reject invalid email: $invalidEmail');
        }
      });
    });

    group('Session Security', () {
      test('should invalidate sessions after sign out', () async {
        // This test would require a valid session first
        // For now, we test that signing out works
        final signOutResult = await authService.signOut();
        
        expect(signOutResult.isSuccess, isTrue);
        
        // Verify no session exists after sign out
        final sessionResult = await authService.getCurrentSession();
        sessionResult.when(
          success: (session) => expect(session, isNull),
          failure: (_) => fail('Should succeed but return null session'),
        );
      });

      test('should not allow cross-user session access', () async {
        // This would require setting up multiple test users
        // For now, we ensure that without authentication, no user data is accessible
        await authService.signOut();
        
        final profileResult = await authService.getUserProfile(userId: 'any-user');
        expect(profileResult.isFailure, isTrue);
      });
    });

    group('Provider Security', () {
      test('should not expose sensitive data in error messages', () async {
        final result = await authService.signInWithEmail(
          email: 'test@example.com',
          password: 'wrongpassword',
        );
        
        expect(result.isFailure, isTrue);
        result.when(
          success: (_) => fail('Should fail with wrong password'),
          failure: (error) {
            // Error message should not expose sensitive information
            final message = error.message.toLowerCase();
            expect(message, isNot(contains('database')));
            expect(message, isNot(contains('sql')));
            expect(message, isNot(contains('internal')));
            expect(message, isNot(contains('stack')));
          },
        );
      });

      test('should handle concurrent authentication attempts safely', () async {
        // Test multiple simultaneous login attempts
        final futures = List.generate(5, (index) => 
          authService.signInWithEmail(
            email: 'test$index@example.com',
            password: 'password',
          ),
        );
        
        final results = await Future.wait(futures);
        
        // All should fail gracefully without exposing system information
        for (final result in results) {
          expect(result.isFailure, isTrue);
          result.when(
            success: (_) => fail('Should fail with invalid credentials'),
            failure: (error) => expect(error.message, isNotEmpty),
          );
        }
      });
    });

    group('Auth State Security', () {
      test('should start in unauthenticated state', () {
        final authNotifier = container.read(authNotifierProvider.notifier);
        final initialState = container.read(authNotifierProvider);
        
        expect(initialState, isA<InitialState>());
        expect(initialState.isAuthenticated, isFalse);
      });

      test('should not persist authentication across app restarts without valid session', () async {
        // Ensure clean state
        await authService.signOut();
        
        // Create new container to simulate app restart
        final newContainer = ProviderContainer();
        
        try {
          final newAuthService = await newContainer.read(authRepositoryProvider.future);
          final sessionResult = await newAuthService.getCurrentSession();
          
          sessionResult.when(
            success: (session) => expect(session, isNull),
            failure: (_) => fail('Should succeed but return null for new container'),
          );
        } finally {
          newContainer.dispose();
        }
      });
    });

    group('Network Security', () {
      test('should handle network timeouts gracefully', () async {
        // This test would require mocking network conditions
        // For now, we ensure that the service doesn't hang indefinitely
        final stopwatch = Stopwatch()..start();
        
        final result = await authService.signInWithEmail(
          email: 'timeout@example.com',
          password: 'password',
        );
        
        stopwatch.stop();
        
        // Should not take more than reasonable time (e.g., 30 seconds)
        expect(stopwatch.elapsed.inSeconds, lessThan(30));
        
        // Should handle the error gracefully
        expect(result.isFailure, isTrue);
      });
    });
  });

  group('Environment Security', () {
    test('should not expose sensitive configuration in errors', () {
      // Test that configuration errors don't expose secrets
      final config = EnvironmentConfig.config;
      
      // These should not contain actual secrets in the config object string representation
      final configString = config.toString();
      expect(configString, isNot(contains('sk_')), reason: 'Should not expose secret keys');
      expect(configString, isNot(contains('password')), reason: 'Should not expose passwords');
    });

    test('should validate service configuration security', () async {
      final config = EnvironmentConfig.config;
      final validation = await ServiceFactory.validateServices(config);
      
      // Validation should pass security checks
      expect(validation.isValid || validation.hasWarnings, isTrue);
      
      // Should not expose sensitive information in validation messages
      final validationString = validation.toString();
      expect(validationString, isNot(contains('password')));
      expect(validationString, isNot(contains('secret')));
      expect(validationString, isNot(contains('key')));
    });
  });
}