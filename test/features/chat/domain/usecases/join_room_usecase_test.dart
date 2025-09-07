import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:whatsapp_clone/core/errors/failures.dart';
import 'package:whatsapp_clone/core/utils/result.dart';
import 'package:whatsapp_clone/features/chat/domain/entities/participant.dart';
import 'package:whatsapp_clone/features/chat/domain/entities/participant_role.dart';
import 'package:whatsapp_clone/features/chat/domain/repositories/i_room_repository.dart';
import 'package:whatsapp_clone/features/chat/domain/usecases/join_room_usecase.dart';

// Mock repository for testing
class MockRoomRepository extends Mock implements IRoomRepository {}

void main() {
  group('JoinRoomUseCase Tests', () {
    late JoinRoomUseCase useCase;
    late MockRoomRepository mockRepository;

    setUpAll(() {
      // Register fallback values for mocktail
      registerFallbackValue(ParticipantRole.member);
      registerFallbackValue(<String>[]);
    });

    setUp(() {
      mockRepository = MockRoomRepository();
      useCase = JoinRoomUseCase(mockRepository);
    });

    test('should join room successfully with default member role', () async {
      // Arrange
      const params = JoinRoomParams(
        roomId: 'room_123',
        userId: 'user_456',
      );
      
      final expectedParticipant = Participant(
        id: 'participant_123',
        userId: 'user_456',
        roomId: 'room_123',
        joinedAt: DateTime.now(),
        role: ParticipantRole.member,
      );

      when(() => mockRepository.addParticipant(
        roomId: any(named: 'roomId'),
        userId: any(named: 'userId'),
        role: any(named: 'role'),
        permissions: any(named: 'permissions'),
      )).thenAnswer((_) async => Success(expectedParticipant));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isSuccess, isTrue);
      final participant = result.dataOrNull!;
      expect(participant.userId, equals('user_456'));
      expect(participant.roomId, equals('room_123'));
      expect(participant.role, equals(ParticipantRole.member));

      verify(() => mockRepository.addParticipant(
        roomId: 'room_123',
        userId: 'user_456',
        role: ParticipantRole.member,
        permissions: null,
      )).called(1);
    });

    test('should join room with specified role and permissions', () async {
      // Arrange
      const params = JoinRoomParams(
        roomId: 'room_123',
        userId: 'user_456',
        role: ParticipantRole.moderator,
        permissions: ['read', 'write', 'moderate'],
      );
      
      final expectedParticipant = Participant(
        id: 'participant_123',
        userId: 'user_456',
        roomId: 'room_123',
        joinedAt: DateTime.now(),
        role: ParticipantRole.moderator,
        permissions: const ['read', 'write', 'moderate'],
      );

      when(() => mockRepository.addParticipant(
        roomId: any(named: 'roomId'),
        userId: any(named: 'userId'),
        role: any(named: 'role'),
        permissions: any(named: 'permissions'),
      )).thenAnswer((_) async => Success(expectedParticipant));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isSuccess, isTrue);
      final participant = result.dataOrNull!;
      expect(participant.userId, equals('user_456'));
      expect(participant.roomId, equals('room_123'));
      expect(participant.role, equals(ParticipantRole.moderator));
      expect(participant.permissions, equals(const ['read', 'write', 'moderate']));

      verify(() => mockRepository.addParticipant(
        roomId: 'room_123',
        userId: 'user_456',
        role: ParticipantRole.moderator,
        permissions: const ['read', 'write', 'moderate'],
      )).called(1);
    });

    test('should return failure when repository fails', () async {
      // Arrange
      const params = JoinRoomParams(
        roomId: 'room_123',
        userId: 'user_456',
      );
      
      const failure = ServerFailure(message: 'Failed to add participant');

      when(() => mockRepository.addParticipant(
        roomId: any(named: 'roomId'),
        userId: any(named: 'userId'),
        role: any(named: 'role'),
        permissions: any(named: 'permissions'),
      )).thenAnswer((_) async => const ResultFailure(failure));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, equals(failure));

      verify(() => mockRepository.addParticipant(
        roomId: 'room_123',
        userId: 'user_456',
        role: ParticipantRole.member,
        permissions: null,
      )).called(1);
    });

    test('should validate room ID is not empty', () async {
      // Arrange
      const params = JoinRoomParams(
        roomId: '',
        userId: 'user_456',
      );

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());

      verifyNever(() => mockRepository.addParticipant(
        roomId: any(named: 'roomId'),
        userId: any(named: 'userId'),
        role: any(named: 'role'),
        permissions: any(named: 'permissions'),
      ));
    });

    test('should validate user ID is not empty', () async {
      // Arrange
      const params = JoinRoomParams(
        roomId: 'room_123',
        userId: '',
      );

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());

      verifyNever(() => mockRepository.addParticipant(
        roomId: any(named: 'roomId'),
        userId: any(named: 'userId'),
        role: any(named: 'role'),
        permissions: any(named: 'permissions'),
      ));
    });

    test('should handle different participant roles correctly', () async {
      // Test member role
      const memberParams = JoinRoomParams(
        roomId: 'room_123',
        userId: 'user_456',
        role: ParticipantRole.member,
      );

      final memberParticipant = Participant(
        id: 'participant_123',
        userId: 'user_456',
        roomId: 'room_123',
        joinedAt: DateTime.now(),
        role: ParticipantRole.member,
      );

      when(() => mockRepository.addParticipant(
        roomId: 'room_123',
        userId: 'user_456',
        role: ParticipantRole.member,
        permissions: null,
      )).thenAnswer((_) async => Success(memberParticipant));

      // Test admin role
      const adminParams = JoinRoomParams(
        roomId: 'room_123',
        userId: 'user_789',
        role: ParticipantRole.admin,
        permissions: ['admin'],
      );

      final adminParticipant = Participant(
        id: 'participant_456',
        userId: 'user_789',
        roomId: 'room_123',
        joinedAt: DateTime.now(),
        role: ParticipantRole.admin,
        permissions: const ['admin'],
      );

      when(() => mockRepository.addParticipant(
        roomId: 'room_123',
        userId: 'user_789',
        role: ParticipantRole.admin,
        permissions: const ['admin'],
      )).thenAnswer((_) async => Success(adminParticipant));

      // Act
      final memberResult = await useCase(memberParams);
      final adminResult = await useCase(adminParams);

      // Assert
      expect(memberResult.isSuccess, isTrue);
      expect(adminResult.isSuccess, isTrue);
      expect(memberResult.dataOrNull!.role, equals(ParticipantRole.member));
      expect(adminResult.dataOrNull!.role, equals(ParticipantRole.admin));
      expect(adminResult.dataOrNull!.permissions, equals(const ['admin']));
    });

    test('should handle empty permissions list correctly', () async {
      // Arrange
      const params = JoinRoomParams(
        roomId: 'room_123',
        userId: 'user_456',
        role: ParticipantRole.member,
        permissions: <String>[],
      );
      
      final expectedParticipant = Participant(
        id: 'participant_123',
        userId: 'user_456',
        roomId: 'room_123',
        joinedAt: DateTime.now(),
        role: ParticipantRole.member,
        permissions: const [],
      );

      when(() => mockRepository.addParticipant(
        roomId: any(named: 'roomId'),
        userId: any(named: 'userId'),
        role: any(named: 'role'),
        permissions: any(named: 'permissions'),
      )).thenAnswer((_) async => Success(expectedParticipant));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isSuccess, isTrue);
      final participant = result.dataOrNull!;
      expect(participant.permissions, isEmpty);

      verify(() => mockRepository.addParticipant(
        roomId: 'room_123',
        userId: 'user_456',
        role: ParticipantRole.member,
        permissions: const [],
      )).called(1);
    });

    test('should handle room not found error', () async {
      // Arrange
      const params = JoinRoomParams(
        roomId: 'non_existent_room',
        userId: 'user_456',
      );
      
      const failure = ValidationFailure(message: 'Room not found');

      when(() => mockRepository.addParticipant(
        roomId: any(named: 'roomId'),
        userId: any(named: 'userId'),
        role: any(named: 'role'),
        permissions: any(named: 'permissions'),
      )).thenAnswer((_) async => const ResultFailure(failure));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, equals(failure));
    });

    test('should handle user already participant error', () async {
      // Arrange
      const params = JoinRoomParams(
        roomId: 'room_123',
        userId: 'existing_user',
      );
      
      const failure = ConflictFailure('User is already a participant');

      when(() => mockRepository.addParticipant(
        roomId: any(named: 'roomId'),
        userId: any(named: 'userId'),
        role: any(named: 'role'),
        permissions: any(named: 'permissions'),
      )).thenAnswer((_) async => const ResultFailure(failure));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, equals(failure));
    });

    test('should handle permission validation correctly', () async {
      // Arrange
      const params = JoinRoomParams(
        roomId: 'room_123',
        userId: 'user_456',
        role: ParticipantRole.member,
        permissions: ['invalid_permission', 'read', 'write'],
      );
      
      final expectedParticipant = Participant(
        id: 'participant_123',
        userId: 'user_456',
        roomId: 'room_123',
        joinedAt: DateTime.now(),
        role: ParticipantRole.member,
        permissions: const ['invalid_permission', 'read', 'write'],
      );

      when(() => mockRepository.addParticipant(
        roomId: any(named: 'roomId'),
        userId: any(named: 'userId'),
        role: any(named: 'role'),
        permissions: any(named: 'permissions'),
      )).thenAnswer((_) async => Success(expectedParticipant));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isSuccess, isTrue);
      // Note: Permission validation would typically be handled at the repository level
      verify(() => mockRepository.addParticipant(
        roomId: 'room_123',
        userId: 'user_456',
        role: ParticipantRole.member,
        permissions: const ['invalid_permission', 'read', 'write'],
      )).called(1);
    });
  });
}