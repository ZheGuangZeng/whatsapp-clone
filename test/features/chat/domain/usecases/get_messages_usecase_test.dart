import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../lib/core/utils/result.dart';
import '../../../../../lib/features/chat/domain/entities/message.dart';
import '../../../../../lib/features/chat/domain/repositories/i_chat_repository.dart';
import '../../../../../lib/features/chat/domain/usecases/get_messages_usecase.dart';

class MockChatRepository extends Mock implements IChatRepository {}

void main() {
  late GetMessagesUseCase useCase;
  late MockChatRepository mockRepository;

  setUp(() {
    mockRepository = MockChatRepository();
    useCase = GetMessagesUseCase(mockRepository);
  });

  group('GetMessagesUseCase', () {
    const testRoomId = 'room-123';
    
    final testMessages = [
      Message(
        id: 'message-1',
        roomId: testRoomId,
        userId: 'user-1',
        content: 'Hello',
        type: MessageType.text,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      Message(
        id: 'message-2',
        roomId: testRoomId,
        userId: 'user-2',
        content: 'Hi there!',
        type: MessageType.text,
        createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
    ];

    test('should get messages successfully with default parameters', () async {
      // Arrange
      const testParams = GetMessagesParams(roomId: testRoomId);
      
      when(() => mockRepository.getMessages(
        any(),
        limit: any(named: 'limit'),
        before: any(named: 'before'),
      )).thenAnswer((_) async => testMessages);

      // Act
      final result = await useCase(testParams);

      // Assert
      expect(result, isA<Success<List<Message>>>());
      expect(result.dataOrNull, equals(testMessages));
      expect(result.dataOrNull?.length, equals(2));
      
      verify(() => mockRepository.getMessages(
        testRoomId,
        limit: 50, // Default limit
        before: null,
      )).called(1);
    });

    test('should get messages with custom limit', () async {
      // Arrange
      const testParams = GetMessagesParams(
        roomId: testRoomId,
        limit: 20,
      );
      
      when(() => mockRepository.getMessages(
        any(),
        limit: any(named: 'limit'),
        before: any(named: 'before'),
      )).thenAnswer((_) async => testMessages);

      // Act
      final result = await useCase(testParams);

      // Assert
      expect(result, isA<Success<List<Message>>>());
      
      verify(() => mockRepository.getMessages(
        testRoomId,
        limit: 20,
        before: null,
      )).called(1);
    });

    test('should get messages with pagination (before parameter)', () async {
      // Arrange
      const beforeMessageId = 'message-before-123';
      const testParams = GetMessagesParams(
        roomId: testRoomId,
        before: beforeMessageId,
      );
      
      when(() => mockRepository.getMessages(
        any(),
        limit: any(named: 'limit'),
        before: any(named: 'before'),
      )).thenAnswer((_) async => testMessages);

      // Act
      final result = await useCase(testParams);

      // Assert
      expect(result, isA<Success<List<Message>>>());
      
      verify(() => mockRepository.getMessages(
        testRoomId,
        limit: 50,
        before: beforeMessageId,
      )).called(1);
    });

    test('should get messages with both custom limit and pagination', () async {
      // Arrange
      const beforeMessageId = 'message-before-123';
      const testParams = GetMessagesParams(
        roomId: testRoomId,
        limit: 25,
        before: beforeMessageId,
      );
      
      when(() => mockRepository.getMessages(
        any(),
        limit: any(named: 'limit'),
        before: any(named: 'before'),
      )).thenAnswer((_) async => testMessages);

      // Act
      final result = await useCase(testParams);

      // Assert
      expect(result, isA<Success<List<Message>>>());
      
      verify(() => mockRepository.getMessages(
        testRoomId,
        limit: 25,
        before: beforeMessageId,
      )).called(1);
    });

    test('should return empty list when no messages found', () async {
      // Arrange
      const testParams = GetMessagesParams(roomId: testRoomId);
      
      when(() => mockRepository.getMessages(
        any(),
        limit: any(named: 'limit'),
        before: any(named: 'before'),
      )).thenAnswer((_) async => []);

      // Act
      final result = await useCase(testParams);

      // Assert
      expect(result, isA<Success<List<Message>>>());
      expect(result.dataOrNull, isEmpty);
    });

    test('should return failure when repository throws exception', () async {
      // Arrange
      const testParams = GetMessagesParams(roomId: testRoomId);
      
      when(() => mockRepository.getMessages(
        any(),
        limit: any(named: 'limit'),
        before: any(named: 'before'),
      )).thenThrow(Exception('Network error'));

      // Act
      final result = await useCase(testParams);

      // Assert
      expect(result, isA<ResultFailure<List<Message>>>());
      expect(result.failureOrNull?.message, contains('Failed to get messages'));
    });

    test('should handle different message types', () async {
      // Arrange
      final mixedMessages = [
        Message(
          id: 'message-1',
          roomId: testRoomId,
          userId: 'user-1',
          content: 'Hello',
          type: MessageType.text,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Message(
          id: 'message-2',
          roomId: testRoomId,
          userId: 'user-2',
          content: 'Image description',
          type: MessageType.image,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Message(
          id: 'message-3',
          roomId: testRoomId,
          userId: 'user-1',
          content: 'Voice message',
          type: MessageType.audio,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      
      const testParams = GetMessagesParams(roomId: testRoomId);
      
      when(() => mockRepository.getMessages(
        any(),
        limit: any(named: 'limit'),
        before: any(named: 'before'),
      )).thenAnswer((_) async => mixedMessages);

      // Act
      final result = await useCase(testParams);

      // Assert
      expect(result, isA<Success<List<Message>>>());
      expect(result.dataOrNull?.length, equals(3));
      expect(result.dataOrNull?[0].type, equals(MessageType.text));
      expect(result.dataOrNull?[1].type, equals(MessageType.image));
      expect(result.dataOrNull?[2].type, equals(MessageType.audio));
    });
  });

  group('GetMessagesParams', () {
    test('should create params with required fields only', () {
      // Arrange & Act
      const params = GetMessagesParams(roomId: 'room-123');

      // Assert
      expect(params.roomId, equals('room-123'));
      expect(params.limit, equals(50)); // Default value
      expect(params.before, isNull);
    });

    test('should create params with all fields', () {
      // Arrange & Act
      const params = GetMessagesParams(
        roomId: 'room-123',
        limit: 25,
        before: 'message-before',
      );

      // Assert
      expect(params.roomId, equals('room-123'));
      expect(params.limit, equals(25));
      expect(params.before, equals('message-before'));
    });

    test('should support equality comparison', () {
      // Arrange
      const params1 = GetMessagesParams(
        roomId: 'room-123',
        limit: 25,
      );
      const params2 = GetMessagesParams(
        roomId: 'room-123',
        limit: 25,
      );
      const params3 = GetMessagesParams(
        roomId: 'room-123',
        limit: 50,
      );

      // Act & Assert
      expect(params1, equals(params2));
      expect(params1, isNot(equals(params3)));
    });
  });
}