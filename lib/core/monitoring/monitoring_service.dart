import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../config/environment_config.dart';
import 'alert_system.dart';
import 'analytics_service.dart';
import 'error_reporter.dart';
import 'performance_monitor.dart';

/// Comprehensive monitoring service for production-grade observability
class MonitoringService {
  static final MonitoringService _instance = MonitoringService._internal();
  factory MonitoringService() => _instance;
  MonitoringService._internal();

  final Logger _logger = Logger('MonitoringService');
  
  ErrorReporter? _errorReporter;
  PerformanceMonitor? _performanceMonitor;
  AnalyticsService? _analyticsService;
  AlertSystem? _alertSystem;
  
  bool _initialized = false;
  StreamSubscription<LogRecord>? _logSubscription;

  /// Initialize monitoring service with crash reporting and performance tracking
  Future<void> initialize() async {
    if (_initialized) {
      _logger.warning('MonitoringService already initialized');
      return;
    }

    try {
      // Initialize logging
      _setupLogging();
      
      // Initialize Firebase services in production
      if (!kDebugMode) {
        await _initializeFirebase();
      }
      
      // Initialize Sentry for error tracking
      await _initializeSentry();
      
      // Initialize sub-services
      _errorReporter = ErrorReporter();
      _performanceMonitor = PerformanceMonitor();
      _analyticsService = AnalyticsService();
      _alertSystem = AlertSystem();
      
      await _errorReporter!.initialize();
      await _performanceMonitor!.initialize();
      await _analyticsService!.initialize();
      await _alertSystem!.initialize();
      
      // Set up global error handlers
      _setupGlobalErrorHandlers();
      
      _initialized = true;
      _logger.info('MonitoringService initialized successfully');
      
      // Track app launch performance
      await _performanceMonitor!.trackAppLaunch();
      
      // Set Sentry tags after initialization
      Sentry.configureScope((scope) {
        scope.setTag('environment', EnvironmentConfig.currentEnvironment.name);
        scope.setTag('platform', Platform.operatingSystem);
      });
      
    } catch (error, stackTrace) {
      _logger.severe('Failed to initialize MonitoringService', error, stackTrace);
      rethrow;
    }
  }

  /// Setup comprehensive logging system
  void _setupLogging() {
    Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
    
    _logSubscription = Logger.root.onRecord.listen((record) {
      // Log to system console
      developer.log(
        record.message,
        time: record.time,
        level: record.level.value,
        name: record.loggerName,
        error: record.error,
        stackTrace: record.stackTrace,
      );
      
      // Send critical logs to remote monitoring
      if (record.level >= Level.WARNING && _initialized) {
        _sendLogToRemote(record);
      }
    });
  }

  /// Initialize Firebase services for production monitoring
  Future<void> _initializeFirebase() async {
    try {
      // Firebase Crashlytics configuration
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      
      // Set custom keys for better error context
      await FirebaseCrashlytics.instance.setCustomKey('environment', EnvironmentConfig.currentEnvironment.name);
      await FirebaseCrashlytics.instance.setCustomKey('platform', Platform.operatingSystem);
      await FirebaseCrashlytics.instance.setCustomKey('app_version', EnvironmentConfig.config.appVersion);
      
      // Firebase Performance Monitoring
      FirebasePerformance.instance.setPerformanceCollectionEnabled(true);
      
      _logger.info('Firebase monitoring services initialized');
    } catch (error, stackTrace) {
      _logger.severe('Firebase initialization failed', error, stackTrace);
    }
  }

