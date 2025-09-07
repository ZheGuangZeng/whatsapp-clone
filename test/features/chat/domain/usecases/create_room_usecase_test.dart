import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:whatsapp_clone/core/errors/failures.dart';
import 'package:whatsapp_clone/core/utils/result.dart';
import 'package:whatsapp_clone/features/chat/domain/entities/room.dart';
import 'package:whatsapp_clone/features/chat/domain/entities/room_type.dart';
import 'package:whatsapp_clone/features/chat/domain/repositories/i_room_repository.dart';
import 'package:whatsapp_clone/features/chat/domain/usecases/create_room_usecase.dart';

// Mock repository for testing
class MockRoomRepository extends Mock implements IRoomRepository {}

void main() {
  group('CreateRoomUseCase Tests', () {
    late CreateRoomUseCase useCase;
    late MockRoomRepository mockRepository;

    setUpAll(() {
      // Register fallback values for mocktail
      registerFallbackValue(RoomType.group);
      registerFallbackValue(<String>[]);
    });

    setUp(() {
      mockRepository = MockRoomRepository();
      useCase = CreateRoomUseCase(mockRepository);
    });

    test('should create a room successfully with required parameters', () async {
      // Arrange
      const params = CreateRoomParams(
        name: 'Test Room',
        creatorId: 'user_123',
      );
      
      final expectedRoom = Room(
        id: 'room_123',
        name: 'Test Room',
        creatorId: 'user_123',
        createdAt: DateTime.now(),
      );

      when(() => mockRepository.createRoom(
        name: any(named: 'name'),
        creatorId: any(named: 'creatorId'),
        type: any(named: 'type'),
        description: any(named: 'description'),
        avatarUrl: any(named: 'avatarUrl'),
        initialParticipants: any(named: 'initialParticipants'),
      )).thenAnswer((_) async => Success(expectedRoom));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isSuccess, isTrue);
      final room = result.dataOrNull!;
      expect(room.name, equals('Test Room'));
      expect(room.creatorId, equals('user_123'));
      expect(room.type, equals(RoomType.group)); // default

      verify(() => mockRepository.createRoom(
        name: 'Test Room',
        creatorId: 'user_123',
        type: RoomType.group,
        description: null,
        avatarUrl: null,
        initialParticipants: null,
      )).called(1);
    });

    test('should create a room with all optional parameters', () async {
      // Arrange
      const params = CreateRoomParams(
        name: 'Test Room',
        creatorId: 'user_123',
        type: RoomType.direct,
        description: 'Test description',
        avatarUrl: 'https://example.com/avatar.jpg',
        initialParticipants: ['user_456', 'user_789'],
      );
      
      final expectedRoom = Room(
        id: 'room_123',
        name: 'Test Room',
        creatorId: 'user_123',
        createdAt: DateTime.now(),
        type: RoomType.direct,
        description: 'Test description',
        avatarUrl: 'https://example.com/avatar.jpg',
        participantCount: 3, // 2 initial + 1 creator
      );

      when(() => mockRepository.createRoom(
        name: any(named: 'name'),
        creatorId: any(named: 'creatorId'),
        type: any(named: 'type'),
        description: any(named: 'description'),
        avatarUrl: any(named: 'avatarUrl'),
        initialParticipants: any(named: 'initialParticipants'),
      )).thenAnswer((_) async => Success(expectedRoom));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isSuccess, isTrue);
      final room = result.dataOrNull!;
      expect(room.name, equals('Test Room'));
      expect(room.creatorId, equals('user_123'));
      expect(room.type, equals(RoomType.direct));
      expect(room.description, equals('Test description'));
      expect(room.avatarUrl, equals('https://example.com/avatar.jpg'));

      verify(() => mockRepository.createRoom(
        name: 'Test Room',
        creatorId: 'user_123',
        type: RoomType.direct,
        description: 'Test description',
        avatarUrl: 'https://example.com/avatar.jpg',
        initialParticipants: ['user_456', 'user_789'],
      )).called(1);
    });

    test('should return failure when repository fails', () async {
      // Arrange
      const params = CreateRoomParams(
        name: 'Test Room',
        creatorId: 'user_123',
      );
      
      const failure = ServerFailure(message: 'Failed to create room');

      when(() => mockRepository.createRoom(
        name: any(named: 'name'),
        creatorId: any(named: 'creatorId'),
        type: any(named: 'type'),
        description: any(named: 'description'),
        avatarUrl: any(named: 'avatarUrl'),
        initialParticipants: any(named: 'initialParticipants'),
      )).thenAnswer((_) async => ResultFailure(failure));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, equals(failure));

      verify(() => mockRepository.createRoom(
        name: 'Test Room',
        creatorId: 'user_123',
        type: RoomType.group,
        description: null,
        avatarUrl: null,
        initialParticipants: null,
      )).called(1);
    });

    test('should validate room name is not empty', () async {
      // Arrange
      const params = CreateRoomParams(
        name: '',
        creatorId: 'user_123',
      );

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());

      verifyNever(() => mockRepository.createRoom(
        name: any(named: 'name'),
        creatorId: any(named: 'creatorId'),
        type: any(named: 'type'),
        description: any(named: 'description'),
        avatarUrl: any(named: 'avatarUrl'),
        initialParticipants: any(named: 'initialParticipants'),
      ));
    });

    test('should validate creator ID is not empty', () async {
      // Arrange
      const params = CreateRoomParams(
        name: 'Test Room',
        creatorId: '',
      );

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());

      verifyNever(() => mockRepository.createRoom(
        name: any(named: 'name'),
        creatorId: any(named: 'creatorId'),
        type: any(named: 'type'),
        description: any(named: 'description'),
        avatarUrl: any(named: 'avatarUrl'),
        initialParticipants: any(named: 'initialParticipants'),
      ));
    });

    test('should handle different room types correctly', () async {
      // Test group room
      const groupParams = CreateRoomParams(
        name: 'Group Room',
        creatorId: 'user_123',
        type: RoomType.group,
      );

      final groupRoom = Room(
        id: 'group_123',
        name: 'Group Room',
        creatorId: 'user_123',
        createdAt: DateTime.now(),
        type: RoomType.group,
      );

      when(() => mockRepository.createRoom(
        name: 'Group Room',
        creatorId: 'user_123',
        type: RoomType.group,
        description: null,
        avatarUrl: null,
        initialParticipants: null,
      )).thenAnswer((_) async => Success(groupRoom));

      // Test direct room
      const directParams = CreateRoomParams(
        name: 'Direct Room',
        creatorId: 'user_123',
        type: RoomType.direct,
      );

      final directRoom = Room(
        id: 'direct_123',
        name: 'Direct Room',
        creatorId: 'user_123',
        createdAt: DateTime.now(),
        type: RoomType.direct,
      );

      when(() => mockRepository.createRoom(
        name: 'Direct Room',
        creatorId: 'user_123',
        type: RoomType.direct,
        description: null,
        avatarUrl: null,
        initialParticipants: null,
      )).thenAnswer((_) async => Success(directRoom));

      // Act
      final groupResult = await useCase(groupParams);
      final directResult = await useCase(directParams);

      // Assert
      expect(groupResult.isSuccess, isTrue);
      expect(directResult.isSuccess, isTrue);
      expect(groupResult.dataOrNull!.type, equals(RoomType.group));
      expect(directResult.dataOrNull!.type, equals(RoomType.direct));
    });

    test('should handle invalid avatar URL gracefully', () async {
      // Arrange
      const params = CreateRoomParams(
        name: 'Test Room',
        creatorId: 'user_123',
        avatarUrl: 'invalid-url',
      );

      // Since URL validation might be handled at the repository level,
      // we test that the use case passes the parameter correctly
      final expectedRoom = Room(
        id: 'room_123',
        name: 'Test Room',
        creatorId: 'user_123',
        createdAt: DateTime.now(),
        avatarUrl: 'invalid-url',
      );

      when(() => mockRepository.createRoom(
        name: any(named: 'name'),
        creatorId: any(named: 'creatorId'),
        type: any(named: 'type'),
        description: any(named: 'description'),
        avatarUrl: any(named: 'avatarUrl'),
        initialParticipants: any(named: 'initialParticipants'),
      )).thenAnswer((_) async => Success(expectedRoom));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isSuccess, isTrue);
      verify(() => mockRepository.createRoom(
        name: 'Test Room',
        creatorId: 'user_123',
        type: RoomType.group,
        description: null,
        avatarUrl: 'invalid-url',
        initialParticipants: null,
      )).called(1);
    });

    test('should handle large participant lists correctly', () async {
      // Arrange
      final largeParticipantList = List.generate(100, (i) => 'user_$i');
      final params = CreateRoomParams(
        name: 'Large Room',
        creatorId: 'user_123',
        initialParticipants: largeParticipantList,
      );

      final expectedRoom = Room(
        id: 'room_123',
        name: 'Large Room',
        creatorId: 'user_123',
        createdAt: DateTime.now(),
        participantCount: 101, // 100 initial + 1 creator
      );

      when(() => mockRepository.createRoom(
        name: any(named: 'name'),
        creatorId: any(named: 'creatorId'),
        type: any(named: 'type'),
        description: any(named: 'description'),
        avatarUrl: any(named: 'avatarUrl'),
        initialParticipants: any(named: 'initialParticipants'),
      )).thenAnswer((_) async => Success(expectedRoom));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isSuccess, isTrue);
      verify(() => mockRepository.createRoom(
        name: 'Large Room',
        creatorId: 'user_123',
        type: RoomType.group,
        description: null,
        avatarUrl: null,
        initialParticipants: largeParticipantList,
      )).called(1);
    });
  });
}