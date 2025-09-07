import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import '../config/environment_config.dart';

/// Comprehensive alerting system for production monitoring
class AlertSystem {
  static final AlertSystem _instance = AlertSystem._internal();
  factory AlertSystem() => _instance;
  AlertSystem._internal();

  final Logger _logger = Logger('AlertSystem');
  
  bool _initialized = false;
  final Map<String, DateTime> _lastAlertTimes = {};
  final Duration _alertCooldown = const Duration(minutes: 5);
  
  late final AlertConfig _config;
  Timer? _healthCheckTimer;

  /// Initialize the alert system
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      _config = AlertConfig.fromEnvironment();
      
      // Start periodic health checks
      _startHealthChecks();
      
      _initialized = true;
      _logger.info('AlertSystem initialized successfully');
      
    } catch (error, stackTrace) {
      _logger.severe('Failed to initialize AlertSystem', error, stackTrace);
      rethrow;
    }
  }

  /// Send critical alert
  Future<void> sendCriticalAlert({
    required String title,
    required String message,
    Map<String, dynamic>? metadata,
  }) async {
    await _sendAlert(
      AlertLevel.critical,
      title: title,
      message: message,
      metadata: metadata,
    );
  }

  /// Send warning alert
  Future<void> sendWarningAlert({
    required String title,
    required String message,
    Map<String, dynamic>? metadata,
  }) async {
    await _sendAlert(
      AlertLevel.warning,
      title: title,
      message: message,
      metadata: metadata,
    );
  }

  /// Send info alert
  Future<void> sendInfoAlert({
    required String title,
    required String message,
    Map<String, dynamic>? metadata,
  }) async {
    await _sendAlert(
      AlertLevel.info,
      title: title,
      message: message,
      metadata: metadata,
    );
  }

  /// Send application crash alert
  Future<void> sendCrashAlert({
    required String error,
    required String stackTrace,
    Map<String, dynamic>? metadata,
  }) async {
    await _sendAlert(
      AlertLevel.critical,
      title: 'Application Crash Detected',
      message: 'Error: $error\n\nStack Trace:\n$stackTrace',
      metadata: {
        'alert_type': 'crash',
        'error_type': error.runtimeType.toString(),
        ...?metadata,
      },
    );
  }

  /// Send performance degradation alert
  Future<void> sendPerformanceAlert({
    required String metric,
    required double value,
    required double threshold,
    Map<String, dynamic>? metadata,
  }) async {
    await _sendAlert(
      AlertLevel.warning,
      title: 'Performance Degradation Detected',
      message: 'Metric: $metric\nCurrent Value: $value\nThreshold: $threshold',
      metadata: {
        'alert_type': 'performance',
        'metric': metric,
        'value': value,
        'threshold': threshold,
        ...?metadata,
      },
    );
  }

  /// Send high error rate alert
  Future<void> sendErrorRateAlert({
    required int errorCount,
    required Duration timeWindow,
    Map<String, dynamic>? metadata,
  }) async {
    final errorRate = errorCount / timeWindow.inMinutes;
    
    await _sendAlert(
      AlertLevel.warning,
      title: 'High Error Rate Detected',
      message: 'Error Rate: ${errorRate.toStringAsFixed(2)} errors/minute\nCount: $errorCount in ${timeWindow.inMinutes} minutes',
      metadata: {
        'alert_type': 'error_rate',
        'error_count': errorCount,
        'time_window_minutes': timeWindow.inMinutes,
        'error_rate': errorRate,
        ...?metadata,
      },
    );
  }

  /// Send low memory alert
  Future<void> sendLowMemoryAlert({
    required double currentMemoryMB,
    required double availableMemoryMB,
    Map<String, dynamic>? metadata,
  }) async {
    final memoryUsagePercent = (currentMemoryMB / (currentMemoryMB + availableMemoryMB)) * 100;
    
    await _sendAlert(
      AlertLevel.warning,
      title: 'Low Memory Warning',
      message: 'Memory Usage: ${memoryUsagePercent.toStringAsFixed(1)}%\nCurrent: ${currentMemoryMB.toStringAsFixed(1)} MB\nAvailable: ${availableMemoryMB.toStringAsFixed(1)} MB',
      metadata: {
        'alert_type': 'memory',
        'memory_usage_mb': currentMemoryMB,
        'available_memory_mb': availableMemoryMB,
        'memory_usage_percent': memoryUsagePercent,
        ...?metadata,
      },
    );
  }

  /// Send service health alert
  Future<void> sendServiceHealthAlert({
    required String serviceName,
    required bool isHealthy,
    String? details,
    Map<String, dynamic>? metadata,
  }) async {
    await _sendAlert(
      isHealthy ? AlertLevel.info : AlertLevel.critical,
      title: 'Service Health Alert',
      message: 'Service: $serviceName\nStatus: ${isHealthy ? 'Healthy' : 'Unhealthy'}\n${details ?? ''}',
      metadata: {
        'alert_type': 'service_health',
        'service_name': serviceName,
        'is_healthy': isHealthy,
        'details': details,
        ...?metadata,
      },
    );
  }

  /// Internal alert sending method
  Future<void> _sendAlert(
    AlertLevel level,
    {
      required String title,
      required String message,
      Map<String, dynamic>? metadata,
    }
  ) async {
    if (!_initialized) {
      _logger.warning('AlertSystem not initialized, skipping alert');
      return;
    }

    // Check cooldown to prevent spam
    final alertKey = '${level.name}_$title';
    final lastAlertTime = _lastAlertTimes[alertKey];
    final now = DateTime.now();
    
    if (lastAlertTime != null && now.difference(lastAlertTime) < _alertCooldown) {
      _logger.fine('Alert cooldown active for: $alertKey');
      return;
    }

    try {
      final alert = Alert(
        level: level,
        title: title,
        message: message,
        timestamp: now,
        environment: EnvironmentConfig.currentEnvironment,
        metadata: metadata ?? {},
      );

      // Send to configured channels
      final futures = <Future<void>>[];

      if (_config.emailEnabled) {
        futures.add(_sendEmailAlert(alert));
      }

      if (_config.slackEnabled) {
        futures.add(_sendSlackAlert(alert));
      }

      if (_config.webhookEnabled) {
        futures.add(_sendWebhookAlert(alert));
      }

      // Send notifications concurrently
      await Future.wait(futures);

      // Update last alert time
      _lastAlertTimes[alertKey] = now;

      _logger.info('Alert sent: $title [${level.name}]');

    } catch (error, stackTrace) {
      _logger.severe('Failed to send alert', error, stackTrace);
    }
  }

  /// Send email alert
  Future<void> _sendEmailAlert(Alert alert) async {
    if (!_config.emailEnabled) return;

    try {
      final response = await http.post(
        Uri.parse(_config.emailWebhookUrl!),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_config.emailApiKey}',
        },
        body: json.encode({
          'to': _config.emailRecipients,
          'subject': '[${alert.level.name.toUpperCase()}] ${alert.title}',
          'html': _generateEmailHtml(alert),
          'text': _generateEmailText(alert),
        }),
      );

      if (response.statusCode != 200) {
        throw HttpException('Email API returned ${response.statusCode}: ${response.body}');
      }

      _logger.fine('Email alert sent successfully');

    } catch (error) {
      _logger.warning('Failed to send email alert', error);
    }
  }

  /// Send Slack alert
  Future<void> _sendSlackAlert(Alert alert) async {
    if (!_config.slackEnabled) return;

    try {
      final color = _getSlackColor(alert.level);
      
      final payload = {
        'channel': _config.slackChannel,
        'username': 'WhatsApp Clone Monitor',
        'icon_emoji': ':warning:',
        'attachments': [
          {
            'color': color,
            'title': alert.title,
            'text': alert.message,
            'fields': [
              {
                'title': 'Environment',
                'value': alert.environment.name,
                'short': true,
              },
              {
                'title': 'Level',
                'value': alert.level.name.toUpperCase(),
                'short': true,
              },
              {
                'title': 'Timestamp',
                'value': alert.timestamp.toIso8601String(),
                'short': true,
              },
              ...alert.metadata.entries.map((entry) => {
                'title': entry.key.replaceAll('_', ' ').toUpperCase(),
                'value': entry.value.toString(),
                'short': true,
              }).toList(),
            ],
            'footer': 'WhatsApp Clone Monitoring',
            'ts': alert.timestamp.millisecondsSinceEpoch ~/ 1000,
          }
        ],
      };

      final response = await http.post(
        Uri.parse(_config.slackWebhookUrl!),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      if (response.statusCode != 200) {
        throw HttpException('Slack webhook returned ${response.statusCode}: ${response.body}');
      }

      _logger.fine('Slack alert sent successfully');

    } catch (error) {
      _logger.warning('Failed to send Slack alert', error);
    }
  }

  /// Send webhook alert
  Future<void> _sendWebhookAlert(Alert alert) async {
    if (!_config.webhookEnabled) return;

    try {
      final payload = {
        'alert': {
          'level': alert.level.name,
          'title': alert.title,
          'message': alert.message,
          'timestamp': alert.timestamp.toIso8601String(),
          'environment': alert.environment.name,
          'metadata': alert.metadata,
        },
      };

      final response = await http.post(
        Uri.parse(_config.webhookUrl!),
        headers: {
          'Content-Type': 'application/json',
          if (_config.webhookSecret != null)
            'X-Webhook-Secret': _config.webhookSecret!,
        },
        body: json.encode(payload),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('Webhook returned ${response.statusCode}: ${response.body}');
      }

      _logger.fine('Webhook alert sent successfully');

    } catch (error) {
      _logger.warning('Failed to send webhook alert', error);
    }
  }

  /// Generate HTML email content
  String _generateEmailHtml(Alert alert) {
    final colorMap = {
      AlertLevel.critical: '#FF4444',
      AlertLevel.warning: '#FF8800',
      AlertLevel.info: '#0088FF',
    };

    final color = colorMap[alert.level] ?? '#666666';

    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; }
        .container { max-width: 600px; margin: 0 auto; background: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { background: $color; color: white; padding: 20px; }
        .content { padding: 20px; }
        .metadata { background: #f8f9fa; padding: 15px; border-radius: 4px; margin-top: 20px; }
        .metadata-item { margin: 5px 0; }
        .footer { background: #f8f9fa; padding: 15px; text-align: center; color: #666; font-size: 12px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>${alert.title}</h1>
          <p>Level: ${alert.level.name.toUpperCase()}</p>
        </div>
        <div class="content">
          <p><strong>Message:</strong></p>
          <p>${alert.message.replaceAll('\n', '<br>')}</p>
          
          <div class="metadata">
            <h3>Additional Information</h3>
            <div class="metadata-item"><strong>Environment:</strong> ${alert.environment.name}</div>
            <div class="metadata-item"><strong>Timestamp:</strong> ${alert.timestamp}</div>
            ${alert.metadata.entries.map((entry) => 
              '<div class="metadata-item"><strong>${entry.key.replaceAll('_', ' ')}:</strong> ${entry.value}</div>'
            ).join('')}
          </div>
        </div>
        <div class="footer">
          <p>WhatsApp Clone Monitoring System</p>
        </div>
      </div>
    </body>
    </html>
    ''';
  }

  /// Generate plain text email content
  String _generateEmailText(Alert alert) {
    final buffer = StringBuffer();
    buffer.writeln('${alert.title}');
    buffer.writeln('Level: ${alert.level.name.toUpperCase()}');
    buffer.writeln('');
    buffer.writeln('Message:');
    buffer.writeln(alert.message);
    buffer.writeln('');
    buffer.writeln('Environment: ${alert.environment.name}');
    buffer.writeln('Timestamp: ${alert.timestamp}');
    
    if (alert.metadata.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('Additional Information:');
      for (final entry in alert.metadata.entries) {
        buffer.writeln('${entry.key.replaceAll('_', ' ')}: ${entry.value}');
      }
    }
    
    buffer.writeln('');
    buffer.writeln('--');
    buffer.writeln('WhatsApp Clone Monitoring System');
    
    return buffer.toString();
  }

  /// Get Slack color for alert level
  String _getSlackColor(AlertLevel level) {
    switch (level) {
      case AlertLevel.critical:
        return 'danger';
      case AlertLevel.warning:
        return 'warning';
      case AlertLevel.info:
        return 'good';
    }
  }

  /// Start periodic health checks
  void _startHealthChecks() {
    _healthCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _performHealthChecks();
    });
  }

  /// Perform health checks and send alerts if needed
  void _performHealthChecks() {
    // TODO: Add health check implementations
    // This would typically check:
    // - Database connectivity
    // - External service availability  
    // - Memory usage thresholds
    // - Error rate thresholds
    // - Response time thresholds
  }

  /// Test alert system with a sample alert
  Future<void> testAlert() async {
    await sendInfoAlert(
      title: 'Alert System Test',
      message: 'This is a test alert to verify the alert system is working correctly.',
      metadata: {
        'test': true,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Dispose of alert system
  void dispose() {
    _healthCheckTimer?.cancel();
    _lastAlertTimes.clear();
    _initialized = false;
    _logger.info('AlertSystem disposed');
  }
}

/// Alert configuration
class AlertConfig {
  final bool emailEnabled;
  final String? emailWebhookUrl;
  final String? emailApiKey;
  final List<String>? emailRecipients;
  
  final bool slackEnabled;
  final String? slackWebhookUrl;
  final String? slackChannel;
  
  final bool webhookEnabled;
  final String? webhookUrl;
  final String? webhookSecret;

  const AlertConfig({
    required this.emailEnabled,
    this.emailWebhookUrl,
    this.emailApiKey,
    this.emailRecipients,
    required this.slackEnabled,
    this.slackWebhookUrl,
    this.slackChannel,
    required this.webhookEnabled,
    this.webhookUrl,
    this.webhookSecret,
  });

  factory AlertConfig.fromEnvironment() {
    // In a real implementation, these would come from environment variables
    // For now, using placeholder values
    return AlertConfig(
      emailEnabled: !kDebugMode,
      emailWebhookUrl: EnvironmentConfig.isProduction ? 'https://api.sendgrid.com/v3/mail/send' : null,
      emailApiKey: EnvironmentConfig.isProduction ? 'your-sendgrid-api-key' : null,
      emailRecipients: EnvironmentConfig.isProduction ? ['alerts@yourcompany.com'] : null,
      
      slackEnabled: !kDebugMode,
      slackWebhookUrl: EnvironmentConfig.isProduction ? 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK' : null,
      slackChannel: EnvironmentConfig.isProduction ? '#alerts' : null,
      
      webhookEnabled: !kDebugMode,
      webhookUrl: EnvironmentConfig.isProduction ? 'https://your-monitoring-service.com/webhook' : null,
      webhookSecret: EnvironmentConfig.isProduction ? 'your-webhook-secret' : null,
    );
  }
}

/// Alert levels
enum AlertLevel {
  critical,
  warning,
  info,
}

/// Alert data class
class Alert {
  final AlertLevel level;
  final String title;
  final String message;
  final DateTime timestamp;
  final Environment environment;
  final Map<String, dynamic> metadata;

  const Alert({
    required this.level,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.environment,
    required this.metadata,
  });

  @override
  String toString() {
    return 'Alert(level: $level, title: $title, timestamp: $timestamp)';
  }
}