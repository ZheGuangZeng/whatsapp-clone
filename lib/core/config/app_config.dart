import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment-specific application configuration
/// Supports development, staging, and production environments
class AppConfig {
  AppConfig._();
  
  /// Initialize configuration (load .env file)
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      // .env file not found or can't be loaded, fall back to compile-time constants
      print('Warning: Could not load .env file: $e');
    }
  }
  
  /// Get environment variable with fallback to compile-time constant
  static String _getEnvVar(String key, String defaultValue) {
    return dotenv.env[key] ?? defaultValue;
  }
  
  static bool _getBoolEnvVar(String key, bool defaultValue) {
    final value = dotenv.env[key];
    if (value != null) {
      return value.toLowerCase() == 'true';
    }
    return defaultValue;
  }
  
  static int _getIntEnvVar(String key, int defaultValue) {
    final value = dotenv.env[key];
    if (value != null) {
      return int.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  /// Environment detection
  static const String _environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
  static const bool _isProduction = String.fromEnvironment('ENVIRONMENT') == 'production';
  static const bool _isStaging = String.fromEnvironment('ENVIRONMENT') == 'staging';
  static const bool _isDevelopment = String.fromEnvironment('ENVIRONMENT') == 'development' || _environment == 'development';

  /// Environment getters
  static bool get isProduction => _isProduction;
  static bool get isStaging => _isStaging;  
  static bool get isDevelopment => _isDevelopment;
  static String get environment => _environment;

  /// Supabase Configuration
  static String get supabaseUrl => _getEnvVar(
    'SUPABASE_URL',
    'https://your-project.supabase.co',
  );
  
  static String get supabaseAnonKey => _getEnvVar(
    'SUPABASE_ANON_KEY', 
    'your-anon-key',
  );

  /// LiveKit Configuration
  static const String livekitUrl = String.fromEnvironment(
    'LIVEKIT_URL',
    defaultValue: 'wss://your-project.livekit.cloud',
  );

  static const String livekitApiKey = String.fromEnvironment(
    'LIVEKIT_API_KEY',
    defaultValue: 'your-livekit-api-key',
  );

  static const String livekitApiSecret = String.fromEnvironment(
    'LIVEKIT_API_SECRET',
    defaultValue: 'your-livekit-api-secret',
  );

  /// CDN Configuration
  static const String cdnUrl = String.fromEnvironment(
    'CDN_URL',
    defaultValue: '',
  );

  /// Regional Configuration
  static const String region = String.fromEnvironment(
    'REGION',
    defaultValue: 'ap-southeast-1', // Singapore as default
  );

  /// China-specific configuration
  static const bool chinaModeEnabled = bool.fromEnvironment(
    'CHINA_MODE_ENABLED',
    defaultValue: false,
  );

  static const String chinaApiEndpoint = String.fromEnvironment(
    'CHINA_API_ENDPOINT',
    defaultValue: '',
  );

  /// Performance Configuration
  static const int connectionTimeout = int.fromEnvironment(
    'CONNECTION_TIMEOUT_MS',
    defaultValue: 30000,
  );

  static const int readTimeout = int.fromEnvironment(
    'READ_TIMEOUT_MS', 
    defaultValue: 30000,
  );

  /// Feature Flags
  static const bool enableAnalytics = bool.fromEnvironment(
    'ENABLE_ANALYTICS',
    defaultValue: true,
  );

  static const bool enableCrashReporting = bool.fromEnvironment(
    'ENABLE_CRASH_REPORTING',
    defaultValue: true,
  );

  static const bool enablePerformanceMonitoring = bool.fromEnvironment(
    'ENABLE_PERFORMANCE_MONITORING',
    defaultValue: true,
  );

  /// Monitoring Configuration  
  static const String sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  );

  /// Debugging
  static const bool enableLogging = bool.fromEnvironment(
    'ENABLE_LOGGING',
    defaultValue: true,
  );

  static const String logLevel = String.fromEnvironment(
    'LOG_LEVEL',
    defaultValue: 'info',
  );

  /// Validation
  static bool get isConfigValid {
    if (supabaseUrl == 'https://your-project.supabase.co') {
      return false;
    }
    if (supabaseAnonKey == 'your-anon-key') {
      return false;
    }
    return true;
  }

  /// Configuration summary for debugging
  static Map<String, dynamic> get configSummary => {
    'environment': environment,
    'isProduction': isProduction,
    'isStaging': isStaging,
    'isDevelopment': isDevelopment,
    'region': region,
    'chinaModeEnabled': chinaModeEnabled,
    'enableAnalytics': enableAnalytics,
    'enableCrashReporting': enableCrashReporting,
    'enablePerformanceMonitoring': enablePerformanceMonitoring,
    'enableLogging': enableLogging,
    'logLevel': logLevel,
    'isConfigValid': isConfigValid,
    'hasSupabaseConfig': supabaseUrl != 'https://your-project.supabase.co',
    'hasLivekitConfig': livekitUrl != 'wss://your-project.livekit.cloud',
    'hasCdnConfig': cdnUrl.isNotEmpty,
    'hasSentryConfig': sentryDsn.isNotEmpty,
  };
}