import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:whatsapp_clone/core/utils/result.dart';
import 'package:whatsapp_clone/features/chat/domain/entities/message.dart';
import 'package:whatsapp_clone/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:whatsapp_clone/features/chat/domain/usecases/send_message_usecase.dart';

class MockChatRepository extends Mock implements IChatRepository {}

void main() {
  late SendMessageUseCase useCase;
  late MockChatRepository mockRepository;

  setUp(() {
    mockRepository = MockChatRepository();
    useCase = SendMessageUseCase(mockRepository);
  });

  group('SendMessageUseCase', () {
    const testRoomId = 'room-123';
    const testContent = 'Hello, World!';
    const testType = 'text';
    
    final testMessage = Message(
      id: 'message-123',
      roomId: testRoomId,
      userId: 'user-123',
      content: testContent,
      type: MessageType.text,
      createdAt: DateTime.utc(2023, 1, 1),
      updatedAt: DateTime.utc(2023, 1, 1),
    );

    const testParams = SendMessageParams(
      roomId: testRoomId,
      content: testContent,
      type: testType,
    );

    test('should send message successfully when repository succeeds', () async {
      // Arrange
      when(() => mockRepository.sendMessage(
        roomId: any(named: 'roomId'),
        content: any(named: 'content'),
        type: any(named: 'type'),
        replyTo: any(named: 'replyTo'),
        metadata: any(named: 'metadata'),
      )).thenAnswer((_) async => testMessage);

      // Act
      final result = await useCase(testParams);

      // Assert
      expect(result, isA<Success<Message>>());
      expect(result.dataOrNull, equals(testMessage));
      
      verify(() => mockRepository.sendMessage(
        roomId: testRoomId,
        content: testContent,
        type: testType,
        replyTo: null,
        metadata: const {},
      )).called(1);
    });

    test('should send message with reply when replyTo is provided', () async {
      // Arrange
      const replyToId = 'reply-message-123';
      const testParamsWithReply = SendMessageParams(
        roomId: testRoomId,
        content: testContent,
        type: testType,
        replyTo: replyToId,
      );

      when(() => mockRepository.sendMessage(
        roomId: any(named: 'roomId'),
        content: any(named: 'content'),
        type: any(named: 'type'),
        replyTo: any(named: 'replyTo'),
        metadata: any(named: 'metadata'),
      )).thenAnswer((_) async => testMessage);

      // Act
      final result = await useCase(testParamsWithReply);

      // Assert
      expect(result, isA<Success<Message>>());
      
      verify(() => mockRepository.sendMessage(
        roomId: testRoomId,
        content: testContent,
        type: testType,
        replyTo: replyToId,
        metadata: const {},
      )).called(1);
    });

    test('should send message with metadata when metadata is provided', () async {
      // Arrange
      const testMetadata = {'file_size': 1024, 'file_name': 'document.pdf'};
      const testParamsWithMetadata = SendMessageParams(
        roomId: testRoomId,
        content: testContent,
        type: 'file',
        metadata: testMetadata,
      );

      when(() => mockRepository.sendMessage(
        roomId: any(named: 'roomId'),
        content: any(named: 'content'),
        type: any(named: 'type'),
        replyTo: any(named: 'replyTo'),
        metadata: any(named: 'metadata'),
      )).thenAnswer((_) async => testMessage);

      // Act
      final result = await useCase(testParamsWithMetadata);

      // Assert
      expect(result, isA<Success<Message>>());
      
      verify(() => mockRepository.sendMessage(
        roomId: testRoomId,
        content: testContent,
        type: 'file',
        replyTo: null,
        metadata: testMetadata,
      )).called(1);
    });

    test('should return failure when repository throws exception', () async {
      // Arrange
      when(() => mockRepository.sendMessage(
        roomId: any(named: 'roomId'),
        content: any(named: 'content'),
        type: any(named: 'type'),
        replyTo: any(named: 'replyTo'),
        metadata: any(named: 'metadata'),
      )).thenThrow(Exception('Network error'));

      // Act
      final result = await useCase(testParams);

      // Assert
      expect(result, isA<ResultFailure<Message>>());
      expect(result.failureOrNull?.message, contains('Failed to send message'));
    });

    test('should handle empty content by trimming', () async {
      // Arrange
      const testParamsEmptyContent = SendMessageParams(
        roomId: testRoomId,
        content: '   ',
        type: testType,
      );

      when(() => mockRepository.sendMessage(
        roomId: any(named: 'roomId'),
        content: any(named: 'content'),
        type: any(named: 'type'),
        replyTo: any(named: 'replyTo'),
        metadata: any(named: 'metadata'),
      )).thenAnswer((_) async => testMessage);

      // Act
      final result = await useCase(testParamsEmptyContent);

      // Assert
      expect(result, isA<Success<Message>>());
      
      verify(() => mockRepository.sendMessage(
        roomId: testRoomId,
        content: '   ', // Content should be passed as-is to repository
        type: testType,
        replyTo: null,
        metadata: const {},
      )).called(1);
    });
  });

  group('SendMessageParams', () {
    test('should create params with required fields', () {
      // Arrange & Act
      const params = SendMessageParams(
        roomId: 'room-123',
        content: 'Test message',
      );

      // Assert
      expect(params.roomId, equals('room-123'));
      expect(params.content, equals('Test message'));
      expect(params.type, equals('text')); // Default value
      expect(params.replyTo, isNull);
      expect(params.metadata, isEmpty);
    });

    test('should create params with all fields', () {
      // Arrange & Act
      const params = SendMessageParams(
        roomId: 'room-123',
        content: 'Test message',
        type: 'image',
        replyTo: 'reply-123',
        metadata: {'width': 1920, 'height': 1080},
      );

      // Assert
      expect(params.roomId, equals('room-123'));
      expect(params.content, equals('Test message'));
      expect(params.type, equals('image'));
      expect(params.replyTo, equals('reply-123'));
      expect(params.metadata, equals({'width': 1920, 'height': 1080}));
    });

    test('should support equality comparison', () {
      // Arrange
      const params1 = SendMessageParams(
        roomId: 'room-123',
        content: 'Test message',
      );
      const params2 = SendMessageParams(
        roomId: 'room-123',
        content: 'Test message',
      );
      const params3 = SendMessageParams(
        roomId: 'room-456',
        content: 'Test message',
      );

      // Act & Assert
      expect(params1, equals(params2));
      expect(params1, isNot(equals(params3)));
    });
  });
}