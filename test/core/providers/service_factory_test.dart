import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_clone/core/config/environment_config.dart';
import 'package:whatsapp_clone/core/providers/service_factory.dart';
import 'package:whatsapp_clone/features/auth/domain/repositories/i_auth_repository.dart';

void main() {
  group('ServiceFactory Tests', () {
    group('Environment-based service switching', () {
      test('creates mock auth service when in mock mode', () async {
        // Arrange
        const config = AppEnvironmentConfig(
          environment: Environment.development,
          serviceMode: ServiceMode.mock,
          appName: 'Test App',
          appVersion: '1.0.0',
          supabaseUrl: 'mock-url',
          supabaseAnonKey: 'mock-key',
          liveKitUrl: 'mock-livekit',
          liveKitApiKey: 'mock-key',
          liveKitApiSecret: 'mock-secret',
          cdnUrl: 'mock-cdn',
          apiBaseUrl: 'mock-api',
          enableAnalytics: false,
          enableCrashReporting: false,
          enablePerformanceMonitoring: false,
          logLevel: 'debug',
          connectionTimeoutMs: 30000,
          readTimeoutMs: 30000,
          enableDebugLogging: true,
          maxRetryAttempts: 3,
          retryDelayMs: 1000,
          enableOfflineSync: true,
          cacheExpiryMinutes: 15,
          region: 'test',
        );

        // Act
        final authService = await ServiceFactory.createAuthService(config);

        // Assert
        expect(authService, isA<IAuthRepository>());
        
        // Test that it behaves like a mock service
        final currentSessionResult = await authService.getCurrentSession();
        expect(currentSessionResult.isSuccess, isTrue);
        expect(currentSessionResult.dataOrNull, isNull);
      });

      test('creates mock message service when in mock mode', () async {
        // Arrange
        const config = AppEnvironmentConfig(
          environment: Environment.development,
          serviceMode: ServiceMode.mock,
          appName: 'Test App',
          appVersion: '1.0.0',
          supabaseUrl: 'mock-url',
          supabaseAnonKey: 'mock-key',
          liveKitUrl: 'mock-livekit',
          liveKitApiKey: 'mock-key',
          liveKitApiSecret: 'mock-secret',
          cdnUrl: 'mock-cdn',
          apiBaseUrl: 'mock-api',
          enableAnalytics: false,
          enableCrashReporting: false,
          enablePerformanceMonitoring: false,
          logLevel: 'debug',
          connectionTimeoutMs: 30000,
          readTimeoutMs: 30000,
          enableDebugLogging: true,
          maxRetryAttempts: 3,
          retryDelayMs: 1000,
          enableOfflineSync: true,
          cacheExpiryMinutes: 15,
          region: 'test',
        );

        // Act
        final messageService = await ServiceFactory.createMessageService(config);

        // Assert
        expect(messageService, isNotNull);
        expect(messageService.toString(), contains('MockSupabaseService'));
      });

      test('creates mock meeting service when in mock mode', () async {
        // Arrange
        const config = AppEnvironmentConfig(
          environment: Environment.development,
          serviceMode: ServiceMode.mock,
          appName: 'Test App',
          appVersion: '1.0.0',
          supabaseUrl: 'mock-url',
          supabaseAnonKey: 'mock-key',
          liveKitUrl: 'mock-livekit',
          liveKitApiKey: 'mock-key',
          liveKitApiSecret: 'mock-secret',
          cdnUrl: 'mock-cdn',
          apiBaseUrl: 'mock-api',
          enableAnalytics: false,
          enableCrashReporting: false,
          enablePerformanceMonitoring: false,
          logLevel: 'debug',
          connectionTimeoutMs: 30000,
          readTimeoutMs: 30000,
          enableDebugLogging: true,
          maxRetryAttempts: 3,
          retryDelayMs: 1000,
          enableOfflineSync: true,
          cacheExpiryMinutes: 15,
          region: 'test',
        );

        // Act
        final meetingService = await ServiceFactory.createMeetingService(config);

        // Assert
        expect(meetingService, isNotNull);
        expect(meetingService.toString(), contains('MockLiveKitService'));
      });

      test('handles service creation errors gracefully', () async {
        // Arrange - invalid configuration
        const config = AppEnvironmentConfig(
          environment: Environment.production,
          serviceMode: ServiceMode.real, // Real services but no Supabase initialized
          appName: 'Test App',
          appVersion: '1.0.0',
          supabaseUrl: '', // Invalid URL
          supabaseAnonKey: '', // Invalid key
          liveKitUrl: '',
          liveKitApiKey: '',
          liveKitApiSecret: '',
          cdnUrl: '',
          apiBaseUrl: '',
          enableAnalytics: false,
          enableCrashReporting: false,
          enablePerformanceMonitoring: false,
          logLevel: 'debug',
          connectionTimeoutMs: 30000,
          readTimeoutMs: 30000,
          enableDebugLogging: true,
          maxRetryAttempts: 3,
          retryDelayMs: 1000,
          enableOfflineSync: true,
          cacheExpiryMinutes: 15,
          region: 'test',
        );

        // Act - should fall back to mock service
        final authService = await ServiceFactory.createAuthService(config);

        // Assert - should still get a working service (mock fallback)
        expect(authService, isA<IAuthRepository>());
        
        final currentSessionResult = await authService.getCurrentSession();
        expect(currentSessionResult.isSuccess, isTrue);
      });
    });

    group('Service validation', () {
      test('validates mock services successfully', () async {
        // Arrange
        const config = AppEnvironmentConfig(
          environment: Environment.development,
          serviceMode: ServiceMode.mock,
          appName: 'Test App',
          appVersion: '1.0.0',
          supabaseUrl: 'mock-url',
          supabaseAnonKey: 'mock-key',
          liveKitUrl: 'mock-livekit',
          liveKitApiKey: 'mock-key',
          liveKitApiSecret: 'mock-secret',
          cdnUrl: 'mock-cdn',
          apiBaseUrl: 'mock-api',
          enableAnalytics: false,
          enableCrashReporting: false,
          enablePerformanceMonitoring: false,
          logLevel: 'debug',
          connectionTimeoutMs: 30000,
          readTimeoutMs: 30000,
          enableDebugLogging: true,
          maxRetryAttempts: 3,
          retryDelayMs: 1000,
          enableOfflineSync: true,
          cacheExpiryMinutes: 15,
          region: 'test',
        );

        // Act
        final validationResult = await ServiceFactory.validateServices(config);

        // Assert
        expect(validationResult.isValid, isTrue);
        expect(validationResult.successes, isNotEmpty);
        expect(validationResult.errors, isEmpty);
      });

      test('provides detailed validation messages', () async {
        // Arrange
        const config = AppEnvironmentConfig(
          environment: Environment.development,
          serviceMode: ServiceMode.mock,
          appName: 'Test App',
          appVersion: '1.0.0',
          supabaseUrl: 'mock-url',
          supabaseAnonKey: 'mock-key',
          liveKitUrl: 'mock-livekit',
          liveKitApiKey: 'mock-key',
          liveKitApiSecret: 'mock-secret',
          cdnUrl: 'mock-cdn',
          apiBaseUrl: 'mock-api',
          enableAnalytics: false,
          enableCrashReporting: false,
          enablePerformanceMonitoring: false,
          logLevel: 'debug',
          connectionTimeoutMs: 30000,
          readTimeoutMs: 30000,
          enableDebugLogging: true,
          maxRetryAttempts: 3,
          retryDelayMs: 1000,
          enableOfflineSync: true,
          cacheExpiryMinutes: 15,
          region: 'test',
        );

        // Act
        final validationResult = await ServiceFactory.validateServices(config);

        // Assert
        final resultString = validationResult.toString();
        expect(resultString, contains('ServiceValidationResult'));
        expect(resultString, contains('Successes'));
        
        if (validationResult.hasWarnings) {
          expect(resultString, contains('Warnings'));
        }
        
        if (!validationResult.isValid) {
          expect(resultString, contains('Errors'));
        }
      });

      test('validation result has correct properties', () async {
        // Arrange
        const config = AppEnvironmentConfig(
          environment: Environment.development,
          serviceMode: ServiceMode.mock,
          appName: 'Test App',
          appVersion: '1.0.0',
          supabaseUrl: 'mock-url',
          supabaseAnonKey: 'mock-key',
          liveKitUrl: 'mock-livekit',
          liveKitApiKey: 'mock-key',
          liveKitApiSecret: 'mock-secret',
          cdnUrl: 'mock-cdn',
          apiBaseUrl: 'mock-api',
          enableAnalytics: false,
          enableCrashReporting: false,
          enablePerformanceMonitoring: false,
          logLevel: 'debug',
          connectionTimeoutMs: 30000,
          readTimeoutMs: 30000,
          enableDebugLogging: true,
          maxRetryAttempts: 3,
          retryDelayMs: 1000,
          enableOfflineSync: true,
          cacheExpiryMinutes: 15,
          region: 'test',
        );

        // Act
        final validationResult = await ServiceFactory.validateServices(config);

        // Assert
        expect(validationResult.successes, isA<List<String>>());
        expect(validationResult.warnings, isA<List<String>>());
        expect(validationResult.errors, isA<List<String>>());
        expect(validationResult.isValid, isA<bool>());
        expect(validationResult.hasWarnings, isA<bool>());
      });
    });

    group('Service mode detection', () {
      test('environment config detects service mode correctly', () {
        // Test mock mode
        final mockConfig = AppEnvironmentConfig.development(serviceMode: ServiceMode.mock);
        expect(mockConfig.serviceMode, equals(ServiceMode.mock));
        expect(mockConfig.isMockMode, isTrue);
        expect(mockConfig.isRealMode, isFalse);

        // Test real mode
        final realConfig = AppEnvironmentConfig.development(serviceMode: ServiceMode.real);
        expect(realConfig.serviceMode, equals(ServiceMode.real));
        expect(realConfig.isMockMode, isFalse);
        expect(realConfig.isRealMode, isTrue);
      });

      test('staging environment defaults to real services', () {
        final config = AppEnvironmentConfig.staging();
        expect(config.serviceMode, equals(ServiceMode.real));
        expect(config.isRealMode, isTrue);
      });

      test('production environment defaults to real services', () {
        final config = AppEnvironmentConfig.production();
        expect(config.serviceMode, equals(ServiceMode.real));
        expect(config.isRealMode, isTrue);
      });

      test('development environment service mode can be overridden', () {
        final mockConfig = AppEnvironmentConfig.development(serviceMode: ServiceMode.mock);
        final realConfig = AppEnvironmentConfig.development(serviceMode: ServiceMode.real);

        expect(mockConfig.serviceMode, equals(ServiceMode.mock));
        expect(realConfig.serviceMode, equals(ServiceMode.real));
      });
    });

    group('Configuration consistency', () {
      test('all environments have required fields populated', () {
        final devConfig = AppEnvironmentConfig.development();
        final stagingConfig = AppEnvironmentConfig.staging();
        final prodConfig = AppEnvironmentConfig.production();

        for (final config in [devConfig, stagingConfig, prodConfig]) {
          expect(config.appName, isNotEmpty);
          expect(config.appVersion, isNotEmpty);
          expect(config.supabaseUrl, isNotEmpty);
          expect(config.supabaseAnonKey, isNotEmpty);
          expect(config.liveKitUrl, isNotEmpty);
          expect(config.liveKitApiKey, isNotEmpty);
          expect(config.liveKitApiSecret, isNotEmpty);
          expect(config.cdnUrl, isNotEmpty);
          expect(config.apiBaseUrl, isNotEmpty);
          expect(config.region, isNotEmpty);
          expect(config.connectionTimeoutMs, greaterThan(0));
          expect(config.readTimeoutMs, greaterThan(0));
          expect(config.maxRetryAttempts, greaterThan(0));
          expect(config.retryDelayMs, greaterThan(0));
          expect(config.cacheExpiryMinutes, greaterThan(0));
        }
      });

      test('configuration toString includes service mode', () {
        final config = AppEnvironmentConfig.development();
        final configString = config.toString();
        
        expect(configString, contains('serviceMode'));
        expect(configString, contains('environment'));
        expect(configString, contains('appName'));
        expect(configString, contains('version'));
      });
    });
  });
}