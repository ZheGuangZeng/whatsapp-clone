import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analytics_service.dart';
import 'error_reporter.dart';
import 'monitoring_service.dart';
import 'performance_monitor.dart';

/// Provider for the main monitoring service
final monitoringServiceProvider = Provider<MonitoringService>((ref) {
  return MonitoringService();
});

/// Provider for the error reporter service
final errorReporterProvider = Provider<ErrorReporter>((ref) {
  return ErrorReporter();
});

/// Provider for the performance monitor service
final performanceMonitorProvider = Provider<PerformanceMonitor>((ref) {
  return PerformanceMonitor();
});

/// Provider for the analytics service
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

/// Provider for monitoring health status
final monitoringHealthProvider = Provider<Map<String, dynamic>>((ref) {
  final monitoring = ref.watch(monitoringServiceProvider);
  return monitoring.getHealthStatus();
});

/// Provider for performance statistics
final performanceStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final performance = ref.watch(performanceMonitorProvider);
  return performance.getPerformanceStats();
});

/// Provider for analytics statistics
final analyticsStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final analytics = ref.watch(analyticsServiceProvider);
  return analytics.getAnalyticsStats();
});

/// Provider for error statistics
final errorStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final errorReporter = ref.watch(errorReporterProvider);
  return errorReporter.getErrorStats();
});