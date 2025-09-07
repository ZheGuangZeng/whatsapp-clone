import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_clone/features/chat/domain/entities/chat_message.dart';
import 'package:whatsapp_clone/features/messaging/domain/entities/message.dart';

void main() {
  group('ChatMessage Entity Tests', () {
    test('should create a valid ChatMessage with required fields', () {
      // Arrange
      const messageId = 'message_123';
      const senderId = 'user_123';
      const content = 'Hello, world!';
      const roomId = 'room_123';
      final timestamp = DateTime.now();
      
      // Act
      final chatMessage = ChatMessage(
        id: messageId,
        senderId: senderId,
        content: content,
        roomId: roomId,
        timestamp: timestamp,
      );
      
      // Assert
      expect(chatMessage.id, equals(messageId));
      expect(chatMessage.senderId, equals(senderId));
      expect(chatMessage.content, equals(content));
      expect(chatMessage.roomId, equals(roomId));
      expect(chatMessage.timestamp, equals(timestamp));
      expect(chatMessage.messageType, equals(MessageType.text)); // default
      expect(chatMessage.isRead, isFalse); // default
      expect(chatMessage.threadId, isNull);
      expect(chatMessage.replyToMessageId, isNull);
      expect(chatMessage.reactions, isEmpty);
      expect(chatMessage.editedAt, isNull);
      expect(chatMessage.isDeleted, isFalse); // default
      expect(chatMessage.metadata, isEmpty);
    });

    test('should create a ChatMessage with all optional fields', () {
      // Arrange
      const messageId = 'message_123';
      const senderId = 'user_123';
      const content = 'Hello, world!';
      const roomId = 'room_123';
      const threadId = 'thread_123';
      const replyToMessageId = 'reply_to_123';
      final timestamp = DateTime.now();
      final editedAt = DateTime.now();
      const reactions = {'👍': ['user_456'], '❤️': ['user_789']};
      const metadata = {'attachment_type': 'image', 'file_size': '1024'};
      
      // Act
      final chatMessage = ChatMessage(
        id: messageId,
        senderId: senderId,
        content: content,
        roomId: roomId,
        timestamp: timestamp,
        messageType: MessageType.image,
        isRead: true,
        threadId: threadId,
        replyToMessageId: replyToMessageId,
        reactions: reactions,
        editedAt: editedAt,
        isDeleted: true,
        metadata: metadata,
      );
      
      // Assert
      expect(chatMessage.id, equals(messageId));
      expect(chatMessage.senderId, equals(senderId));
      expect(chatMessage.content, equals(content));
      expect(chatMessage.roomId, equals(roomId));
      expect(chatMessage.timestamp, equals(timestamp));
      expect(chatMessage.messageType, equals(MessageType.image));
      expect(chatMessage.isRead, isTrue);
      expect(chatMessage.threadId, equals(threadId));
      expect(chatMessage.replyToMessageId, equals(replyToMessageId));
      expect(chatMessage.reactions, equals(reactions));
      expect(chatMessage.editedAt, equals(editedAt));
      expect(chatMessage.isDeleted, isTrue);
      expect(chatMessage.metadata, equals(metadata));
    });

    test('should support equality comparison', () {
      // Arrange
      final timestamp = DateTime.now();
      final chatMessage1 = ChatMessage(
        id: 'message_123',
        senderId: 'user_123',
        content: 'Hello',
        roomId: 'room_123',
        timestamp: timestamp,
      );
      final chatMessage2 = ChatMessage(
        id: 'message_123',
        senderId: 'user_123',
        content: 'Hello',
        roomId: 'room_123',
        timestamp: timestamp,
      );
      final chatMessage3 = ChatMessage(
        id: 'message_456',
        senderId: 'user_123',
        content: 'Hello',
        roomId: 'room_123',
        timestamp: timestamp,
      );
      
      // Act & Assert
      expect(chatMessage1, equals(chatMessage2));
      expect(chatMessage1, isNot(equals(chatMessage3)));
      expect(chatMessage1.hashCode, equals(chatMessage2.hashCode));
      expect(chatMessage1.hashCode, isNot(equals(chatMessage3.hashCode)));
    });

    test('should create a copy with updated fields', () {
      // Arrange
      final originalMessage = ChatMessage(
        id: 'message_123',
        senderId: 'user_123',
        content: 'Original content',
        roomId: 'room_123',
        timestamp: DateTime.now(),
        isRead: false,
        reactions: const {'👍': ['user_456']},
      );
      final editedAt = DateTime.now();
      
      // Act
      final updatedMessage = originalMessage.copyWith(
        content: 'Updated content',
        isRead: true,
        editedAt: editedAt,
        reactions: const {'👍': ['user_456'], '❤️': ['user_789']},
      );
      
      // Assert
      expect(updatedMessage.id, equals(originalMessage.id));
      expect(updatedMessage.senderId, equals(originalMessage.senderId));
      expect(updatedMessage.content, equals('Updated content'));
      expect(updatedMessage.roomId, equals(originalMessage.roomId));
      expect(updatedMessage.timestamp, equals(originalMessage.timestamp));
      expect(updatedMessage.isRead, isTrue);
      expect(updatedMessage.editedAt, equals(editedAt));
      expect(updatedMessage.reactions, equals(const {'👍': ['user_456'], '❤️': ['user_789']}));
    });

    test('should validate message ID is not empty', () {
      // Act & Assert
      expect(
        () => ChatMessage(
          id: '',
          senderId: 'user_123',
          content: 'Hello',
          roomId: 'room_123',
          timestamp: DateTime.now(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('should validate sender ID is not empty', () {
      // Act & Assert
      expect(
        () => ChatMessage(
          id: 'message_123',
          senderId: '',
          content: 'Hello',
          roomId: 'room_123',
          timestamp: DateTime.now(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('should validate room ID is not empty', () {
      // Act & Assert
      expect(
        () => ChatMessage(
          id: 'message_123',
          senderId: 'user_123',
          content: 'Hello',
          roomId: '',
          timestamp: DateTime.now(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('should handle reaction management correctly', () {
      // Arrange
      final message = ChatMessage(
        id: 'message_123',
        senderId: 'user_123',
        content: 'Hello',
        roomId: 'room_123',
        timestamp: DateTime.now(),
        reactions: const {'👍': ['user_456']},
      );
      
      // Act - Add new reaction
      final withNewReaction = message.copyWith(
        reactions: const {
          '👍': ['user_456'],
          '❤️': ['user_789', 'user_101'],
        },
      );
      
      // Assert
      expect(withNewReaction.reactions.keys, hasLength(2));
      expect(withNewReaction.reactions['👍'], equals(['user_456']));
      expect(withNewReaction.reactions['❤️'], equals(['user_789', 'user_101']));
      expect(message.reactions.keys, hasLength(1)); // original unchanged
    });

    test('should handle thread message correctly', () {
      // Arrange
      final threadMessage = ChatMessage(
        id: 'message_123',
        senderId: 'user_123',
        content: 'Thread reply',
        roomId: 'room_123',
        timestamp: DateTime.now(),
        threadId: 'thread_456',
        replyToMessageId: 'message_root',
      );
      
      // Act & Assert
      expect(threadMessage.threadId, equals('thread_456'));
      expect(threadMessage.replyToMessageId, equals('message_root'));
      expect(threadMessage.isThreadMessage, isTrue);
    });

    test('should identify non-thread message correctly', () {
      // Arrange
      final regularMessage = ChatMessage(
        id: 'message_123',
        senderId: 'user_123',
        content: 'Regular message',
        roomId: 'room_123',
        timestamp: DateTime.now(),
      );
      
      // Act & Assert
      expect(regularMessage.threadId, isNull);
      expect(regularMessage.replyToMessageId, isNull);
      expect(regularMessage.isThreadMessage, isFalse);
    });

    test('should handle message editing correctly', () {
      // Arrange
      final originalMessage = ChatMessage(
        id: 'message_123',
        senderId: 'user_123',
        content: 'Original content',
        roomId: 'room_123',
        timestamp: DateTime.now(),
      );
      final editTime = DateTime.now();
      
      // Act
      final editedMessage = originalMessage.copyWith(
        content: 'Edited content',
        editedAt: editTime,
      );
      
      // Assert
      expect(editedMessage.content, equals('Edited content'));
      expect(editedMessage.editedAt, equals(editTime));
      expect(editedMessage.isEdited, isTrue);
      expect(originalMessage.isEdited, isFalse); // original unchanged
    });

    test('should handle message deletion correctly', () {
      // Arrange
      final message = ChatMessage(
        id: 'message_123',
        senderId: 'user_123',
        content: 'To be deleted',
        roomId: 'room_123',
        timestamp: DateTime.now(),
        isDeleted: false,
      );
      
      // Act
      final deletedMessage = message.copyWith(isDeleted: true);
      
      // Assert
      expect(deletedMessage.isDeleted, isTrue);
      expect(message.isDeleted, isFalse); // original unchanged
    });

    test('should handle metadata correctly', () {
      // Arrange
      final message = ChatMessage(
        id: 'message_123',
        senderId: 'user_123',
        content: 'Message with metadata',
        roomId: 'room_123',
        timestamp: DateTime.now(),
        metadata: const {'type': 'image', 'width': '100', 'height': '200'},
      );
      
      // Act & Assert
      expect(message.metadata['type'], equals('image'));
      expect(message.metadata['width'], equals('100'));
      expect(message.metadata['height'], equals('200'));
      expect(message.metadata.keys, hasLength(3));
    });
  });
}