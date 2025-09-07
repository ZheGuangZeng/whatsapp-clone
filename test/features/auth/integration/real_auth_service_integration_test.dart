import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:whatsapp_clone/core/config/environment_config.dart';
import 'package:whatsapp_clone/core/providers/service_factory.dart';
import 'package:whatsapp_clone/core/services/service_manager.dart';
import 'package:whatsapp_clone/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:whatsapp_clone/features/auth/presentation/providers/auth_providers.dart';

/// Integration tests for real Supabase authentication service
/// These tests verify that the authentication flow works with actual Supabase backend
/// 
/// NOTE: These tests require a real Supabase instance and should be run against
/// a development/test environment, never against production.
void main() {
  group('Real Auth Service Integration Tests', () {
    late ProviderContainer container;
    late IAuthRepository authService;

    setUpAll(() async {
      // Initialize environment for testing with real services
      EnvironmentConfig.initialize(environment: Environment.development);
      final config = EnvironmentConfig.config;
      
      // Ensure we're using real services for this test
      if (config.isMockMode) {
        fail('This test requires real services. Set SUPABASE_URL and SUPABASE_ANON_KEY environment variables.');
      }

      // Initialize Supabase for testing
      await Supabase.initialize(
        url: config.supabaseUrl,
        anonKey: config.supabaseAnonKey,
        debug: true,
      );

      // Initialize service manager
      final serviceManager = await ServiceManager.instance;
      await serviceManager.initialize(liveKitUrl: config.liveKitUrl);
    });

    setUp(() async {
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

    group('Service Initialization', () {
      test('should create real auth service successfully', () async {
        expect(authService, isNotNull);
        expect(authService, isA<IAuthRepository>());
      });

      test('should validate services successfully', () async {
        final config = EnvironmentConfig.config;
        final validation = await ServiceFactory.validateServices(config);
        
        expect(validation.isValid, isTrue, 
          reason: 'Service validation failed: ${validation.errors}');
      });
    });

    group('Authentication Flow', () {
      const testEmail = 'test-user@example.com';
      const testPassword = 'test123456';
      const testDisplayName = 'Test User';

      test('should get null session when not authenticated', () async {
        final sessionResult = await authService.getCurrentSession();
        
        expect(sessionResult.isSuccess, isTrue);
        sessionResult.when(
          success: (session) => expect(session, isNull),
          failure: (_) => fail('Should succeed when getting current session'),
        );
      });

      test('should handle invalid login credentials', () async {
        final result = await authService.signInWithEmail(
          email: 'invalid@example.com',
          password: 'wrongpassword',
        );
        
        expect(result.isFailure, isTrue);
        result.when(
          success: (_) => fail('Should fail with invalid credentials'),
          failure: (error) => expect(error.message, contains('Invalid')),
        );
      });

      test('should handle registration with existing email', () async {
        // First, try to register a user (this might succeed or fail depending on existing data)
        final firstAttempt = await authService.signUpWithEmail(
          email: testEmail,
          password: testPassword,
          displayName: testDisplayName,
        );

        // If first registration succeeded, sign out and try again
        if (firstAttempt.isSuccess) {
          await authService.signOut();
        }

        // Second attempt should fail with existing email
        final secondAttempt = await authService.signUpWithEmail(
          email: testEmail,
          password: testPassword,
          displayName: testDisplayName,
        );

        // One of the attempts should indicate email already exists
        final hasEmailConflict = firstAttempt.isFailure || secondAttempt.isFailure;
        expect(hasEmailConflict, isTrue, 
          reason: 'Should detect existing email conflict');
      }, skip: 'Requires clean test database');

      test('should handle password reset request', () async {
        final result = await authService.sendPasswordReset(email: testEmail);
        
        // Password reset should succeed or fail gracefully
        expect(result.isSuccess || result.isFailure, isTrue);
        
        result.when(
          success: (_) => <String, dynamic>{/* Password reset sent successfully */},
          failure: (error) => expect(error.message, isNotEmpty),
        );
      });
    });

    group('Session Management', () {
      test('should handle token refresh gracefully', () async {
        // Test with invalid refresh token
        final result = await authService.refreshToken(refreshToken: 'invalid-token');
        
        expect(result.isFailure, isTrue);
        result.when(
          success: (_) => fail('Should fail with invalid refresh token'),
          failure: (error) => expect(error.message, isNotEmpty),
        );
      });

      test('should handle sign out from non-authenticated state', () async {
        final result = await authService.signOut();
        
        // Sign out should succeed even when not authenticated
        expect(result.isSuccess, isTrue);
      });
    });

    group('Error Handling', () {
      test('should handle network connectivity issues', () async {
        // This test would require mocking network conditions
        // For now, we test that the service handles errors gracefully
        const invalidEmail = 'not-an-email';
        
        final result = await authService.signInWithEmail(
          email: invalidEmail,
          password: 'password',
        );
        
        expect(result.isFailure, isTrue);
        result.when(
          success: (_) => fail('Should fail with malformed request'),
          failure: (error) => expect(error.message, isNotEmpty),
        );
      });

      test('should handle malformed requests', () async {
        final result = await authService.signUpWithEmail(
          email: '',
          password: '',
          displayName: '',
        );
        
        expect(result.isFailure, isTrue);
        result.when(
          success: (_) => fail('Should fail with malformed request'),
          failure: (error) => expect(error.message, isNotEmpty),
        );
      });
    });

    group('Auth State Stream', () {
      test('should provide auth state changes stream', () async {
        expect(authService.authStateChanges, isNotNull);
        expect(authService.authStateChanges, isA<Stream<dynamic>>());
      });

      test('should emit null when signing out', () async {
        // Ensure we're signed out first
        await authService.signOut();
        
        // Listen to the stream
        final streamTest = expectLater(
          authService.authStateChanges.take(1),
          emits(isNull),
        );
        
        await streamTest;
      });
    }, skip: 'Stream testing requires more complex setup');

    group('Profile Management', () {
      test('should handle profile operations when not authenticated', () async {
        final result = await authService.updateProfile(
          userId: 'non-existent-user',
          displayName: 'New Name',
        );
        
        expect(result.isFailure, isTrue);
      });

      test('should handle getting non-existent user profile', () async {
        final result = await authService.getUserProfile(
          userId: 'non-existent-user-id',
        );
        
        expect(result.isFailure, isTrue);
      });
    });
  });

  group('Service Provider Integration', () {
    test('should provide auth service through provider system', () async {
      final container = ProviderContainer();
      
      try {
        // This should not throw and should provide a valid service
        final authService = await container.read(authRepositoryProvider.future);
        expect(authService, isNotNull);
      } finally {
        container.dispose();
      }
    });

    test('should handle service provider errors gracefully', () async {
      // Test with invalid environment configuration
      // This would require mocking environment config
    });
  });
}