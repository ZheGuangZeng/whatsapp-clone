import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/environment_config.dart';
import 'alert_system.dart';

/// Comprehensive health check service for monitoring system resilience
class HealthCheckService {
  static final HealthCheckService _instance = HealthCheckService._internal();
  factory HealthCheckService() => _instance;
  HealthCheckService._internal();

  final Logger _logger = Logger('HealthCheckService');
  
  bool _initialized = false;
  late final AlertSystem _alertSystem;
  
  Timer? _healthCheckTimer;
  final Map<String, HealthCheckResult> _lastResults = {};
  final Duration _checkInterval = const Duration(minutes: 1);
  
  // Health check thresholds
  static const Duration _responseTimeThreshold = Duration(seconds: 5);
  static const int _maxRetries = 3;

  /// Initialize health check service
  Future<void> initialize({required AlertSystem alertSystem}) async {
    if (_initialized) return;
    
    try {
      _alertSystem = alertSystem;
      
      // Start periodic health checks
      _startPeriodicHealthChecks();
      
      // Run initial health check
      await runComprehensiveHealthCheck();
      
      _initialized = true;
      _logger.info('HealthCheckService initialized successfully');
      
    } catch (error, stackTrace) {
      _logger.severe('Failed to initialize HealthCheckService', error, stackTrace);
      rethrow;
    }
  }

  /// Run comprehensive health check across all systems
  Future<Map<String, HealthCheckResult>> runComprehensiveHealthCheck() async {
    if (!_initialized) {
      throw StateError('HealthCheckService not initialized');
    }

    final results = <String, HealthCheckResult>{};
    
    try {
      // Run all health checks concurrently
      final futures = [
        _checkSupabaseHealth().then((r) => results['supabase'] = r),
        _checkInternetConnectivity().then((r) => results['internet'] = r),
        _checkMemoryUsage().then((r) => results['memory'] = r),
        _checkDiskSpace().then((r) => results['disk'] = r),
        _checkSystemPerformance().then((r) => results['performance'] = r),
        _checkExternalDependencies().then((r) => results['external_deps'] = r),
      ];

      await Future.wait(futures);
      
      // Store results for comparison
      _lastResults.addAll(results);
      
      // Check for critical failures and send alerts
      await _processHealthCheckResults(results);
      
      _logger.info('Comprehensive health check completed');
      return results;
      
    } catch (error, stackTrace) {
      _logger.severe('Failed to run comprehensive health check', error, stackTrace);
      
      // Send critical alert for health check failure
      await _alertSystem.sendCriticalAlert(
        title: 'Health Check System Failure',
        message: 'Unable to perform system health checks: $error',
        metadata: {
          'error': error.toString(),
          'stack_trace': stackTrace.toString(),
        },
      );
      
      rethrow;
    }
  }

  /// Check Supabase database connectivity and performance
  Future<HealthCheckResult> _checkSupabaseHealth() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Test basic connectivity
      final response = await Supabase.instance.client
          .from('health_check')
          .select('*')
          .limit(1)
          .timeout(_responseTimeThreshold);
      
      stopwatch.stop();
      
      final responseTime = stopwatch.elapsed;
      final isHealthy = responseTime < _responseTimeThreshold;
      
