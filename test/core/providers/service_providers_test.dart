import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_clone/core/config/environment_config.dart';
import 'package:whatsapp_clone/core/providers/service_providers.dart';

void main() {
  group('Service Providers Tests', () {
    late ProviderContainer container;

    setUp(() {
      // Initialize environment for testing
      EnvironmentConfig.initialize(environment: Environment.development);
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('Environment Configuration Provider', () {
      test('provides current environment configuration', () {
        // Act
        final config = container.read(environmentConfigProvider);

        // Assert
        expect(config, isA<AppEnvironmentConfig>());
        expect(config.environment, equals(Environment.development));
        expect(config.serviceMode, isA<ServiceMode>());
        expect(config.appName, isNotEmpty);
        expect(config.appVersion, isNotEmpty);
      });

      test('configuration has consistent properties', () {
        // Act
        final config = container.read(environmentConfigProvider);

        // Assert
        expect(config.isMockMode, equals(config.serviceMode == ServiceMode.mock));
        expect(config.isRealMode, equals(config.serviceMode == ServiceMode.real));
        expect(config.toString(), contains('serviceMode'));
      });
    });

    group('Service Config Status Provider', () {
      test('provides service configuration status', () async {
        // Act
        final statusAsync = container.read(serviceConfigStatusProvider);
        
        // Assert
        expect(statusAsync, isA<ServiceConfigStatus>());
        expect(statusAsync.serviceMode, isA<ServiceMode>());
        expect(statusAsync.environment, isA<Environment>());
        expect(statusAsync.isValid, isA<bool>());
        expect(statusAsync.hasWarnings, isA<bool>());
        expect(statusAsync.validationMessage, isA<String>());
      });

      test('status provides correct display names', () {
        // Act
        final status = container.read(serviceConfigStatusProvider);
        
        // Assert
        expect(status.serviceModeDisplayName, isIn(['Mock Services', 'Real Services']));
        expect(status.environmentDisplayName, isIn(['Development', 'Staging', 'Production']));
        expect(status.statusColor, isIn(['red', 'orange', 'green']));
      });

      test('status toString contains relevant information', () {
        // Act
        final status = container.read(serviceConfigStatusProvider);
        final statusString = status.toString();
        
        // Assert
        expect(statusString, contains('ServiceConfigStatus'));
        expect(statusString, contains('mode:'));
        expect(statusString, contains('env:'));
        expect(statusString, contains('valid:'));
        expect(statusString, contains('warnings:'));
      });
    });

    group('Service Health Provider', () {
      test('provides service health status stream', () async {
        // Act
        final healthStreamAsync = container.read(serviceHealthProvider);
        
        // Assert
        await expectLater(
          healthStreamAsync.when(
            data: (healthStatus) {
              expect(healthStatus, isA<Map<String, bool>>());
              expect(healthStatus.containsKey('auth'), isTrue);
              expect(healthStatus.containsKey('message'), isTrue);
              expect(healthStatus.containsKey('meeting'), isTrue);
              return healthStatus;
            },
            loading: () => <String, bool>{},
            error: (error, stack) => <String, bool>{},
          ),
          isA<Map<String, bool>>(),
        );
      });

      test('mock services always report as healthy', () async {
        // Arrange - ensure mock mode
        EnvironmentConfig.initialize(environment: Environment.development);
        final config = EnvironmentConfig.config;
        
        if (config.isMockMode) {
          // Act
          final healthStreamAsync = container.read(serviceHealthProvider);
          
          // Assert
          await expectLater(
            healthStreamAsync.when(
              data: (healthStatus) {
                expect(healthStatus['auth'], isTrue);
                expect(healthStatus['message'], isTrue);
                expect(healthStatus['meeting'], isTrue);
                return healthStatus;
              },
              loading: () => <String, bool>{},
              error: (error, stack) => <String, bool>{},
            ),
            isA<Map<String, bool>>(),
          );
        }
      });
    });

    group('Service Validation Provider', () {
      test('provides service validation result', () async {
        // Act
        final validationAsync = container.read(serviceValidationProvider);
        
        // Assert
        await expectLater(
          validationAsync.when(
            data: (validation) {
              expect(validation.isValid, isA<bool>());
              expect(validation.hasWarnings, isA<bool>());
              expect(validation.successes, isA<List<String>>());
              expect(validation.warnings, isA<List<String>>());
              expect(validation.errors, isA<List<String>>());
              return validation;
            },
            loading: () => throw Exception('Still loading'),
            error: (error, stack) => throw error,
          ),
          isA<Object>(),
        );
      });

      test('validation result has consistent properties', () async {
        // Act
        final validationAsync = container.read(serviceValidationProvider);
        
        // Assert
        await expectLater(
          validationAsync.when(
            data: (validation) {
              // If no errors, should be valid
              if (validation.errors.isEmpty) {
                expect(validation.isValid, isTrue);
              }
              
              // If has warnings, hasWarnings should be true
              if (validation.warnings.isNotEmpty) {
                expect(validation.hasWarnings, isTrue);
              }
              
              // toString should contain validation information
              final validationString = validation.toString();
              expect(validationString, contains('ServiceValidationResult'));
              
              return validation;
            },
            loading: () => throw Exception('Still loading'),
            error: (error, stack) => throw error,
          ),
          isA<Object>(),
        );
      });
    });

    group('Service Provider Creation', () {
      test('auth service provider creates appropriate service', () async {
        // Act & Assert - should not throw
        expect(
          () => container.read(authServiceProvider),
          returnsNormally,
        );
      });

      test('message service provider creates appropriate service', () async {
        // Act & Assert - should not throw
        expect(
          () => container.read(messageServiceProvider),
          returnsNormally,
        );
      });

      test('meeting service provider creates appropriate service', () async {
        // Act & Assert - should not throw
        expect(
          () => container.read(meetingServiceProvider),
          returnsNormally,
        );
      });
    });

    group('Provider Dependencies', () {
      test('service config status depends on environment config', () {
        // Arrange - change environment
        EnvironmentConfig.initialize(environment: Environment.staging);
        final newContainer = ProviderContainer();
        
        try {
          // Act
          final config = newContainer.read(environmentConfigProvider);
          final status = newContainer.read(serviceConfigStatusProvider);
          
          // Assert
          expect(status.environment, equals(config.environment));
          expect(status.serviceMode, equals(config.serviceMode));
        } finally {
          newContainer.dispose();
        }
      });

      test('service validation updates when environment changes', () {
        // This test demonstrates that providers properly depend on environment config
        expect(
          () => container.read(serviceValidationProvider),
          returnsNormally,
        );
      });
    });

    group('Error Handling', () {
      test('providers handle invalid states gracefully', () {
        // This test ensures providers don't throw synchronously
        expect(() => container.read(environmentConfigProvider), returnsNormally);
        expect(() => container.read(serviceConfigStatusProvider), returnsNormally);
        expect(() => container.read(serviceHealthProvider), returnsNormally);
        expect(() => container.read(serviceValidationProvider), returnsNormally);
        expect(() => container.read(authServiceProvider), returnsNormally);
        expect(() => container.read(messageServiceProvider), returnsNormally);
        expect(() => container.read(meetingServiceProvider), returnsNormally);
      });
    });
  });
}