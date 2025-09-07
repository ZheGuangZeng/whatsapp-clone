import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_clone/features/chat/domain/entities/room.dart';
import 'package:whatsapp_clone/features/chat/domain/entities/room_type.dart';

void main() {
  group('Room Entity Tests', () {
    test('should create a valid Room with required fields', () {
      // Arrange
      const roomId = 'room_123';
      const name = 'Test Room';
      const creatorId = 'user_123';
      final createdAt = DateTime.now();
      
      // Act
      final room = Room(
        id: roomId,
        name: name,
        creatorId: creatorId,
        createdAt: createdAt,
      );
      
      // Assert
      expect(room.id, equals(roomId));
      expect(room.name, equals(name));
      expect(room.creatorId, equals(creatorId));
      expect(room.createdAt, equals(createdAt));
      expect(room.type, equals(RoomType.group)); // default
      expect(room.description, isNull);
      expect(room.avatarUrl, isNull);
      expect(room.isActive, isTrue); // default
      expect(room.participantCount, equals(0)); // default
      expect(room.lastActivity, isNull);
    });

    test('should create a Room with all optional fields', () {
      // Arrange
      const roomId = 'room_123';
      const name = 'Test Room';
      const creatorId = 'user_123';
      final createdAt = DateTime.now();
      final lastActivity = DateTime.now();
      const description = 'Test description';
      const avatarUrl = 'https://example.com/avatar.jpg';
      const participantCount = 5;
      
      // Act
      final room = Room(
        id: roomId,
        name: name,
        creatorId: creatorId,
        createdAt: createdAt,
        type: RoomType.direct,
        description: description,
        avatarUrl: avatarUrl,
        isActive: false,
        participantCount: participantCount,
        lastActivity: lastActivity,
      );
      
      // Assert
      expect(room.id, equals(roomId));
      expect(room.name, equals(name));
      expect(room.creatorId, equals(creatorId));
      expect(room.createdAt, equals(createdAt));
      expect(room.type, equals(RoomType.direct));
      expect(room.description, equals(description));
      expect(room.avatarUrl, equals(avatarUrl));
      expect(room.isActive, isFalse);
      expect(room.participantCount, equals(participantCount));
      expect(room.lastActivity, equals(lastActivity));
    });

    test('should support equality comparison', () {
      // Arrange
      final createdAt = DateTime.now();
      final room1 = Room(
        id: 'room_123',
        name: 'Test Room',
        creatorId: 'user_123',
        createdAt: createdAt,
      );
      final room2 = Room(
        id: 'room_123',
        name: 'Test Room',
        creatorId: 'user_123',
        createdAt: createdAt,
      );
      final room3 = Room(
        id: 'room_456',
        name: 'Test Room',
        creatorId: 'user_123',
        createdAt: createdAt,
      );
      
      // Act & Assert
      expect(room1, equals(room2));
      expect(room1, isNot(equals(room3)));
      expect(room1.hashCode, equals(room2.hashCode));
      expect(room1.hashCode, isNot(equals(room3.hashCode)));
    });

    test('should create a copy with updated fields', () {
      // Arrange
      final originalRoom = Room(
        id: 'room_123',
        name: 'Original Room',
        creatorId: 'user_123',
        createdAt: DateTime.now(),
        isActive: true,
        participantCount: 5,
      );
      
      // Act
      final updatedRoom = originalRoom.copyWith(
        name: 'Updated Room',
        isActive: false,
        participantCount: 10,
      );
      
      // Assert
      expect(updatedRoom.id, equals(originalRoom.id));
      expect(updatedRoom.name, equals('Updated Room'));
      expect(updatedRoom.creatorId, equals(originalRoom.creatorId));
      expect(updatedRoom.createdAt, equals(originalRoom.createdAt));
      expect(updatedRoom.isActive, isFalse);
      expect(updatedRoom.participantCount, equals(10));
    });

    test('should validate room name is not empty', () {
      // Arrange
      final createdAt = DateTime.now();
      
      // Act & Assert
      expect(
        () => Room(
          id: 'room_123',
          name: '',
          creatorId: 'user_123',
          createdAt: createdAt,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('should validate room ID is not empty', () {
      // Arrange
      final createdAt = DateTime.now();
      
      // Act & Assert
      expect(
        () => Room(
          id: '',
          name: 'Test Room',
          creatorId: 'user_123',
          createdAt: createdAt,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('should validate creator ID is not empty', () {
      // Arrange
      final createdAt = DateTime.now();
      
      // Act & Assert
      expect(
        () => Room(
          id: 'room_123',
          name: 'Test Room',
          creatorId: '',
          createdAt: createdAt,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('should validate participant count is not negative', () {
      // Arrange
      final createdAt = DateTime.now();
      
      // Act & Assert
      expect(
        () => Room(
          id: 'room_123',
          name: 'Test Room',
          creatorId: 'user_123',
          createdAt: createdAt,
          participantCount: -1,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('should handle room type changes correctly', () {
      // Arrange
      final room = Room(
        id: 'room_123',
        name: 'Test Room',
        creatorId: 'user_123',
        createdAt: DateTime.now(),
        type: RoomType.group,
      );
      
      // Act
      final directRoom = room.copyWith(type: RoomType.direct);
      final channelRoom = room.copyWith(type: RoomType.channel);
      
      // Assert
      expect(directRoom.type, equals(RoomType.direct));
      expect(channelRoom.type, equals(RoomType.channel));
      expect(room.type, equals(RoomType.group)); // original unchanged
    });

    test('should update last activity correctly', () {
      // Arrange
      final room = Room(
        id: 'room_123',
        name: 'Test Room',
        creatorId: 'user_123',
        createdAt: DateTime.now(),
      );
      final newActivity = DateTime.now().add(const Duration(hours: 1));
      
      // Act
      final updatedRoom = room.copyWith(lastActivity: newActivity);
      
      // Assert
      expect(updatedRoom.lastActivity, equals(newActivity));
      expect(room.lastActivity, isNull); // original unchanged
    });
  });
}