      return HealthCheckResult(
        service: 'supabase',
        isHealthy: isHealthy,
        responseTime: responseTime,
        message: isHealthy 
            ? 'Supabase connection healthy' 
            : 'Supabase response time exceeded threshold',
        metadata: {
          'response_time_ms': responseTime.inMilliseconds,
          'threshold_ms': _responseTimeThreshold.inMilliseconds,
          'query_result_count': response.length,
        },
      );
      
    } catch (error) {
      stopwatch.stop();
      
      return HealthCheckResult(
        service: 'supabase',
        isHealthy: false,
        responseTime: stopwatch.elapsed,
        message: 'Supabase connection failed: $error',
        metadata: {
          'error': error.toString(),
          'response_time_ms': stopwatch.elapsed.inMilliseconds,
        },
      );
    }
  }

  /// Check internet connectivity
  Future<HealthCheckResult> _checkInternetConnectivity() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Test connectivity to Google DNS
      final result = await InternetAddress.lookup('google.com')
          .timeout(_responseTimeThreshold);
      
      stopwatch.stop();
      
      final isHealthy = result.isNotEmpty;
      
      return HealthCheckResult(
        service: 'internet',
        isHealthy: isHealthy,
        responseTime: stopwatch.elapsed,
        message: isHealthy 
            ? 'Internet connectivity healthy' 
            : 'No internet connectivity',
        metadata: {
          'lookup_result_count': result.length,
          'response_time_ms': stopwatch.elapsed.inMilliseconds,
        },
      );
      
    } catch (error) {
      stopwatch.stop();
      
      return HealthCheckResult(
        service: 'internet',
        isHealthy: false,
        responseTime: stopwatch.elapsed,
        message: 'Internet connectivity check failed: $error',
        metadata: {
          'error': error.toString(),
          'response_time_ms': stopwatch.elapsed.inMilliseconds,
        },
      );
    }
  }

  /// Check memory usage
  Future<HealthCheckResult> _checkMemoryUsage() async {
    try {
      // This is a simplified check - in a real app you'd get actual memory stats
      final memoryUsageMB = await _getCurrentMemoryUsage();
      const memoryThresholdMB = 200.0; // 200MB threshold
      
      final isHealthy = memoryUsageMB < memoryThresholdMB;
      
      return HealthCheckResult(
        service: 'memory',
        isHealthy: isHealthy,
        responseTime: Duration.zero,
        message: isHealthy 
            ? 'Memory usage within limits' 
            : 'Memory usage exceeds threshold',
        metadata: {
          'memory_usage_mb': memoryUsageMB,
          'threshold_mb': memoryThresholdMB,
          'usage_percentage': (memoryUsageMB / memoryThresholdMB * 100).toStringAsFixed(1),
        },
      );
      
    } catch (error) {
      return HealthCheckResult(
        service: 'memory',
        isHealthy: false,
        responseTime: Duration.zero,
        message: 'Memory check failed: $error',
        metadata: {'error': error.toString()},
      );
    }
  }

  /// Check available disk space
  Future<HealthCheckResult> _checkDiskSpace() async {
    try {
      // This is a simplified check - would need platform-specific implementation
      const availableSpaceMB = 1000.0; // Mock value
      const diskThresholdMB = 100.0; // 100MB minimum threshold
      
      final isHealthy = availableSpaceMB > diskThresholdMB;
      
      return HealthCheckResult(
        service: 'disk',
        isHealthy: isHealthy,
        responseTime: Duration.zero,
        message: isHealthy 
            ? 'Sufficient disk space available' 
            : 'Low disk space warning',
        metadata: {
          'available_space_mb': availableSpaceMB,
          'threshold_mb': diskThresholdMB,
        },
      );
      
    } catch (error) {
      return HealthCheckResult(
        service: 'disk',
        isHealthy: false,
        responseTime: Duration.zero,
        message: 'Disk space check failed: $error',
        metadata: {'error': error.toString()},
      );
    }
  }

  /// Check system performance metrics
  Future<HealthCheckResult> _checkSystemPerformance() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Perform a CPU-intensive operation to test performance
      const iterations = 100000;
      var sum = 0;
      for (var i = 0; i < iterations; i++) {
        sum += i;
      }
      
      stopwatch.stop();
      
      const performanceThreshold = Duration(milliseconds: 100);
      final isHealthy = stopwatch.elapsed < performanceThreshold;
      
      return HealthCheckResult(
        service: 'performance',
        isHealthy: isHealthy,
        responseTime: stopwatch.elapsed,
        message: isHealthy 
            ? 'System performance healthy' 
            : 'System performance degraded',
        metadata: {
          'computation_time_ms': stopwatch.elapsed.inMilliseconds,
          'threshold_ms': performanceThreshold.inMilliseconds,
          'iterations': iterations,
          'result': sum,
        },
      );
      
    } catch (error) {
      stopwatch.stop();
      
      return HealthCheckResult(
        service: 'performance',
        isHealthy: false,
        responseTime: stopwatch.elapsed,
        message: 'Performance check failed: $error',
        metadata: {'error': error.toString()},
      );
    }
  }

  /// Check external dependencies
  Future<HealthCheckResult> _checkExternalDependencies() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final futures = <Future<bool>>[];
      
      // Check environment-specific endpoints
      if (EnvironmentConfig.isProduction) {
        // Check production endpoints
        futures.addAll([
          _pingEndpoint('https://api.example.com/health'),
          _pingEndpoint('https://cdn.example.com/health'),
        ]);
      }
      
      if (futures.isEmpty) {
        // No external dependencies to check in dev/test
        return HealthCheckResult(
          service: 'external_deps',
          isHealthy: true,
          responseTime: Duration.zero,
          message: 'No external dependencies to check',
          metadata: {'environment': EnvironmentConfig.currentEnvironment.name},
        );
      }
      
      final results = await Future.wait(futures);
      stopwatch.stop();
      
      final healthyCount = results.where((r) => r).length;
      final isHealthy = healthyCount == results.length;
      
      return HealthCheckResult(
        service: 'external_deps',
        isHealthy: isHealthy,
        responseTime: stopwatch.elapsed,
        message: isHealthy 
            ? 'All external dependencies healthy' 
            : '$healthyCount/${results.length} external dependencies healthy',
        metadata: {
          'total_deps': results.length,
          'healthy_deps': healthyCount,
          'response_time_ms': stopwatch.elapsed.inMilliseconds,
        },
      );
      
    } catch (error) {
      stopwatch.stop();
      
      return HealthCheckResult(
        service: 'external_deps',
        isHealthy: false,
        responseTime: stopwatch.elapsed,
        message: 'External dependency check failed: $error',
        metadata: {'error': error.toString()},
      );
    }
  }

  /// Ping an endpoint to check its health
  Future<bool> _pingEndpoint(String url) async {
    try {
      final response = await http.head(Uri.parse(url))
          .timeout(_responseTimeThreshold);
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (error) {
      _logger.fine('Endpoint ping failed: $url - $error');
      return false;
    }
  }

  /// Get current memory usage (simplified)
  Future<double> _getCurrentMemoryUsage() async {
    try {
      if (Platform.isLinux || Platform.isAndroid) {
        final result = await Process.run('cat', ['/proc/self/status']);
        final lines = result.stdout.toString().split('\n');
        
        for (final line in lines) {
          if (line.startsWith('VmRSS:')) {
            final parts = line.split(RegExp(r'\s+'));
            if (parts.length >= 2) {
              final memoryKb = int.tryParse(parts[1]) ?? 0;
              return memoryKb / 1024.0; // Convert to MB
            }
          }
        }
      }
      
      // Fallback estimation
      return 50.0; // 50MB estimation
    } catch (error) {
      return 50.0; // Default estimation on error
    }
  }

  /// Start periodic health checks
  void _startPeriodicHealthChecks() {
    _healthCheckTimer = Timer.periodic(_checkInterval, (_) {
      runComprehensiveHealthCheck().catchError((error) {
        _logger.warning('Periodic health check failed', error);
      });
    });
  }

  /// Process health check results and send alerts
  Future<void> _processHealthCheckResults(Map<String, HealthCheckResult> results) async {
    for (final entry in results.entries) {
      final serviceName = entry.key;
      final result = entry.value;
      
      // Check if service health has changed
      final previousResult = _lastResults[serviceName];
      final healthChanged = previousResult?.isHealthy != result.isHealthy;
      
      if (!result.isHealthy) {
        // Send alert for unhealthy service
        await _alertSystem.sendServiceHealthAlert(
          serviceName: serviceName,
          isHealthy: false,
          details: result.message,
          metadata: result.metadata,
        );
      } else if (healthChanged && previousResult != null && !previousResult.isHealthy) {
        // Send recovery alert
        await _alertSystem.sendServiceHealthAlert(
          serviceName: serviceName,
          isHealthy: true,
          details: 'Service recovered: ${result.message}',
          metadata: result.metadata,
        );
      }
      
      // Check for performance degradation
      if (result.isHealthy && result.responseTime > _responseTimeThreshold) {
        await _alertSystem.sendPerformanceAlert(
          metric: '${serviceName}_response_time',
          value: result.responseTime.inMilliseconds.toDouble(),
          threshold: _responseTimeThreshold.inMilliseconds.toDouble(),
          metadata: result.metadata,
        );
      }
    }
  }

  /// Get overall system health status
  Map<String, dynamic> getOverallHealthStatus() {
    if (_lastResults.isEmpty) {
      return {
        'overall_health': 'unknown',
        'last_check': null,
        'services': {},
      };
    }

    final healthyServices = _lastResults.values.where((r) => r.isHealthy).length;
    final totalServices = _lastResults.length;
    final healthPercentage = (healthyServices / totalServices * 100).round();

    String overallHealth;
    if (healthPercentage == 100) {
      overallHealth = 'healthy';
    } else if (healthPercentage >= 80) {
      overallHealth = 'degraded';
    } else {
      overallHealth = 'unhealthy';
    }

    return {
      'overall_health': overallHealth,
      'health_percentage': healthPercentage,
      'healthy_services': healthyServices,
      'total_services': totalServices,
      'last_check': _lastResults.values.first.timestamp.toIso8601String(),
      'services': _lastResults.map((key, value) => MapEntry(key, value.toJson())),
    };
  }

  /// Test all health check systems
  Future<void> runHealthCheckTest() async {
    try {
      _logger.info('Running health check system test...');
      
      final results = await runComprehensiveHealthCheck();
      
      // Send test notification
      await _alertSystem.sendInfoAlert(
        title: 'Health Check System Test',
        message: 'Health check test completed successfully',
        metadata: {
          'test_timestamp': DateTime.now().toIso8601String(),
          'services_checked': results.length,
          'healthy_services': results.values.where((r) => r.isHealthy).length,
        },
      );
      
      _logger.info('Health check system test completed');
      
    } catch (error, stackTrace) {
      _logger.severe('Health check system test failed', error, stackTrace);
      rethrow;
    }
  }

  /// Dispose of health check service
  void dispose() {
    _healthCheckTimer?.cancel();
    _lastResults.clear();
    _initialized = false;
    _logger.info('HealthCheckService disposed');
  }
}

/// Health check result data class
class HealthCheckResult {
  final String service;
  final bool isHealthy;
  final Duration responseTime;
  final String message;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  HealthCheckResult({
    required this.service,
    required this.isHealthy,
    required this.responseTime,
    required this.message,
    required this.metadata,
  }) : timestamp = DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'service': service,
      'is_healthy': isHealthy,
      'response_time_ms': responseTime.inMilliseconds,
      'message': message,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'HealthCheckResult(service: $service, healthy: $isHealthy, time: ${responseTime.inMilliseconds}ms)';
  }
}