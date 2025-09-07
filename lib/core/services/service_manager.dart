import 'dart:async';
import 'dart:developer' as developer;

import 'package:livekit_client/livekit_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'real_livekit_meeting_service.dart';
import 'real_supabase_auth_service.dart';
import 'real_supabase_message_service.dart';

/// Centralized service manager for handling service lifecycle and connection pooling
/// Provides singleton access to all real service adapters with proper resource management
class ServiceManager {
  static const String _logTag = 'ServiceManager';
  
  static ServiceManager? _instance;
  static final Completer<ServiceManager> _instanceCompleter = Completer<ServiceManager>();
  
  late final RealSupabaseAuthService _authService;
  late final RealSupabaseMessageService _messageService;
  late final RealLiveKitMeetingService _meetingService;
  
  bool _isInitialized = false;
  Timer? _healthCheckTimer;
  
  /// Private constructor
  ServiceManager._();
  
  /// Get singleton instance
  static Future<ServiceManager> get instance async {
    if (_instance != null) {
      return _instance!;
    }
    
    if (!_instanceCompleter.isCompleted) {
      _instance = ServiceManager._();
      _instanceCompleter.complete(_instance!);
    }
    
    return _instanceCompleter.future;
  }
  
  /// Initialize all services
  Future<void> initialize({
    required String liveKitUrl,
    SupabaseClient? supabaseClient,
  }) async {
    if (_isInitialized) {
      developer.log('ServiceManager already initialized', name: _logTag);
      return;
    }
    
    try {
      developer.log('Initializing ServiceManager', name: _logTag);
      
      final client = supabaseClient ?? Supabase.instance.client;
      
      // Initialize services
      _authService = RealSupabaseAuthService(client: client);
      _messageService = RealSupabaseMessageService(client: client);
      _meetingService = RealLiveKitMeetingService(
        supabaseClient: client,
        liveKitUrl: liveKitUrl,
      );
      
      // Start health monitoring
      _startHealthMonitoring();
      
      _isInitialized = true;
      developer.log('ServiceManager initialized successfully', name: _logTag);
      
    } catch (error) {
      developer.log('Failed to initialize ServiceManager: $error', name: _logTag, level: 1000);
      rethrow;
    }
  }
  
  /// Get auth service instance
  RealSupabaseAuthService get authService {
    _ensureInitialized();
    return _authService;
  }
  
  /// Get message service instance
  RealSupabaseMessageService get messageService {
    _ensureInitialized();
    return _messageService;
  }
  
  /// Get meeting service instance
  RealLiveKitMeetingService get meetingService {
    _ensureInitialized();
    return _meetingService;
  }
  
  /// Check if services are healthy
  Future<Map<String, bool>> checkServicesHealth() async {
    _ensureInitialized();
    
    final healthStatus = <String, bool>{};
    
    try {
      // Check auth service
      final authResult = await _authService.getCurrentSession();
      healthStatus['auth'] = authResult.isSuccess;
      
      // Check Supabase connection (via message service)
      healthStatus['supabase'] = Supabase.instance.client.auth.currentSession != null ||
                                 Supabase.instance.client.realtime.isConnected;
      
      // Check LiveKit service
      healthStatus['livekit'] = _meetingService.connectionState != ConnectionState.disconnected;
      
    } catch (error) {
      developer.log('Health check failed: $error', name: _logTag, level: 1000);
      healthStatus.forEach((key, value) => healthStatus[key] = false);
    }
    
    return healthStatus;
  }
  
  /// Reconnect services if needed
  Future<void> reconnectServices() async {
    _ensureInitialized();
    developer.log('Attempting to reconnect services', name: _logTag);
    
    try {
      // Check and reconnect Supabase if needed
      if (!Supabase.instance.client.realtime.isConnected) {
        await Supabase.instance.client.realtime.connect();
        developer.log('Reconnected to Supabase Realtime', name: _logTag);
      }
      
      // LiveKit reconnection is handled automatically by the client
      
    } catch (error) {
      developer.log('Failed to reconnect services: $error', name: _logTag, level: 1000);
    }
  }
  
  /// Start periodic health monitoring
  void _startHealthMonitoring() {
    _healthCheckTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) async {
        final health = await checkServicesHealth();
        final unhealthyServices = health.entries
            .where((entry) => !entry.value)
            .map((entry) => entry.key)
            .toList();
        
        if (unhealthyServices.isNotEmpty) {
          developer.log(
            'Unhealthy services detected: ${unhealthyServices.join(', ')}',
            name: _logTag,
            level: 900,
          );
          
          // Attempt reconnection
          await reconnectServices();
        }
      },
    );
  }
  
  /// Ensure services are initialized
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw Exception('ServiceManager not initialized. Call initialize() first.');
    }
  }
  
  /// Dispose all services and resources
  Future<void> dispose() async {
    developer.log('Disposing ServiceManager', name: _logTag);
    
    try {
      // Stop health monitoring
      _healthCheckTimer?.cancel();
      _healthCheckTimer = null;
      
      // Dispose services
      if (_isInitialized) {
        _authService.dispose();
        _messageService.dispose();
        _meetingService.dispose();
      }
      
      _isInitialized = false;
      developer.log('ServiceManager disposed successfully', name: _logTag);
      
    } catch (error) {
      developer.log('Error disposing ServiceManager: $error', name: _logTag, level: 1000);
    }
  }
}

/// Service configuration options
class ServiceConfig {
  const ServiceConfig({
    required this.liveKitUrl,
    this.healthCheckInterval = const Duration(minutes: 1),
    this.retryAttempts = 3,
    this.retryDelay = const Duration(milliseconds: 500),
  });
  
  final String liveKitUrl;
  final Duration healthCheckInterval;
  final int retryAttempts;
  final Duration retryDelay;
}

/// Service health status
class ServiceHealth {
  const ServiceHealth({
    required this.isHealthy,
    required this.lastChecked,
    this.error,
  });
  
  final bool isHealthy;
  final DateTime lastChecked;
  final String? error;
}

/// Connection pool status for monitoring
class ConnectionPoolStatus {
  const ConnectionPoolStatus({
    required this.activeConnections,
    required this.availableConnections,
    required this.totalConnections,
    required this.lastActivity,
  });
  
  final int activeConnections;
  final int availableConnections;
  final int totalConnections;
  final DateTime lastActivity;
}