/// Application-wide constants for WhatsApp Clone
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  /// Environment configuration
  static const bool isDevelopment = true;

  /// Supabase configuration
  /// TODO: Replace with actual Supabase URL and anon key
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key';

  /// App configuration
  static const String appName = 'WhatsApp Clone';
  static const String appVersion = '1.0.0';

  /// UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  
  /// Colors
  static const int whatsAppGreen = 0xFF25D366;
  static const int whatsAppDarkGreen = 0xFF128C7E;
  static const int whatsAppTeal = 0xFF075E54;
  static const int whatsAppLightGreen = 0xFFDCF8C6;
  
  /// Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 150);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  /// Database tables
  static const String usersTable = 'users';
  static const String chatsTable = 'chats';
  static const String messagesTable = 'messages';
  static const String groupsTable = 'groups';
  static const String communitiesTable = 'communities';
}