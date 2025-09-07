import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_clone/features/messaging/domain/entities/message.dart';
import 'package:whatsapp_clone/features/messaging/data/models/message_model.dart';

void main() {
  group('Real-time Messaging Integration Tests', () {
    test('Message entity should be created with required fields', () {
      // Arrange
      final testCreatedAt = DateTime.now();
      final testMessage = Message(
        id: 'test-id',
        roomId: 'room-123',
        userId: 'user-456', 
        content: 'Hello World',
        createdAt: testCreatedAt,
      );

      // Assert
      expect(testMessage.id, 'test-id');
      expect(testMessage.roomId, 'room-123');
      expect(testMessage.userId, 'user-456');
      expect(testMessage.content, 'Hello World');
      expect(testMessage.createdAt, testCreatedAt);
      expect(testMessage.type, MessageType.text);
      expect(testMessage.replyTo, null);
      expect(testMessage.isDeleted, false);
      expect(testMessage.isEdited, false);
    });

    test('Message model should convert to and from JSON correctly', () {
      // Arrange
      final testCreatedAt = DateTime.now();
      final testMessage = MessageModel(
        id: 'test-id',
        roomId: 'room-123',
        userId: 'user-456',
        content: 'Hello World',
        createdAt: testCreatedAt,
        type: MessageType.text,
      );

      // Act
      final json = testMessage.toJson();
      final messageFromJson = MessageModel.fromJson(json);

      // Assert
      expect(messageFromJson.id, testMessage.id);
      expect(messageFromJson.roomId, testMessage.roomId);
      expect(messageFromJson.userId, testMessage.userId);
      expect(messageFromJson.content, testMessage.content);
      expect(messageFromJson.type, testMessage.type);
      expect(messageFromJson.createdAt.toIso8601String(), 
             testMessage.createdAt.toIso8601String());
    });

    test('Message should support all message types', () {
      final testCreatedAt = DateTime.now();
      
      for (final messageType in MessageType.values) {
        final message = Message(
          id: 'test-id',
          roomId: 'room-123',
          userId: 'user-456',
          content: 'Test content',
          createdAt: testCreatedAt,
          type: messageType,
        );
        
        expect(message.type, messageType);
      }
    });

    test('Message should support metadata and reply functionality', () {
      // Arrange
      final testCreatedAt = DateTime.now();
      const metadata = {'file_url': 'https://example.com/file.jpg', 'size': '1024'};
      
      final message = Message(
        id: 'test-id',
        roomId: 'room-123',
        userId: 'user-456',
        content: 'Check out this image',
        createdAt: testCreatedAt,
        type: MessageType.image,
        replyTo: 'parent-message-id',
        metadata: metadata,
      );

      // Assert
      expect(message.type, MessageType.image);
      expect(message.replyTo, 'parent-message-id');
      expect(message.metadata, metadata);
      expect(message.metadata['file_url'], 'https://example.com/file.jpg');
      expect(message.metadata['size'], '1024');
    });

    test('Message status entity should track delivery states', () {
      // Arrange
      final testTimestamp = DateTime.now();
      
      for (final status in MessageStatus.values) {
        final statusEntity = MessageStatusEntity(
          id: 'status-id',
          messageId: 'message-id',
          userId: 'user-id',
          status: status,
          timestamp: testTimestamp,
        );
        
        expect(statusEntity.status, status);
        expect(statusEntity.messageId, 'message-id');
        expect(statusEntity.userId, 'user-id');
      }
    });

    test('Typing indicator should track real-time typing status', () {
      // Arrange
      final testUpdatedAt = DateTime.now();
      final typingIndicator = TypingIndicator(
        roomId: 'room-123',
        userId: 'user-456',
        isTyping: true,
        updatedAt: testUpdatedAt,
      );

      // Assert
      expect(typingIndicator.roomId, 'room-123');
      expect(typingIndicator.userId, 'user-456');
      expect(typingIndicator.isTyping, true);
      expect(typingIndicator.updatedAt, testUpdatedAt);
    });

    test('User presence should track online status', () {
      // Arrange
      final testLastSeen = DateTime.now();
      final testUpdatedAt = DateTime.now();
      
      for (final status in PresenceStatus.values) {
        final presence = UserPresence(
          userId: 'user-456',
          isOnline: true,
          lastSeen: testLastSeen,
          status: status,
          updatedAt: testUpdatedAt,
        );
        
        expect(presence.userId, 'user-456');
        expect(presence.isOnline, true);
        expect(presence.status, status);
        expect(presence.lastSeen, testLastSeen);
        expect(presence.updatedAt, testUpdatedAt);
      }
    });

    test('Message copyWith should create updated instances', () {
      // Arrange
      final originalCreatedAt = DateTime.now();
      final editedAt = DateTime.now().add(const Duration(minutes: 5));
      
      final originalMessage = Message(
        id: 'test-id',
        roomId: 'room-123',
        userId: 'user-456',
        content: 'Original content',
        createdAt: originalCreatedAt,
      );

      // Act
      final editedMessage = originalMessage.copyWith(
        content: 'Edited content',
        editedAt: editedAt,
      );

      // Assert
      expect(editedMessage.id, originalMessage.id);
      expect(editedMessage.roomId, originalMessage.roomId);
      expect(editedMessage.userId, originalMessage.userId);
      expect(editedMessage.content, 'Edited content');
      expect(editedMessage.createdAt, originalMessage.createdAt);
      expect(editedMessage.editedAt, editedAt);
      expect(editedMessage.isEdited, true);
    });
  });
}