  /// Initialize Sentry for comprehensive error tracking
  Future<void> _initializeSentry() async {
    try {
      final sentryDsn = EnvironmentConfig.config.sentryDsn;
      
      // Skip Sentry initialization if DSN is not provided
      if (sentryDsn == null || sentryDsn.isEmpty) {
        _logger.info('Sentry DSN not provided, skipping Sentry initialization');
        return;
      }
      
      await SentryFlutter.init(
        (options) {
          options.dsn = sentryDsn;
          options.environment = EnvironmentConfig.currentEnvironment.name;
          options.release = EnvironmentConfig.config.appVersion;
          options.tracesSampleRate = kDebugMode ? 1.0 : 0.1;
          options.profilesSampleRate = kDebugMode ? 1.0 : 0.1;
          // Screenshot and view hierarchy capture
          options.attachScreenshot = true;
          options.attachViewHierarchy = true;
          options.enableAutoSessionTracking = true;
          
          // Filter sensitive data
          options.beforeSend = (event, {hint}) async {
            // Remove sensitive information
            return _sanitizeEvent(event);
          };
          
          // Custom tags will be set after initialization
        },
        appRunner: () {}, // Will be set by main app
      );
      
      _logger.info('Sentry error tracking initialized');
    } catch (error, stackTrace) {
      _logger.warning('Failed to initialize Sentry', error, stackTrace);
      // Don't let Sentry initialization failure prevent app startup
    }
  }

  /// Setup global error handlers for comprehensive crash reporting
  void _setupGlobalErrorHandlers() {
    // Catch Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      _logger.severe(
        'Flutter Error: ${details.summary}', 
        details.exception,
        details.stack,
      );
      
