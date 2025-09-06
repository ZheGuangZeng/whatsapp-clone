import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:whatsapp_clone/core/errors/failures.dart';
import 'package:whatsapp_clone/core/utils/result.dart';
import 'package:whatsapp_clone/features/chat/domain/entities/room.dart';
import 'package:whatsapp_clone/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:whatsapp_clone/features/chat/domain/usecases/create_room_usecase.dart';

class MockChatRepository extends Mock implements IChatRepository {}

void main() {
  late CreateRoomUseCase useCase;
  late GetOrCreateDirectMessageUseCase directMessageUseCase;
  late MockChatRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(RoomType.direct);
  });

  setUp(() {
    mockRepository = MockChatRepository();
    useCase = CreateRoomUseCase(mockRepository);
    directMessageUseCase = GetOrCreateDirectMessageUseCase(mockRepository);
  });

  group('CreateRoomUseCase', () {
    final testRoom = Room(
      id: 'room-123',
      name: 'Test Room',
      type: RoomType.group,
      createdBy: 'user-123',
      createdAt: DateTime.utc(2023, 1, 1),
      updatedAt: DateTime.utc(2023, 1, 1),
    );

    group('group room creation', () {
      test('should create group room successfully', () async {
        // Arrange
        const params = CreateRoomParams(
          name: 'Test Room',
          description: 'Test Description',
          type: RoomType.group,
          participantIds: ['user-1', 'user-2'],
        );

        when(() => mockRepository.createRoom(
              name: any(named: 'name'),
              description: any(named: 'description'),
              type: any(named: 'type'),
              participantIds: any(named: 'participantIds'),
            )).thenAnswer((_) async => testRoom);

        // Act
        final result = await useCase(params);

        // Assert
        expect(result, isA<Success<Room>>());
        expect(result.dataOrNull, testRoom);
        verify(() => mockRepository.createRoom(
              name: 'Test Room',
              description: 'Test Description',
              type: 'group',
              participantIds: ['user-1', 'user-2'],
            )).called(1);
      });

      test('should create group room without description', () async {
        // Arrange
        const params = CreateRoomParams(
          name: 'Test Room',
          type: RoomType.group,
          participantIds: ['user-1', 'user-2'],
        );

        when(() => mockRepository.createRoom(
              name: any(named: 'name'),
              description: any(named: 'description'),
              type: any(named: 'type'),
              participantIds: any(named: 'participantIds'),
            )).thenAnswer((_) async => testRoom);

        // Act
        final result = await useCase(params);

        // Assert
        expect(result, isA<Success<Room>>());
        expect(result.dataOrNull, testRoom);
        verify(() => mockRepository.createRoom(
              name: 'Test Room',
              description: null,
              type: 'group',
              participantIds: ['user-1', 'user-2'],
            )).called(1);
      });

      test('should create group room with empty participants', () async {
        // Arrange
        const params = CreateRoomParams(
          name: 'Test Room',
          type: RoomType.group,
        );

        when(() => mockRepository.createRoom(
              name: any(named: 'name'),
              description: any(named: 'description'),
              type: any(named: 'type'),
              participantIds: any(named: 'participantIds'),
            )).thenAnswer((_) async => testRoom);

        // Act
        final result = await useCase(params);

        // Assert
        expect(result, isA<Success<Room>>());
        verify(() => mockRepository.createRoom(
              name: 'Test Room',
              description: null,
              type: 'group',
              participantIds: const <String>[],
            )).called(1);
      });
    });

    group('direct message room creation', () {
      test('should create direct room successfully', () async {
        // Arrange
        final directRoom = testRoom.copyWith(
          type: RoomType.direct,
          name: null,
        );

        const params = CreateRoomParams(
          type: RoomType.direct,
          participantIds: ['user-1'],
        );

        when(() => mockRepository.createRoom(
              name: any(named: 'name'),
              description: any(named: 'description'),
              type: any(named: 'type'),
              participantIds: any(named: 'participantIds'),
            )).thenAnswer((_) async => directRoom);

        // Act
        final result = await useCase(params);

        // Assert
        expect(result, isA<Success<Room>>());
        expect(result.dataOrNull, directRoom);
        verify(() => mockRepository.createRoom(
              name: null,
              description: null,
              type: 'direct',
              participantIds: ['user-1'],
            )).called(1);
      });
    });

    group('error handling', () {
      test('should return failure when repository throws exception', () async {
        // Arrange
        const params = CreateRoomParams(
          name: 'Test Room',
          type: RoomType.group,
        );

        when(() => mockRepository.createRoom(
              name: any(named: 'name'),
              description: any(named: 'description'),
              type: any(named: 'type'),
              participantIds: any(named: 'participantIds'),
            )).thenThrow(Exception('Network error'));

        // Act
        final result = await useCase(params);

        // Assert
        expect(result, isA<ResultFailure<Room>>());
        final failure = result.failureOrNull;
        expect(failure, isA<ServerFailure>());
        expect(failure!.message, 'Failed to create room');
        verify(() => mockRepository.createRoom(
              name: 'Test Room',
              description: null,
              type: 'group',
              participantIds: const <String>[],
            )).called(1);
      });

      test('should handle various exception types', () async {
        // Arrange
        const params = CreateRoomParams(
          name: 'Test Room',
          type: RoomType.group,
        );

        when(() => mockRepository.createRoom(
              name: any(named: 'name'),
              description: any(named: 'description'),
              type: any(named: 'type'),
              participantIds: any(named: 'participantIds'),
            )).thenThrow(ArgumentError('Invalid argument'));

        // Act
        final result = await useCase(params);

        // Assert
        expect(result, isA<ResultFailure<Room>>());
        expect(result.failureOrNull, isA<ServerFailure>());
      });
    });
  });

  group('GetOrCreateDirectMessageUseCase', () {
    final testDirectRoom = Room(
      id: 'dm-room-123',
      type: RoomType.direct,
      createdBy: 'user-123',
      createdAt: DateTime.utc(2023, 1, 1),
      updatedAt: DateTime.utc(2023, 1, 1),
    );

    test('should get or create direct message successfully', () async {
      // Arrange
      const params = GetOrCreateDirectMessageParams(otherUserId: 'user-456');

      when(() => mockRepository.getOrCreateDirectMessage(any()))
          .thenAnswer((_) async => testDirectRoom);

      // Act
      final result = await directMessageUseCase(params);

      // Assert
      expect(result, isA<Success<Room>>());
      expect(result.dataOrNull, testDirectRoom);
      verify(() => mockRepository.getOrCreateDirectMessage('user-456')).called(1);
    });

    test('should return failure when repository throws exception', () async {
      // Arrange
      const params = GetOrCreateDirectMessageParams(otherUserId: 'user-456');

      when(() => mockRepository.getOrCreateDirectMessage(any()))
          .thenThrow(Exception('Database error'));

      // Act
      final result = await directMessageUseCase(params);

      // Assert
      expect(result, isA<ResultFailure<Room>>());
      final failure = result.failureOrNull;
      expect(failure, isA<ServerFailure>());
      expect(failure!.message, 'Failed to get or create direct message');
    });

    test('should handle invalid user ID', () async {
      // Arrange
      const params = GetOrCreateDirectMessageParams(otherUserId: '');

      when(() => mockRepository.getOrCreateDirectMessage(any()))
          .thenThrow(ArgumentError('Invalid user ID'));

      // Act
      final result = await directMessageUseCase(params);

      // Assert
      expect(result, isA<ResultFailure<Room>>());
      expect(result.failureOrNull, isA<ServerFailure>());
    });
  });

  group('CreateRoomParams', () {
    test('should create params with all properties', () {
      const params = CreateRoomParams(
        name: 'Test Room',
        description: 'Test Description',
        type: RoomType.group,
        participantIds: ['user-1', 'user-2'],
      );

      expect(params.name, 'Test Room');
      expect(params.description, 'Test Description');
      expect(params.type, RoomType.group);
      expect(params.participantIds, ['user-1', 'user-2']);
    });

    test('should create params with minimal properties', () {
      const params = CreateRoomParams(type: RoomType.direct);

      expect(params.name, isNull);
      expect(params.description, isNull);
      expect(params.type, RoomType.direct);
      expect(params.participantIds, isEmpty);
    });

    test('should support equality comparison', () {
      const params1 = CreateRoomParams(
        name: 'Test Room',
        type: RoomType.group,
        participantIds: ['user-1'],
      );

      const params2 = CreateRoomParams(
        name: 'Test Room',
        type: RoomType.group,
        participantIds: ['user-1'],
      );

      const params3 = CreateRoomParams(
        name: 'Different Room',
        type: RoomType.group,
        participantIds: ['user-1'],
      );

      expect(params1, equals(params2));
      expect(params1, isNot(equals(params3)));
    });

    test('should have consistent hashCode for equal objects', () {
      const params1 = CreateRoomParams(
        name: 'Test Room',
        type: RoomType.group,
      );

      const params2 = CreateRoomParams(
        name: 'Test Room',
        type: RoomType.group,
      );

      expect(params1.hashCode, params2.hashCode);
    });

    test('should include all properties in props', () {
      const params = CreateRoomParams(
        name: 'Test Room',
        description: 'Test Description',
        type: RoomType.group,
        participantIds: ['user-1', 'user-2'],
      );

      final props = params.props;
      expect(props, contains(params.name));
      expect(props, contains(params.description));
      expect(props, contains(params.type));
      expect(props, contains(params.participantIds));
    });
  });

  group('GetOrCreateDirectMessageParams', () {
    test('should create params with other user ID', () {
      const params = GetOrCreateDirectMessageParams(otherUserId: 'user-456');

      expect(params.otherUserId, 'user-456');
    });

    test('should support equality comparison', () {
      const params1 = GetOrCreateDirectMessageParams(otherUserId: 'user-456');
      const params2 = GetOrCreateDirectMessageParams(otherUserId: 'user-456');
      const params3 = GetOrCreateDirectMessageParams(otherUserId: 'user-789');

      expect(params1, equals(params2));
      expect(params1, isNot(equals(params3)));
    });

    test('should have consistent hashCode for equal objects', () {
      const params1 = GetOrCreateDirectMessageParams(otherUserId: 'user-456');
      const params2 = GetOrCreateDirectMessageParams(otherUserId: 'user-456');

      expect(params1.hashCode, params2.hashCode);
    });

    test('should include all properties in props', () {
      const params = GetOrCreateDirectMessageParams(otherUserId: 'user-456');

      expect(params.props, contains(params.otherUserId));
    });
  });
}