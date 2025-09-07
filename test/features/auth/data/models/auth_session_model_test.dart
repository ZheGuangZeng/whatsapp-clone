import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:whatsapp_clone/features/auth/data/models/auth_session_model.dart';
import 'package:whatsapp_clone/features/auth/data/models/user_model.dart';
import 'package:whatsapp_clone/features/auth/domain/entities/auth_session.dart';
import 'package:whatsapp_clone/features/auth/domain/entities/user.dart';

void main() {
  group('AuthSessionModel', () {
    // Test data
    const testUserId = 'test-user-id';
    const testEmail = 'test@example.com';
    const testDisplayName = 'Test User';
    final testExpiresAt = DateTime.now().add(const Duration(hours: 1));
    const testAccessToken = 'access-token';
    const testRefreshToken = 'refresh-token';
    const testTokenType = 'Bearer';

    // Create domain entities for testing
    final testUser = User(
      id: testUserId,
      email: testEmail,
      displayName: testDisplayName,
      avatarUrl: null,
      phone: null,
      createdAt: DateTime.now(),
    );

    final testUserModel = UserModel(
      id: testUserId,
      email: testEmail,
      displayName: testDisplayName,
      avatarUrl: null,
      phone: null,
      createdAt: DateTime.now(),
    );

    final testAuthSession = AuthSession(
      accessToken: testAccessToken,
      refreshToken: testRefreshToken,
      user: testUser,
      expiresAt: testExpiresAt,
      tokenType: testTokenType,
    );

    group('Domain Conversion', () {
      test('should convert from domain entity correctly', () {
        // Arrange & Act
        final model = AuthSessionModel.fromDomain(testAuthSession);

        // Assert
        expect(model.accessToken, testAccessToken);
        expect(model.refreshToken, testRefreshToken);
        expect(model.expiresAt, testExpiresAt);
        expect(model.tokenType, testTokenType);
        // This should pass - user should be a UserModel
        expect(model.user, isA<UserModel>());
        expect(model.user.id, testUserId);
        expect(model.user.email, testEmail);
      });

      test('should convert to domain entity correctly', () {
        // Arrange
        final model = AuthSessionModel(
          accessToken: testAccessToken,
          refreshToken: testRefreshToken,
          user: testUserModel,
          expiresAt: testExpiresAt,
          tokenType: testTokenType,
        );

        // Act
        final domain = model.toDomain();

        // Assert
        expect(domain.accessToken, testAccessToken);
        expect(domain.refreshToken, testRefreshToken);
        expect(domain.expiresAt, testExpiresAt);
        expect(domain.tokenType, testTokenType);
        // This should pass - user should be a User entity
        expect(domain.user, isA<User>());
        expect(domain.user.id, testUserId);
        expect(domain.user.email, testEmail);
      });

      test('should handle round-trip conversion without data loss', () {
        // Arrange
        final originalSession = testAuthSession;

        // Act
        final model = AuthSessionModel.fromDomain(originalSession);
        final convertedBack = model.toDomain();

        // Assert
        expect(convertedBack.accessToken, originalSession.accessToken);
        expect(convertedBack.refreshToken, originalSession.refreshToken);
        expect(convertedBack.expiresAt, originalSession.expiresAt);
        expect(convertedBack.tokenType, originalSession.tokenType);
        expect(convertedBack.user.id, originalSession.user.id);
        expect(convertedBack.user.email, originalSession.user.email);
        expect(convertedBack.user.displayName, originalSession.user.displayName);
      });
    });

    group('Supabase Conversion', () {
      test('should convert from Supabase session correctly', () {
        // Arrange
        final mockSession = MockSupabaseSession(
          accessToken: testAccessToken,
          refreshToken: testRefreshToken,
          expiresAt: testExpiresAt.millisecondsSinceEpoch ~/ 1000,
          tokenType: testTokenType,
        );

        // Act
        final model = AuthSessionModel.fromSupabaseSession(mockSession, testUserModel);

        // Assert
        expect(model.accessToken, testAccessToken);
        expect(model.refreshToken, testRefreshToken);
        expect(model.user, testUserModel);
        expect(model.expiresAt, testExpiresAt);
        expect(model.tokenType, testTokenType);
      });

      test('should handle null refresh token from Supabase', () {
        // Arrange
        final mockSession = MockSupabaseSession(
          accessToken: testAccessToken,
          refreshToken: null,
          expiresAt: testExpiresAt.millisecondsSinceEpoch ~/ 1000,
          tokenType: testTokenType,
        );

        // Act
        final model = AuthSessionModel.fromSupabaseSession(mockSession, testUserModel);

        // Assert
        expect(model.refreshToken, '');
      });

      test('should handle null token type from Supabase', () {
        // Arrange
        final mockSession = MockSupabaseSession(
          accessToken: testAccessToken,
          refreshToken: testRefreshToken,
          expiresAt: testExpiresAt.millisecondsSinceEpoch ~/ 1000,
          tokenType: null,
        );

        // Act
        final model = AuthSessionModel.fromSupabaseSession(mockSession, testUserModel);

        // Assert
        expect(model.tokenType, 'Bearer');
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON correctly', () {
        // Arrange
        final model = AuthSessionModel(
          accessToken: testAccessToken,
          refreshToken: testRefreshToken,
          user: testUserModel,
          expiresAt: testExpiresAt,
          tokenType: testTokenType,
        );

        // Act
        final json = model.toJson();

        // Assert
        expect(json['accessToken'], testAccessToken);
        expect(json['refreshToken'], testRefreshToken);
        expect(json['tokenType'], testTokenType);
        expect(json['user'], isA<Map<String, dynamic>>());
        expect(json['expiresAt'], isA<String>());
      });

      test('should deserialize from JSON correctly', () {
        // Arrange
        final json = {
          'accessToken': testAccessToken,
          'refreshToken': testRefreshToken,
          'user': testUserModel.toJson(),
          'expiresAt': testExpiresAt.toIso8601String(),
          'tokenType': testTokenType,
        };

        // Act
        final model = AuthSessionModel.fromJson(json);

        // Assert
        expect(model.accessToken, testAccessToken);
        expect(model.refreshToken, testRefreshToken);
        expect(model.tokenType, testTokenType);
        expect(model.user, isA<UserModel>());
        expect(model.user.id, testUserId);
      });

      test('should handle round-trip JSON conversion without data loss', () {
        // Arrange
        final originalModel = AuthSessionModel(
          accessToken: testAccessToken,
          refreshToken: testRefreshToken,
          user: testUserModel,
          expiresAt: testExpiresAt,
          tokenType: testTokenType,
        );

        // Act
        final json = originalModel.toJson();
        final reconstructed = AuthSessionModel.fromJson(json);

        // Assert
        expect(reconstructed.accessToken, originalModel.accessToken);
        expect(reconstructed.refreshToken, originalModel.refreshToken);
        expect(reconstructed.tokenType, originalModel.tokenType);
        expect(reconstructed.user.id, originalModel.user.id);
        // Note: DateTime precision might be lost in JSON conversion
        expect(reconstructed.expiresAt.millisecondsSinceEpoch,
               closeTo(originalModel.expiresAt.millisecondsSinceEpoch, 1000));
      });
    });
  });
}

// Mock class for Supabase Session (since we can't easily create real Session objects in tests)
class MockSupabaseSession implements Session {
  MockSupabaseSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.tokenType,
  });

  @override
  final String accessToken;
  
  @override
  final String? refreshToken;
  
  @override
  final int? expiresAt;
  
  @override
  final String tokenType;

  // Implement required Session methods with dummy values
  @override
  int? get expiresIn => null;

  @override
  String? get providerRefreshToken => null;

  @override
  String? get providerToken => null;

  @override
  dynamic get user => null;

  @override
  bool get isExpired => false;

  @override
  Map<String, dynamic> toJson() => {};

  @override
  Session copyWith({String? accessToken, String? refreshToken, int? expiresAt, String? tokenType}) => 
      throw UnimplementedError();
}