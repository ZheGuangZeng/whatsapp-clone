import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/environment_config.dart';
import 'service_factory.dart';

/// Provider for environment configuration
final environmentConfigProvider = Provider<AppEnvironmentConfig>((ref) {
  return EnvironmentConfig.config;
});

/// Provider for service validation result
final serviceValidationProvider = FutureProvider<ServiceValidationResult>((ref) async {
  final config = ref.watch(environmentConfigProvider);
  return ServiceFactory.validateServices(config);
});

/// Provider for auth service based on environment configuration
final authServiceProvider = FutureProvider((ref) async {
  final config = ref.watch(environmentConfigProvider);
  
  try {
    final authService = await ServiceFactory.createAuthService(config);
    developer.log('Auth service created successfully for ${config.serviceMode}', name: 'ServiceProviders');
    return authService;
  } catch (error) {
    developer.log('Failed to create auth service: $error', name: 'ServiceProviders', level: 1000);
    rethrow;
  }
});

/// Provider for message service based on environment configuration
final messageServiceProvider = FutureProvider((ref) async {
  final config = ref.watch(environmentConfigProvider);
  
  try {
    final messageService = await ServiceFactory.createMessageService(config);
    developer.log('Message service created successfully for ${config.serviceMode}', name: 'ServiceProviders');
    return messageService;
  } catch (error) {
    developer.log('Failed to create message service: $error', name: 'ServiceProviders', level: 1000);
    rethrow;
  }
});

/// Provider for meeting service based on environment configuration
final meetingServiceProvider = FutureProvider((ref) async {
  final config = ref.watch(environmentConfigProvider);
  
  try {
    final meetingService = await ServiceFactory.createMeetingService(config);
    developer.log('Meeting service created successfully for ${config.serviceMode}', name: 'ServiceProviders');
    return meetingService;
  } catch (error) {
    developer.log('Failed to create meeting service: $error', name: 'ServiceProviders', level: 1000);
    rethrow;
  }
});

/// Provider for service health monitoring
final serviceHealthProvider = StreamProvider<Map<String, bool>>((ref) async* {
  final config = ref.watch(environmentConfigProvider);
  
  // For mock services, always report as healthy
  if (config.isMockMode) {
    yield {
      'auth': true,
      'message': true,
      'meeting': true,
    };
    return;
  }
  
  // For real services, periodically check health
  while (true) {
    try {
      // This would typically use ServiceManager.instance.checkServicesHealth()
      // For now, we'll provide a basic implementation
      yield {
        'auth': true,
        'message': true,
        'meeting': true,
      };
    } catch (error) {
      developer.log('Service health check failed: $error', name: 'ServiceProviders', level: 1000);
      yield {
        'auth': false,
        'message': false,
        'meeting': false,
      };
    }
    
    await Future<void>.delayed(const Duration(minutes: 1));
  }
});

/// Provider for service configuration status
final serviceConfigStatusProvider = Provider<ServiceConfigStatus>((ref) {
  final config = ref.watch(environmentConfigProvider);
  final validationAsync = ref.watch(serviceValidationProvider);
  
  return validationAsync.when(
    data: (validation) => ServiceConfigStatus(
      serviceMode: config.serviceMode,
      environment: config.environment,
      isValid: validation.isValid,
      hasWarnings: validation.hasWarnings,
      validationMessage: validation.toString(),
    ),
    loading: () => ServiceConfigStatus(
      serviceMode: config.serviceMode,
      environment: config.environment,
      isValid: false,
      hasWarnings: false,
      validationMessage: 'Validating services...',
    ),
    error: (error, stack) => ServiceConfigStatus(
      serviceMode: config.serviceMode,
      environment: config.environment,
      isValid: false,
      hasWarnings: true,
      validationMessage: 'Service validation failed: $error',
    ),
  );
});

/// Data class for service configuration status
class ServiceConfigStatus {
  const ServiceConfigStatus({
    required this.serviceMode,
    required this.environment,
    required this.isValid,
    required this.hasWarnings,
    required this.validationMessage,
  });
  
  final ServiceMode serviceMode;
  final Environment environment;
  final bool isValid;
  final bool hasWarnings;
  final String validationMessage;
  
  /// Get display name for service mode
  String get serviceModeDisplayName {
    switch (serviceMode) {
      case ServiceMode.mock:
        return 'Mock Services';
      case ServiceMode.real:
        return 'Real Services';
    }
  }
  
  /// Get display name for environment
  String get environmentDisplayName {
    switch (environment) {
      case Environment.development:
        return 'Development';
      case Environment.staging:
        return 'Staging';
      case Environment.production:
        return 'Production';
    }
  }
  
  /// Get status color based on validation result
  String get statusColor {
    if (!isValid) return 'red';
    if (hasWarnings) return 'orange';
    return 'green';
  }
  
  @override
  String toString() {
    return 'ServiceConfigStatus('
        'mode: $serviceMode, '
        'env: $environment, '
        'valid: $isValid, '
        'warnings: $hasWarnings'
        ')';
  }
}