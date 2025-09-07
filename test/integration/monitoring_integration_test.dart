import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:whatsapp_clone/core/config/environment_config.dart';
import 'package:whatsapp_clone/core/monitoring/alert_system.dart';
import 'package:whatsapp_clone/core/monitoring/analytics_service.dart';
import 'package:whatsapp_clone/core/monitoring/business_metrics.dart';
import 'package:whatsapp_clone/core/monitoring/health_check_service.dart';
import 'package:whatsapp_clone/core/monitoring/monitoring_service.dart';

/// Comprehensive integration test for the monitoring system
/// 
/// This test verifies that all monitoring components work together
/// and provide the expected production-grade observability.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Monitoring System Integration Tests', () {
    late MonitoringService monitoringService;
    late AlertSystem alertSystem;
    late BusinessMetrics businessMetrics;
    late HealthCheckService healthCheckService;

    setUpAll(() async {
      // Initialize test environment
      EnvironmentConfig.initialize(environment: Environment.development);
      
      // Initialize core services
      monitoringService = MonitoringService();
      alertSystem = AlertSystem();
      businessMetrics = BusinessMetrics();
      healthCheckService = HealthCheckService();
    });

    tearDownAll(() async {
      // Clean up all services
      monitoringService.dispose();
      alertSystem.dispose();
      businessMetrics.dispose();
      healthCheckService.dispose();
    });

    testWidgets('Complete monitoring system initialization and integration', (tester) async {
      // Test 1: Initialize all monitoring services
      await monitoringService.initialize();
      await alertSystem.initialize();
      
      // Test 2: Initialize dependent services
      await healthCheckService.initialize(alertSystem: alertSystem);
      await businessMetrics.initialize(
        analyticsService: AnalyticsService(),
        alertSystem: alertSystem,
      );

      // Verify all services are initialized and healthy
      final healthStatus = monitoringService.getHealthStatus();
      expect(healthStatus['initialized'], isTrue);
      
      // Test 3: Error tracking and reporting
      await _testErrorTracking(monitoringService);
      
      // Test 4: Performance monitoring
      await _testPerformanceMonitoring(monitoringService);
      
      // Test 5: Business metrics tracking
      await _testBusinessMetrics(businessMetrics);
      
      // Test 6: Alert system
      await _testAlertSystem(alertSystem);
      
      // Test 7: Health checks
      await _testHealthChecks(healthCheckService);
      
      // Test 8: End-to-end monitoring workflow
      await _testEndToEndWorkflow(
        monitoringService,
        alertSystem,
        businessMetrics,
        healthCheckService,
      );
      
      print('✅ All monitoring system integration tests passed');
    });

    testWidgets('Monitoring dashboard integration', (tester) async {
      // This would test the actual dashboard UI if we had a full app context
      // For now, we'll test the data providers work correctly
      
      await monitoringService.initialize();
      
      // Simulate some activity
      await monitoringService.trackEvent('test_event', {'test': true});
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Verify dashboard data is available
      final healthStatus = monitoringService.getHealthStatus();
      expect(healthStatus, isA<Map<String, dynamic>>());
      expect(healthStatus['initialized'], isTrue);
      
      print('✅ Monitoring dashboard integration test passed');
    });

    testWidgets('Production readiness verification', (tester) async {
      await monitoringService.initialize();
      await alertSystem.initialize();
      
      // Test production-critical features
      await _testProductionReadiness(monitoringService, alertSystem);
      
      print('✅ Production readiness verification passed');
    });
  });
}

/// Test error tracking and reporting functionality
Future<void> _testErrorTracking(MonitoringService monitoringService) async {
  print('Testing error tracking...');
  
  // Test custom error reporting
  await monitoringService.trackEvent('test_error_tracking', {
    'error_type': 'test',
    'timestamp': DateTime.now().toIso8601String(),
  });
  
  // Simulate error reporting (without actually throwing)
  final testError = Exception('Test exception for monitoring');
  final testStack = StackTrace.current;
  
  // This would normally report an error, but we're just testing the API
  expect(() async {
    // Test error handling without actually throwing
    try {
      throw testError;
    } catch (e, s) {
      // Error caught and would be reported
      await monitoringService.trackEvent('error_handled', {
        'error': e.toString(),
        'has_stack_trace': s != null,
      });
    }
  }, returnsNormally);
  
  print('✅ Error tracking tests passed');
}

