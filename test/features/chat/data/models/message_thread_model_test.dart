import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_clone/features/chat/data/models/message_thread_model.dart';
import 'package:whatsapp_clone/features/chat/domain/entities/message_thread.dart';
import 'package:whatsapp_clone/features/messaging/domain/entities/message.dart';

void main() {
  group('MessageThreadModel', () {
    final testMessage = Message(
      id: 'message_1',
      senderId: 'user_1',
      content: 'Root message content',
      timestamp: DateTime.parse('2024-01-01T12:00:00Z'),
      roomId: 'room_1',
      messageType: MessageType.text,
      isRead: true,
    );

    final testLastReply = Message(
      id: 'message_2',
      senderId: 'user_2',
      content: 'Last reply content',
      timestamp: DateTime.parse('2024-01-01T12:30:00Z'),
      roomId: 'room_1',
      messageType: MessageType.text,
      isRead: false,
    );

    final testMessageThreadModel = MessageThreadModel(
      id: 'thread_1',
      roomId: 'room_1',
      rootMessage: testMessage,
      createdAt: DateTime.parse('2024-01-01T12:00:00Z'),
      isActive: true,
      replyCount: 5,
      lastReply: testLastReply,
      participants: const ['user_1', 'user_2', 'user_3'],
    );

    group('fromJson', () {
      test('should return a valid MessageThreadModel when JSON contains all required fields', () {
        // Arrange
        final json = {
          'id': 'thread_1',
          'room_id': 'room_1',
          'root_message': {
            'id': 'message_1',
            'sender_id': 'user_1',
            'content': 'Root message content',
            'timestamp': '2024-01-01T12:00:00.000Z',
            'room_id': 'room_1',
            'message_type': 'text',
            'is_read': true,
          },
          'created_at': '2024-01-01T12:00:00.000Z',
          'is_active': true,
          'reply_count': 5,
          'last_reply': {
            'id': 'message_2',
            'sender_id': 'user_2',
            'content': 'Last reply content',
            'timestamp': '2024-01-01T12:30:00.000Z',
            'room_id': 'room_1',
            'message_type': 'text',
            'is_read': false,
          },
          'participants': ['user_1', 'user_2', 'user_3'],
        };

        // Act
        final result = MessageThreadModel.fromJson(json);

        // Assert
        expect(result, isA<MessageThreadModel>());
        expect(result.id, equals('thread_1'));
        expect(result.roomId, equals('room_1'));
        expect(result.rootMessage.id, equals('message_1'));
        expect(result.rootMessage.content, equals('Root message content'));
        expect(result.createdAt, equals(DateTime.parse('2024-01-01T12:00:00.000Z')));
        expect(result.isActive, equals(true));
        expect(result.replyCount, equals(5));
        expect(result.lastReply?.id, equals('message_2'));
        expect(result.participants, containsAll(['user_1', 'user_2', 'user_3']));
      });

      test('should return a valid MessageThreadModel with minimal required fields', () {
        // Arrange
        final json = {
          'id': 'thread_1',
          'room_id': 'room_1',
          'root_message': {
            'id': 'message_1',
            'sender_id': 'user_1',
            'content': 'Root message content',
            'timestamp': '2024-01-01T12:00:00.000Z',
            'room_id': 'room_1',
            'message_type': 'text',
            'is_read': false,
          },
          'created_at': '2024-01-01T12:00:00.000Z',
        };

        // Act
        final result = MessageThreadModel.fromJson(json);

        // Assert
        expect(result, isA<MessageThreadModel>());
        expect(result.id, equals('thread_1'));
        expect(result.roomId, equals('room_1'));
        expect(result.rootMessage.id, equals('message_1'));
        expect(result.createdAt, equals(DateTime.parse('2024-01-01T12:00:00.000Z')));
        expect(result.isActive, equals(true)); // default value
        expect(result.replyCount, equals(0)); // default value
        expect(result.lastReply, isNull);
        expect(result.participants, isEmpty); // default value
      });

      test('should handle different message types correctly', () {
        // Arrange
        final json = {
          'id': 'thread_1',
          'room_id': 'room_1',
          'root_message': {
            'id': 'message_1',
            'sender_id': 'user_1',
            'content': 'Image message',
            'timestamp': '2024-01-01T12:00:00.000Z',
            'room_id': 'room_1',
            'message_type': 'image',
            'is_read': false,
          },
          'created_at': '2024-01-01T12:00:00.000Z',
        };

        // Act
        final result = MessageThreadModel.fromJson(json);

        // Assert
        expect(result.rootMessage.messageType, equals(MessageType.image));
      });

      test('should validate required fields are present', () {
        // Test missing id
        expect(
          () => MessageThreadModel.fromJson(const {'room_id': 'room_1'}),
          throwsException,
        );

        // Test missing room_id
        expect(
          () => MessageThreadModel.fromJson(const {'id': 'thread_1'}),
          throwsException,
        );

        // Test missing root_message
        expect(
          () => MessageThreadModel.fromJson(const {
            'id': 'thread_1',
            'room_id': 'room_1',
            'created_at': '2024-01-01T12:00:00.000Z',
          }),
          throwsException,
        );

        // Test missing created_at
        expect(
          () => MessageThreadModel.fromJson(const {
            'id': 'thread_1',
            'room_id': 'room_1',
            'root_message': {
              'id': 'message_1',
              'sender_id': 'user_1',
              'content': 'Content',
              'timestamp': '2024-01-01T12:00:00.000Z',
              'room_id': 'room_1',
            },
          }),
          throwsException,
        );
      });

      test('should handle null optional fields correctly', () {
        // Arrange
        final json = {
          'id': 'thread_1',
          'room_id': 'room_1',
          'root_message': {
            'id': 'message_1',
            'sender_id': 'user_1',
            'content': 'Root message content',
            'timestamp': '2024-01-01T12:00:00.000Z',
            'room_id': 'room_1',
            'message_type': 'text',
            'is_read': false,
          },
          'created_at': '2024-01-01T12:00:00.000Z',
          'is_active': null,
          'reply_count': null,
          'last_reply': null,
          'participants': null,
        };

        // Act
        final result = MessageThreadModel.fromJson(json);

        // Assert
        expect(result.isActive, equals(true)); // default value
        expect(result.replyCount, equals(0)); // default value
        expect(result.lastReply, isNull);
        expect(result.participants, isEmpty);
      });
    });

    group('toJson', () {
      test('should return valid JSON map with all fields', () {
        // Act
        final result = testMessageThreadModel.toJson();

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['id'], equals('thread_1'));
        expect(result['room_id'], equals('room_1'));
        expect(result['root_message'], isA<Map<String, dynamic>>());
        expect(result['root_message']['id'], equals('message_1'));
        expect(result['created_at'], equals('2024-01-01T12:00:00.000Z'));
        expect(result['is_active'], equals(true));
        expect(result['reply_count'], equals(5));
        expect(result['last_reply'], isA<Map<String, dynamic>>());
        expect(result['last_reply']['id'], equals('message_2'));
        expect(result['participants'], containsAll(['user_1', 'user_2', 'user_3']));
      });

      test('should return valid JSON map with minimal fields', () {
        // Arrange
        final minimalModel = MessageThreadModel(
          id: 'thread_1',
          roomId: 'room_1',
          rootMessage: testMessage,
          createdAt: DateTime.parse('2024-01-01T12:00:00Z'),
        );

        // Act
        final result = minimalModel.toJson();

        // Assert
        expect(result['id'], equals('thread_1'));
        expect(result['room_id'], equals('room_1'));
        expect(result['root_message'], isA<Map<String, dynamic>>());
        expect(result['created_at'], equals('2024-01-01T12:00:00.000Z'));
        expect(result['is_active'], equals(true));
        expect(result['reply_count'], equals(0));
        expect(result['last_reply'], isNull);
        expect(result['participants'], isEmpty);
      });
    });

    group('fromEntity/toEntity', () {
      test('should convert between model and entity correctly', () {
        // Arrange
        final entity = MessageThread(
          id: 'thread_1',
          roomId: 'room_1',
          rootMessage: testMessage,
          createdAt: DateTime.parse('2024-01-01T12:00:00Z'),
          isActive: true,
          replyCount: 5,
          lastReply: testLastReply,
          participants: const ['user_1', 'user_2', 'user_3'],
        );

        // Act - Convert entity to model
        final model = MessageThreadModel.fromEntity(entity);
        
        // Convert model back to entity
        final resultEntity = model.toEntity();

        // Assert
        expect(model, isA<MessageThreadModel>());
        expect(model.id, equals(entity.id));
        expect(model.roomId, equals(entity.roomId));
        expect(model.rootMessage, equals(entity.rootMessage));
        expect(model.createdAt, equals(entity.createdAt));
        expect(model.isActive, equals(entity.isActive));
        expect(model.replyCount, equals(entity.replyCount));
        expect(model.lastReply, equals(entity.lastReply));
        expect(model.participants, equals(entity.participants));

        expect(resultEntity, isA<MessageThread>());
        expect(resultEntity.id, equals(entity.id));
        expect(resultEntity.roomId, equals(entity.roomId));
        expect(resultEntity.rootMessage, equals(entity.rootMessage));
        expect(resultEntity.createdAt, equals(entity.createdAt));
        expect(resultEntity.isActive, equals(entity.isActive));
        expect(resultEntity.replyCount, equals(entity.replyCount));
        expect(resultEntity.lastReply, equals(entity.lastReply));
        expect(resultEntity.participants, equals(entity.participants));
      });
    });

    group('JSON roundtrip', () {
      test('should maintain data integrity through JSON serialization roundtrip', () {
        // Act
        final json = testMessageThreadModel.toJson();
        final deserializedModel = MessageThreadModel.fromJson(json);

        // Assert
        expect(deserializedModel.id, equals(testMessageThreadModel.id));
        expect(deserializedModel.roomId, equals(testMessageThreadModel.roomId));
        expect(deserializedModel.rootMessage.id, equals(testMessageThreadModel.rootMessage.id));
        expect(deserializedModel.rootMessage.content, equals(testMessageThreadModel.rootMessage.content));
        expect(deserializedModel.createdAt, equals(testMessageThreadModel.createdAt));
        expect(deserializedModel.isActive, equals(testMessageThreadModel.isActive));
        expect(deserializedModel.replyCount, equals(testMessageThreadModel.replyCount));
        expect(deserializedModel.lastReply?.id, equals(testMessageThreadModel.lastReply?.id));
        expect(deserializedModel.participants, equals(testMessageThreadModel.participants));
      });
    });
  });
}