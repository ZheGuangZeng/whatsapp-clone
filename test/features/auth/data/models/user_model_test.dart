import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_clone/features/auth/data/models/user_model.dart';
import 'package:whatsapp_clone/features/auth/domain/entities/user.dart';

void main() {
  group('UserModel', () {
    final userModel = UserModel(
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

    final userJson = {
      'id': '123',
      'email': 'test@example.com',
      'phone': '+1234567890',
      'displayName': 'Test User',
      'avatarUrl': 'https://example.com/avatar.jpg',
      'status': 'Available',
      'createdAt': '2023-01-01T00:00:00.000',
      'lastSeen': '2023-12-31T00:00:00.000',
      'isOnline': true,
    };

    test('should serialize to JSON correctly', () {
      // Act
      final json = userModel.toJson();

      // Assert
      expect(json, equals(userJson));
    });

    test('should deserialize from JSON correctly', () {
      // Act
      final result = UserModel.fromJson(userJson);

      // Assert
      expect(result.id, userModel.id);
      expect(result.email, userModel.email);
      expect(result.phone, userModel.phone);
      expect(result.displayName, userModel.displayName);
      expect(result.avatarUrl, userModel.avatarUrl);
      expect(result.status, userModel.status);
      expect(result.createdAt, userModel.createdAt);
      expect(result.lastSeen, userModel.lastSeen);
      expect(result.isOnline, userModel.isOnline);
    });

    test('should handle null values correctly in JSON', () {
      final minimalJson = {
        'id': '123',
        'email': 'test@example.com',
        'displayName': 'Test User',
        'createdAt': '2023-01-01T00:00:00.000',
        'isOnline': false,
      };

      // Act
      final result = UserModel.fromJson(minimalJson);

      // Assert
      expect(result.id, '123');
      expect(result.email, 'test@example.com');
      expect(result.displayName, 'Test User');
      expect(result.createdAt, DateTime(2023, 1, 1));
      expect(result.phone, isNull);
      expect(result.avatarUrl, isNull);
      expect(result.status, isNull);
      expect(result.lastSeen, isNull);
      expect(result.isOnline, false);
    });

    test('should convert to domain entity correctly', () {
      // Act
      final domainUser = userModel.toDomain();

      // Assert
      expect(domainUser, isA<User>());
      expect(domainUser.id, userModel.id);
      expect(domainUser.email, userModel.email);
      expect(domainUser.phone, userModel.phone);
      expect(domainUser.displayName, userModel.displayName);
      expect(domainUser.avatarUrl, userModel.avatarUrl);
      expect(domainUser.status, userModel.status);
      expect(domainUser.createdAt, userModel.createdAt);
      expect(domainUser.lastSeen, userModel.lastSeen);
      expect(domainUser.isOnline, userModel.isOnline);
    });

    test('should create from domain entity correctly', () {
      // Arrange
      final domainUser = User(
        id: '456',
        email: 'domain@example.com',
        displayName: 'Domain User',
        createdAt: DateTime(2023, 6, 15),
      );

      // Act
      final userModel = UserModel.fromDomain(domainUser);

      // Assert
      expect(userModel.id, domainUser.id);
      expect(userModel.email, domainUser.email);
      expect(userModel.phone, domainUser.phone);
      expect(userModel.displayName, domainUser.displayName);
      expect(userModel.avatarUrl, domainUser.avatarUrl);
      expect(userModel.status, domainUser.status);
      expect(userModel.createdAt, domainUser.createdAt);
      expect(userModel.lastSeen, domainUser.lastSeen);
      expect(userModel.isOnline, domainUser.isOnline);
    });

    test('should create from Supabase user data correctly', () {
      // Arrange
      final supabaseUser = {
        'id': '789',
        'email': 'supabase@example.com',
        'phone': '+9876543210',
        'created_at': '2023-03-15T10:30:00.000Z',
      };

      final profile = {
        'display_name': 'Supabase User',
        'avatar_url': 'https://example.com/supabase-avatar.jpg',
        'status': 'Busy',
        'last_seen': '2023-12-01T14:22:00.000Z',
        'is_online': true,
      };

      // Act
      final result = UserModel.fromSupabaseUser(supabaseUser, profile);

      // Assert
      expect(result.id, '789');
      expect(result.email, 'supabase@example.com');
      expect(result.phone, '+9876543210');
      expect(result.displayName, 'Supabase User');
      expect(result.avatarUrl, 'https://example.com/supabase-avatar.jpg');
      expect(result.status, 'Busy');
      expect(result.createdAt, DateTime.parse('2023-03-15T10:30:00.000Z'));
      expect(result.lastSeen, DateTime.parse('2023-12-01T14:22:00.000Z'));
      expect(result.isOnline, true);
    });

    test('should handle null profile data from Supabase correctly', () {
      // Arrange
      final supabaseUser = {
        'id': '999',
        'email': 'minimal@example.com',
        'created_at': '2023-03-15T10:30:00.000Z',
      };

      // Act
      final result = UserModel.fromSupabaseUser(supabaseUser, null);

      // Assert
      expect(result.id, '999');
      expect(result.email, 'minimal@example.com');
      expect(result.displayName, 'minimal@example.com'); // Fallback to email
      expect(result.createdAt, DateTime.parse('2023-03-15T10:30:00.000Z'));
      expect(result.phone, isNull);
      expect(result.avatarUrl, isNull);
      expect(result.status, isNull);
      expect(result.lastSeen, isNull);
      expect(result.isOnline, false);
    });
  });
}