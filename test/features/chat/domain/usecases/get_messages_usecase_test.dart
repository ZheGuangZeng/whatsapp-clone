import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:whatsapp_clone/core/errors/failures.dart';
import 'package:whatsapp_clone/core/utils/result.dart';
import 'package:whatsapp_clone/features/chat/domain/entities/chat_message.dart';
import 'package:whatsapp_clone/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:whatsapp_clone/features/chat/domain/usecases/get_messages_usecase.dart';
import 'package:whatsapp_clone/features/messaging/domain/entities/message.dart';

// Mock repository for testing
class MockChatRepository extends Mock implements IChatRepository {}

void main() {
  group('GetMessagesUseCase Tests', () {
    late GetMessagesUseCase useCase;
    late MockChatRepository mockRepository;

    setUp(() {
      mockRepository = MockChatRepository();
      useCase = GetMessagesUseCase(mockRepository);
    });

    test('should get messages successfully with default parameters', () async {
      // Arrange
      const params = GetMessagesParams(roomId: 'room_123');
      
      final expectedMessages = [
        ChatMessage(
          id: 'message_1',
          senderId: 'user_1',
          content: 'Hello',
          roomId: 'room_123',
          timestamp: DateTime.now(),
        ),
        ChatMessage(
          id: 'message_2',
          senderId: 'user_2',
          content: 'Hi there',
          roomId: 'room_123',
          timestamp: DateTime.now(),
        ),
      ];

      when(() => mockRepository.getMessages(
        roomId: any(named: 'roomId'),
        limit: any(named: 'limit'),
        beforeMessageId: any(named: 'beforeMessageId'),
        threadId: any(named: 'threadId'),
      )).thenAnswer((_) async => Success(expectedMessages));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isSuccess, isTrue);
      final messages = result.dataOrNull!;
      expect(messages, hasLength(2));
      expect(messages.first.id, equals('message_1'));
      expect(messages.last.id, equals('message_2'));

      verify(() => mockRepository.getMessages(
        roomId: 'room_123',
        limit: 50, // default
        beforeMessageId: null,
        threadId: null,
      )).called(1);
    });

    test('should get messages with custom limit', () async {
      // Arrange
      const params = GetMessagesParams(
        roomId: 'room_123',
        limit: 25,
      );
      
      final expectedMessages = List.generate(25, (i) => ChatMessage(
        id: 'message_$i',
        senderId: 'user_$i',
        content: 'Message $i',
        roomId: 'room_123',
        timestamp: DateTime.now(),
      ));

      when(() => mockRepository.getMessages(
        roomId: any(named: 'roomId'),
        limit: any(named: 'limit'),
        beforeMessageId: any(named: 'beforeMessageId'),
        threadId: any(named: 'threadId'),
      )).thenAnswer((_) async => Success(expectedMessages));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isSuccess, isTrue);
      final messages = result.dataOrNull!;
      expect(messages, hasLength(25));

      verify(() => mockRepository.getMessages(
        roomId: 'room_123',
        limit: 25,
        beforeMessageId: null,
        threadId: null,
      )).called(1);
    });

    test('should get messages with pagination', () async {
      // Arrange
      const params = GetMessagesParams(
        roomId: 'room_123',
        limit: 20,
        beforeMessageId: 'message_50',
      );
      
      final expectedMessages = List.generate(20, (i) => ChatMessage(
        id: 'message_${30 + i}', // Earlier messages
        senderId: 'user_${30 + i}',
        content: 'Message ${30 + i}',
        roomId: 'room_123',
        timestamp: DateTime.now().subtract(Duration(hours: i)),
      ));

      when(() => mockRepository.getMessages(
        roomId: any(named: 'roomId'),
        limit: any(named: 'limit'),
        beforeMessageId: any(named: 'beforeMessageId'),
        threadId: any(named: 'threadId'),
      )).thenAnswer((_) async => Success(expectedMessages));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isSuccess, isTrue);
      final messages = result.dataOrNull!;
      expect(messages, hasLength(20));

      verify(() => mockRepository.getMessages(
        roomId: 'room_123',
        limit: 20,
        beforeMessageId: 'message_50',
        threadId: null,
      )).called(1);
    });

    test('should get thread messages', () async {
      // Arrange
      const params = GetMessagesParams(
        roomId: 'room_123',
        threadId: 'thread_456',
      );
      
      final expectedMessages = [
        ChatMessage(
          id: 'message_thread_1',
          senderId: 'user_1',
          content: 'Thread reply 1',
          roomId: 'room_123',
          timestamp: DateTime.now(),
          threadId: 'thread_456',
        ),
        ChatMessage(
          id: 'message_thread_2',
          senderId: 'user_2',
          content: 'Thread reply 2',
          roomId: 'room_123',
          timestamp: DateTime.now(),
          threadId: 'thread_456',
        ),
      ];

      when(() => mockRepository.getMessages(
        roomId: any(named: 'roomId'),
        limit: any(named: 'limit'),
        beforeMessageId: any(named: 'beforeMessageId'),
        threadId: any(named: 'threadId'),
      )).thenAnswer((_) async => Success(expectedMessages));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isSuccess, isTrue);
      final messages = result.dataOrNull!;
      expect(messages, hasLength(2));
      expect(messages.every((ChatMessage m) => m.threadId == 'thread_456'), isTrue);

      verify(() => mockRepository.getMessages(
        roomId: 'room_123',
        limit: 50,
        beforeMessageId: null,
        threadId: 'thread_456',
      )).called(1);
    });

    test('should return failure when repository fails', () async {
      // Arrange
      const params = GetMessagesParams(roomId: 'room_123');
      const failure = ServerFailure(message: 'Failed to get messages');

      when(() => mockRepository.getMessages(
        roomId: any(named: 'roomId'),
        limit: any(named: 'limit'),
        beforeMessageId: any(named: 'beforeMessageId'),
        threadId: any(named: 'threadId'),
      )).thenAnswer((_) async => const ResultFailure(failure));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, equals(failure));
    });

    test('should validate room ID is not empty', () async {
      // Arrange
      const params = GetMessagesParams(roomId: '');

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());

      verifyNever(() => mockRepository.getMessages(
        roomId: any(named: 'roomId'),
        limit: any(named: 'limit'),
        beforeMessageId: any(named: 'beforeMessageId'),
        threadId: any(named: 'threadId'),
      ));
    });

    test('should validate limit is positive', () async {
      // Arrange
      const params = GetMessagesParams(
        roomId: 'room_123',
        limit: 0,
      );

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());

      verifyNever(() => mockRepository.getMessages(
        roomId: any(named: 'roomId'),
        limit: any(named: 'limit'),
        beforeMessageId: any(named: 'beforeMessageId'),
        threadId: any(named: 'threadId'),
      ));
    });

    test('should validate limit does not exceed maximum', () async {
      // Arrange
      const params = GetMessagesParams(
        roomId: 'room_123',
        limit: 200, // Exceeds max of 100
      );

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());

      verifyNever(() => mockRepository.getMessages(
        roomId: any(named: 'roomId'),
        limit: any(named: 'limit'),
        beforeMessageId: any(named: 'beforeMessageId'),
        threadId: any(named: 'threadId'),
      ));
    });

    test('should return empty list when no messages found', () async {
      // Arrange
      const params = GetMessagesParams(roomId: 'empty_room');

      when(() => mockRepository.getMessages(
        roomId: any(named: 'roomId'),
        limit: any(named: 'limit'),
        beforeMessageId: any(named: 'beforeMessageId'),
        threadId: any(named: 'threadId'),
      )).thenAnswer((_) async => const Success([]));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isSuccess, isTrue);
      final messages = result.dataOrNull!;
      expect(messages, isEmpty);

      verify(() => mockRepository.getMessages(
        roomId: 'empty_room',
        limit: 50,
        beforeMessageId: null,
        threadId: null,
      )).called(1);
    });

    test('should handle room not found error', () async {
      // Arrange
      const params = GetMessagesParams(roomId: 'non_existent_room');
      const failure = ValidationFailure(message: 'Room not found');

      when(() => mockRepository.getMessages(
        roomId: any(named: 'roomId'),
        limit: any(named: 'limit'),
        beforeMessageId: any(named: 'beforeMessageId'),
        threadId: any(named: 'threadId'),
      )).thenAnswer((_) async => const ResultFailure(failure));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, equals(failure));
    });

    test('should handle network error gracefully', () async {
      // Arrange
      const params = GetMessagesParams(roomId: 'room_123');
      const failure = NetworkFailure(message: 'No internet connection');

      when(() => mockRepository.getMessages(
        roomId: any(named: 'roomId'),
        limit: any(named: 'limit'),
        beforeMessageId: any(named: 'beforeMessageId'),
        threadId: any(named: 'threadId'),
      )).thenAnswer((_) async => const ResultFailure(failure));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, equals(failure));
    });

    test('should get messages with all parameters', () async {
      // Arrange
      const params = GetMessagesParams(
        roomId: 'room_123',
        limit: 30,
        beforeMessageId: 'message_100',
        threadId: 'thread_789',
      );
      
      final expectedMessages = [
        ChatMessage(
          id: 'message_70',
          senderId: 'user_1',
          content: 'Thread message',
          roomId: 'room_123',
          timestamp: DateTime.now(),
          threadId: 'thread_789',
        ),
      ];

      when(() => mockRepository.getMessages(
        roomId: any(named: 'roomId'),
        limit: any(named: 'limit'),
        beforeMessageId: any(named: 'beforeMessageId'),
        threadId: any(named: 'threadId'),
      )).thenAnswer((_) async => Success(expectedMessages));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isSuccess, isTrue);
      final messages = result.dataOrNull!;
      expect(messages, hasLength(1));

      verify(() => mockRepository.getMessages(
        roomId: 'room_123',
        limit: 30,
        beforeMessageId: 'message_100',
        threadId: 'thread_789',
      )).called(1);
    });

    test('should handle different message types in results', () async {
      // Arrange
      const params = GetMessagesParams(roomId: 'room_123');
      
      final expectedMessages = [
        ChatMessage(
          id: 'message_text',
          senderId: 'user_1',
          content: 'Text message',
          roomId: 'room_123',
          timestamp: DateTime.now(),
          messageType: MessageType.text,
        ),
        ChatMessage(
          id: 'message_image',
          senderId: 'user_2',
          content: 'Photo',
          roomId: 'room_123',
          timestamp: DateTime.now(),
          messageType: MessageType.image,
          metadata: const {'url': 'https://example.com/photo.jpg'},
        ),
        ChatMessage(
          id: 'message_file',
          senderId: 'user_3',
          content: 'Document.pdf',
          roomId: 'room_123',
          timestamp: DateTime.now(),
          messageType: MessageType.file,
        ),
      ];

      when(() => mockRepository.getMessages(
        roomId: any(named: 'roomId'),
        limit: any(named: 'limit'),
        beforeMessageId: any(named: 'beforeMessageId'),
        threadId: any(named: 'threadId'),
      )).thenAnswer((_) async => Success(expectedMessages));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isSuccess, isTrue);
      final messages = result.dataOrNull!;
      expect(messages, hasLength(3));
      expect(messages[0].messageType, equals(MessageType.text));
      expect(messages[1].messageType, equals(MessageType.image));
      expect(messages[1].metadata['url'], equals('https://example.com/photo.jpg'));
      expect(messages[2].messageType, equals(MessageType.file));
    });
  });
}