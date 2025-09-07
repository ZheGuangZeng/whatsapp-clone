import 'dart:async';
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Comprehensive error reporting service for production monitoring
class ErrorReporter {
  static final ErrorReporter _instance = ErrorReporter._internal();
  factory ErrorReporter() => _instance;
  ErrorReporter._internal();

  final Logger _logger = Logger('ErrorReporter');
  
  bool _initialized = false;
  bool _isHealthy = true;
  
  final List<ErrorRecord> _errorQueue = [];
  final Map<String, int> _errorCounts = {};
  
  Timer? _reportingTimer;
  
  /// Current health status
  bool get isHealthy => _isHealthy;

  /// Initialize error reporting service
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      _logger.info('Initializing ErrorReporter');
      
      // Start periodic error reporting
      _startPeriodicReporting();
      
      _initialized = true;
      _isHealthy = true;
      
      _logger.info('ErrorReporter initialized successfully');
      
    } catch (error, stackTrace) {
      _logger.severe('Failed to initialize ErrorReporter', error, stackTrace);
      _isHealthy = false;
      rethrow;
    }
  }

  /// Report error to all monitoring services
  Future<void> reportError(
    dynamic error,
    StackTrace? stackTrace,
    String context, {
    Map<String, dynamic>? metadata,
    bool isFatal = false,
  }) async {
    if (!_initialized) {
      _queueError(error, stackTrace, context, metadata, isFatal);
      return;
    }
    
    try {
      final errorKey = _generateErrorKey(error, stackTrace);
      _errorCounts[errorKey] = (_errorCounts[errorKey] ?? 0) + 1;
      
      // Create error record
      final errorRecord = ErrorRecord(
        error: error,
        stackTrace: stackTrace,
        context: context,
        metadata: metadata ?? {},
        timestamp: DateTime.now(),
        isFatal: isFatal,
        count: _errorCounts[errorKey]!,
      );
      
      // Report to Firebase Crashlytics
      await _reportToFirebaseCrashlytics(errorRecord);
      
      // Report to Sentry
      await _reportToSentry(errorRecord);
      
      // Log locally
      _logError(errorRecord);
      
      _logger.fine('Error reported: ${errorRecord.error}');
      
    } catch (reportingError, reportingStack) {
      _logger.severe('Failed to report error', reportingError, reportingStack);
      _queueError(error, stackTrace, context, metadata, isFatal);
      _isHealthy = false;
    }
  }

  /// Queue error for later reporting if service is not initialized
  void _queueError(
    dynamic error,
    StackTrace? stackTrace,
    String context,
    Map<String, dynamic>? metadata,
    bool isFatal,
  ) {
    if (_errorQueue.length < 100) { // Prevent memory overflow
      _errorQueue.add(ErrorRecord(
        error: error,
        stackTrace: stackTrace,
        context: context,
        metadata: metadata ?? {},
        timestamp: DateTime.now(),
        isFatal: isFatal,
        count: 1,
      ));
    }
  }

  /// Start periodic error reporting for queued errors
  void _startPeriodicReporting() {
    _reportingTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      if (_errorQueue.isNotEmpty) {
        final errorsToReport = List<ErrorRecord>.from(_errorQueue);
        _errorQueue.clear();
        
        for (final errorRecord in errorsToReport) {
          await reportError(
            errorRecord.error,
            errorRecord.stackTrace,
            errorRecord.context,
            metadata: errorRecord.metadata,
            isFatal: errorRecord.isFatal,
          );
        }
      }
      
      // Reset error counts periodically to prevent memory leaks
      if (_errorCounts.length > 1000) {
        _errorCounts.clear();
      }
    });
  }

  /// Report error to Firebase Crashlytics
  Future<void> _reportToFirebaseCrashlytics(ErrorRecord errorRecord) async {
    if (kDebugMode) return; // Skip in debug mode
    
    try {
      await FirebaseCrashlytics.instance.recordError(
        errorRecord.error,
        errorRecord.stackTrace,
        fatal: errorRecord.isFatal,
        information: [
          errorRecord.context,
          'Count: ${errorRecord.count}',
          'Metadata: ${errorRecord.metadata}',
        ],
      );
      
      // Set custom keys for better context
      await FirebaseCrashlytics.instance.setCustomKey('error_context', errorRecord.context);
      await FirebaseCrashlytics.instance.setCustomKey('error_count', errorRecord.count);
      await FirebaseCrashlytics.instance.setCustomKey('is_fatal', errorRecord.isFatal);
      
    } catch (error) {
      _logger.warning('Failed to report to Firebase Crashlytics', error);
    }
  }

  /// Report error to Sentry
  Future<void> _reportToSentry(ErrorRecord errorRecord) async {
    try {
      await Sentry.captureException(
        errorRecord.error,
        stackTrace: errorRecord.stackTrace,
        withScope: (scope) {
          scope.setTag('error_context', errorRecord.context);
          scope.setTag('error_count', errorRecord.count.toString());
          scope.setTag('is_fatal', errorRecord.isFatal.toString());
          
          // Add metadata as extra data
          for (final entry in errorRecord.metadata.entries) {
            scope.setExtra(entry.key, entry.value);
          }
          
          // Add device context
          scope.setExtra('platform', Platform.operatingSystem);
          scope.setExtra('platform_version', Platform.operatingSystemVersion);
          
          // Add app context
          scope.setExtra('timestamp', errorRecord.timestamp.toIso8601String());
        },
      );
      
    } catch (error) {
      _logger.warning('Failed to report to Sentry', error);
    }
  }

  /// Log error locally
  void _logError(ErrorRecord errorRecord) {
    final level = errorRecord.isFatal ? Level.SEVERE : Level.WARNING;
    
    _logger.log(
      level,
      'Error in ${errorRecord.context}: ${errorRecord.error}',
      errorRecord.error,
      errorRecord.stackTrace,
    );
  }

  /// Generate unique key for error deduplication
  String _generateErrorKey(dynamic error, StackTrace? stackTrace) {
    final errorString = error.toString();
    final stackString = stackTrace?.toString() ?? '';
    
    // Create hash of error + first few lines of stack trace for deduplication
    final key = '$errorString${stackString.split('\n').take(3).join('\n')}';
    return key.hashCode.toString();
  }

  /// Get error statistics
  Map<String, dynamic> getErrorStats() {
    return {
      'total_errors': _errorCounts.values.fold<int>(0, (sum, count) => sum + count),
      'unique_errors': _errorCounts.length,
      'queued_errors': _errorQueue.length,
      'most_frequent_errors': _getMostFrequentErrors(),
      'last_updated': DateTime.now().toIso8601String(),
    };
  }

  /// Get most frequent errors for debugging
  List<Map<String, dynamic>> _getMostFrequentErrors({int limit = 10}) {
    final sortedErrors = _errorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedErrors.take(limit).map((entry) => {
      'error_key': entry.key,
      'count': entry.value,
    }).toList();
  }

  /// Clear error statistics (useful for testing)
  void clearStats() {
    _errorCounts.clear();
    _errorQueue.clear();
    _logger.info('Error statistics cleared');
  }

  /// Dispose of error reporter
  void dispose() {
    _reportingTimer?.cancel();
    _errorQueue.clear();
    _errorCounts.clear();
    _initialized = false;
    _logger.info('ErrorReporter disposed');
  }
}

/// Error record data class
class ErrorRecord {
  final dynamic error;
  final StackTrace? stackTrace;
  final String context;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  final bool isFatal;
  final int count;

  const ErrorRecord({
    required this.error,
    this.stackTrace,
    required this.context,
    required this.metadata,
    required this.timestamp,
    required this.isFatal,
    required this.count,
  });

  @override
  String toString() {
    return 'ErrorRecord(context: $context, error: $error, count: $count, fatal: $isFatal)';
  }
}