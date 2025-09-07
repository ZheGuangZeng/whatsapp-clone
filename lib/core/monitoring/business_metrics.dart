import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'analytics_service.dart';
import 'alert_system.dart';

/// Business metrics and KPI tracking service
class BusinessMetrics {
  static final BusinessMetrics _instance = BusinessMetrics._internal();
  factory BusinessMetrics() => _instance;
  BusinessMetrics._internal();

  final Logger _logger = Logger('BusinessMetrics');
  
  bool _initialized = false;
  late final AnalyticsService _analyticsService;
  late final AlertSystem _alertSystem;
  
  // Session tracking
  DateTime? _sessionStart;
  final Map<String, int> _sessionMetrics = {};
  
  // User engagement tracking
  final Map<String, DateTime> _userLastActivity = {};
  final Map<String, int> _userEventCounts = {};
  
  // Messaging metrics
  int _messagesPerSession = 0;
  int _totalMessagesSent = 0;
  int _totalMessagesReceived = 0;
  int _totalMessagesRead = 0;
  
  // Meeting metrics
  int _meetingsStarted = 0;
  int _meetingsJoined = 0;
  final List<Duration> _meetingDurations = [];
  
  // Performance KPIs
  final List<Duration> _messageDeliveryTimes = [];
  final List<Duration> _appLoadTimes = [];
  
  // Feature usage metrics
  final Map<String, int> _featureUsage = {};
  
  // Retention metrics
  final Set<String> _dailyActiveUsers = {};
  final Set<String> _weeklyActiveUsers = {};
  final Set<String> _monthlyActiveUsers = {};
  
  // Revenue/monetization metrics (if applicable)
  final Map<String, double> _revenueMetrics = {};
  
  Timer? _metricsTimer;

  /// Initialize business metrics tracking
  Future<void> initialize({
    required AnalyticsService analyticsService,
    required AlertSystem alertSystem,
  }) async {
    if (_initialized) return;
    
    try {
      _analyticsService = analyticsService;
      _alertSystem = alertSystem;
      
      _sessionStart = DateTime.now();
      
      // Start periodic metrics reporting
      _startPeriodicReporting();
      
      _initialized = true;
      _logger.info('BusinessMetrics initialized successfully');
      
      // Track app launch
      await trackAppLaunch();
      
    } catch (error, stackTrace) {
      _logger.severe('Failed to initialize BusinessMetrics', error, stackTrace);
      rethrow;
    }
  }

  /// Track app launch and startup metrics
  Future<void> trackAppLaunch() async {
    if (!_initialized) return;
    
    try {
      final launchTime = DateTime.now().difference(_sessionStart!);
      _appLoadTimes.add(launchTime);
      
      await _analyticsService.trackEvent('app_launch', {
        'launch_time_ms': launchTime.inMilliseconds,
        'cold_start': _sessionMetrics.isEmpty,
      });
      
      await _analyticsService.trackBusinessMetric(
        metricName: 'app_launch_time',
        value: launchTime.inMilliseconds.toDouble(),
        unit: 'milliseconds',
      );
      
    } catch (error) {
      _logger.warning('Failed to track app launch', error);
    }
  }

  /// Track user login/authentication
  Future<void> trackUserLogin({
    required String userId,
    required String loginMethod,
    bool isNewUser = false,
  }) async {
    if (!_initialized) return;
    
    try {
      // Update user activity
      _userLastActivity[userId] = DateTime.now();
      _dailyActiveUsers.add(userId);
      _weeklyActiveUsers.add(userId);
      _monthlyActiveUsers.add(userId);
      
      await _analyticsService.trackAuthEvent(
        action: 'login',
        method: loginMethod,
        success: true,
      );
      
      // Track new vs returning user
      await _analyticsService.trackEvent(isNewUser ? 'new_user_signup' : 'user_login', {
        'user_id': userId,
        'login_method': loginMethod,
        'is_new_user': isNewUser,
      });
      
      // Track user acquisition if new user
      if (isNewUser) {
        await trackUserAcquisition(userId: userId, source: loginMethod);
      }
      
    } catch (error) {
      _logger.warning('Failed to track user login', error);
    }
  }