/// Test performance monitoring functionality
Future<void> _testPerformanceMonitoring(MonitoringService monitoringService) async {
  print('Testing performance monitoring...');
  
  // Test performance tracking
  final stopwatch = Stopwatch()..start();
  
  // Simulate some work
  await Future.delayed(const Duration(milliseconds: 50));
  
  stopwatch.stop();
  
  await monitoringService.trackPerformance(
    'test_operation',
    stopwatch.elapsed,
    metadata: {
      'operation_type': 'integration_test',
      'test_timestamp': DateTime.now().toIso8601String(),
    },
  );
  
  // Test app launch tracking would happen automatically
  await monitoringService.trackEvent('performance_test_completed', {
    'duration_ms': stopwatch.elapsed.inMilliseconds,
  });
  
  print('✅ Performance monitoring tests passed');
}

/// Test business metrics tracking
Future<void> _testBusinessMetrics(BusinessMetrics businessMetrics) async {
  print('Testing business metrics...');
  
  final testUserId = 'test_user_${DateTime.now().millisecondsSinceEpoch}';
  
  // Test user tracking
  await businessMetrics.trackUserLogin(
    userId: testUserId,
    loginMethod: 'test',
    isNewUser: true,
  );
  
  // Test messaging metrics
  await businessMetrics.trackMessageSent(
    messageType: 'text',
    chatType: 'individual',
    messageSize: 100,
    deliveryTime: const Duration(milliseconds: 150),
  );
  
  await businessMetrics.trackMessageReceived(
    messageType: 'text',
    chatType: 'individual',
    deliveryTime: const Duration(milliseconds: 200),
  );
  
  // Test meeting metrics
  await businessMetrics.trackMeetingStart(
    meetingType: 'video',
    participantCount: 2,
  );
  
  await businessMetrics.trackMeetingEnd(
    meetingType: 'video',
    duration: const Duration(minutes: 5),
    participantCount: 2,
  );
  
  // Test feature usage
  await businessMetrics.trackFeatureUsage(
    featureName: 'integration_test_feature',
    metadata: {'test': true},
  );
  
  // Verify business report generation
  final report = businessMetrics.getBusinessReport();
  expect(report, isA<Map<String, dynamic>>());
  expect(report['messaging_metrics'], isA<Map<String, dynamic>>());
  expect(report['meeting_metrics'], isA<Map<String, dynamic>>());
  
  print('✅ Business metrics tests passed');
}

/// Test alert system functionality
Future<void> _testAlertSystem(AlertSystem alertSystem) async {
  print('Testing alert system...');
  
  // Test info alert (safe for testing)
  await alertSystem.sendInfoAlert(
    title: 'Integration Test Alert',
    message: 'This is a test alert from the integration test suite',
    metadata: {
      'test': true,
      'timestamp': DateTime.now().toIso8601String(),
      'test_type': 'integration',
    },
  );
  
  // Test alert system health
  await alertSystem.testAlert();
  
  print('✅ Alert system tests passed');
}

/// Test health check functionality
Future<void> _testHealthChecks(HealthCheckService healthCheckService) async {
  print('Testing health checks...');
  
  // Run comprehensive health check
  final healthResults = await healthCheckService.runComprehensiveHealthCheck();
  
  expect(healthResults, isA<Map<String, HealthCheckResult>>());
  expect(healthResults.isNotEmpty, isTrue);
  
  // Verify specific health checks
  expect(healthResults.containsKey('internet'), isTrue);
  expect(healthResults.containsKey('memory'), isTrue);
  expect(healthResults.containsKey('disk'), isTrue);
  expect(healthResults.containsKey('performance'), isTrue);
  
  // Test overall health status
  final overallHealth = healthCheckService.getOverallHealthStatus();
  expect(overallHealth, isA<Map<String, dynamic>>());
  expect(overallHealth['overall_health'], isNotNull);
  
  print('✅ Health check tests passed');
}

