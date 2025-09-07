import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_clone/features/messaging/domain/entities/message.dart';

void main() {
  group('Message Entity', () {
    // Test data
    const testId = 'message-123';
    const testUserId = 'user-456';
    const testContent = 'Hello, World!';
    final testCreatedAt = DateTime(2024, 1, 15, 10, 30);
    const testRoomId = 'room-789';

    final testMessage = Message(
      id: testId,
      userId: testUserId,
      content: testContent,
      createdAt: testCreatedAt,
      roomId: testRoomId,
    );

    group('Constructor', () {
      test('should create message with all required fields', () {
        // Assert
        expect(testMessage.id, testId);
        expect(testMessage.userId, testUserId);
        expect(testMessage.content, testContent);
        expect(testMessage.createdAt, testCreatedAt);
        expect(testMessage.roomId, testRoomId);
      });

      test('should have default values for optional fields', () {
        // Assert
        expect(testMessage.type, MessageType.text);
        expect(testMessage.replyTo, null);
        expect(testMessage.metadata, const {});
        expect(testMessage.editedAt, null);
        expect(testMessage.deletedAt, null);
      });

      test('should accept custom values for optional fields', () {
        // Arrange & Act
        final message = Message(
          id: testId,
          senderId: testSenderId,
          content: testContent,
          timestamp: testTimestamp,
          roomId: testRoomId,
          messageType: MessageType.image,
          isRead: true,
        );

        // Assert
        expect(message.messageType, MessageType.image);
        expect(message.isRead, true);
      });
    });

    group('Equality', () {
      test('should be equal when all properties match', () {
        // Arrange
        final message1 = Message(
          id: testId,
          senderId: testSenderId,
          content: testContent,
          timestamp: testTimestamp,
          roomId: testRoomId,
        );

        final message2 = Message(
          id: testId,
          senderId: testSenderId,
          content: testContent,
          timestamp: testTimestamp,
          roomId: testRoomId,
        );

        // Assert
        expect(message1, equals(message2));
        expect(message1.hashCode, message2.hashCode);
      });

      test('should not be equal when properties differ', () {
        // Arrange
        final message1 = testMessage;
        final message2 = Message(
          id: 'different-id',
          senderId: testSenderId,
          content: testContent,
          timestamp: testTimestamp,
          roomId: testRoomId,
        );

        // Assert
        expect(message1, isNot(equals(message2)));
        expect(message1.hashCode, isNot(message2.hashCode));
      });
    });

    group('CopyWith', () {
      test('should create copy with updated id', () {
        // Arrange & Act
        final updatedMessage = testMessage.copyWith(id: 'new-id');

        // Assert
        expect(updatedMessage.id, 'new-id');
        expect(updatedMessage.senderId, testMessage.senderId);
        expect(updatedMessage.content, testMessage.content);
        expect(updatedMessage.timestamp, testMessage.timestamp);
        expect(updatedMessage.roomId, testMessage.roomId);
      });

      test('should create copy with updated isRead status', () {
        // Arrange & Act
        final readMessage = testMessage.copyWith(isRead: true);

        // Assert
        expect(readMessage.isRead, true);
        expect(readMessage.id, testMessage.id);
        expect(readMessage.content, testMessage.content);
      });

      test('should create copy with updated message type', () {
        // Arrange & Act
        final imageMessage = testMessage.copyWith(messageType: MessageType.image);

        // Assert
        expect(imageMessage.messageType, MessageType.image);
        expect(imageMessage.id, testMessage.id);
        expect(imageMessage.content, testMessage.content);
      });

      test('should preserve all fields when no changes provided', () {
        // Arrange & Act
        final copiedMessage = testMessage.copyWith();

        // Assert
        expect(copiedMessage, equals(testMessage));
        expect(identical(copiedMessage, testMessage), false); // Different instances
      });
    });

    group('MessageType enum', () {
      test('should have all expected message types', () {
        // Assert
        expect(MessageType.values, contains(MessageType.text));
        expect(MessageType.values, contains(MessageType.image));
        expect(MessageType.values, contains(MessageType.file));
      });

      test('should default to text type', () {
        // Assert
        expect(testMessage.messageType, MessageType.text);
      });
    });

    group('Business Logic', () {
      test('should support empty content for certain message types', () {
        // Arrange & Act
        final emptyMessage = Message(
          id: testId,
          senderId: testSenderId,
          content: '', // Empty content - might be valid for file messages
          timestamp: testTimestamp,
          roomId: testRoomId,
          messageType: MessageType.file,
        );

        // Assert
        expect(emptyMessage.content, '');
        expect(emptyMessage.messageType, MessageType.file);
      });

      test('should handle past and future timestamps', () {
        // Arrange
        final pastTime = DateTime(2020, 1, 1);
        final futureTime = DateTime(2030, 1, 1);

        // Act
        final pastMessage = testMessage.copyWith(timestamp: pastTime);
        final futureMessage = testMessage.copyWith(timestamp: futureTime);

        // Assert
        expect(pastMessage.timestamp, pastTime);
        expect(futureMessage.timestamp, futureTime);
      });
    });
  });
}