  /// Track user acquisition
  Future<void> trackUserAcquisition({
    required String userId,
    required String source,
    String? campaign,
    String? medium,
  }) async {
    if (!_initialized) return;
    
    try {
      await _analyticsService.trackEvent('user_acquisition', {
        'user_id': userId,
        'source': source,
        'campaign': campaign,
        'medium': medium,
      });
      
      await _analyticsService.trackBusinessMetric(
        metricName: 'new_users',
        value: 1,
        metadata: {
          'source': source,
          'campaign': campaign,
        },
      );
      
    } catch (error) {
      _logger.warning('Failed to track user acquisition', error);
    }
  }

  /// Track message sending
  Future<void> trackMessageSent({
    required String messageType,
    required String chatType,
    int? messageSize,
    Duration? deliveryTime,
  }) async {
    if (!_initialized) return;
    
    try {
      _messagesPerSession++;
      _totalMessagesSent++;
      
      if (deliveryTime != null) {
        _messageDeliveryTimes.add(deliveryTime);
      }
      
      await _analyticsService.trackMessageEvent(
        action: 'sent',
        messageType: messageType,
        chatType: chatType,
        metadata: {
          'message_size': messageSize,
          'delivery_time_ms': deliveryTime?.inMilliseconds,
          'session_message_count': _messagesPerSession,
        },
      );
      
      await _analyticsService.trackBusinessMetric(
        metricName: 'messages_sent',
        value: 1,
        metadata: {
          'message_type': messageType,
          'chat_type': chatType,
        },
      );
      
    } catch (error) {
      _logger.warning('Failed to track message sent', error);
    }
  }

  /// Track message receiving
  Future<void> trackMessageReceived({
    required String messageType,
    required String chatType,
    Duration? deliveryTime,
  }) async {
    if (!_initialized) return;
    
    try {
      _totalMessagesReceived++;
      
      await _analyticsService.trackMessageEvent(
        action: 'received',
        messageType: messageType,
        chatType: chatType,
        metadata: {
          'delivery_time_ms': deliveryTime?.inMilliseconds,
        },
      );
      
      await _analyticsService.trackBusinessMetric(
        metricName: 'messages_received',
        value: 1,
        metadata: {
          'message_type': messageType,
          'chat_type': chatType,
        },
      );
      
    } catch (error) {
      _logger.warning('Failed to track message received', error);
    }
  }

  /// Track message read
  Future<void> trackMessageRead({
    required String messageType,
    required Duration timeToRead,
  }) async {
    if (!_initialized) return;
    
    try {
      _totalMessagesRead++;
      
      await _analyticsService.trackMessageEvent(
        action: 'read',
        messageType: messageType,
        metadata: {
          'time_to_read_ms': timeToRead.inMilliseconds,
        },
      );
      
      await _analyticsService.trackBusinessMetric(
        metricName: 'messages_read',
        value: 1,
        metadata: {
          'message_type': messageType,
          'time_to_read_ms': timeToRead.inMilliseconds,
        },
      );
      
    } catch (error) {
      _logger.warning('Failed to track message read', error);
    }
  }

  /// Track meeting start
  Future<void> trackMeetingStart({
    required String meetingType,
    required int participantCount,
  }) async {
    if (!_initialized) return;
    
    try {
      _meetingsStarted++;
      
      await _analyticsService.trackMeetingEvent(
        action: 'started',
        participantCount: participantCount,
        meetingType: meetingType,
      );
      
      await _analyticsService.trackBusinessMetric(
        metricName: 'meetings_started',
        value: 1,
        metadata: {
          'meeting_type': meetingType,
          'participant_count': participantCount,
        },
      );
      
    } catch (error) {
      _logger.warning('Failed to track meeting start', error);
    }
  }

  /// Track meeting join
  Future<void> trackMeetingJoin({
    required String meetingType,
    required int participantCount,
  }) async {
    if (!_initialized) return;
    
    try {
      _meetingsJoined++;
      
      await _analyticsService.trackMeetingEvent(
        action: 'joined',
        participantCount: participantCount,
        meetingType: meetingType,
      );
      
      await _analyticsService.trackBusinessMetric(
        metricName: 'meetings_joined',
        value: 1,
        metadata: {
          'meeting_type': meetingType,
          'participant_count': participantCount,
        },
      );
      
    } catch (error) {
      _logger.warning('Failed to track meeting join', error);
    }
  }

