import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_clone/features/auth/domain/entities/user.dart';

void main() {
  group('User', () {
    final user = User(
      id: '123',
      email: 'test@example.com',
      phone: '+1234567890',
      displayName: 'Test User',
      avatarUrl: 'https://example.com/avatar.jpg',
      status: 'Available',
      createdAt: DateTime(2023, 1, 1),
      lastSeen: DateTime(2023, 12, 31),
      isOnline: true,
    );

    test('should create user with all properties', () {
      expect(user.id, '123');
      expect(user.email, 'test@example.com');
      expect(user.phone, '+1234567890');
      expect(user.displayName, 'Test User');
      expect(user.avatarUrl, 'https://example.com/avatar.jpg');
      expect(user.status, 'Available');
      expect(user.createdAt, DateTime(2023, 1, 1));
      expect(user.lastSeen, DateTime(2023, 12, 31));
      expect(user.isOnline, true);
    });

    test('should create user with minimal required properties', () {
      final minimalUser = User(
        id: '123',
        email: 'test@example.com',
        displayName: 'Test User',
        createdAt: DateTime(2023, 1, 1),
      );

      expect(minimalUser.id, '123');
      expect(minimalUser.email, 'test@example.com');
      expect(minimalUser.displayName, 'Test User');
      expect(minimalUser.createdAt, DateTime(2023, 1, 1));
      expect(minimalUser.phone, isNull);
      expect(minimalUser.avatarUrl, isNull);
      expect(minimalUser.status, isNull);
      expect(minimalUser.lastSeen, isNull);
      expect(minimalUser.isOnline, false);
    });

    test('should support copyWith', () {
      final updatedUser = user.copyWith(
        displayName: 'Updated User',
        isOnline: false,
      );

      expect(updatedUser.id, '123');
      expect(updatedUser.email, 'test@example.com');
      expect(updatedUser.displayName, 'Updated User');
      expect(updatedUser.isOnline, false);
      expect(updatedUser.phone, user.phone);
      expect(updatedUser.avatarUrl, user.avatarUrl);
      expect(updatedUser.status, user.status);
      expect(updatedUser.createdAt, user.createdAt);
      expect(updatedUser.lastSeen, user.lastSeen);
    });

    test('should support equality comparison', () {
      final user1 = User(
        id: '123',
        email: 'test@example.com',
        displayName: 'Test User',
        createdAt: DateTime(2023, 1, 1),
      );

      final user2 = User(
        id: '123',
        email: 'test@example.com',
        displayName: 'Test User',
        createdAt: DateTime(2023, 1, 1),
      );

      final user3 = User(
        id: '456',
        email: 'test@example.com',
        displayName: 'Test User',
        createdAt: DateTime(2023, 1, 1),
      );

      expect(user1, equals(user2));
      expect(user1, isNot(equals(user3)));
    });
  });
}