      // Report to multiple services for redundancy
      _reportError(details.exception, details.stack, 'Flutter Framework Error');
    };

    // Catch async errors outside Flutter framework
    PlatformDispatcher.instance.onError = (error, stack) {
      _logger.severe('Uncaught Error', error, stack);
      _reportError(error, stack, 'Uncaught Async Error');
      return true;
    };
    
    // Catch platform-specific errors
    SystemChannels.platform.setMethodCallHandler((call) async {
      if (call.method == 'SystemNavigator.pop') {
        _analyticsService?.trackEvent('app_background', {});
      }
      return null;
    });
  }

  /// Report error to multiple monitoring services
  void _reportError(dynamic error, StackTrace? stackTrace, String context) {
    if (!_initialized) return;
    
    try {
      // Report to Firebase Crashlytics
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        fatal: false,
        information: [context],
      );
      
      // Report to Sentry
      Sentry.captureException(
        error,
        stackTrace: stackTrace,
        withScope: (scope) {
          scope.setTag('error_context', context);
        },
      );
      
      // Log to custom error reporter
      _errorReporter?.reportError(error, stackTrace, context);
      
      // Send alert for critical errors
      if (error is Error || error.toString().contains('Error')) {
        _alertSystem?.sendCrashAlert(
          error: error.toString(),
          stackTrace: stackTrace.toString(),
          metadata: {
            'context': context,
            'error_type': error.runtimeType.toString(),
          },
        );
      }
      
    } catch (reportingError) {
      _logger.severe('Failed to report error', reportingError);
    }
  }

  /// Send critical logs to remote monitoring
  void _sendLogToRemote(LogRecord record) {
    try {
      // Create structured log data
      final logData = {
        'level': record.level.name,
        'message': record.message,
        'logger': record.loggerName,
        'timestamp': record.time.toIso8601String(),
        'error': record.error?.toString(),
        'stackTrace': record.stackTrace?.toString(),
      };
      
      // Send to Sentry as breadcrumb
      Sentry.addBreadcrumb(
        Breadcrumb(
          message: record.message,
          level: _mapLogLevelToSentry(record.level),
          category: record.loggerName,
          timestamp: record.time,
          data: logData,
        ),
      );
      
    } catch (error) {
      developer.log('Failed to send log to remote: $error');
    }
  }

  /// Sanitize event data to remove sensitive information
  SentryEvent _sanitizeEvent(SentryEvent event) {
    // Remove sensitive data from request contexts
    if (event.request?.data != null) {
      final sanitized = <String, dynamic>{};
      
      // Copy non-sensitive data
      final originalData = event.request!.data as Map<String, dynamic>;
      
      // Remove common sensitive fields
      const sensitiveFields = [
        'password',
        'token',
        'authorization',
        'api_key',
        'secret',
        'private_key',
        'credit_card',
        'ssn',
      ];
      
      for (final entry in originalData.entries) {
        final isKeySensitive = sensitiveFields.any((field) => 
          entry.key.toLowerCase().contains(field));
        
        if (isKeySensitive) {
          sanitized[entry.key] = '[REDACTED]';
        } else {
          sanitized[entry.key] = entry.value;
        }
      }
      
      // Create new event with sanitized data
      return event.copyWith(
        request: event.request!.copyWith(data: sanitized),
      );
    }
    
    return event;
  }

  /// Map logging levels to Sentry levels
  SentryLevel _mapLogLevelToSentry(Level level) {
    if (level >= Level.SEVERE) return SentryLevel.error;
    if (level >= Level.WARNING) return SentryLevel.warning;
    if (level >= Level.INFO) return SentryLevel.info;
    return SentryLevel.debug;
  }

  /// Track custom events for business intelligence
  Future<void> trackEvent(String eventName, Map<String, dynamic> properties) async {
    if (!_initialized) return;
    
    try {
      await _analyticsService?.trackEvent(eventName, properties);
      
      // Add to Sentry breadcrumbs for context
      Sentry.addBreadcrumb(
        Breadcrumb(
          message: 'Event: $eventName',
          category: 'analytics',
          level: SentryLevel.info,
          data: properties,
        ),
      );
      
    } catch (error) {
      _logger.warning('Failed to track event: $eventName', error);
    }
  }

  /// Track performance metrics
  Future<void> trackPerformance(String operationName, Duration duration, {Map<String, dynamic>? metadata}) async {
    if (!_initialized) return;
    
    try {
      await _performanceMonitor?.trackManualOperation(operationName, duration, metadata);
    } catch (error) {
      _logger.warning('Failed to track performance: $operationName', error);
    }
  }

  /// Set user context for better error attribution
  Future<void> setUser({
    required String id,
    String? email,
    String? username,
    Map<String, dynamic>? properties,
  }) async {
    if (!_initialized) return;
    
    try {
      // Set user in Firebase Crashlytics
      await FirebaseCrashlytics.instance.setUserIdentifier(id);
      
      // Set user in Sentry
      Sentry.configureScope((scope) => 
        scope.setUser(
          SentryUser(
            id: id,
            email: email,
            username: username,
            data: properties,
          ),
        ),
      );
      
      // Set user in analytics
      await _analyticsService?.setUserId(id);
      
      _logger.info('User context set: $id');
      
    } catch (error) {
      _logger.warning('Failed to set user context', error);
    }
  }

  /// Clear user context on logout
  Future<void> clearUser() async {
    if (!_initialized) return;
    
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier('');
      
      Sentry.configureScope((scope) => scope.setUser(null));
      
      await _analyticsService?.resetAnalyticsData();
      
      _logger.info('User context cleared');
      
    } catch (error) {
      _logger.warning('Failed to clear user context', error);
    }
  }

  /// Get monitoring health status
  Map<String, dynamic> getHealthStatus() {
    return {
      'initialized': _initialized,
      'services': {
        'error_reporter': _errorReporter?.isHealthy ?? false,
        'performance_monitor': _performanceMonitor?.isHealthy ?? false,
        'analytics': _analyticsService?.isHealthy ?? false,
      },
      'last_check': DateTime.now().toIso8601String(),
    };
  }

  /// Dispose of monitoring service
  void dispose() {
    _logSubscription?.cancel();
    
    // Only dispose if services were initialized
    if (_initialized) {
      _errorReporter?.dispose();
      _performanceMonitor?.dispose();
      _analyticsService?.dispose();
      _alertSystem?.dispose();
      
      // Reset services to null to allow re-initialization
      _errorReporter = null;
      _performanceMonitor = null;
      _analyticsService = null;
      _alertSystem = null;
    }
    
    _initialized = false;
    _logger.info('MonitoringService disposed');
  }
}