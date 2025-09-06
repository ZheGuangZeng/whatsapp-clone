import 'package:flutter_test/flutter_test.dart';

import 'package:whatsapp_clone/features/chat/domain/entities/message.dart';

void main() {
  group('Message', () {
    late DateTime testDate;

    setUp(() {
      testDate = DateTime.now();
    });

    test('should create message with required fields', () {
      // Arrange & Act
      final message = Message(
        id: 'message-123',
        roomId: 'room-123',
        userId: 'user-123',
        content: 'Hello, World!',
        createdAt: testDate,
        updatedAt: testDate,
      );

      // Assert
      expect(message.id, equals('message-123'));
      expect(message.roomId, equals('room-123'));
      expect(message.userId, equals('user-123'));
      expect(message.content, equals('Hello, World!'));
      expect(message.type, equals(MessageType.text)); // Default value
      expect(message.status, equals(MessageStatus.sent)); // Default value
      expect(message.createdAt, equals(testDate));
      expect(message.updatedAt, equals(testDate));
      expect(message.replyTo, isNull);
      expect(message.metadata, isEmpty);
      expect(message.editedAt, isNull);
      expect(message.deletedAt, isNull);
      expect(message.reactions, isEmpty);
    });

    test('should create message with all fields', () {
      // Arrange
      final editedDate = testDate.add(const Duration(minutes: 5));
      final reactions = [
        MessageReaction(
          id: 'reaction-1',
          messageId: 'message-123',
          userId: 'user-456',
          emoji: '👍',
          createdAt: testDate,
        ),
      ];

      // Act
      final message = Message(
        id: 'message-123',
        roomId: 'room-123',
        userId: 'user-123',
        content: 'Hello, World!',
        type: MessageType.image,
        replyTo: 'reply-message-456',
        metadata: {'width': 1920, 'height': 1080},
        editedAt: editedDate,
        createdAt: testDate,
        updatedAt: testDate,
        status: MessageStatus.read,
        reactions: reactions,
      );

      // Assert
      expect(message.type, equals(MessageType.image));
      expect(message.replyTo, equals('reply-message-456'));
      expect(message.metadata, equals({'width': 1920, 'height': 1080}));
      expect(message.editedAt, equals(editedDate));
      expect(message.status, equals(MessageStatus.read));
      expect(message.reactions, equals(reactions));
    });

    test('should have correct boolean getters', () {
      // Arrange
      final editedMessage = Message(
        id: 'message-1',
        roomId: 'room-1',
        userId: 'user-1',
        content: 'Edited message',
        editedAt: testDate,
        createdAt: testDate,
        updatedAt: testDate,
      );

      final deletedMessage = Message(
        id: 'message-2',
        roomId: 'room-1',
        userId: 'user-1',
        content: 'Deleted message',
        deletedAt: testDate,
        createdAt: testDate,
        updatedAt: testDate,
      );

      final replyMessage = Message(
        id: 'message-3',
        roomId: 'room-1',
        userId: 'user-1',
        content: 'Reply message',
        replyTo: 'original-message',
        createdAt: testDate,
        updatedAt: testDate,
      );

      final systemMessage = Message(
        id: 'message-4',
        roomId: 'room-1',
        userId: 'system',
        content: 'User joined the chat',
        type: MessageType.system,
        createdAt: testDate,
        updatedAt: testDate,
      );

      // Act & Assert
      expect(editedMessage.isEdited, isTrue);
      expect(deletedMessage.isDeleted, isTrue);
      expect(replyMessage.isReply, isTrue);
      expect(systemMessage.isSystemMessage, isTrue);

      // Test false cases
      final normalMessage = Message(
        id: 'message-5',
        roomId: 'room-1',
        userId: 'user-1',
        content: 'Normal message',
        createdAt: testDate,
        updatedAt: testDate,
      );

      expect(normalMessage.isEdited, isFalse);
      expect(normalMessage.isDeleted, isFalse);
      expect(normalMessage.isReply, isFalse);
      expect(normalMessage.isSystemMessage, isFalse);
    });

    test('should support equality comparison', () {
      // Arrange
      final message1 = Message(
        id: 'message-123',
        roomId: 'room-123',
        userId: 'user-123',
        content: 'Hello',
        createdAt: testDate,
        updatedAt: testDate,
      );

      final message2 = Message(
        id: 'message-123',
        roomId: 'room-123',
        userId: 'user-123',
        content: 'Hello',
        createdAt: testDate,
        updatedAt: testDate,
      );

      final message3 = Message(
        id: 'message-456',
        roomId: 'room-123',
        userId: 'user-123',
        content: 'Hello',
        createdAt: testDate,
        updatedAt: testDate,
      );

      // Act & Assert
      expect(message1, equals(message2));
      expect(message1, isNot(equals(message3)));
    });

    test('should create copy with updated fields', () {
      // Arrange
      final originalMessage = Message(
        id: 'message-123',
        roomId: 'room-123',
        userId: 'user-123',
        content: 'Original content',
        createdAt: testDate,
        updatedAt: testDate,
      );

      final editedDate = testDate.add(const Duration(minutes: 5));

      // Act
      final updatedMessage = originalMessage.copyWith(
        content: 'Updated content',
        editedAt: editedDate,
        status: MessageStatus.read,
      );

      // Assert
      expect(updatedMessage.id, equals(originalMessage.id));
      expect(updatedMessage.roomId, equals(originalMessage.roomId));
      expect(updatedMessage.userId, equals(originalMessage.userId));
      expect(updatedMessage.content, equals('Updated content'));
      expect(updatedMessage.editedAt, equals(editedDate));
      expect(updatedMessage.status, equals(MessageStatus.read));
      expect(updatedMessage.createdAt, equals(originalMessage.createdAt));
      expect(updatedMessage.updatedAt, equals(originalMessage.updatedAt));
      
      // Original message should remain unchanged
      expect(originalMessage.content, equals('Original content'));
      expect(originalMessage.editedAt, isNull);
      expect(originalMessage.status, equals(MessageStatus.sent));
    });
  });

  group('MessageType', () {
    test('should create from string value', () {
      // Act & Assert
      expect(MessageType.fromString('text'), equals(MessageType.text));
      expect(MessageType.fromString('image'), equals(MessageType.image));
      expect(MessageType.fromString('file'), equals(MessageType.file));
      expect(MessageType.fromString('audio'), equals(MessageType.audio));
      expect(MessageType.fromString('video'), equals(MessageType.video));
      expect(MessageType.fromString('system'), equals(MessageType.system));
    });

    test('should return text type for unknown values', () {
      // Act & Assert
      expect(MessageType.fromString('unknown'), equals(MessageType.text));
      expect(MessageType.fromString(''), equals(MessageType.text));
      expect(MessageType.fromString('invalid-type'), equals(MessageType.text));
    });

    test('should have correct string values', () {
      // Act & Assert
      expect(MessageType.text.value, equals('text'));
      expect(MessageType.image.value, equals('image'));
      expect(MessageType.file.value, equals('file'));
      expect(MessageType.audio.value, equals('audio'));
      expect(MessageType.video.value, equals('video'));
      expect(MessageType.system.value, equals('system'));
    });
  });

  group('MessageStatus', () {
    test('should create from string value', () {
      // Act & Assert
      expect(MessageStatus.fromString('sent'), equals(MessageStatus.sent));
      expect(MessageStatus.fromString('delivered'), equals(MessageStatus.delivered));
      expect(MessageStatus.fromString('read'), equals(MessageStatus.read));
    });

    test('should return sent status for unknown values', () {
      // Act & Assert
      expect(MessageStatus.fromString('unknown'), equals(MessageStatus.sent));
      expect(MessageStatus.fromString(''), equals(MessageStatus.sent));
      expect(MessageStatus.fromString('invalid-status'), equals(MessageStatus.sent));
    });

    test('should have correct string values', () {
      // Act & Assert
      expect(MessageStatus.sent.value, equals('sent'));
      expect(MessageStatus.delivered.value, equals('delivered'));
      expect(MessageStatus.read.value, equals('read'));
    });
  });

  group('MessageReaction', () {
    late DateTime testDate;

    setUp(() {
      testDate = DateTime.now();
    });

    test('should create reaction with all fields', () {
      // Arrange & Act
      final reaction = MessageReaction(
        id: 'reaction-123',
        messageId: 'message-456',
        userId: 'user-789',
        emoji: '👍',
        createdAt: testDate,
      );

      // Assert
      expect(reaction.id, equals('reaction-123'));
      expect(reaction.messageId, equals('message-456'));
      expect(reaction.userId, equals('user-789'));
      expect(reaction.emoji, equals('👍'));
      expect(reaction.createdAt, equals(testDate));
    });

    test('should support equality comparison', () {
      // Arrange
      final reaction1 = MessageReaction(
        id: 'reaction-123',
        messageId: 'message-456',
        userId: 'user-789',
        emoji: '👍',
        createdAt: testDate,
      );

      final reaction2 = MessageReaction(
        id: 'reaction-123',
        messageId: 'message-456',
        userId: 'user-789',
        emoji: '👍',
        createdAt: testDate,
      );

      final reaction3 = MessageReaction(
        id: 'reaction-456',
        messageId: 'message-456',
        userId: 'user-789',
        emoji: '👍',
        createdAt: testDate,
      );

      // Act & Assert
      expect(reaction1, equals(reaction2));
      expect(reaction1, isNot(equals(reaction3)));
    });

    test('should create copy with updated fields', () {
      // Arrange
      final originalReaction = MessageReaction(
        id: 'reaction-123',
        messageId: 'message-456',
        userId: 'user-789',
        emoji: '👍',
        createdAt: testDate,
      );

      final newDate = testDate.add(const Duration(minutes: 1));

      // Act
      final updatedReaction = originalReaction.copyWith(
        emoji: '❤️',
        createdAt: newDate,
      );

      // Assert
      expect(updatedReaction.id, equals(originalReaction.id));
      expect(updatedReaction.messageId, equals(originalReaction.messageId));
      expect(updatedReaction.userId, equals(originalReaction.userId));
      expect(updatedReaction.emoji, equals('❤️'));
      expect(updatedReaction.createdAt, equals(newDate));
      
      // Original reaction should remain unchanged
      expect(originalReaction.emoji, equals('👍'));
      expect(originalReaction.createdAt, equals(testDate));
    });
  });
}