import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_clone/core/utils/result.dart';
import 'package:whatsapp_clone/features/chat/domain/entities/chat_message.dart';
import 'package:whatsapp_clone/features/chat/domain/entities/message_thread.dart';
import 'package:whatsapp_clone/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:whatsapp_clone/features/messaging/domain/entities/message.dart';

// Mock implementation for testing interface contracts
class MockChatRepository implements IChatRepository {
  @override
  Future<Result<ChatMessage>> sendMessage({
    required String roomId,
    required String senderId,
    required String content,
    MessageType messageType = MessageType.text,
    String? threadId,
    String? replyToMessageId,
    Map<String, String>? metadata,
  }) async {
    // Mock implementation - would be replaced with actual implementation
    final message = ChatMessage(
      id: 'mock_message_id',
      senderId: senderId,
      content: content,
      roomId: roomId,
      timestamp: DateTime.now(),
      messageType: messageType,
      threadId: threadId,
      replyToMessageId: replyToMessageId,
      metadata: metadata ?? {},
    );
    return Success(message);
  }

  @override
  Future<Result<List<ChatMessage>>> getMessages({
    required String roomId,
    int limit = 50,
    String? beforeMessageId,
    String? threadId,
  }) async {
    // Mock implementation
    return const Success([]);
  }

  @override
  Future<Result<ChatMessage>> editMessage({
    required String messageId,
    required String content,
  }) async {
    // Mock implementation
    final editedMessage = ChatMessage(
      id: messageId,
      senderId: 'mock_sender',
      content: content,
      roomId: 'mock_room',
      timestamp: DateTime.now(),
      editedAt: DateTime.now(),
    );
    return Success(editedMessage);
  }

  @override
  Future<Result<void>> deleteMessage(String messageId) async {
    return const Success(null);
  }

  @override
  Future<Result<ChatMessage>> addReaction({
    required String messageId,
    required String userId,
    required String reaction,
  }) async {
    // Mock implementation
    final message = ChatMessage(
      id: messageId,
      senderId: 'mock_sender',
      content: 'mock_content',
      roomId: 'mock_room',
      timestamp: DateTime.now(),
      reactions: {reaction: [userId]},
    );
    return Success(message);
  }

  @override
  Future<Result<ChatMessage>> removeReaction({
    required String messageId,
    required String userId,
    required String reaction,
  }) async {
    // Mock implementation
    final message = ChatMessage(
      id: messageId,
      senderId: 'mock_sender',
      content: 'mock_content',
      roomId: 'mock_room',
      timestamp: DateTime.now(),
      reactions: const {},
    );
    return Success(message);
  }

  @override
  Future<Result<MessageThread>> createThread({
    required String roomId,
    required String rootMessageId,
  }) async {
    // Mock implementation
    final rootMessage = ChatMessage(
      id: rootMessageId,
      senderId: 'mock_sender',
      content: 'Root message',
      roomId: roomId,
      timestamp: DateTime.now(),
    ).toMessage();
    
    final thread = MessageThread(
      id: 'mock_thread_id',
      roomId: roomId,
      rootMessage: rootMessage,
      createdAt: DateTime.now(),
    );
    return Success(thread);
  }

  @override
  Future<Result<List<MessageThread>>> getThreads(String roomId) async {
    return const Success([]);
  }

  @override
  Future<Result<void>> markMessagesAsRead({
    required String roomId,
    required String userId,
    String? lastMessageId,
  }) async {
    return const Success(null);
  }

  @override
  Future<Result<List<ChatMessage>>> searchMessages({
    required String roomId,
    required String query,
    int limit = 50,
  }) async {
    return const Success([]);
  }
}

