import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_clone/features/chat/data/models/participant_model.dart';
import 'package:whatsapp_clone/features/chat/domain/entities/participant.dart';
import 'package:whatsapp_clone/features/chat/domain/entities/participant_role.dart';

void main() {
  group('ParticipantModel', () {
    group('fromJson', () {
      test('should return a valid ParticipantModel when JSON contains all required fields', () {
        // arrange
        final Map<String, dynamic> json = {
          'id': 'participant_123',
          'user_id': 'user_456',
          'room_id': 'room_789',
          'joined_at': '2024-01-01T12:00:00.000Z',
          'role': 'admin',
          'is_active': true,
          'last_activity': '2024-01-01T15:00:00.000Z',
          'permissions': ['manage_messages', 'ban_users', 'edit_room'],
        };

        // act
        final result = ParticipantModel.fromJson(json);

        // assert
        expect(result, isA<ParticipantModel>());
        expect(result.id, equals('participant_123'));
        expect(result.userId, equals('user_456'));
        expect(result.roomId, equals('room_789'));
        expect(result.joinedAt, equals(DateTime.parse('2024-01-01T12:00:00.000Z')));
        expect(result.role, equals(ParticipantRole.admin));
        expect(result.isActive, equals(true));
        expect(result.lastActivity, equals(DateTime.parse('2024-01-01T15:00:00.000Z')));
        expect(result.permissions, equals(['manage_messages', 'ban_users', 'edit_room']));
      });

      test('should return a valid ParticipantModel with minimal required fields', () {
        // arrange
        final Map<String, dynamic> json = {
          'id': 'participant_456',
          'user_id': 'user_789',
          'room_id': 'room_123',
          'joined_at': '2024-01-01T12:00:00.000Z',
        };

        // act
        final result = ParticipantModel.fromJson(json);

        // assert
        expect(result, isA<ParticipantModel>());
        expect(result.id, equals('participant_456'));
        expect(result.userId, equals('user_789'));
        expect(result.roomId, equals('room_123'));
        expect(result.joinedAt, equals(DateTime.parse('2024-01-01T12:00:00.000Z')));
        expect(result.role, equals(ParticipantRole.member)); // default value
        expect(result.isActive, equals(true)); // default value
        expect(result.lastActivity, isNull);
        expect(result.permissions, equals(const <String>[])); // default value
      });

      test('should handle different participant roles correctly', () {
        // arrange - member role
        final memberJson = {
          'id': 'participant_member',
          'user_id': 'user_123',
          'room_id': 'room_123',
          'joined_at': '2024-01-01T12:00:00.000Z',
          'role': 'member',
        };

        // arrange - moderator role
        final moderatorJson = {
          'id': 'participant_mod',
          'user_id': 'user_123',
          'room_id': 'room_123',
          'joined_at': '2024-01-01T12:00:00.000Z',
          'role': 'moderator',
        };

        // arrange - admin role
        final adminJson = {
          'id': 'participant_admin',
          'user_id': 'user_123',
          'room_id': 'room_123',
          'joined_at': '2024-01-01T12:00:00.000Z',
          'role': 'admin',
        };

        // act
        final memberResult = ParticipantModel.fromJson(memberJson);
        final moderatorResult = ParticipantModel.fromJson(moderatorJson);
        final adminResult = ParticipantModel.fromJson(adminJson);

        // assert
        expect(memberResult.role, equals(ParticipantRole.member));
        expect(moderatorResult.role, equals(ParticipantRole.moderator));
        expect(adminResult.role, equals(ParticipantRole.admin));
      });

      test('should validate required fields are present', () {
        // arrange
        final invalidJson = {
          'user_id': 'user_456',
          'room_id': 'room_789',
          'joined_at': '2024-01-01T12:00:00.000Z',
        };

        // act & assert
        expect(() => ParticipantModel.fromJson(invalidJson), throwsA(isA<Exception>()));
      });

      test('should handle null optional fields correctly', () {
        // arrange
        final Map<String, dynamic> json = {
          'id': 'participant_123',
          'user_id': 'user_456',
          'room_id': 'room_789',
          'joined_at': '2024-01-01T12:00:00.000Z',
          'role': null,
          'is_active': null,
          'last_activity': null,
          'permissions': null,
        };

        // act
        final result = ParticipantModel.fromJson(json);

        // assert
        expect(result.role, equals(ParticipantRole.member)); // default value when null
        expect(result.isActive, equals(true)); // default value when null
        expect(result.lastActivity, isNull);
        expect(result.permissions, equals(const <String>[])); // default value when null
      });

      test('should handle permissions as list of strings', () {
        // arrange
        final Map<String, dynamic> json = {
          'id': 'participant_123',
          'user_id': 'user_456',
          'room_id': 'room_789',
          'joined_at': '2024-01-01T12:00:00.000Z',
          'permissions': ['read', 'write', 'moderate'],
        };

        // act
        final result = ParticipantModel.fromJson(json);

        // assert
        expect(result.permissions, equals(['read', 'write', 'moderate']));
      });
    });

    group('toJson', () {
      test('should return valid JSON map with all fields', () {
        // arrange
        final model = ParticipantModel(
          id: 'participant_123',
          userId: 'user_456',
          roomId: 'room_789',
          joinedAt: DateTime(2024, 1, 1, 12, 0),
          role: ParticipantRole.admin,
          isActive: true,
          lastActivity: DateTime(2024, 1, 1, 15, 0),
          permissions: const ['manage_messages', 'ban_users'],
        );

        // act
        final result = model.toJson();

        // assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['id'], equals('participant_123'));
        expect(result['user_id'], equals('user_456'));
        expect(result['room_id'], equals('room_789'));
        expect(result['joined_at'], equals('2024-01-01T12:00:00.000'));
        expect(result['role'], equals('admin'));
        expect(result['is_active'], equals(true));
        expect(result['last_activity'], equals('2024-01-01T15:00:00.000'));
        expect(result['permissions'], equals(['manage_messages', 'ban_users']));
      });

      test('should return valid JSON map with minimal fields', () {
        // arrange
        final model = ParticipantModel(
          id: 'participant_123',
          userId: 'user_456',
          roomId: 'room_789',
          joinedAt: DateTime(2024, 1, 1, 12, 0),
        );

        // act
        final result = model.toJson();

        // assert
        expect(result['id'], equals('participant_123'));
        expect(result['user_id'], equals('user_456'));
        expect(result['room_id'], equals('room_789'));
        expect(result['joined_at'], equals('2024-01-01T12:00:00.000'));
        expect(result['role'], equals('member')); // default value
        expect(result['is_active'], equals(true)); // default value
        expect(result['last_activity'], isNull);
        expect(result['permissions'], equals(const <String>[])); // default value
      });
    });

    group('fromEntity/toEntity', () {
      test('should convert between model and entity correctly', () {
        // arrange
        final entity = Participant(
          id: 'participant_123',
          userId: 'user_456',
          roomId: 'room_789',
          joinedAt: DateTime(2024, 1, 1, 12, 0),
          role: ParticipantRole.moderator,
          isActive: false,
          lastActivity: DateTime(2024, 1, 1, 18, 0),
          permissions: const ['moderate', 'mute'],
        );

        // act
        final model = ParticipantModel.fromEntity(entity);
        final backToEntity = model.toEntity();

        // assert
        expect(model, isA<ParticipantModel>());
        expect(backToEntity.id, equals(entity.id));
        expect(backToEntity.userId, equals(entity.userId));
        expect(backToEntity.roomId, equals(entity.roomId));
        expect(backToEntity.joinedAt, equals(entity.joinedAt));
        expect(backToEntity.role, equals(entity.role));
        expect(backToEntity.isActive, equals(entity.isActive));
        expect(backToEntity.lastActivity, equals(entity.lastActivity));
        expect(backToEntity.permissions, equals(entity.permissions));
      });
    });

    group('JSON roundtrip', () {
      test('should maintain data integrity through JSON serialization roundtrip', () {
        // arrange
        final originalModel = ParticipantModel(
          id: 'participant_123',
          userId: 'user_456',
          roomId: 'room_789',
          joinedAt: DateTime(2024, 1, 1, 12, 0),
          role: ParticipantRole.moderator,
          isActive: false,
          lastActivity: DateTime(2024, 1, 1, 16, 30),
          permissions: const ['moderate', 'manage_messages', 'kick_users'],
        );

        // act
        final json = originalModel.toJson();
        final reconstructedModel = ParticipantModel.fromJson(json);

        // assert
        expect(reconstructedModel.id, equals(originalModel.id));
        expect(reconstructedModel.userId, equals(originalModel.userId));
        expect(reconstructedModel.roomId, equals(originalModel.roomId));
        expect(reconstructedModel.joinedAt, equals(originalModel.joinedAt));
        expect(reconstructedModel.role, equals(originalModel.role));
        expect(reconstructedModel.isActive, equals(originalModel.isActive));
        expect(reconstructedModel.lastActivity, equals(originalModel.lastActivity));
        expect(reconstructedModel.permissions, equals(originalModel.permissions));
      });
    });
  });
}