  /// Track meeting end
  Future<void> trackMeetingEnd({
    required String meetingType,
    required Duration duration,
    required int participantCount,
  }) async {
    if (!_initialized) return;
    
    try {
      _meetingDurations.add(duration);
      
      await _analyticsService.trackMeetingEvent(
        action: 'ended',
        duration: duration,
        participantCount: participantCount,
        meetingType: meetingType,
      );
      
      await _analyticsService.trackBusinessMetric(
        metricName: 'meeting_duration',
        value: duration.inMinutes.toDouble(),
        unit: 'minutes',
        metadata: {
          'meeting_type': meetingType,
          'participant_count': participantCount,
        },
      );
      
    } catch (error) {
      _logger.warning('Failed to track meeting end', error);
    }
  }

  /// Track feature usage
  Future<void> trackFeatureUsage({
    required String featureName,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_initialized) return;
    
    try {
      _featureUsage[featureName] = (_featureUsage[featureName] ?? 0) + 1;
      
      await _analyticsService.trackEvent('feature_usage', {
        'feature_name': featureName,
        'usage_count': _featureUsage[featureName],
        ...?metadata,
      });
      
      await _analyticsService.trackBusinessMetric(
        metricName: 'feature_usage',
        value: 1,
        metadata: {
          'feature_name': featureName,
          ...?metadata,
        },
      );
      
    } catch (error) {
      _logger.warning('Failed to track feature usage', error);
    }
  }

  /// Track user engagement
  Future<void> trackUserEngagement({
    required String userId,
    required String engagementType,
    Duration? sessionDuration,
  }) async {
    if (!_initialized) return;
    
    try {
      _userLastActivity[userId] = DateTime.now();
      _userEventCounts[userId] = (_userEventCounts[userId] ?? 0) + 1;
      
      await _analyticsService.trackUserEngagement(
        feature: 'app',
        action: engagementType,
        metadata: {
          'user_id': userId,
          'session_duration_ms': sessionDuration?.inMilliseconds,
          'user_event_count': _userEventCounts[userId],
        },
      );
      
    } catch (error) {
      _logger.warning('Failed to track user engagement', error);
    }
  }

  /// Track app performance KPIs
  Future<void> trackPerformanceKPI({
    required String kpiName,
    required double value,
    String? unit,
  }) async {
    if (!_initialized) return;
    
    try {
      await _analyticsService.trackBusinessMetric(
        metricName: kpiName,
        value: value,
        unit: unit,
      );
      
      // Check if KPI exceeds thresholds and send alerts
      await _checkKPIThresholds(kpiName, value);
      
    } catch (error) {
      _logger.warning('Failed to track performance KPI', error);
    }
  }

  /// Get comprehensive business metrics report
  Map<String, dynamic> getBusinessReport() {
    final sessionDuration = _sessionStart != null 
        ? DateTime.now().difference(_sessionStart!)
        : Duration.zero;

    return {
      'session_metrics': {
        'session_duration_minutes': sessionDuration.inMinutes,
        'messages_per_session': _messagesPerSession,
        'session_start': _sessionStart?.toIso8601String(),
      },
      'messaging_metrics': {
        'total_messages_sent': _totalMessagesSent,
        'total_messages_received': _totalMessagesReceived,
        'total_messages_read': _totalMessagesRead,
        'message_read_rate': _totalMessagesSent > 0 
            ? (_totalMessagesRead / _totalMessagesSent * 100).toStringAsFixed(1) + '%'
            : '0%',
        'average_delivery_time_ms': _messageDeliveryTimes.isNotEmpty
            ? _messageDeliveryTimes.map((d) => d.inMilliseconds).reduce((a, b) => a + b) / _messageDeliveryTimes.length
            : 0,
      },
      'meeting_metrics': {
        'meetings_started': _meetingsStarted,
        'meetings_joined': _meetingsJoined,
        'average_meeting_duration_minutes': _meetingDurations.isNotEmpty
            ? _meetingDurations.map((d) => d.inMinutes).reduce((a, b) => a + b) / _meetingDurations.length
            : 0,
      },
      'user_engagement': {
        'daily_active_users': _dailyActiveUsers.length,
        'weekly_active_users': _weeklyActiveUsers.length,
        'monthly_active_users': _monthlyActiveUsers.length,
        'active_user_count': _userLastActivity.length,
      },
      'feature_usage': Map<String, dynamic>.from(_featureUsage),
      'performance_kpis': {
        'average_app_load_time_ms': _appLoadTimes.isNotEmpty
            ? _appLoadTimes.map((d) => d.inMilliseconds).reduce((a, b) => a + b) / _appLoadTimes.length
            : 0,
      },
      'revenue_metrics': Map<String, dynamic>.from(_revenueMetrics),
    };
  }