void main() {
  group('IChatRepository Interface Tests', () {
    late IChatRepository repository;

    setUp(() {
      repository = MockChatRepository();
    });

    test('should send a message successfully', () async {
      // Arrange
      const roomId = 'room_123';
      const senderId = 'user_123';
      const content = 'Hello, world!';
      
      // Act
      final result = await repository.sendMessage(
        roomId: roomId,
        senderId: senderId,
        content: content,
      );
      
      // Assert
      expect(result.isSuccess, isTrue);
      final message = result.dataOrNull!;
      expect(message.senderId, equals(senderId));
      expect(message.content, equals(content));
      expect(message.roomId, equals(roomId));
      expect(message.messageType, equals(MessageType.text));
    });

    test('should send a message with thread information', () async {
      // Arrange
      const roomId = 'room_123';
      const senderId = 'user_123';
      const content = 'Thread reply';
      const threadId = 'thread_456';
      const replyToMessageId = 'message_root';
      
      // Act
      final result = await repository.sendMessage(
        roomId: roomId,
        senderId: senderId,
        content: content,
        threadId: threadId,
        replyToMessageId: replyToMessageId,
      );
      
      // Assert
      expect(result.isSuccess, isTrue);
      final message = result.dataOrNull!;
      expect(message.threadId, equals(threadId));
      expect(message.replyToMessageId, equals(replyToMessageId));
    });

    test('should get messages for a room', () async {
      // Arrange
      const roomId = 'room_123';
      
      // Act
      final result = await repository.getMessages(roomId: roomId);
      
      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isA<List<ChatMessage>>());
    });

    test('should get messages with pagination', () async {
      // Arrange
      const roomId = 'room_123';
      const limit = 25;
      const beforeMessageId = 'message_before';
      
      // Act
      final result = await repository.getMessages(
        roomId: roomId,
        limit: limit,
        beforeMessageId: beforeMessageId,
      );
      
      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isA<List<ChatMessage>>());
    });

    test('should get thread messages', () async {
      // Arrange
      const roomId = 'room_123';
      const threadId = 'thread_456';
      
      // Act
      final result = await repository.getMessages(
        roomId: roomId,
        threadId: threadId,
      );
      
      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isA<List<ChatMessage>>());
    });

    test('should edit a message', () async {
      // Arrange
      const messageId = 'message_123';
      const newContent = 'Edited content';
      
      // Act
      final result = await repository.editMessage(
        messageId: messageId,
        content: newContent,
      );
      
      // Assert
      expect(result.isSuccess, isTrue);
      final editedMessage = result.dataOrNull!;
      expect(editedMessage.id, equals(messageId));
      expect(editedMessage.content, equals(newContent));
      expect(editedMessage.isEdited, isTrue);
    });

    test('should delete a message', () async {
      // Arrange
      const messageId = 'message_123';
      
      // Act
      final result = await repository.deleteMessage(messageId);
      
      // Assert
      expect(result.isSuccess, isTrue);
    });

    test('should add a reaction to message', () async {
      // Arrange
      const messageId = 'message_123';
      const userId = 'user_123';
      const reaction = '👍';
      
      // Act
      final result = await repository.addReaction(
        messageId: messageId,
        userId: userId,
        reaction: reaction,
      );
      
      // Assert
      expect(result.isSuccess, isTrue);
      final message = result.dataOrNull!;
      expect(message.reactions[reaction], contains(userId));
    });

    test('should remove a reaction from message', () async {
      // Arrange
      const messageId = 'message_123';
      const userId = 'user_123';
      const reaction = '👍';
      
      // Act
      final result = await repository.removeReaction(
        messageId: messageId,
        userId: userId,
        reaction: reaction,
      );
      
      // Assert
      expect(result.isSuccess, isTrue);
      final message = result.dataOrNull!;
      expect(message.reactions, isEmpty);
    });

    test('should create a thread', () async {
      // Arrange
      const roomId = 'room_123';
      const rootMessageId = 'message_root';
      
      // Act
      final result = await repository.createThread(
        roomId: roomId,
        rootMessageId: rootMessageId,
      );
      
      // Assert
      expect(result.isSuccess, isTrue);
      final thread = result.dataOrNull!;
      expect(thread.roomId, equals(roomId));
      expect(thread.rootMessage.id, equals(rootMessageId));
    });

    test('should get threads for a room', () async {
      // Arrange
      const roomId = 'room_123';
      
      // Act
      final result = await repository.getThreads(roomId);
      
      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isA<List<MessageThread>>());
    });

    test('should mark messages as read', () async {
      // Arrange
      const roomId = 'room_123';
      const userId = 'user_123';
      const lastMessageId = 'message_last';
      
      // Act
      final result = await repository.markMessagesAsRead(
        roomId: roomId,
        userId: userId,
        lastMessageId: lastMessageId,
      );
      
      // Assert
      expect(result.isSuccess, isTrue);
    });

    test('should search messages', () async {
      // Arrange
      const roomId = 'room_123';
      const query = 'search term';
      const limit = 25;
      
      // Act
      final result = await repository.searchMessages(
        roomId: roomId,
        query: query,
        limit: limit,
      );
      
      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isA<List<ChatMessage>>());
    });
  });
}