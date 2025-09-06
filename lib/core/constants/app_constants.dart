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
  static const String filesTable = 'files';
  
  /// File Storage Configuration
  static const String userAvatarsBucket = 'user-avatars';
  static const String chatMediaBucket = 'chat-media';
  static const String messageAttachmentsBucket = 'message-attachments';
  static const String thumbnailsBucket = 'thumbnails';
  
  /// File size limits (in bytes)
  static const int maxAvatarSize = 2 * 1024 * 1024; // 2MB
  static const int maxChatMediaSize = 100 * 1024 * 1024; // 100MB
  static const int maxAttachmentSize = 50 * 1024 * 1024; // 50MB
  
  /// Compression settings
  static const int imageCompressionQuality = 80;
  static const int thumbnailSize = 200;
  static const int videoThumbnailQuality = 50;
  
  /// Supported file types
  static const List<String> supportedImageTypes = [
    'jpg', 'jpeg', 'png', 'webp', 'gif'
  ];
  static const List<String> supportedVideoTypes = [
    'mp4', 'mov', 'avi', 'webm'
  ];
  static const List<String> supportedAudioTypes = [
    'mp3', 'wav', 'm4a', 'aac'
  ];
  static const List<String> supportedDocumentTypes = [
    'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt'
  ];
}