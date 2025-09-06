import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_clone/features/auth/domain/entities/auth_session.dart';
import 'package:whatsapp_clone/features/auth/domain/entities/user.dart';

void main() {
  group('AuthSession', () {
    final testUser = User(
      id: '123',
      email: 'test@example.com',
      displayName: 'Test User',
      createdAt: DateTime.utc(2023, 1, 1),
    );

    final futureDateTime = DateTime.utc(2025, 12, 31);
    final pastDateTime = DateTime.utc(2020, 1, 1);
    final nearFutureDateTime = DateTime.now().add(const Duration(minutes: 3));

    test('should create AuthSession with all properties', () {
      final session = AuthSession(
        accessToken: 'access_token_123',
        refreshToken: 'refresh_token_456',
        user: testUser,
        expiresAt: futureDateTime,
        tokenType: 'Bearer',
      );

      expect(session.accessToken, 'access_token_123');
      expect(session.refreshToken, 'refresh_token_456');
      expect(session.user, testUser);
      expect(session.expiresAt, futureDateTime);
      expect(session.tokenType, 'Bearer');
    });

    test('should correctly identify non-expired token', () {
      final session = AuthSession(
        accessToken: 'access_token',
        refreshToken: 'refresh_token',
        user: testUser,
        expiresAt: futureDateTime,
        tokenType: 'Bearer',
      );

      expect(session.isExpired, false);
    });

    test('should correctly identify expired token', () {
      final session = AuthSession(
        accessToken: 'access_token',
        refreshToken: 'refresh_token',
        user: testUser,
        expiresAt: pastDateTime,
        tokenType: 'Bearer',
      );

      expect(session.isExpired, true);
    });

    test('should correctly identify token expiring soon', () {
      final session = AuthSession(
        accessToken: 'access_token',
        refreshToken: 'refresh_token',
        user: testUser,
        expiresAt: nearFutureDateTime,
        tokenType: 'Bearer',
      );

      expect(session.isExpiringSoon, true);
    });

    test('should correctly identify token not expiring soon', () {
      final session = AuthSession(
        accessToken: 'access_token',
        refreshToken: 'refresh_token',
        user: testUser,
        expiresAt: futureDateTime,
        tokenType: 'Bearer',
      );

      expect(session.isExpiringSoon, false);
    });

    test('should support copyWith for all fields', () {
      final originalSession = AuthSession(
        accessToken: 'original_access',
        refreshToken: 'original_refresh',
        user: testUser,
        expiresAt: futureDateTime,
        tokenType: 'Bearer',
      );

      final newUser = User(
        id: '456',
        email: 'new@example.com',
        displayName: 'New User',
        createdAt: DateTime.utc(2023, 2, 1),
      );

      final newDateTime = DateTime.utc(2026, 1, 1);

      final updatedSession = originalSession.copyWith(
        accessToken: 'new_access',
        refreshToken: 'new_refresh',
        user: newUser,
        expiresAt: newDateTime,
        tokenType: 'JWT',
      );

      expect(updatedSession.accessToken, 'new_access');
      expect(updatedSession.refreshToken, 'new_refresh');
      expect(updatedSession.user, newUser);
      expect(updatedSession.expiresAt, newDateTime);
      expect(updatedSession.tokenType, 'JWT');
    });

    test('should support copyWith with partial updates', () {
      final originalSession = AuthSession(
        accessToken: 'original_access',
        refreshToken: 'original_refresh',
        user: testUser,
        expiresAt: futureDateTime,
        tokenType: 'Bearer',
      );

      final updatedSession = originalSession.copyWith(
        accessToken: 'new_access',
      );

      expect(updatedSession.accessToken, 'new_access');
      expect(updatedSession.refreshToken, originalSession.refreshToken);
      expect(updatedSession.user, originalSession.user);
      expect(updatedSession.expiresAt, originalSession.expiresAt);
      expect(updatedSession.tokenType, originalSession.tokenType);
    });

    test('should support equality comparison', () {
      final session1 = AuthSession(
        accessToken: 'access_token',
        refreshToken: 'refresh_token',
        user: testUser,
        expiresAt: futureDateTime,
        tokenType: 'Bearer',
      );

      final session2 = AuthSession(
        accessToken: 'access_token',
        refreshToken: 'refresh_token',
        user: testUser,
        expiresAt: futureDateTime,
        tokenType: 'Bearer',
      );

      final session3 = AuthSession(
        accessToken: 'different_access',
        refreshToken: 'refresh_token',
        user: testUser,
        expiresAt: futureDateTime,
        tokenType: 'Bearer',
      );

      expect(session1, equals(session2));
      expect(session1, isNot(equals(session3)));
    });

    test('should have consistent hashCode for equal objects', () {
      final session1 = AuthSession(
        accessToken: 'access_token',
        refreshToken: 'refresh_token',
        user: testUser,
        expiresAt: futureDateTime,
        tokenType: 'Bearer',
      );

      final session2 = AuthSession(
        accessToken: 'access_token',
        refreshToken: 'refresh_token',
        user: testUser,
        expiresAt: futureDateTime,
        tokenType: 'Bearer',
      );

      expect(session1.hashCode, session2.hashCode);
    });

    test('should include all properties in props', () {
      final session = AuthSession(
        accessToken: 'access_token',
        refreshToken: 'refresh_token',
        user: testUser,
        expiresAt: futureDateTime,
        tokenType: 'Bearer',
      );

      expect(session.props, contains(session.accessToken));
      expect(session.props, contains(session.refreshToken));
      expect(session.props, contains(session.user));
      expect(session.props, contains(session.expiresAt));
      expect(session.props, contains(session.tokenType));
    });
  });
}