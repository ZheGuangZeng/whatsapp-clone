/// Environment configuration for different deployment environments
class EnvironmentConfig {
  // Private constructor to prevent instantiation
  EnvironmentConfig._();

  /// Current environment
  static late Environment _currentEnvironment;
  
  /// Initialize environment based on compile-time constants or runtime detection
  static void initialize({Environment? environment}) {
    _currentEnvironment = environment ?? _detectEnvironment();
  }
  
  /// Detect environment automatically
  static Environment _detectEnvironment() {
    // Check for compile-time environment variables
    const environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
    
    switch (environment.toLowerCase()) {
      case 'production':
        return Environment.production;
      case 'staging':
        return Environment.staging;
      case 'development':
      default:
        return Environment.development;
    }
  }
  
  /// Current environment getter
  static Environment get currentEnvironment => _currentEnvironment;
  
  /// Environment check helpers
  static bool get isDevelopment => _currentEnvironment == Environment.development;
  static bool get isStaging => _currentEnvironment == Environment.staging;
  static bool get isProduction => _currentEnvironment == Environment.production;
  
  /// Get configuration for current environment
  static AppEnvironmentConfig get config {
    switch (_currentEnvironment) {
      case Environment.production:
        return AppEnvironmentConfig.production();
      case Environment.staging:
        return AppEnvironmentConfig.staging();
      case Environment.development:
        return AppEnvironmentConfig.development();
    }
  }
}

/// Available environments
enum Environment {
  development,
  staging,
  production,
}

/// Environment-specific configuration
class AppEnvironmentConfig {
  const AppEnvironmentConfig({
    required this.environment,
    required this.appName,
    required this.appVersion,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.liveKitUrl,
    required this.liveKitApiKey,
    required this.liveKitApiSecret,
    required this.cdnUrl,
    required this.apiBaseUrl,
    required this.enableAnalytics,
    required this.enableCrashReporting,
    required this.enablePerformanceMonitoring,
    required this.logLevel,
    required this.connectionTimeoutMs,
    required this.readTimeoutMs,
    required this.enableDebugLogging,
    required this.maxRetryAttempts,
    required this.retryDelayMs,
    required this.enableOfflineSync,
    required this.cacheExpiryMinutes,
    required this.region,
    this.secondarySupabaseUrl,
    this.secondarySupabaseAnonKey,
    this.sentryDsn,
    this.chinaCdnUrl,
    this.chinaApiEndpoint,
  });

  /// Development environment configuration
  factory AppEnvironmentConfig.development() {
    return const AppEnvironmentConfig(
      environment: Environment.development,
      appName: 'WhatsApp Clone (Dev)',
      appVersion: '1.0.0-dev',
      supabaseUrl: 'https://your-dev-project.supabase.co',
      supabaseAnonKey: 'your-dev-supabase-anon-key',
      liveKitUrl: 'wss://your-dev-domain.livekit.cloud',
      liveKitApiKey: 'your-dev-livekit-api-key',
      liveKitApiSecret: 'your-dev-livekit-api-secret',
      cdnUrl: 'https://dev-cdn.your-domain.com',
      apiBaseUrl: 'https://dev-api.your-domain.com',
      region: 'ap-southeast-1',
      enableAnalytics: false,
      enableCrashReporting: false,
      enablePerformanceMonitoring: true,
      enableDebugLogging: true,
      enableOfflineSync: true,
      logLevel: 'debug',
      connectionTimeoutMs: 30000,
      readTimeoutMs: 30000,
      maxRetryAttempts: 3,
      retryDelayMs: 1000,
      cacheExpiryMinutes: 15,
      sentryDsn: 'https://test@o0.ingest.sentry.io/0000000',
    );
  }
  
  /// Staging environment configuration
  factory AppEnvironmentConfig.staging() {
    return const AppEnvironmentConfig(
      environment: Environment.staging,
      appName: 'WhatsApp Clone (Staging)',
      appVersion: '1.0.0-staging',
      supabaseUrl: 'https://your-staging-project-sg.supabase.co',
      supabaseAnonKey: 'your-staging-supabase-anon-key',
      secondarySupabaseUrl: 'https://your-staging-project-jp.supabase.co',
      secondarySupabaseAnonKey: 'your-japan-staging-anon-key',
      liveKitUrl: 'wss://your-staging-domain.livekit.cloud',
      liveKitApiKey: 'your-staging-livekit-api-key',
      liveKitApiSecret: 'your-staging-livekit-api-secret',
      cdnUrl: 'https://cdn-staging.your-domain.com',
      apiBaseUrl: 'https://api-staging.your-domain.com',
      region: 'ap-southeast-1',
      enableAnalytics: true,
      enableCrashReporting: true,
      enablePerformanceMonitoring: true,
      enableDebugLogging: true,
      enableOfflineSync: true,
      logLevel: 'debug',
      connectionTimeoutMs: 15000,
      readTimeoutMs: 30000,
      maxRetryAttempts: 5,
      retryDelayMs: 2000,
      cacheExpiryMinutes: 30,
      sentryDsn: 'https://your-staging-sentry-dsn@sentry.io/staging-project-id',
      chinaCdnUrl: 'https://china-cdn-staging.your-domain.com',
      chinaApiEndpoint: 'https://china-api-staging.your-domain.com',
    );
  }
  
