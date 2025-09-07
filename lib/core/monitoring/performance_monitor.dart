import 'dart:async';
import 'dart:io';

import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';

/// Performance monitoring service for tracking app performance metrics
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Logger _logger = Logger('PerformanceMonitor');
  
  bool _initialized = false;
  bool _isHealthy = true;
  
  final Map<String, Trace> _activeTraces = {};
  final Map<String, Stopwatch> _customStopwatches = {};
  final Map<String, List<Duration>> _operationTimes = {};
  
  Timer? _memoryMonitorTimer;
  Timer? _fpsMonitorTimer;
  
  double _currentMemoryUsage = 0.0;
  double _peakMemoryUsage = 0.0;
  double _currentFps = 60.0;
  
  /// Current health status
  bool get isHealthy => _isHealthy;
  
  /// Initialize performance monitoring
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      _logger.info('Initializing PerformanceMonitor');
      
      // Start memory monitoring
      _startMemoryMonitoring();
      
      // Start FPS monitoring
      _startFpsMonitoring();
      
      // Set up method channel listener for native performance data
      _setupNativePerformanceTracking();
      
      _initialized = true;
      _isHealthy = true;
      
      _logger.info('PerformanceMonitor initialized successfully');
      
    } catch (error, stackTrace) {
      _logger.severe('Failed to initialize PerformanceMonitor', error, stackTrace);
      _isHealthy = false;
      rethrow;
    }
  }

  /// Track app launch performance
  Future<void> trackAppLaunch() async {
    if (!_initialized) return;
    
    try {
      final trace = FirebasePerformance.instance.newTrace('app_launch');
      await trace.start();
      
      // Measure app initialization time
      final initStopwatch = Stopwatch()..start();
      
      // Wait for first frame to be rendered
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        initStopwatch.stop();
        
        trace.setMetric('initialization_time_ms', initStopwatch.elapsedMilliseconds);
        trace.setMetric('memory_usage_mb', (_currentMemoryUsage / 1024 / 1024).round());
        
        await trace.stop();
        
        _logger.info('App launch tracked: ${initStopwatch.elapsedMilliseconds}ms');
        
        // Track launch performance metrics
        _recordCustomMetric('app_launch_time', initStopwatch.elapsed);
      });
      
    } catch (error) {
      _logger.warning('Failed to track app launch', error);
    }
  }

  /// Start a custom performance trace
  Future<Trace?> startTrace(String traceName) async {
    if (!_initialized) return null;
    
    try {
      if (_activeTraces.containsKey(traceName)) {
        _logger.warning('Trace $traceName already active');
        return _activeTraces[traceName];
      }
      
      final trace = FirebasePerformance.instance.newTrace(traceName);
      await trace.start();
      
      _activeTraces[traceName] = trace;
      _customStopwatches[traceName] = Stopwatch()..start();
      
      _logger.fine('Started trace: $traceName');
      return trace;
      
    } catch (error) {
      _logger.warning('Failed to start trace: $traceName', error);
      return null;
    }
  }

  /// Stop a custom performance trace
  Future<void> stopTrace(String traceName, {Map<String, dynamic>? metadata}) async {
    if (!_initialized) return;
    
    try {
      final trace = _activeTraces.remove(traceName);
      final stopwatch = _customStopwatches.remove(traceName);
      
      if (trace == null || stopwatch == null) {
        _logger.warning('No active trace found: $traceName');
        return;
      }
      
      stopwatch.stop();
      
      // Add custom metrics
      if (metadata != null) {
        for (final entry in metadata.entries) {
          if (entry.value is int) {
            trace.setMetric(entry.key, entry.value as int);
          } else if (entry.value is double) {
            trace.setMetric(entry.key, (entry.value as double).round());
          }
        }
      }
      
      // Add duration metric
      trace.setMetric('duration_ms', stopwatch.elapsedMilliseconds);
      
      await trace.stop();
      
      // Record custom metrics
      _recordCustomMetric(traceName, stopwatch.elapsed);
      
      _logger.fine('Stopped trace: $traceName (${stopwatch.elapsedMilliseconds}ms)');
      
    } catch (error) {
      _logger.warning('Failed to stop trace: $traceName', error);
    }
  }

  /// Track a complete operation
  Future<T> trackOperation<T>(
    String operationName, 
    Future<T> Function() operation, {
    Map<String, dynamic>? metadata,
  }) async {
    if (!_initialized) return await operation();
    
    final stopwatch = Stopwatch()..start();
    final trace = await startTrace(operationName);
    
    try {
      final result = await operation();
      
      stopwatch.stop();
      
      // Add success metrics
      await stopTrace(operationName, metadata: {
        'success': 1,
        'duration_ms': stopwatch.elapsedMilliseconds,
        ...?metadata,
      });
      
      return result;
      
    } catch (error) {
      stopwatch.stop();
      
      // Add failure metrics
      await stopTrace(operationName, metadata: {
        'success': 0,
        'error': 1,
        'duration_ms': stopwatch.elapsedMilliseconds,
        ...?metadata,
      });
      
      rethrow;
    }
  }

  /// Track operation with manual timing
  Future<void> trackManualOperation(String operationName, Duration duration, Map<String, dynamic>? metadata) async {
    if (!_initialized) return;
    
    try {
      final trace = FirebasePerformance.instance.newTrace(operationName);
      await trace.start();
      
      trace.setMetric('duration_ms', duration.inMilliseconds);
      
      if (metadata != null) {
        for (final entry in metadata.entries) {
          if (entry.value is int) {
            trace.setMetric(entry.key, entry.value as int);
          } else if (entry.value is double) {
            trace.setMetric(entry.key, (entry.value as double).round());
          }
        }
      }
      
      await trace.stop();
      
      _recordCustomMetric(operationName, duration);
      
    } catch (error) {
      _logger.warning('Failed to track operation: $operationName', error);
    }
  }

  /// Track network request performance
  Future<void> trackNetworkRequest({
    required String url,
    required String httpMethod,
    required int responseCode,
    required int requestPayloadSize,
    required int responsePayloadSize,
    required Duration duration,
  }) async {
    if (!_initialized) return;
    
    try {
      final httpMetric = FirebasePerformance.instance.newHttpMetric(url, HttpMethod.values.firstWhere(
        (method) => method.name.toUpperCase() == httpMethod.toUpperCase(),
        orElse: () => HttpMethod.Get,
      ));
      
      await httpMetric.start();
      
      httpMetric
        ..httpResponseCode = responseCode
        ..requestPayloadSize = requestPayloadSize
        ..responsePayloadSize = responsePayloadSize;
      
      await httpMetric.stop();
      
      _logger.fine('Network request tracked: $httpMethod $url (${duration.inMilliseconds}ms)');
      
    } catch (error) {
      _logger.warning('Failed to track network request: $url', error);
    }
  }

  /// Start memory monitoring
  void _startMemoryMonitoring() {
    _memoryMonitorTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      try {
        // Simplified memory monitoring using ProcessInfo
        if (Platform.isLinux || Platform.isAndroid) {
          final result = await Process.run('cat', ['/proc/self/status']);
          final lines = result.stdout.toString().split('\n');
          
          for (final line in lines) {
            if (line.startsWith('VmRSS:')) {
              final parts = line.split(RegExp(r'\s+'));
              if (parts.length >= 2) {
                final memoryKb = int.tryParse(parts[1]) ?? 0;
                _currentMemoryUsage = memoryKb * 1024.0; // Convert to bytes
                
                if (_currentMemoryUsage > _peakMemoryUsage) {
                  _peakMemoryUsage = _currentMemoryUsage;
                }
              }
              break;
            }
          }
        } else {
          // For iOS/macOS, use a simple estimation
          _currentMemoryUsage = _estimateMemoryUsage();
        }
        
        // Report memory usage periodically
        if (_currentMemoryUsage > 100 * 1024 * 1024) { // > 100MB
          _logger.info('Memory usage: ${(_currentMemoryUsage / 1024 / 1024).toStringAsFixed(1)}MB');
        }
        
      } catch (error) {
        _logger.fine('Memory monitoring error: $error');
        _currentMemoryUsage = _estimateMemoryUsage();
      }
    });
  }
  
  /// Estimate memory usage when system calls are not available
  double _estimateMemoryUsage() {
    // Simple estimation based on runtime statistics
    try {
      return 50 * 1024 * 1024.0; // Default to 50MB estimate
    } catch (error) {
      return 0.0;
    }
  }

  /// Start FPS monitoring
  void _startFpsMonitoring() {
    if (!kDebugMode) return; // Only monitor FPS in debug mode
    
    try {
      // Check if WidgetsBinding is available
      if (!WidgetsBinding.instance.debugDidSendFirstFrameEvent) {
        _logger.fine('WidgetsBinding not ready, skipping FPS monitoring');
        return;
      }
      
      Duration? previousFrameTimeStamp;
      final List<Duration> frameTimes = [];
      
      _fpsMonitorTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (frameTimes.isNotEmpty) {
          final avgFrameTime = frameTimes.reduce((a, b) => a + b) ~/ frameTimes.length;
          _currentFps = 1000000 / avgFrameTime.inMicroseconds; // Convert to FPS
          
          if (_currentFps < 30) {
            _logger.warning('Low FPS detected: ${_currentFps.toStringAsFixed(1)}');
          }
          
          frameTimes.clear();
        }
      });
      
      SchedulerBinding.instance.addPersistentFrameCallback((timeStamp) {
        if (previousFrameTimeStamp != null) {
          frameTimes.add(timeStamp - previousFrameTimeStamp!);
        }
        previousFrameTimeStamp = timeStamp;
      });
    } catch (error) {
      _logger.fine('FPS monitoring not available: $error');
    }
  }

  /// Setup native performance tracking
  void _setupNativePerformanceTracking() {
    try {
      const platform = MethodChannel('com.whatsappclone.performance');
      
      platform.setMethodCallHandler((call) async {
        try {
          switch (call.method) {
            case 'reportNativePerformance':
              final args = call.arguments as Map<String, dynamic>;
              await _handleNativePerformanceData(args);
              break;
            default:
              _logger.warning('Unknown method call: ${call.method}');
          }
        } catch (error) {
          _logger.warning('Failed to handle native performance data', error);
        }
        
        return null;
      });
    } catch (error) {
      _logger.fine('Native performance tracking not available: $error');
    }
  }

  /// Handle native performance data
  Future<void> _handleNativePerformanceData(Map<String, dynamic> data) async {
    final operationName = data['operation'] as String?;
    final duration = data['duration_ms'] as int?;
    final metadata = data['metadata'] as Map<String, dynamic>?;
    
    if (operationName != null && duration != null) {
      await trackManualOperation(operationName, Duration(milliseconds: duration), metadata);
    }
  }

  /// Record custom performance metric
  void _recordCustomMetric(String name, Duration duration) {
    if (!_operationTimes.containsKey(name)) {
      _operationTimes[name] = [];
    }
    
    _operationTimes[name]!.add(duration);
    
    // Keep only last 100 measurements to prevent memory leaks
    if (_operationTimes[name]!.length > 100) {
      _operationTimes[name]!.removeAt(0);
    }
  }

  /// Get performance statistics
  Map<String, dynamic> getPerformanceStats() {
    final stats = <String, dynamic>{
      'memory_usage_mb': _currentMemoryUsage / 1024 / 1024,
      'peak_memory_usage_mb': _peakMemoryUsage / 1024 / 1024,
      'current_fps': _currentFps,
      'active_traces': _activeTraces.keys.toList(),
      'operation_stats': <String, dynamic>{},
    };
    
    // Calculate operation statistics
    for (final entry in _operationTimes.entries) {
      final times = entry.value;
      if (times.isNotEmpty) {
        final sortedTimes = List<Duration>.from(times)..sort((a, b) => a.compareTo(b));
        
        stats['operation_stats'][entry.key] = {
          'count': times.length,
          'avg_ms': times.map((d) => d.inMilliseconds).reduce((a, b) => a + b) ~/ times.length,
          'min_ms': sortedTimes.first.inMilliseconds,
          'max_ms': sortedTimes.last.inMilliseconds,
          'p95_ms': sortedTimes[(sortedTimes.length * 0.95).round() - 1].inMilliseconds,
        };
      }
    }
    
    return stats;
  }

  /// Dispose of performance monitor
  void dispose() {
    _memoryMonitorTimer?.cancel();
    _fpsMonitorTimer?.cancel();
    
    // Clean up active traces
    for (final trace in _activeTraces.values) {
      trace.stop().catchError((Object error) => 
        _logger.warning('Error stopping trace on dispose', error),
      );
    }
    
    _activeTraces.clear();
    _customStopwatches.clear();
    _operationTimes.clear();
    
    _initialized = false;
    _logger.info('PerformanceMonitor disposed');
  }
}