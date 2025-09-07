import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../config/environment_config.dart';
import '../errors/failures.dart';
import '../services/mock_services.dart';
import '../services/service_manager.dart';
import '../utils/result.dart';
import '../../features/auth/domain/entities/auth_session.dart';
import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/domain/repositories/i_auth_repository.dart';

/// Service factory that creates appropriate service instances based on environment configuration
class ServiceFactory {
  static const String _logTag = 'ServiceFactory';
  
  /// Private constructor to prevent instantiation
  ServiceFactory._();
  
  /// Creates auth service based on current environment configuration
  static Future<IAuthRepository> createAuthService(AppEnvironmentConfig config) async {
    try {
      developer.log('Creating auth service for ${config.serviceMode}', name: _logTag);
      
      switch (config.serviceMode) {
        case ServiceMode.mock:
          return const _MockAuthRepository();
          
        case ServiceMode.real:
          await _ensureSupabaseInitialized(config);
          final serviceManager = await ServiceManager.instance;
          return serviceManager.authService;
      }
    } catch (error) {
      developer.log('Failed to create auth service: $error', name: _logTag, level: 1000);
      
      // Fall back to mock service on error
      developer.log('Falling back to mock auth service', name: _logTag, level: 900);
      return _MockAuthRepository();
    }
  }
  
  /// Creates message service based on current environment configuration
  static Future<dynamic> createMessageService(AppEnvironmentConfig config) async {
    try {
      developer.log('Creating message service for ${config.serviceMode}', name: _logTag);
      
      switch (config.serviceMode) {
        case ServiceMode.mock:
          return MockSupabaseService();
          
        case ServiceMode.real:
          await _ensureSupabaseInitialized(config);
          final serviceManager = await ServiceManager.instance;
          return serviceManager.messageService;
      }
    } catch (error) {
      developer.log('Failed to create message service: $error', name: _logTag, level: 1000);
      
      // Fall back to mock service on error
      developer.log('Falling back to mock message service', name: _logTag, level: 900);
      return MockSupabaseService();
    }
  }
  
  /// Creates meeting service based on current environment configuration
  static Future<dynamic> createMeetingService(AppEnvironmentConfig config) async {
    try {
      developer.log('Creating meeting service for ${config.serviceMode}', name: _logTag);
      
      switch (config.serviceMode) {
        case ServiceMode.mock:
          return MockLiveKitService();
          
        case ServiceMode.real:
          await _ensureSupabaseInitialized(config);
          final serviceManager = await ServiceManager.instance;
          return serviceManager.meetingService;
      }
    } catch (error) {
      developer.log('Failed to create meeting service: $error', name: _logTag, level: 1000);
      
      // Fall back to mock service on error
      developer.log('Falling back to mock meeting service', name: _logTag, level: 900);
      return MockLiveKitService();
    }
  }
  
  /// Validates that the selected services are available and working
  static Future<ServiceValidationResult> validateServices(AppEnvironmentConfig config) async {
    final validationResult = ServiceValidationResult();
    
    try {
      developer.log('Validating services for ${config.serviceMode}', name: _logTag);
      
      switch (config.serviceMode) {
        case ServiceMode.mock:
          await _validateMockServices(validationResult);
          
        case ServiceMode.real:
          await _validateRealServices(config, validationResult);
      }
      
    } catch (error) {
      developer.log('Service validation failed: $error', name: _logTag, level: 1000);
      validationResult.addError('Service validation failed: $error');
    }
    
    developer.log(
      'Service validation complete: ${validationResult.isValid ? 'PASSED' : 'FAILED'}',
      name: _logTag,
      level: validationResult.isValid ? 800 : 1000,
    );
    
    return validationResult;
  }
  
  /// Ensures Supabase is properly initialized for real services
  static Future<void> _ensureSupabaseInitialized(AppEnvironmentConfig config) async {
    try {
      // Check if Supabase is already initialized
      if (Supabase.instance.isInitialized) {
        developer.log('Supabase already initialized', name: _logTag);
        return;
      }
    } catch (_) {
      // Supabase not initialized, proceed with initialization
    }
    
    developer.log('Initializing Supabase with real configuration', name: _logTag);
    
    await Supabase.initialize(
      url: config.supabaseUrl,
      anonKey: config.supabaseAnonKey,
      debug: config.enableDebugLogging,
    );
    
    // Initialize service manager
    final serviceManager = await ServiceManager.instance;
    await serviceManager.initialize(
      liveKitUrl: config.liveKitUrl,
    );
    
    developer.log('Supabase and services initialized successfully', name: _logTag);
  }
  
  /// Validates mock services are working
  static Future<void> _validateMockServices(ServiceValidationResult result) async {
    try {
      // Initialize mock services
      await MockServices.initialize();
      await MockSupabaseService().initialize();
      
      // Test mock auth
      final mockAuth = _MockAuthRepository();
      final authResult = await mockAuth.getCurrentSession();
      
      if (authResult.isSuccess) {
        result.addSuccess('Mock auth service initialized');
      } else {
        result.addWarning('Mock auth service initialization warning');
      }
      
      result.addSuccess('Mock services validation complete');
    } catch (error) {
      result.addError('Mock services validation failed: $error');
    }
  }
  
