import 'dart:async';
import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Analytics service for tracking user behavior and business metrics
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final Logger _logger = Logger('AnalyticsService');
  
  bool _initialized = false;
  bool _isHealthy = true;
  
  late FirebaseAnalytics _analytics;
  late FirebaseAnalyticsObserver _observer;
  
  final Map<String, dynamic> _sessionProperties = {};
  final Map<String, int> _eventCounts = {};
  
  Timer? _sessionTimer;
  DateTime? _sessionStart;
  String? _currentUserId;
  
  /// Current health status
  bool get isHealthy => _isHealthy;
  
  /// Firebase Analytics Observer for route tracking
  FirebaseAnalyticsObserver get observer => _observer;

  /// Initialize analytics service
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      _logger.info('Initializing AnalyticsService');
      
      if (!kDebugMode) {
        _analytics = FirebaseAnalytics.instance;
        _observer = FirebaseAnalyticsObserver(analytics: _analytics);
        
        // Enable analytics collection
        await _analytics.setAnalyticsCollectionEnabled(true);
        
        // Set default properties
        await _setDefaultProperties();
        
        // Start session tracking
        _startSessionTracking();
      }
      
      _initialized = true;
      _isHealthy = true;
      
      _logger.info('AnalyticsService initialized successfully');
      
    } catch (error, stackTrace) {
      _logger.severe('Failed to initialize AnalyticsService', error, stackTrace);
      _isHealthy = false;
      rethrow;
    }
  }

  /// Set default analytics properties
  Future<void> _setDefaultProperties() async {
    try {
      await _analytics.setUserProperty(
        name: 'platform',
        value: Platform.operatingSystem,
      );
      
      await _analytics.setUserProperty(
        name: 'app_version',
        value: '1.0.0+1',
      );
      
      await _analytics.setUserProperty(
        name: 'build_mode',
        value: kDebugMode ? 'debug' : 'release',
      );
      
    } catch (error) {
      _logger.warning('Failed to set default properties', error);
    }
  }

  /// Start session tracking
  void _startSessionTracking() {
    _sessionStart = DateTime.now();
    
    // Track session duration every 30 seconds
    _sessionTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _trackSessionMetrics();
    });
    
    // Track app start
    trackEvent('app_start', {
      'cold_start': true,
      'platform': Platform.operatingSystem,
    });
  }

  /// Track session metrics
  void _trackSessionMetrics() {
    if (_sessionStart == null) return;
    
    final sessionDuration = DateTime.now().difference(_sessionStart!);
    
    _sessionProperties['session_duration_minutes'] = sessionDuration.inMinutes;
    _sessionProperties['events_in_session'] = _eventCounts.values.fold<int>(0, (sum, count) => sum + count);
  }

  /// Track custom event
  Future<void> trackEvent(String eventName, Map<String, dynamic> parameters) async {
    if (!_initialized || kDebugMode) {
      _logger.fine('Event tracked (debug): $eventName with $parameters');
      return;
    }
    
    try {
      // Sanitize parameters for Firebase Analytics
      final sanitizedParams = <String, Object>{};
      
      for (final entry in parameters.entries) {
        final key = _sanitizeParameterName(entry.key);
        final value = _sanitizeParameterValue(entry.value);
        if (value != null) {
          sanitizedParams[key] = value;
        }
      }
      
      // Add session context
      sanitizedParams['session_id'] = _sessionStart?.millisecondsSinceEpoch.toString() ?? 'unknown';
      if (_currentUserId != null) {
        sanitizedParams['user_id'] = _currentUserId!;
      }
      
      await _analytics.logEvent(
        name: _sanitizeEventName(eventName),
        parameters: sanitizedParams,
      );
      
      // Track event counts
      _eventCounts[eventName] = (_eventCounts[eventName] ?? 0) + 1;
      
      _logger.fine('Event tracked: $eventName');
      
    } catch (error) {
      _logger.warning('Failed to track event: $eventName', error);
      _isHealthy = false;
    }
  }

  /// Track user engagement events
  Future<void> trackUserEngagement({
    required String feature,
    required String action,
    Map<String, dynamic>? metadata,
  }) async {
    await trackEvent('user_engagement', {
      'feature': feature,
      'action': action,
      ...?metadata,
    });
  }

  /// Track business metrics
  Future<void> trackBusinessMetric({
    required String metricName,
    required double value,
    String? unit,
    Map<String, dynamic>? metadata,
  }) async {
    await trackEvent('business_metric', {
      'metric_name': metricName,
      'metric_value': value,
      'unit': unit ?? 'count',
      ...?metadata,
    });
  }

  /// Track messaging events
  Future<void> trackMessageEvent({
    required String action, // 'sent', 'received', 'delivered', 'read'
    required String messageType, // 'text', 'image', 'video', 'audio'
    String? chatType, // 'individual', 'group'
    Map<String, dynamic>? metadata,
  }) async {
    await trackEvent('message_event', {
      'action': action,
      'message_type': messageType,
      'chat_type': chatType ?? 'individual',
      ...?metadata,
    });
  }

  /// Track meeting events
  Future<void> trackMeetingEvent({
    required String action, // 'started', 'joined', 'left', 'ended'
    int? participantCount,
    Duration? duration,
    String? meetingType, // 'audio', 'video'
    Map<String, dynamic>? metadata,
  }) async {
    await trackEvent('meeting_event', {
      'action': action,
      'participant_count': participantCount,
      'duration_minutes': duration?.inMinutes,
      'meeting_type': meetingType ?? 'video',
      ...?metadata,
    });
  }

  /// Track user authentication events
  Future<void> trackAuthEvent({
    required String action, // 'login', 'logout', 'register', 'verify'
    String? method, // 'email', 'phone', 'social'
    bool success = true,
    String? errorCode,
  }) async {
    await trackEvent('auth_event', {
      'action': action,
      'method': method ?? 'email',
      'success': success,
      'error_code': errorCode,
    });
  }

  /// Track screen views
  Future<void> trackScreenView({
    required String screenName,
    String? screenClass,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_initialized || kDebugMode) return;
    
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? 'Flutter',
      );
      
      // Also track as custom event for additional context
      await trackEvent('screen_view', {
        'screen_name': screenName,
        'screen_class': screenClass ?? 'Flutter',
        ...?metadata,
      });
      
    } catch (error) {
      _logger.warning('Failed to track screen view: $screenName', error);
    }
  }

  /// Set user ID for analytics
  Future<void> setUserId(String userId) async {
    if (!_initialized || kDebugMode) return;
    
    try {
      await _analytics.setUserId(id: userId);
      _currentUserId = userId;
      
      _logger.info('Analytics user ID set: $userId');
      
    } catch (error) {
      _logger.warning('Failed to set user ID', error);
    }
  }

  /// Set user properties
  Future<void> setUserProperties(Map<String, String> properties) async {
    if (!_initialized || kDebugMode) return;
    
    try {
      for (final entry in properties.entries) {
        await _analytics.setUserProperty(
          name: _sanitizeParameterName(entry.key),
          value: entry.value,
        );
      }
      
      _logger.fine('User properties set: ${properties.keys}');
      
    } catch (error) {
      _logger.warning('Failed to set user properties', error);
    }
  }

  /// Reset analytics data (for logout)
  Future<void> resetAnalyticsData() async {
    if (!_initialized || kDebugMode) return;
    
    try {
      await _analytics.resetAnalyticsData();
      _currentUserId = null;
      
      _logger.info('Analytics data reset');
      
    } catch (error) {
      _logger.warning('Failed to reset analytics data', error);
    }
  }

  /// Sanitize event name for Firebase Analytics
  String _sanitizeEventName(String eventName) {
    // Firebase Analytics event names must be 40 characters or fewer
    // and can only contain letters, numbers, and underscores
    return eventName
        .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')
        .toLowerCase()
        .substring(0, eventName.length > 40 ? 40 : eventName.length);
  }

  /// Sanitize parameter name for Firebase Analytics
  String _sanitizeParameterName(String paramName) {
    // Parameter names must be 40 characters or fewer
    return paramName
        .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')
        .toLowerCase()
        .substring(0, paramName.length > 40 ? 40 : paramName.length);
  }

  /// Sanitize parameter value for Firebase Analytics
  Object? _sanitizeParameterValue(dynamic value) {
    if (value == null) return null;
    
    if (value is String) {
      // String values must be 100 characters or fewer
      return value.length > 100 ? value.substring(0, 100) : value;
    } else if (value is num) {
      return value;
    } else if (value is bool) {
      return value;
    } else {
      // Convert other types to string
      final stringValue = value.toString();
      return stringValue.length > 100 ? stringValue.substring(0, 100) : stringValue;
    }
  }

  /// Get analytics statistics
  Map<String, dynamic> getAnalyticsStats() {
    return {
      'session_start': _sessionStart?.toIso8601String(),
      'session_duration_minutes': _sessionStart != null 
          ? DateTime.now().difference(_sessionStart!).inMinutes 
          : 0,
      'events_tracked': _eventCounts.values.fold<int>(0, (sum, count) => sum + count),
      'unique_events': _eventCounts.length,
      'current_user_id': _currentUserId,
      'session_properties': Map<String, dynamic>.from(_sessionProperties),
      'top_events': _getTopEvents(),
    };
  }

  /// Get top events for debugging
  List<Map<String, dynamic>> _getTopEvents({int limit = 10}) {
    final sortedEvents = _eventCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedEvents.take(limit).map((entry) => {
      'event_name': entry.key,
      'count': entry.value,
    }).toList();
  }

  /// End current session and start new one
  void restartSession() {
    if (_sessionStart != null) {
      final sessionDuration = DateTime.now().difference(_sessionStart!);
      
      trackEvent('session_end', {
        'session_duration_minutes': sessionDuration.inMinutes,
        'events_in_session': _eventCounts.values.fold<int>(0, (sum, count) => sum + count),
      });
    }
    
    _sessionStart = DateTime.now();
    _eventCounts.clear();
    _sessionProperties.clear();
    
    trackEvent('session_start', {
      'platform': Platform.operatingSystem,
    });
  }

  /// Dispose of analytics service
  void dispose() {
    _sessionTimer?.cancel();
    
    // Track session end
    if (_sessionStart != null) {
      final sessionDuration = DateTime.now().difference(_sessionStart!);
      
      trackEvent('app_close', {
        'session_duration_minutes': sessionDuration.inMinutes,
        'total_events': _eventCounts.values.fold<int>(0, (sum, count) => sum + count),
      });
    }
    
    _eventCounts.clear();
    _sessionProperties.clear();
    _initialized = false;
    
    _logger.info('AnalyticsService disposed');
  }
}