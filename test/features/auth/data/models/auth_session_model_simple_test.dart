import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_clone/features/auth/data/models/auth_session_model.dart';
import 'package:whatsapp_clone/features/auth/data/models/user_model.dart';
import 'package:whatsapp_clone/features/auth/domain/entities/auth_session.dart';
import 'package:whatsapp_clone/features/auth/domain/entities/user.dart';

void main() {
  group('AuthSessionModel Type Conversion', () {
    // Test data
    const testUserId = 'test-user-id';
    const testEmail = 'test@example.com';
    const testDisplayName = 'Test User';
    final testExpiresAt = DateTime(2025, 1, 1, 12, 0, 0);
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
      createdAt: DateTime(2024, 1, 1),
    );

    final testUserModel = UserModel(
      id: testUserId,
      email: testEmail,
      displayName: testDisplayName,
      avatarUrl: null,
      phone: null,
      createdAt: DateTime(2024, 1, 1),
    );

    final testAuthSession = AuthSession(
      accessToken: testAccessToken,
      refreshToken: testRefreshToken,
      user: testUser,
      expiresAt: testExpiresAt,
      tokenType: testTokenType,
    );

    group('Domain Conversion', () {
      test('should convert from domain entity with proper user type conversion', () {
        // Act
        final model = AuthSessionModel.fromDomain(testAuthSession);

        // Assert
        expect(model.accessToken, testAccessToken);
        expect(model.refreshToken, testRefreshToken);
        expect(model.expiresAt, testExpiresAt);
        expect(model.tokenType, testTokenType);
        // Critical: user should be converted to UserModel
        expect(model.user, isA<UserModel>());
        expect(model.user.id, testUserId);
        expect(model.user.email, testEmail);
        expect(model.user.displayName, testDisplayName);
      });

      test('should convert to domain entity with proper user type conversion', () {
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
        // Critical: user should be converted to User entity
        expect(domain.user, isA<User>());
        expect(domain.user.id, testUserId);
        expect(domain.user.email, testEmail);
        expect(domain.user.displayName, testDisplayName);
      });

      test('should handle round-trip conversion without data loss', () {
        // Arrange
        final originalSession = testAuthSession;

        // Act - Convert domain -> model -> domain
        final model = AuthSessionModel.fromDomain(originalSession);
        final convertedBack = model.toDomain();

        // Assert - Should maintain all data
        expect(convertedBack.accessToken, originalSession.accessToken);
        expect(convertedBack.refreshToken, originalSession.refreshToken);
        expect(convertedBack.expiresAt, originalSession.expiresAt);
        expect(convertedBack.tokenType, originalSession.tokenType);
        
        // User data should also be preserved
        expect(convertedBack.user.id, originalSession.user.id);
        expect(convertedBack.user.email, originalSession.user.email);
        expect(convertedBack.user.displayName, originalSession.user.displayName);
        expect(convertedBack.user.phone, originalSession.user.phone);
        expect(convertedBack.user.avatarUrl, originalSession.user.avatarUrl);
        expect(convertedBack.user.createdAt, originalSession.user.createdAt);
      });
    });

    group('JSON Serialization', () {
      test('should serialize and deserialize correctly', () {
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
        expect(reconstructed.user.email, originalModel.user.email);
        
        // DateTime precision might be affected by JSON serialization
        expect(
          reconstructed.expiresAt.millisecondsSinceEpoch,
          closeTo(originalModel.expiresAt.millisecondsSinceEpoch, 1000),
        );
      });
    });
  });
}