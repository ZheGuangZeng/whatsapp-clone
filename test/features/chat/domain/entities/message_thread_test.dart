import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_clone/features/chat/domain/entities/message_thread.dart';
import 'package:whatsapp_clone/features/messaging/domain/entities/message.dart';

void main() {
  group('MessageThread Entity Tests', () {
    test('should create a valid MessageThread with required fields', () {
      // Arrange
      const threadId = 'thread_123';
      const roomId = 'room_123';
      final rootMessage = Message(
        id: 'message_root',
        senderId: 'user_123',
        content: 'Root message',
        timestamp: DateTime.now(),
        roomId: roomId,
      );
      final createdAt = DateTime.now();
      
      // Act
      final thread = MessageThread(
        id: threadId,
        roomId: roomId,
        rootMessage: rootMessage,
        createdAt: createdAt,
      );
      
      // Assert
      expect(thread.id, equals(threadId));
      expect(thread.roomId, equals(roomId));
      expect(thread.rootMessage, equals(rootMessage));
      expect(thread.createdAt, equals(createdAt));
      expect(thread.isActive, isTrue); // default
      expect(thread.replyCount, equals(0)); // default
      expect(thread.lastReply, isNull);
      expect(thread.participants, isEmpty);
    });

    test('should create a MessageThread with all optional fields', () {
      // Arrange
      const threadId = 'thread_123';
      const roomId = 'room_123';
      final rootMessage = Message(
        id: 'message_root',
        senderId: 'user_123',
        content: 'Root message',
        timestamp: DateTime.now(),
        roomId: roomId,
      );
      final lastReply = Message(
        id: 'message_reply',
        senderId: 'user_456',
        content: 'Reply message',
        timestamp: DateTime.now(),
        roomId: roomId,
      );
      final createdAt = DateTime.now();
      const participants = ['user_123', 'user_456'];
      
      // Act
      final thread = MessageThread(
        id: threadId,
        roomId: roomId,
        rootMessage: rootMessage,
        createdAt: createdAt,
        isActive: false,
        replyCount: 5,
        lastReply: lastReply,
        participants: participants,
      );
      
      // Assert
      expect(thread.id, equals(threadId));
      expect(thread.roomId, equals(roomId));
      expect(thread.rootMessage, equals(rootMessage));
      expect(thread.createdAt, equals(createdAt));
      expect(thread.isActive, isFalse);
      expect(thread.replyCount, equals(5));
      expect(thread.lastReply, equals(lastReply));
      expect(thread.participants, equals(participants));
    });

    test('should support equality comparison', () {
      // Arrange
      final rootMessage = Message(
        id: 'message_root',
        senderId: 'user_123',
        content: 'Root message',
        timestamp: DateTime.now(),
        roomId: 'room_123',
      );
      final createdAt = DateTime.now();
      final thread1 = MessageThread(
        id: 'thread_123',
        roomId: 'room_123',
        rootMessage: rootMessage,
        createdAt: createdAt,
      );
      final thread2 = MessageThread(
        id: 'thread_123',
        roomId: 'room_123',
        rootMessage: rootMessage,
        createdAt: createdAt,
      );
      final thread3 = MessageThread(
        id: 'thread_456',
        roomId: 'room_123',
        rootMessage: rootMessage,
        createdAt: createdAt,
      );
      
      // Act & Assert
      expect(thread1, equals(thread2));
      expect(thread1, isNot(equals(thread3)));
      expect(thread1.hashCode, equals(thread2.hashCode));
      expect(thread1.hashCode, isNot(equals(thread3.hashCode)));
    });

    test('should create a copy with updated fields', () {
      // Arrange
      final originalThread = MessageThread(
        id: 'thread_123',
        roomId: 'room_123',
        rootMessage: Message(
          id: 'message_root',
          senderId: 'user_123',
          content: 'Root message',
          timestamp: DateTime.now(),
          roomId: 'room_123',
        ),
        createdAt: DateTime.now(),
        isActive: true,
        replyCount: 0,
      );
      
      final newReply = Message(
        id: 'message_reply',
        senderId: 'user_456',
        content: 'Reply message',
        timestamp: DateTime.now(),
        roomId: 'room_123',
      );
      
      // Act
      final updatedThread = originalThread.copyWith(
        isActive: false,
        replyCount: 3,
        lastReply: newReply,
        participants: const ['user_123', 'user_456'],
      );
      
      // Assert
      expect(updatedThread.id, equals(originalThread.id));
      expect(updatedThread.roomId, equals(originalThread.roomId));
      expect(updatedThread.rootMessage, equals(originalThread.rootMessage));
      expect(updatedThread.createdAt, equals(originalThread.createdAt));
      expect(updatedThread.isActive, isFalse);
      expect(updatedThread.replyCount, equals(3));
      expect(updatedThread.lastReply, equals(newReply));
      expect(updatedThread.participants, equals(const ['user_123', 'user_456']));
    });

    test('should validate thread ID is not empty', () {
      // Arrange
      final rootMessage = Message(
        id: 'message_root',
        senderId: 'user_123',
        content: 'Root message',
        timestamp: DateTime.now(),
        roomId: 'room_123',
      );
      
      // Act & Assert
      expect(
        () => MessageThread(
          id: '',
          roomId: 'room_123',
          rootMessage: rootMessage,
          createdAt: DateTime.now(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('should validate room ID is not empty', () {
      // Arrange
      final rootMessage = Message(
        id: 'message_root',
        senderId: 'user_123',
        content: 'Root message',
        timestamp: DateTime.now(),
        roomId: 'room_123',
      );
      
      // Act & Assert
      expect(
        () => MessageThread(
          id: 'thread_123',
          roomId: '',
          rootMessage: rootMessage,
          createdAt: DateTime.now(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('should validate reply count is not negative', () {
      // Arrange
      final rootMessage = Message(
        id: 'message_root',
        senderId: 'user_123',
        content: 'Root message',
        timestamp: DateTime.now(),
        roomId: 'room_123',
      );
      
      // Act & Assert
      expect(
        () => MessageThread(
          id: 'thread_123',
          roomId: 'room_123',
          rootMessage: rootMessage,
          createdAt: DateTime.now(),
          replyCount: -1,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('should handle thread closure correctly', () {
      // Arrange
      final thread = MessageThread(
        id: 'thread_123',
        roomId: 'room_123',
        rootMessage: Message(
          id: 'message_root',
          senderId: 'user_123',
          content: 'Root message',
          timestamp: DateTime.now(),
          roomId: 'room_123',
        ),
        createdAt: DateTime.now(),
        isActive: true,
      );
      
      // Act
      final closedThread = thread.copyWith(isActive: false);
      
      // Assert
      expect(closedThread.isActive, isFalse);
      expect(thread.isActive, isTrue); // original unchanged
    });

    test('should handle participant updates correctly', () {
      // Arrange
      final thread = MessageThread(
        id: 'thread_123',
        roomId: 'room_123',
        rootMessage: Message(
          id: 'message_root',
          senderId: 'user_123',
          content: 'Root message',
          timestamp: DateTime.now(),
          roomId: 'room_123',
        ),
        createdAt: DateTime.now(),
        participants: const ['user_123'],
      );
      
      // Act
      final updatedThread = thread.copyWith(
        participants: const ['user_123', 'user_456', 'user_789'],
      );
      
      // Assert
      expect(updatedThread.participants, hasLength(3));
      expect(updatedThread.participants, contains('user_123'));
      expect(updatedThread.participants, contains('user_456'));
      expect(updatedThread.participants, contains('user_789'));
      expect(thread.participants, hasLength(1)); // original unchanged
    });

    test('should handle reply count updates correctly', () {
      // Arrange
      final thread = MessageThread(
        id: 'thread_123',
        roomId: 'room_123',
        rootMessage: Message(
          id: 'message_root',
          senderId: 'user_123',
          content: 'Root message',
          timestamp: DateTime.now(),
          roomId: 'room_123',
        ),
        createdAt: DateTime.now(),
        replyCount: 0,
      );
      
      final newReply = Message(
        id: 'message_reply',
        senderId: 'user_456',
        content: 'Reply message',
        timestamp: DateTime.now(),
        roomId: 'room_123',
      );
      
      // Act
      final updatedThread = thread.copyWith(
        replyCount: 1,
        lastReply: newReply,
      );
      
      // Assert
      expect(updatedThread.replyCount, equals(1));
      expect(updatedThread.lastReply, equals(newReply));
      expect(thread.replyCount, equals(0)); // original unchanged
    });
  });
}