import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_clone/features/chat/data/models/chat_message_model.dart';
import 'package:whatsapp_clone/features/chat/domain/entities/chat_message.dart';
import 'package:whatsapp_clone/features/messaging/domain/entities/message.dart';

void main() {
  group('ChatMessageModel', () {
    group('fromJson', () {
      test('should return a valid ChatMessageModel when JSON contains all required fields', () {
        // arrange
        final Map<String, dynamic> json = {
          'id': 'msg_123',
          'sender_id': 'user_456',
          'content': 'Hello, World!',
          'room_id': 'room_789',
          'timestamp': '2024-01-01T12:00:00.000Z',
          'message_type': 'text',
          'is_read': false,
          'reactions': {'👍': ['user_1', 'user_2'], '❤️': ['user_3']},
          'metadata': {'key1': 'value1', 'key2': 'value2'},
        };

        // act
        final result = ChatMessageModel.fromJson(json);

        // assert
        expect(result, isA<ChatMessageModel>());
        expect(result.id, equals('msg_123'));
        expect(result.senderId, equals('user_456'));
        expect(result.content, equals('Hello, World!'));
        expect(result.roomId, equals('room_789'));
        expect(result.timestamp, equals(DateTime.parse('2024-01-01T12:00:00.000Z')));
        expect(result.messageType, equals(MessageType.text));
        expect(result.isRead, equals(false));
        expect(result.reactions, equals({'👍': ['user_1', 'user_2'], '❤️': ['user_3']}));
        expect(result.metadata, equals({'key1': 'value1', 'key2': 'value2'}));
      });

      test('should return a valid ChatMessageModel with optional fields from JSON', () {
        // arrange
        final Map<String, dynamic> json = {
          'id': 'msg_456',
          'sender_id': 'user_789',
          'content': 'Reply message',
          'room_id': 'room_789',
          'timestamp': '2024-01-01T13:00:00.000Z',
          'message_type': 'text',
          'is_read': true,
          'thread_id': 'thread_123',
          'reply_to_message_id': 'msg_123',
          'edited_at': '2024-01-01T13:30:00.000Z',
          'is_deleted': false,
        };

        // act
        final result = ChatMessageModel.fromJson(json);

        // assert
        expect(result, isA<ChatMessageModel>());
        expect(result.threadId, equals('thread_123'));
        expect(result.replyToMessageId, equals('msg_123'));
        expect(result.editedAt, equals(DateTime.parse('2024-01-01T13:30:00.000Z')));
        expect(result.isDeleted, equals(false));
      });

      test('should handle different message types correctly', () {
        // arrange - text message
        final textJson = {
          'id': 'msg_123',
          'sender_id': 'user_456',
          'content': 'Hello, World!',
          'room_id': 'room_789',
          'timestamp': '2024-01-01T12:00:00.000Z',
          'message_type': 'text',
          'is_read': false,
        };

        // arrange - image message
        final imageJson = {
          'id': 'msg_124',
          'sender_id': 'user_456',
          'content': 'image.jpg',
          'room_id': 'room_789',
          'timestamp': '2024-01-01T12:01:00.000Z',
          'message_type': 'image',
          'is_read': false,
        };

        // arrange - file message
        final fileJson = {
          'id': 'msg_125',
          'sender_id': 'user_456',
          'content': 'document.pdf',
          'room_id': 'room_789',
          'timestamp': '2024-01-01T12:02:00.000Z',
          'message_type': 'file',
          'is_read': false,
        };

        // act
        final textResult = ChatMessageModel.fromJson(textJson);
        final imageResult = ChatMessageModel.fromJson(imageJson);
        final fileResult = ChatMessageModel.fromJson(fileJson);

        // assert
        expect(textResult.messageType, equals(MessageType.text));
        expect(imageResult.messageType, equals(MessageType.image));
        expect(fileResult.messageType, equals(MessageType.file));
      });

      test('should validate required fields are present', () {
        // arrange
        final invalidJson = {
          'sender_id': 'user_456',
          'content': 'Hello, World!',
          'room_id': 'room_789',
          'timestamp': '2024-01-01T12:00:00.000Z',
        };

        // act & assert
        expect(() => ChatMessageModel.fromJson(invalidJson), throwsA(isA<Exception>()));
      });
    });

    group('toJson', () {
      test('should return valid JSON map with all fields', () {
        // arrange
        final model = ChatMessageModel(
          id: 'msg_123',
          senderId: 'user_456',
          content: 'Hello, World!',
          roomId: 'room_789',
          timestamp: DateTime(2024, 1, 1, 12, 0),
          messageType: MessageType.text,
          isRead: false,
          reactions: const {'👍': ['user_1', 'user_2'], '❤️': ['user_3']},
          metadata: const {'key1': 'value1', 'key2': 'value2'},
        );

        // act
        final result = model.toJson();

        // assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['id'], equals('msg_123'));
        expect(result['sender_id'], equals('user_456'));
        expect(result['content'], equals('Hello, World!'));
        expect(result['room_id'], equals('room_789'));
        expect(result['timestamp'], equals('2024-01-01T12:00:00.000'));
        expect(result['message_type'], equals('text'));
        expect(result['is_read'], equals(false));
        expect(result['reactions'], equals({'👍': ['user_1', 'user_2'], '❤️': ['user_3']}));
        expect(result['metadata'], equals({'key1': 'value1', 'key2': 'value2'}));
      });
    });

    group('fromEntity/toEntity', () {
      test('should convert between model and entity correctly', () {
        // arrange
        final entity = ChatMessage(
          id: 'msg_123',
          senderId: 'user_456',
          content: 'Hello, World!',
          roomId: 'room_789',
          timestamp: DateTime(2024, 1, 1, 12, 0),
          messageType: MessageType.text,
          isRead: false,
          reactions: const {'👍': ['user_1', 'user_2']},
          metadata: const {'key1': 'value1'},
        );

        // act
        final model = ChatMessageModel.fromEntity(entity);
        final backToEntity = model.toEntity();

        // assert
        expect(model, isA<ChatMessageModel>());
        expect(backToEntity.id, equals(entity.id));
        expect(backToEntity.senderId, equals(entity.senderId));
        expect(backToEntity.content, equals(entity.content));
        expect(backToEntity.roomId, equals(entity.roomId));
        expect(backToEntity.timestamp, equals(entity.timestamp));
        expect(backToEntity.messageType, equals(entity.messageType));
        expect(backToEntity.isRead, equals(entity.isRead));
        expect(backToEntity.reactions, equals(entity.reactions));
        expect(backToEntity.metadata, equals(entity.metadata));
      });
    });

    group('JSON roundtrip', () {
      test('should maintain data integrity through JSON serialization roundtrip', () {
        // arrange
        final originalModel = ChatMessageModel(
          id: 'msg_123',
          senderId: 'user_456',
          content: 'Hello, World!',
          roomId: 'room_789',
          timestamp: DateTime(2024, 1, 1, 12, 0),
          messageType: MessageType.text,
          isRead: false,
          threadId: 'thread_123',
          replyToMessageId: 'msg_parent',
          reactions: const {'👍': ['user_1', 'user_2'], '❤️': ['user_3']},
          editedAt: DateTime(2024, 1, 1, 13, 30),
          isDeleted: false,
          metadata: const {'key1': 'value1', 'key2': 'value2'},
        );

        // act
        final json = originalModel.toJson();
        final reconstructedModel = ChatMessageModel.fromJson(json);

        // assert
        expect(reconstructedModel.id, equals(originalModel.id));
        expect(reconstructedModel.senderId, equals(originalModel.senderId));
        expect(reconstructedModel.content, equals(originalModel.content));
        expect(reconstructedModel.roomId, equals(originalModel.roomId));
        expect(reconstructedModel.timestamp, equals(originalModel.timestamp));
        expect(reconstructedModel.messageType, equals(originalModel.messageType));
        expect(reconstructedModel.isRead, equals(originalModel.isRead));
        expect(reconstructedModel.threadId, equals(originalModel.threadId));
        expect(reconstructedModel.replyToMessageId, equals(originalModel.replyToMessageId));
        expect(reconstructedModel.reactions, equals(originalModel.reactions));
        expect(reconstructedModel.editedAt, equals(originalModel.editedAt));
        expect(reconstructedModel.isDeleted, equals(originalModel.isDeleted));
        expect(reconstructedModel.metadata, equals(originalModel.metadata));
      });
    });
  });
}