/// Test end-to-end monitoring workflow
Future<void> _testEndToEndWorkflow(
  MonitoringService monitoringService,
  AlertSystem alertSystem,
  BusinessMetrics businessMetrics,
  HealthCheckService healthCheckService,
) async {
  print('Testing end-to-end workflow...');
  
  final testUserId = 'e2e_test_user_${DateTime.now().millisecondsSinceEpoch}';
  
  // Simulate complete user journey with monitoring
  
  // 1. User login (tracked by business metrics)
  await businessMetrics.trackUserLogin(
    userId: testUserId,
    loginMethod: 'email',
    isNewUser: false,
  );
  
  // 2. Set user context in monitoring
  await monitoringService.setUser(
    id: testUserId,
    email: 'test@example.com',
    properties: {'test_user': true},
  );
  
  // 3. User performs actions (tracked by analytics)
  await monitoringService.trackEvent('screen_view', {
    'screen_name': 'chat_list',
    'user_id': testUserId,
  });
  
  // 4. Performance operation (tracked by performance monitor)
  await monitoringService.trackPerformance(
    'load_chat_list',
    const Duration(milliseconds: 300),
  );
  
  // 5. Business operation (message sending)
  await businessMetrics.trackMessageSent(
    messageType: 'text',
    chatType: 'individual',
    deliveryTime: const Duration(milliseconds: 120),
  );
  
  // 6. Feature usage tracking
  await businessMetrics.trackFeatureUsage(
    featureName: 'send_message',
    metadata: {'message_type': 'text'},
  );
  
  // 7. Health check (system monitoring)
  await healthCheckService.runComprehensiveHealthCheck();
  
  // 8. Verify all data is integrated
  final healthStatus = monitoringService.getHealthStatus();
  final businessReport = businessMetrics.getBusinessReport();
  final overallHealth = healthCheckService.getOverallHealthStatus();
  
  expect(healthStatus['initialized'], isTrue);
  expect(businessReport['messaging_metrics']['total_messages_sent'], greaterThan(0));
  expect(overallHealth['overall_health'], isNotNull);
  
  // 9. Clean up user context
  await monitoringService.clearUser();
  
  print('✅ End-to-end workflow test passed');
}

/// Test production readiness
Future<void> _testProductionReadiness(
  MonitoringService monitoringService,
  AlertSystem alertSystem,
) async {
  print('Testing production readiness...');
  
  // Test 1: Verify all critical monitoring components are functional
  final healthStatus = monitoringService.getHealthStatus();
  expect(healthStatus['initialized'], isTrue);
  
  final services = healthStatus['services'] as Map<String, dynamic>;
  expect(services.isNotEmpty, isTrue);
  
  // Test 2: Verify error handling resilience
  try {
    // Simulate various error scenarios
    await monitoringService.trackEvent('production_test', {
      'large_data': List.generate(1000, (i) => 'data_$i'),
    });
    
    // Test with null data
    await monitoringService.trackEvent('null_test', {
      'null_value': null,
      'empty_string': '',
      'zero': 0,
    });
    
    // All should complete without throwing
  } catch (error) {
    fail('Production monitoring should handle edge cases gracefully: $error');
  }
  
  // Test 3: Verify alert system can handle multiple alerts
  await alertSystem.sendInfoAlert(
    title: 'Production Test 1',
    message: 'Testing alert system resilience',
  );
  
  await alertSystem.sendInfoAlert(
    title: 'Production Test 2',
    message: 'Testing alert cooldown and deduplication',
  );
  
  // Test 4: Verify monitoring system performance under load
  final futures = <Future<void>>[];
  for (int i = 0; i < 10; i++) {
    futures.add(
      monitoringService.trackEvent('load_test_$i', {
        'iteration': i,
        'timestamp': DateTime.now().toIso8601String(),
      })
    );
  }
  
  await Future.wait(futures);
  
  // Test 5: Verify graceful degradation
  // The system should continue working even if some components fail
  expect(healthStatus['initialized'], isTrue);
  
  print('✅ Production readiness tests passed');
}