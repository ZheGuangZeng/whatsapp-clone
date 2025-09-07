import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_clone/features/chat/data/models/room_model.dart';
import 'package:whatsapp_clone/features/chat/domain/entities/room.dart';
import 'package:whatsapp_clone/features/chat/domain/entities/room_type.dart';

void main() {
  group('RoomModel', () {
    group('fromJson', () {
      test('should return a valid RoomModel when JSON contains all required fields', () {
        // arrange
        final Map<String, dynamic> json = {
          'id': 'room_123',
          'name': 'Test Room',
          'creator_id': 'user_456',
          'created_at': '2024-01-01T12:00:00.000Z',
          'type': 'group',
          'description': 'A test room for testing',
          'avatar_url': 'https://example.com/avatar.jpg',
          'is_active': true,
          'participant_count': 5,
          'last_activity': '2024-01-01T15:00:00.000Z',
        };

        // act
        final result = RoomModel.fromJson(json);

        // assert
        expect(result, isA<RoomModel>());
        expect(result.id, equals('room_123'));
        expect(result.name, equals('Test Room'));
        expect(result.creatorId, equals('user_456'));
        expect(result.createdAt, equals(DateTime.parse('2024-01-01T12:00:00.000Z')));
        expect(result.type, equals(RoomType.group));
        expect(result.description, equals('A test room for testing'));
        expect(result.avatarUrl, equals('https://example.com/avatar.jpg'));
        expect(result.isActive, equals(true));
        expect(result.participantCount, equals(5));
        expect(result.lastActivity, equals(DateTime.parse('2024-01-01T15:00:00.000Z')));
      });

      test('should return a valid RoomModel with minimal required fields', () {
        // arrange
        final Map<String, dynamic> json = {
          'id': 'room_456',
          'name': 'Minimal Room',
          'creator_id': 'user_789',
          'created_at': '2024-01-01T12:00:00.000Z',
        };

        // act
        final result = RoomModel.fromJson(json);

        // assert
        expect(result, isA<RoomModel>());
        expect(result.id, equals('room_456'));
        expect(result.name, equals('Minimal Room'));
        expect(result.creatorId, equals('user_789'));
        expect(result.createdAt, equals(DateTime.parse('2024-01-01T12:00:00.000Z')));
        expect(result.type, equals(RoomType.group)); // default value
        expect(result.description, isNull);
        expect(result.avatarUrl, isNull);
        expect(result.isActive, equals(true)); // default value
        expect(result.participantCount, equals(0)); // default value
        expect(result.lastActivity, isNull);
      });

      test('should handle different room types correctly', () {
        // arrange - direct room
        final directJson = {
          'id': 'room_direct',
          'name': 'Direct Chat',
          'creator_id': 'user_123',
          'created_at': '2024-01-01T12:00:00.000Z',
          'type': 'direct',
        };

        // arrange - group room
        final groupJson = {
          'id': 'room_group',
          'name': 'Group Chat',
          'creator_id': 'user_123',
          'created_at': '2024-01-01T12:00:00.000Z',
          'type': 'group',
        };

        // arrange - channel room
        final channelJson = {
          'id': 'room_channel',
          'name': 'Channel',
          'creator_id': 'user_123',
          'created_at': '2024-01-01T12:00:00.000Z',
          'type': 'channel',
        };

        // act
        final directResult = RoomModel.fromJson(directJson);
        final groupResult = RoomModel.fromJson(groupJson);
        final channelResult = RoomModel.fromJson(channelJson);

        // assert
        expect(directResult.type, equals(RoomType.direct));
        expect(groupResult.type, equals(RoomType.group));
        expect(channelResult.type, equals(RoomType.channel));
      });

      test('should validate required fields are present', () {
        // arrange
        final invalidJson = {
          'name': 'Test Room',
          'creator_id': 'user_456',
          'created_at': '2024-01-01T12:00:00.000Z',
        };

        // act & assert
        expect(() => RoomModel.fromJson(invalidJson), throwsA(isA<Exception>()));
      });

      test('should handle null optional fields correctly', () {
        // arrange
        final Map<String, dynamic> json = {
          'id': 'room_123',
          'name': 'Test Room',
          'creator_id': 'user_456',
          'created_at': '2024-01-01T12:00:00.000Z',
          'type': 'group',
          'description': null,
          'avatar_url': null,
          'is_active': null,
          'participant_count': null,
          'last_activity': null,
        };

        // act
        final result = RoomModel.fromJson(json);

        // assert
        expect(result.description, isNull);
        expect(result.avatarUrl, isNull);
        expect(result.isActive, equals(true)); // default value when null
        expect(result.participantCount, equals(0)); // default value when null
        expect(result.lastActivity, isNull);
      });
    });

    group('toJson', () {
      test('should return valid JSON map with all fields', () {
        // arrange
        final model = RoomModel(
          id: 'room_123',
          name: 'Test Room',
          creatorId: 'user_456',
          createdAt: DateTime(2024, 1, 1, 12, 0),
          type: RoomType.group,
          description: 'A test room for testing',
          avatarUrl: 'https://example.com/avatar.jpg',
          isActive: true,
          participantCount: 5,
          lastActivity: DateTime(2024, 1, 1, 15, 0),
        );

        // act
        final result = model.toJson();

        // assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['id'], equals('room_123'));
        expect(result['name'], equals('Test Room'));
        expect(result['creator_id'], equals('user_456'));
        expect(result['created_at'], equals('2024-01-01T12:00:00.000'));
        expect(result['type'], equals('group'));
        expect(result['description'], equals('A test room for testing'));
        expect(result['avatar_url'], equals('https://example.com/avatar.jpg'));
        expect(result['is_active'], equals(true));
        expect(result['participant_count'], equals(5));
        expect(result['last_activity'], equals('2024-01-01T15:00:00.000'));
      });

      test('should return valid JSON map with minimal fields', () {
        // arrange
        final model = RoomModel(
          id: 'room_123',
          name: 'Test Room',
          creatorId: 'user_456',
          createdAt: DateTime(2024, 1, 1, 12, 0),
        );

        // act
        final result = model.toJson();

        // assert
        expect(result['id'], equals('room_123'));
        expect(result['name'], equals('Test Room'));
        expect(result['creator_id'], equals('user_456'));
        expect(result['created_at'], equals('2024-01-01T12:00:00.000'));
        expect(result['type'], equals('group')); // default value
        expect(result['description'], isNull);
        expect(result['avatar_url'], isNull);
        expect(result['is_active'], equals(true)); // default value
        expect(result['participant_count'], equals(0)); // default value
        expect(result['last_activity'], isNull);
      });
    });

    group('fromEntity/toEntity', () {
      test('should convert between model and entity correctly', () {
        // arrange
        final entity = Room(
          id: 'room_123',
          name: 'Test Room',
          creatorId: 'user_456',
          createdAt: DateTime(2024, 1, 1, 12, 0),
          type: RoomType.group,
          description: 'A test room',
          avatarUrl: 'https://example.com/avatar.jpg',
          isActive: true,
          participantCount: 3,
          lastActivity: DateTime(2024, 1, 1, 15, 0),
        );

        // act
        final model = RoomModel.fromEntity(entity);
        final backToEntity = model.toEntity();

        // assert
        expect(model, isA<RoomModel>());
        expect(backToEntity.id, equals(entity.id));
        expect(backToEntity.name, equals(entity.name));
        expect(backToEntity.creatorId, equals(entity.creatorId));
        expect(backToEntity.createdAt, equals(entity.createdAt));
        expect(backToEntity.type, equals(entity.type));
        expect(backToEntity.description, equals(entity.description));
        expect(backToEntity.avatarUrl, equals(entity.avatarUrl));
        expect(backToEntity.isActive, equals(entity.isActive));
        expect(backToEntity.participantCount, equals(entity.participantCount));
        expect(backToEntity.lastActivity, equals(entity.lastActivity));
      });
    });

    group('JSON roundtrip', () {
      test('should maintain data integrity through JSON serialization roundtrip', () {
        // arrange
        final originalModel = RoomModel(
          id: 'room_123',
          name: 'Test Room',
          creatorId: 'user_456',
          createdAt: DateTime(2024, 1, 1, 12, 0),
          type: RoomType.channel,
          description: 'A test room for testing',
          avatarUrl: 'https://example.com/avatar.jpg',
          isActive: false,
          participantCount: 10,
          lastActivity: DateTime(2024, 1, 1, 18, 30),
        );

        // act
        final json = originalModel.toJson();
        final reconstructedModel = RoomModel.fromJson(json);

        // assert
        expect(reconstructedModel.id, equals(originalModel.id));
        expect(reconstructedModel.name, equals(originalModel.name));
        expect(reconstructedModel.creatorId, equals(originalModel.creatorId));
        expect(reconstructedModel.createdAt, equals(originalModel.createdAt));
        expect(reconstructedModel.type, equals(originalModel.type));
        expect(reconstructedModel.description, equals(originalModel.description));
        expect(reconstructedModel.avatarUrl, equals(originalModel.avatarUrl));
        expect(reconstructedModel.isActive, equals(originalModel.isActive));
        expect(reconstructedModel.participantCount, equals(originalModel.participantCount));
        expect(reconstructedModel.lastActivity, equals(originalModel.lastActivity));
      });
    });
  });
}