  /// Production environment configuration
  factory AppEnvironmentConfig.production() {
    return const AppEnvironmentConfig(
      environment: Environment.production,
      appName: 'WhatsApp Clone',
      appVersion: '1.0.0',
      supabaseUrl: 'https://your-production-project-sg.supabase.co',
      supabaseAnonKey: 'your-production-supabase-anon-key',
      secondarySupabaseUrl: 'https://your-production-project-jp.supabase.co',
      secondarySupabaseAnonKey: 'your-japan-anon-key',
      liveKitUrl: 'wss://your-production-domain.livekit.cloud',
      liveKitApiKey: 'your-production-livekit-api-key',
      liveKitApiSecret: 'your-production-livekit-api-secret',
      cdnUrl: 'https://cdn.your-production-domain.com',
      apiBaseUrl: 'https://api.your-production-domain.com',
      region: 'ap-southeast-1',
      enableAnalytics: true,
      enableCrashReporting: true,
      enablePerformanceMonitoring: true,
      enableDebugLogging: false,
      enableOfflineSync: true,
      logLevel: 'info',
      connectionTimeoutMs: 10000,
      readTimeoutMs: 30000,
      maxRetryAttempts: 5,
      retryDelayMs: 3000,
      cacheExpiryMinutes: 60,
      sentryDsn: 'https://your-sentry-dsn@sentry.io/project-id',
      chinaCdnUrl: 'https://china-cdn.your-domain.com',
      chinaApiEndpoint: 'https://china-api.your-domain.com',
    );
  }
  
  final Environment environment;
  final String appName;
  final String appVersion;
  
  // Supabase Configuration
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String? secondarySupabaseUrl;
  final String? secondarySupabaseAnonKey;
  
  // LiveKit Configuration
  final String liveKitUrl;
  final String liveKitApiKey;
  final String liveKitApiSecret;
  
  // Infrastructure Configuration
  final String cdnUrl;
  final String apiBaseUrl;
  final String region;
  
  // Feature Flags
  final bool enableAnalytics;
  final bool enableCrashReporting;
  final bool enablePerformanceMonitoring;
  final bool enableDebugLogging;
  final bool enableOfflineSync;
  
  // Performance Configuration
  final int connectionTimeoutMs;
  final int readTimeoutMs;
  final int maxRetryAttempts;
  final int retryDelayMs;
  final int cacheExpiryMinutes;
  
  // Monitoring
  final String logLevel;
  final String? sentryDsn;
  
  // China Optimization
  final String? chinaCdnUrl;
  final String? chinaApiEndpoint;
  
  /// Check if running in China region (for network optimization)
  bool get isChinaOptimized => chinaCdnUrl != null && chinaApiEndpoint != null;
  
  /// Get appropriate CDN URL based on user location
  String getCdnUrl({bool? isChinaUser}) {
    if (isChinaUser == true && chinaCdnUrl != null) {
      return chinaCdnUrl!;
    }
    return cdnUrl;
  }
  
  /// Get appropriate API endpoint based on user location
  String getApiBaseUrl({bool? isChinaUser}) {
    if (isChinaUser == true && chinaApiEndpoint != null) {
      return chinaApiEndpoint!;
    }
    return apiBaseUrl;
  }
  
  /// Get Supabase URL with failover support
  String getSupabaseUrl({bool useSecondary = false}) {
    if (useSecondary && secondarySupabaseUrl != null) {
      return secondarySupabaseUrl!;
    }
    return supabaseUrl;
  }
  
  /// Get Supabase anon key with failover support
  String getSupabaseAnonKey({bool useSecondary = false}) {
    if (useSecondary && secondarySupabaseAnonKey != null) {
      return secondarySupabaseAnonKey!;
    }
    return supabaseAnonKey;
  }
  
  @override
  String toString() {
    return 'AppEnvironmentConfig(environment: $environment, appName: $appName, version: $appVersion)';
  }
}

/// Production security configurations
class SecurityConfig {
  // Private constructor to prevent instantiation
  SecurityConfig._();
  
  /// SSL/TLS Configuration
  static const bool forceHttps = true;
  static const List<String> tlsVersions = ['TLSv1.2', 'TLSv1.3'];
  
  /// Certificate pinning for production
  static const bool enableCertificatePinning = true;
  static const List<String> pinnedCertificates = [
    // Production certificate hashes - update with actual values
    'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
    'sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=',
  ];
  
  /// Rate limiting
  static const int rateLimitRequestsPerMinute = 300;
  static const bool enableRateLimiting = true;
  
  /// JWT Configuration
  static const int jwtExpirySeconds = 3600; // 1 hour
  static const bool enableJwtValidation = true;
  
  /// CORS Configuration
  static const List<String> allowedOrigins = [
    'https://your-production-domain.com',
    'https://admin.your-production-domain.com',
  ];
  
  /// Content Security Policy
  static const Map<String, String> securityHeaders = {
    'Content-Security-Policy': "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline';",
    'X-Frame-Options': 'DENY',
    'X-Content-Type-Options': 'nosniff',
    'Referrer-Policy': 'strict-origin-when-cross-origin',
    'Permissions-Policy': 'geolocation=(), microphone=(), camera=()',
  };
}