  /// Get key performance indicators summary
  Map<String, dynamic> getKPISummary() {
    final report = getBusinessReport();
    
    return {
      'user_engagement': {
        'dau': report['user_engagement']['daily_active_users'],
        'wau': report['user_engagement']['weekly_active_users'],
        'mau': report['user_engagement']['monthly_active_users'],
      },
      'messaging_kpis': {
        'messages_sent': _totalMessagesSent,
        'message_delivery_time_p95': _getPercentile(_messageDeliveryTimes.map((d) => d.inMilliseconds.toDouble()).toList(), 0.95),
        'message_read_rate': report['messaging_metrics']['message_read_rate'],
      },
      'meeting_kpis': {
        'meetings_started': _meetingsStarted,
        'average_meeting_duration': report['meeting_metrics']['average_meeting_duration_minutes'],
      },
      'performance_kpis': {
        'app_load_time_p95': _getPercentile(_appLoadTimes.map((d) => d.inMilliseconds.toDouble()).toList(), 0.95),
      },
    };
  }

  /// Start periodic metrics reporting
  void _startPeriodicReporting() {
    _metricsTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      _reportPeriodicMetrics();
    });
  }

  /// Report periodic business metrics
  Future<void> _reportPeriodicMetrics() async {
    try {
      final report = getBusinessReport();
      
      // Report session metrics
      await _analyticsService.trackEvent('periodic_business_metrics', report);
      
      // Check for any threshold violations
      await _checkBusinessMetricThresholds(report);
      
    } catch (error) {
      _logger.warning('Failed to report periodic metrics', error);
    }
  }

  /// Check KPI thresholds and send alerts
  Future<void> _checkKPIThresholds(String kpiName, double value) async {
    // Define thresholds for different KPIs
    final thresholds = {
      'app_launch_time': 3000.0, // 3 seconds
      'message_delivery_time': 5000.0, // 5 seconds
      'memory_usage': 200.0, // 200 MB
      'error_rate': 5.0, // 5% error rate
    };
    
    final threshold = thresholds[kpiName];
    if (threshold != null && value > threshold) {
      await _alertSystem.sendPerformanceAlert(
        metric: kpiName,
        value: value,
        threshold: threshold,
        metadata: {'timestamp': DateTime.now().toIso8601String()},
      );
    }
  }

  /// Check business metric thresholds
  Future<void> _checkBusinessMetricThresholds(Map<String, dynamic> report) async {
    // Example: Alert if DAU drops significantly
    final dau = report['user_engagement']['daily_active_users'] as int;
    if (dau < 10) { // Threshold for low DAU
      await _alertSystem.sendWarningAlert(
        title: 'Low Daily Active Users',
        message: 'Daily active users have dropped to $dau',
        metadata: report,
      );
    }
  }

  /// Calculate percentile from list of values
  double _getPercentile(List<double> values, double percentile) {
    if (values.isEmpty) return 0;
    
    final sortedValues = List<double>.from(values)..sort();
    final index = (sortedValues.length * percentile).ceil() - 1;
    return sortedValues[math.max(0, math.min(index, sortedValues.length - 1))];
  }

  /// Reset daily metrics (called at midnight)
  void resetDailyMetrics() {
    _dailyActiveUsers.clear();
    _logger.info('Daily metrics reset');
  }

  /// Reset weekly metrics (called weekly)
  void resetWeeklyMetrics() {
    _weeklyActiveUsers.clear();
    _logger.info('Weekly metrics reset');
  }

  /// Reset monthly metrics (called monthly)
  void resetMonthlyMetrics() {
    _monthlyActiveUsers.clear();
    _logger.info('Monthly metrics reset');
  }

  /// Dispose of business metrics
  void dispose() {
    _metricsTimer?.cancel();
    
    // Clear all metrics
    _sessionMetrics.clear();
    _userLastActivity.clear();
    _userEventCounts.clear();
    _featureUsage.clear();
    _messageDeliveryTimes.clear();
    _appLoadTimes.clear();
    _meetingDurations.clear();
    _dailyActiveUsers.clear();
    _weeklyActiveUsers.clear();
    _monthlyActiveUsers.clear();
    _revenueMetrics.clear();
    
    _initialized = false;
    _logger.info('BusinessMetrics disposed');
  }
}