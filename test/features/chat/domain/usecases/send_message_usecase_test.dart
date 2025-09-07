import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:whatsapp_clone/core/errors/failures.dart';
import 'package:whatsapp_clone/core/utils/result.dart';
import 'package:whatsapp_clone/features/chat/domain/entities/chat_message.dart';
import 'package:whatsapp_clone/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:whatsapp_clone/features/chat/domain/usecases/send_message_usecase.dart';
import 'package:whatsapp_clone/features/messaging/domain/entities/message.dart';

// Mock repository for testing
class MockChatRepository extends Mock implements IChatRepository {}

void main() {
  group('SendMessageUseCase Tests', () {
    late SendMessageUseCase useCase;
    late MockChatRepository mockRepository;

    setUpAll(() {
      // Register fallback values for mocktail
      registerFallbackValue(MessageType.text);
      registerFallbackValue(<String, String>{});
    });

    setUp(() {
      mockRepository = MockChatRepository();
      useCase = SendMessageUseCase(mockRepository);
    });

    test('should send a text message successfully', () async {
      // Arrange
      const params = SendMessageParams(
        roomId: 'room_123',
        senderId: 'user_123',
        content: 'Hello, world!',
      );
      
      final expectedMessage = ChatMessage(
        id: 'message_123',
        senderId: 'user_123',
        content: 'Hello, world!',
        roomId: 'room_123',
        timestamp: DateTime.now(),
        messageType: MessageType.text,
      );

      when(() => mockRepository.sendMessage(
        roomId: any(named: 'roomId'),
        senderId: any(named: 'senderId'),
        content: any(named: 'content'),
        messageType: any(named: 'messageType'),
        threadId: any(named: 'threadId'),
        replyToMessageId: any(named: 'replyToMessageId'),
        metadata: any(named: 'metadata'),
      )).thenAnswer((_) async => Success(expectedMessage));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isSuccess, isTrue);
      final message = result.dataOrNull!;
      expect(message.senderId, equals('user_123'));
      expect(message.content, equals('Hello, world!'));
      expect(message.roomId, equals('room_123'));
      expect(message.messageType, equals(MessageType.text));

      verify(() => mockRepository.sendMessage(
        roomId: 'room_123',
        senderId: 'user_123',
        content: 'Hello, world!',
        messageType: MessageType.text,
        threadId: null,
        replyToMessageId: null,
        metadata: null,
      )).called(1);
    });

    test('should send a message with all optional parameters', () async {
      // Arrange
      const params = SendMessageParams(
        roomId: 'room_123',
        senderId: 'user_123',
        content: 'Image message',
        messageType: MessageType.image,
        threadId: 'thread_456',
        replyToMessageId: 'message_root',
        metadata: {'url': 'https://example.com/image.jpg', 'size': '1024'},
      );
      
      final expectedMessage = ChatMessage(
        id: 'message_123',
        senderId: 'user_123',
        content: 'Image message',
        roomId: 'room_123',
        timestamp: DateTime.now(),
        messageType: MessageType.image,
        threadId: 'thread_456',
        replyToMessageId: 'message_root',
        metadata: const {'url': 'https://example.com/image.jpg', 'size': '1024'},
      );

      when(() => mockRepository.sendMessage(
        roomId: any(named: 'roomId'),
        senderId: any(named: 'senderId'),
        content: any(named: 'content'),
        messageType: any(named: 'messageType'),
        threadId: any(named: 'threadId'),
        replyToMessageId: any(named: 'replyToMessageId'),
        metadata: any(named: 'metadata'),
      )).thenAnswer((_) async => Success(expectedMessage));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isSuccess, isTrue);
      final message = result.dataOrNull!;
      expect(message.senderId, equals('user_123'));
      expect(message.content, equals('Image message'));
      expect(message.messageType, equals(MessageType.image));
      expect(message.threadId, equals('thread_456'));
      expect(message.replyToMessageId, equals('message_root'));
      expect(message.metadata, equals(const {'url': 'https://example.com/image.jpg', 'size': '1024'}));

      verify(() => mockRepository.sendMessage(
        roomId: 'room_123',
        senderId: 'user_123',
        content: 'Image message',
        messageType: MessageType.image,
        threadId: 'thread_456',
        replyToMessageId: 'message_root',
        metadata: const {'url': 'https://example.com/image.jpg', 'size': '1024'},
      )).called(1);
    });

    test('should return failure when repository fails', () async {
      // Arrange
      const params = SendMessageParams(
        roomId: 'room_123',
        senderId: 'user_123',
        content: 'Hello, world!',
      );
      
      const failure = ServerFailure(message: 'Failed to send message');

      when(() => mockRepository.sendMessage(
        roomId: any(named: 'roomId'),
        senderId: any(named: 'senderId'),
        content: any(named: 'content'),
        messageType: any(named: 'messageType'),
        threadId: any(named: 'threadId'),
        replyToMessageId: any(named: 'replyToMessageId'),
        metadata: any(named: 'metadata'),
      )).thenAnswer((_) async => const ResultFailure(failure));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, equals(failure));
    });

    test('should validate room ID is not empty', () async {
      // Arrange
      const params = SendMessageParams(
        roomId: '',
        senderId: 'user_123',
        content: 'Hello, world!',
      );

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());

      verifyNever(() => mockRepository.sendMessage(
        roomId: any(named: 'roomId'),
        senderId: any(named: 'senderId'),
        content: any(named: 'content'),
        messageType: any(named: 'messageType'),
        threadId: any(named: 'threadId'),
        replyToMessageId: any(named: 'replyToMessageId'),
        metadata: any(named: 'metadata'),
      ));
    });

    test('should validate sender ID is not empty', () async {
      // Arrange
      const params = SendMessageParams(
        roomId: 'room_123',
        senderId: '',
        content: 'Hello, world!',
      );

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());

      verifyNever(() => mockRepository.sendMessage(
        roomId: any(named: 'roomId'),
        senderId: any(named: 'senderId'),
        content: any(named: 'content'),
        messageType: any(named: 'messageType'),
        threadId: any(named: 'threadId'),
        replyToMessageId: any(named: 'replyToMessageId'),
        metadata: any(named: 'metadata'),
      ));
    });

    test('should validate content is not empty', () async {
      // Arrange
      const params = SendMessageParams(
        roomId: 'room_123',
        senderId: 'user_123',
        content: '',
      );

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());

      verifyNever(() => mockRepository.sendMessage(
        roomId: any(named: 'roomId'),
        senderId: any(named: 'senderId'),
        content: any(named: 'content'),
        messageType: any(named: 'messageType'),
        threadId: any(named: 'threadId'),
        replyToMessageId: any(named: 'replyToMessageId'),
        metadata: any(named: 'metadata'),
      ));
    });

    test('should handle different message types correctly', () async {
      // Test text message
      const textParams = SendMessageParams(
        roomId: 'room_123',
        senderId: 'user_123',
        content: 'Text message',
        messageType: MessageType.text,
      );

      final textMessage = ChatMessage(
        id: 'message_text',
        senderId: 'user_123',
        content: 'Text message',
        roomId: 'room_123',
        timestamp: DateTime.now(),
        messageType: MessageType.text,
      );

      when(() => mockRepository.sendMessage(
        roomId: 'room_123',
        senderId: 'user_123',
        content: 'Text message',
        messageType: MessageType.text,
        threadId: null,
        replyToMessageId: null,
        metadata: null,
      )).thenAnswer((_) async => Success(textMessage));

      // Test file message
      const fileParams = SendMessageParams(
        roomId: 'room_123',
        senderId: 'user_123',
        content: 'Document.pdf',
        messageType: MessageType.file,
      );

      final fileMessage = ChatMessage(
        id: 'message_file',
        senderId: 'user_123',
        content: 'Document.pdf',
        roomId: 'room_123',
        timestamp: DateTime.now(),
        messageType: MessageType.file,
      );

      when(() => mockRepository.sendMessage(
        roomId: 'room_123',
        senderId: 'user_123',
        content: 'Document.pdf',
        messageType: MessageType.file,
        threadId: null,
        replyToMessageId: null,
        metadata: null,
      )).thenAnswer((_) async => Success(fileMessage));

      // Act
      final textResult = await useCase(textParams);
      final fileResult = await useCase(fileParams);

      // Assert
      expect(textResult.isSuccess, isTrue);
      expect(fileResult.isSuccess, isTrue);
      expect(textResult.dataOrNull!.messageType, equals(MessageType.text));
      expect(fileResult.dataOrNull!.messageType, equals(MessageType.file));
    });

    test('should handle thread messages correctly', () async {
      // Arrange
      const params = SendMessageParams(
        roomId: 'room_123',
        senderId: 'user_123',
        content: 'Thread reply',
        threadId: 'thread_456',
        replyToMessageId: 'message_root',
      );
      
      final expectedMessage = ChatMessage(
        id: 'message_123',
        senderId: 'user_123',
        content: 'Thread reply',
        roomId: 'room_123',
        timestamp: DateTime.now(),
        threadId: 'thread_456',
        replyToMessageId: 'message_root',
      );

      when(() => mockRepository.sendMessage(
        roomId: any(named: 'roomId'),
        senderId: any(named: 'senderId'),
        content: any(named: 'content'),
        messageType: any(named: 'messageType'),
        threadId: any(named: 'threadId'),
        replyToMessageId: any(named: 'replyToMessageId'),
        metadata: any(named: 'metadata'),
      )).thenAnswer((_) async => Success(expectedMessage));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isSuccess, isTrue);
      final message = result.dataOrNull!;
      expect(message.isThreadMessage, isTrue);
      expect(message.threadId, equals('thread_456'));
      expect(message.replyToMessageId, equals('message_root'));
    });

    test('should handle message with metadata correctly', () async {
      // Arrange
      const metadata = {'type': 'image', 'width': '800', 'height': '600'};
      const params = SendMessageParams(
        roomId: 'room_123',
        senderId: 'user_123',
        content: 'Photo',
        messageType: MessageType.image,
        metadata: metadata,
      );
      
      final expectedMessage = ChatMessage(
        id: 'message_123',
        senderId: 'user_123',
        content: 'Photo',
        roomId: 'room_123',
        timestamp: DateTime.now(),
        messageType: MessageType.image,
        metadata: metadata,
      );

      when(() => mockRepository.sendMessage(
        roomId: any(named: 'roomId'),
        senderId: any(named: 'senderId'),
        content: any(named: 'content'),
        messageType: any(named: 'messageType'),
        threadId: any(named: 'threadId'),
        replyToMessageId: any(named: 'replyToMessageId'),
        metadata: any(named: 'metadata'),
      )).thenAnswer((_) async => Success(expectedMessage));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isSuccess, isTrue);
      final message = result.dataOrNull!;
      expect(message.metadata, equals(metadata));
      expect(message.metadata['type'], equals('image'));
      expect(message.metadata['width'], equals('800'));
    });

    test('should trim whitespace from content before sending', () async {
      // Arrange
      const params = SendMessageParams(
        roomId: 'room_123',
        senderId: 'user_123',
        content: '  Hello, world!  ',
      );
      
      final expectedMessage = ChatMessage(
        id: 'message_123',
        senderId: 'user_123',
        content: 'Hello, world!',
        roomId: 'room_123',
        timestamp: DateTime.now(),
      );

      when(() => mockRepository.sendMessage(
        roomId: any(named: 'roomId'),
        senderId: any(named: 'senderId'),
        content: any(named: 'content'),
        messageType: any(named: 'messageType'),
        threadId: any(named: 'threadId'),
        replyToMessageId: any(named: 'replyToMessageId'),
        metadata: any(named: 'metadata'),
      )).thenAnswer((_) async => Success(expectedMessage));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isSuccess, isTrue);
      verify(() => mockRepository.sendMessage(
        roomId: 'room_123',
        senderId: 'user_123',
        content: 'Hello, world!', // Should be trimmed
        messageType: MessageType.text,
        threadId: null,
        replyToMessageId: null,
        metadata: null,
      )).called(1);
    });

    test('should reject content that is only whitespace', () async {
      // Arrange
      const params = SendMessageParams(
        roomId: 'room_123',
        senderId: 'user_123',
        content: '   ',
      );

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());

      verifyNever(() => mockRepository.sendMessage(
        roomId: any(named: 'roomId'),
        senderId: any(named: 'senderId'),
        content: any(named: 'content'),
        messageType: any(named: 'messageType'),
        threadId: any(named: 'threadId'),
        replyToMessageId: any(named: 'replyToMessageId'),
        metadata: any(named: 'metadata'),
      ));
    });
  });
}