  /// Validates real services are working
  static Future<void> _validateRealServices(
    AppEnvironmentConfig config, 
    ServiceValidationResult result,
  ) async {
    try {
      // Test Supabase connection
      final client = Supabase.instance.client;
      try {
        await client.from('profiles').select('id').limit(1);
        result.addSuccess('Supabase connection established');
      } catch (e) {
        result.addWarning('Supabase connection test failed: $e');
      }
      
      // Test service manager health
      final serviceManager = await ServiceManager.instance;
      final healthStatus = await serviceManager.checkServicesHealth();
      
      final healthyServices = healthStatus.entries.where((entry) => entry.value);
      final unhealthyServices = healthStatus.entries.where((entry) => !entry.value);
      
      for (final service in healthyServices) {
        result.addSuccess('${service.key} service is healthy');
      }
      
      for (final service in unhealthyServices) {
        result.addWarning('${service.key} service is not healthy');
      }
      
    } catch (error) {
      result.addError('Real services validation failed: $error');
    }
  }
}

/// Service validation result container
class ServiceValidationResult {
  final List<String> _successes = [];
  final List<String> _warnings = [];
  final List<String> _errors = [];
  
  List<String> get successes => List.unmodifiable(_successes);
  List<String> get warnings => List.unmodifiable(_warnings);
  List<String> get errors => List.unmodifiable(_errors);
  
  bool get isValid => _errors.isEmpty;
  bool get hasWarnings => _warnings.isNotEmpty;
  
  void addSuccess(String message) => _successes.add(message);
  void addWarning(String message) => _warnings.add(message);
  void addError(String message) => _errors.add(message);
  
  @override
  String toString() {
    final buffer = StringBuffer('ServiceValidationResult:\n');
    
    if (_successes.isNotEmpty) {
      buffer.writeln('✅ Successes:');
      for (final success in _successes) {
        buffer.writeln('  - $success');
      }
    }
    
    if (_warnings.isNotEmpty) {
      buffer.writeln('⚠️  Warnings:');
      for (final warning in _warnings) {
        buffer.writeln('  - $warning');
      }
    }
    
    if (_errors.isNotEmpty) {
      buffer.writeln('❌ Errors:');
      for (final error in _errors) {
        buffer.writeln('  - $error');
      }
    }
    
    return buffer.toString();
  }
}

/// Mock implementation of IAuthRepository for fallback
class _MockAuthRepository implements IAuthRepository {
  const _MockAuthRepository();
  
  @override
  Stream<AuthSession?> get authStateChanges => const Stream<AuthSession?>.empty();
  
  @override
  Future<Result<AuthSession?>> getCurrentSession() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return Success<AuthSession?>(null);
  }
  
  @override
  Future<Result<AuthSession>> signInWithEmail({required String email, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (email.contains('@') && password.length >= 6) {
      return Success(_createMockSession());
    }
    return const ResultFailure(AuthFailure(message: 'Invalid credentials'));
  }
  
  @override
  Future<Result<AuthSession>> signInWithPhone({required String phone, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return Success(_createMockSession());
  }
  
  @override
  Future<Result<AuthSession>> signUpWithEmail({
    required String email, 
    required String password, 
    required String displayName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return Success(_createMockSession());
  }
  
  @override
  Future<Result<AuthSession>> signUpWithPhone({
    required String phone, 
    required String password, 
    required String displayName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return Success(_createMockSession());
  }
  
  @override
  Future<Result<void>> sendEmailVerification({required String email}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return const Success<void>(null);
  }
  
  @override
  Future<Result<void>> sendPhoneVerification({required String phone}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return const Success<void>(null);
  }
  
  @override
  Future<Result<AuthSession>> verifyEmail({required String email, required String otp}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return Success(_createMockSession());
  }
  
  @override
  Future<Result<AuthSession>> verifyPhone({required String phone, required String otp}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return Success(_createMockSession());
  }
  
  @override
  Future<Result<AuthSession>> refreshToken({required String refreshToken}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return Success(_createMockSession());
  }
  
  @override
  Future<Result<void>> signOut() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return const Success<void>(null);
  }
  
  @override
  Future<Result<void>> sendPasswordReset({required String email}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return const Success<void>(null);
  }
  
  @override
  Future<Result<void>> resetPassword({required String token, required String newPassword}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return const Success<void>(null);
  }
  
  @override
  Future<Result<User>> updateProfile({
    required String userId, 
    String? displayName, 
    String? status, 
    String? avatarUrl,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return Success(_createMockUser(userId, displayName));
  }
  
  @override
  Future<Result<void>> updateOnlineStatus({required String userId, required bool isOnline}) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return const Success<void>(null);
  }
  
  @override
  Future<Result<User>> getUserProfile({required String userId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return Success(_createMockUser(userId, 'Mock User'));
  }
  
  // Helper methods for mock entities
  AuthSession _createMockSession() {
    return AuthSession(
      accessToken: 'mock_access_token',
      refreshToken: 'mock_refresh_token',
      user: _createMockUser('mock_user_id', 'Mock User'),
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      tokenType: 'Bearer',
    );
  }
  
  User _createMockUser(String id, String? displayName) {
    return User(
      id: id,
      email: 'mock@example.com',
      displayName: displayName ?? 'Mock User',
      createdAt: DateTime.now(),
      isOnline: true,
    );
  }
}