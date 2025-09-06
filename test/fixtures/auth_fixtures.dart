import 'package:whatsapp_clone/features/auth/data/models/auth_session_model.dart';
import 'package:whatsapp_clone/features/auth/data/models/user_model.dart';
import 'package:whatsapp_clone/features/auth/domain/entities/auth_session.dart';
import 'package:whatsapp_clone/features/auth/domain/entities/user.dart';

/// Fixture helper for authentication-related test data
class AuthFixtures {
  // Test constants
  static const testUserId = 'test-user-id-123';
  static const testEmail = 'test@example.com';
  static const testPhone = '+1234567890';
  static const testDisplayName = 'Test User';
  static const testStatus = 'Available';
  static const testAvatarUrl = 'https://example.com/avatar.jpg';
  static const testAccessToken = 'test-access-token';
  static const testRefreshToken = 'test-refresh-token';
  static const testTokenType = 'Bearer';
  
  static final testCreatedAt = DateTime.utc(2023, 1, 1, 12, 0, 0);
  static final testExpiresAt = DateTime.utc(2023, 1, 1, 13, 0, 0);

  /// Creates a test User domain entity
  static User createUser({
    String? id,
    String? email,
    String? phone,
    String? displayName,
    String? status,
    String? avatarUrl,
    DateTime? createdAt,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return User(
      id: id ?? testUserId,
      email: email ?? testEmail,
      phone: phone,
      displayName: displayName ?? testDisplayName,
      status: status,
      avatarUrl: avatarUrl,
      createdAt: createdAt ?? testCreatedAt,
      isOnline: isOnline ?? false,
      lastSeen: lastSeen,
    );
  }

  /// Creates a test UserModel data model
  static UserModel createUserModel({
    String? id,
    String? email,
    String? phone,
    String? displayName,
    String? status,
    String? avatarUrl,
    DateTime? createdAt,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return UserModel(
      id: id ?? testUserId,
      email: email ?? testEmail,
      phone: phone,
      displayName: displayName ?? testDisplayName,
      status: status,
      avatarUrl: avatarUrl,
      createdAt: createdAt ?? testCreatedAt,
      isOnline: isOnline ?? false,
      lastSeen: lastSeen,
    );
  }

  /// Creates a test AuthSession domain entity
  static AuthSession createAuthSession({
    String? accessToken,
    String? refreshToken,
    User? user,
    DateTime? expiresAt,
    String? tokenType,
  }) {
    return AuthSession(
      accessToken: accessToken ?? testAccessToken,
      refreshToken: refreshToken ?? testRefreshToken,
      user: user ?? createUser(),
      expiresAt: expiresAt ?? testExpiresAt,
      tokenType: tokenType ?? testTokenType,
    );
  }

  /// Creates a test AuthSessionModel data model
  static AuthSessionModel createAuthSessionModel({
    String? accessToken,
    String? refreshToken,
    UserModel? user,
    DateTime? expiresAt,
    String? tokenType,
  }) {
    return AuthSessionModel(
      accessToken: accessToken ?? testAccessToken,
      refreshToken: refreshToken ?? testRefreshToken,
      user: user ?? createUserModel(),
      expiresAt: expiresAt ?? testExpiresAt,
      tokenType: tokenType ?? testTokenType,
    );
  }

  /// Creates a user for sign-up scenarios (minimal data)
  static UserModel createSignUpUser({
    String? id,
    String? email,
    String? phone,
    String? displayName,
  }) {
    return UserModel(
      id: id ?? testUserId,
      email: email ?? testEmail,
      phone: phone,
      displayName: displayName ?? testDisplayName,
      createdAt: testCreatedAt,
    );
  }

  /// Creates an auth session for email verification scenarios
  static AuthSessionModel createVerificationSession({
    String? userId,
    String? email,
    String? phone,
  }) {
    final user = createUserModel(
      id: userId ?? testUserId,
      email: email ?? testEmail,
      phone: phone,
    );
    
    return AuthSessionModel(
      accessToken: '',
      refreshToken: '',
      user: user,
      expiresAt: testExpiresAt,
      tokenType: testTokenType,
    );
  }

  /// Creates test JSON for user profile response
  static Map<String, dynamic> createUserProfileJson({
    String? id,
    String? displayName,
    String? email,
    String? phone,
    String? status,
    String? avatarUrl,
    bool? isOnline,
    String? lastSeen,
  }) {
    return {
      'id': id ?? testUserId,
      'display_name': displayName ?? testDisplayName,
      'email': email ?? testEmail,
      'phone': phone,
      'status': status,
      'avatar_url': avatarUrl,
      'is_online': isOnline ?? false,
      'last_seen': lastSeen,
      'created_at': testCreatedAt.toIso8601String(),
      'updated_at': testCreatedAt.toIso8601String(),
    };
  }

  /// Creates test JSON for Supabase user
  static Map<String, dynamic> createSupabaseUserJson({
    String? id,
    String? email,
    String? phone,
  }) {
    return {
      'id': id ?? testUserId,
      'email': email ?? testEmail,
      'phone': phone,
      'aud': 'authenticated',
      'created_at': testCreatedAt.toIso8601String(),
      'updated_at': testCreatedAt.toIso8601String(),
      'email_confirmed_at': testCreatedAt.toIso8601String(),
    };
  }
}