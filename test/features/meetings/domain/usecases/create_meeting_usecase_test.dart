import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:whatsapp_clone/core/errors/failures.dart';
import 'package:whatsapp_clone/core/utils/result.dart';
import 'package:whatsapp_clone/features/meetings/domain/entities/meeting.dart';
import 'package:whatsapp_clone/features/meetings/domain/entities/meeting_settings.dart';
import 'package:whatsapp_clone/features/meetings/domain/entities/meeting_state.dart';
import 'package:whatsapp_clone/features/meetings/domain/repositories/i_meeting_repository.dart';
import 'package:whatsapp_clone/features/meetings/domain/usecases/create_meeting_usecase.dart';

class MockMeetingRepository extends Mock implements IMeetingRepository {}

void main() {
  group('CreateMeetingUseCase', () {
    late CreateMeetingUseCase useCase;
    late MockMeetingRepository mockRepository;

    setUpAll(() {
      registerFallbackValue(const CreateMeetingParams(
        title: 'Test Meeting',
        hostId: 'test-host',
        settings: MeetingSettings.openMeeting(),
      ));
    });

    setUp(() {
      mockRepository = MockMeetingRepository();
      useCase = CreateMeetingUseCase(mockRepository);
    });

    group('Valid Meeting Creation', () {
      test('should create meeting successfully with all required fields', () async {
        // Arrange
        final params = CreateMeetingParams(
          title: 'Team Standup',
          description: 'Daily standup meeting',
          hostId: 'user-123',
          scheduledStartTime: DateTime.now().add(const Duration(hours: 1)),
          settings: const MeetingSettings.openMeeting(),
        );

        final expectedMeeting = Meeting(
          id: 'meeting-123',
          title: params.title,
          description: params.description,
          hostId: params.hostId,
          roomId: 'room-456',
          createdAt: DateTime.now(),
          scheduledStartTime: params.scheduledStartTime,
          state: MeetingState.scheduled,
          settings: params.settings,
          participants: const [],
        );

        when(() => mockRepository.createMeeting(params))
            .thenAnswer((_) async => Success(expectedMeeting));

        // Act
        final result = await useCase(params);

        // Assert
        expect(result, isA<Success<Meeting>>());
        expect(result.dataOrNull, equals(expectedMeeting));
        verify(() => mockRepository.createMeeting(params)).called(1);
      });

      test('should create instant meeting without scheduled start time', () async {
        // Arrange
        const params = CreateMeetingParams(
          title: 'Instant Meeting',
          hostId: 'user-456',
          settings: MeetingSettings.openMeeting(),
        );

        final expectedMeeting = Meeting(
          id: 'meeting-456',
          title: params.title,
          hostId: params.hostId,
          roomId: 'room-789',
          createdAt: DateTime.now(),
          state: MeetingState.scheduled,
          settings: params.settings,
          participants: const [],
        );

        when(() => mockRepository.createMeeting(params))
            .thenAnswer((_) async => Success(expectedMeeting));

        // Act
        final result = await useCase(params);

        // Assert
        expect(result, isA<Success<Meeting>>());
        expect(result.dataOrNull!.scheduledStartTime, isNull);
        verify(() => mockRepository.createMeeting(params)).called(1);
      });

      test('should create meeting with custom settings', () async {
        // Arrange
        const customSettings = MeetingSettings(
          maxParticipants: 25,
          isRecordingEnabled: true,
          allowScreenShare: false,
          password: 'secure123',
        );

        const params = CreateMeetingParams(
          title: 'Secure Meeting',
          hostId: 'user-789',
          settings: customSettings,
        );

        final expectedMeeting = Meeting(
          id: 'meeting-789',
          title: params.title,
          hostId: params.hostId,
          roomId: 'room-321',
          createdAt: DateTime.now(),
          state: MeetingState.scheduled,
          settings: customSettings,
          participants: const [],
        );

        when(() => mockRepository.createMeeting(params))
            .thenAnswer((_) async => Success(expectedMeeting));

        // Act
        final result = await useCase(params);

        // Assert
        expect(result, isA<Success<Meeting>>());
        expect(result.dataOrNull!.settings, equals(customSettings));
        verify(() => mockRepository.createMeeting(params)).called(1);
      });
    });

    group('Validation Failures', () {
      test('should fail when title is empty', () async {
        // Arrange
        const params = CreateMeetingParams(
          title: '',
          hostId: 'user-123',
          settings: MeetingSettings.openMeeting(),
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result, isA<ResultFailure<Meeting>>());
        expect(result.failureOrNull, isA<ValidationFailure>());
        expect(result.failureOrNull!.message, contains('Title cannot be empty'));
        verifyNever(() => mockRepository.createMeeting(any()));
      });

      test('should fail when host ID is empty', () async {
        // Arrange
        const params = CreateMeetingParams(
          title: 'Valid Title',
          hostId: '',
          settings: MeetingSettings.openMeeting(),
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result, isA<ResultFailure<Meeting>>());
        expect(result.failureOrNull, isA<ValidationFailure>());
        expect(result.failureOrNull!.message, contains('Host ID cannot be empty'));
        verifyNever(() => mockRepository.createMeeting(any()));
      });

      test('should fail when scheduled time is in the past', () async {
        // Arrange
        final params = CreateMeetingParams(
          title: 'Past Meeting',
          hostId: 'user-123',
          scheduledStartTime: DateTime.now().subtract(const Duration(hours: 1)),
          settings: const MeetingSettings.openMeeting(),
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result, isA<ResultFailure<Meeting>>());
        expect(result.failureOrNull, isA<ValidationFailure>());
        expect(result.failureOrNull!.message, contains('scheduled time cannot be in the past'));
        verifyNever(() => mockRepository.createMeeting(any()));
      });

      test('should fail when title exceeds maximum length', () async {
        // Arrange
        final longTitle = 'a' * 201; // Exceeds 200 character limit
        final params = CreateMeetingParams(
          title: longTitle,
          hostId: 'user-123',
          settings: const MeetingSettings.openMeeting(),
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result, isA<ResultFailure<Meeting>>());
        expect(result.failureOrNull, isA<ValidationFailure>());
        expect(result.failureOrNull!.message, contains('Title cannot exceed'));
        verifyNever(() => mockRepository.createMeeting(any()));
      });

      test('should fail when description exceeds maximum length', () async {
        // Arrange
        final longDescription = 'a' * 1001; // Exceeds 1000 character limit
        final params = CreateMeetingParams(
          title: 'Valid Title',
          description: longDescription,
          hostId: 'user-123',
          settings: const MeetingSettings.openMeeting(),
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result, isA<ResultFailure<Meeting>>());
        expect(result.failureOrNull, isA<ValidationFailure>());
        expect(result.failureOrNull!.message, contains('Description cannot exceed'));
        verifyNever(() => mockRepository.createMeeting(any()));
      });
    });

    group('Repository Failures', () {
      test('should return failure when repository fails to create meeting', () async {
        // Arrange
        const params = CreateMeetingParams(
          title: 'Valid Meeting',
          hostId: 'user-123',
          settings: MeetingSettings.openMeeting(),
        );

        const failure = ServerFailure(message: 'Failed to create meeting room');
        when(() => mockRepository.createMeeting(params))
            .thenAnswer((_) async => const ResultFailure(failure));

        // Act
        final result = await useCase(params);

        // Assert
        expect(result, isA<ResultFailure<Meeting>>());
        expect(result.failureOrNull, equals(failure));
        verify(() => mockRepository.createMeeting(params)).called(1);
      });

      test('should return failure when network is unavailable', () async {
        // Arrange
        const params = CreateMeetingParams(
          title: 'Network Test Meeting',
          hostId: 'user-123',
          settings: MeetingSettings.openMeeting(),
        );

        const failure = NetworkFailure(message: 'No internet connection');
        when(() => mockRepository.createMeeting(params))
            .thenAnswer((_) async => const ResultFailure(failure));

        // Act
        final result = await useCase(params);

        // Assert
        expect(result, isA<ResultFailure<Meeting>>());
        expect(result.failureOrNull, equals(failure));
        verify(() => mockRepository.createMeeting(params)).called(1);
      });

      test('should handle room creation service failures', () async {
        // Arrange
        const params = CreateMeetingParams(
          title: 'Service Failure Test',
          hostId: 'user-123',
          settings: MeetingSettings.openMeeting(),
        );

        const failure = ServiceFailure('LiveKit room creation failed');
        when(() => mockRepository.createMeeting(params))
            .thenAnswer((_) async => const ResultFailure(failure));

        // Act
        final result = await useCase(params);

        // Assert
        expect(result, isA<ResultFailure<Meeting>>());
        expect(result.failureOrNull, equals(failure));
        verify(() => mockRepository.createMeeting(params)).called(1);
      });
    });

    group('Edge Cases', () {
      test('should handle settings validation properly', () async {
        // Arrange - Settings with invalid participant limit
        const invalidSettings = MeetingSettings(
          maxParticipants: 0, // Invalid
        );

        const params = CreateMeetingParams(
          title: 'Settings Test',
          hostId: 'user-123',
          settings: invalidSettings,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result, isA<ResultFailure<Meeting>>());
        expect(result.failureOrNull, isA<ValidationFailure>());
        expect(result.failureOrNull!.message, contains('participant limit'));
        verifyNever(() => mockRepository.createMeeting(any()));
      });

      test('should validate special characters in title', () async {
        // Arrange
        const params = CreateMeetingParams(
          title: 'Meeting<script>alert("xss")</script>',
          hostId: 'user-123',
          settings: MeetingSettings.openMeeting(),
        );

        final expectedMeeting = Meeting(
          id: 'meeting-safe',
          title: 'Meeting&lt;script&gt;alert("xss")&lt;/script&gt;', // Sanitized
          hostId: params.hostId,
          roomId: 'room-safe',
          createdAt: DateTime.now(),
          state: MeetingState.scheduled,
          settings: params.settings,
          participants: const [],
        );

        when(() => mockRepository.createMeeting(params))
            .thenAnswer((_) async => Success(expectedMeeting));

        // Act
        final result = await useCase(params);

        // Assert
        expect(result, isA<Success<Meeting>>());
        // The repository should handle sanitization
        verify(() => mockRepository.createMeeting(params)).called(1);
      });

      test('should handle concurrent creation attempts', () async {
        // Arrange
        const params = CreateMeetingParams(
          title: 'Concurrent Test',
          hostId: 'user-123',
          settings: MeetingSettings.openMeeting(),
        );

        const failure = ConflictFailure('Room ID already exists');
        when(() => mockRepository.createMeeting(params))
            .thenAnswer((_) async => const ResultFailure(failure));

        // Act
        final result = await useCase(params);

        // Assert
        expect(result, isA<ResultFailure<Meeting>>());
        expect(result.failureOrNull, equals(failure));
        verify(() => mockRepository.createMeeting(params)).called(1);
      });
    });

    group('Business Logic', () {
      test('should ensure meeting starts in scheduled state', () async {
        // Arrange
        const params = CreateMeetingParams(
          title: 'State Test Meeting',
          hostId: 'user-123',
          settings: MeetingSettings.openMeeting(),
        );

        final expectedMeeting = Meeting(
          id: 'meeting-state-test',
          title: params.title,
          hostId: params.hostId,
          roomId: 'room-state',
          createdAt: DateTime.now(),
          state: MeetingState.scheduled,
          settings: params.settings,
          participants: const [],
        );

        when(() => mockRepository.createMeeting(params))
            .thenAnswer((_) async => Success(expectedMeeting));

        // Act
        final result = await useCase(params);

        // Assert
        expect(result, isA<Success<Meeting>>());
        expect(result.dataOrNull!.state, equals(MeetingState.scheduled));
        expect(result.dataOrNull!.participants, isEmpty);
        verify(() => mockRepository.createMeeting(params)).called(1);
      });

      test('should generate unique identifiers for each meeting', () async {
        // Arrange
        const params1 = CreateMeetingParams(
          title: 'Meeting One',
          hostId: 'user-123',
          settings: MeetingSettings.openMeeting(),
        );

        const params2 = CreateMeetingParams(
          title: 'Meeting Two',
          hostId: 'user-123',
          settings: MeetingSettings.openMeeting(),
        );

        final meeting1 = Meeting(
          id: 'meeting-unique-1',
          title: params1.title,
          hostId: params1.hostId,
          roomId: 'room-unique-1',
          createdAt: DateTime.now(),
          state: MeetingState.scheduled,
          settings: params1.settings,
          participants: const [],
        );

        final meeting2 = Meeting(
          id: 'meeting-unique-2',
          title: params2.title,
          hostId: params2.hostId,
          roomId: 'room-unique-2',
          createdAt: DateTime.now(),
          state: MeetingState.scheduled,
          settings: params2.settings,
          participants: const [],
        );

        when(() => mockRepository.createMeeting(params1))
            .thenAnswer((_) async => Success(meeting1));
        when(() => mockRepository.createMeeting(params2))
            .thenAnswer((_) async => Success(meeting2));

        // Act
        final result1 = await useCase(params1);
        final result2 = await useCase(params2);

        // Assert
        expect(result1.dataOrNull!.id, isNot(equals(result2.dataOrNull!.id)));
        expect(result1.dataOrNull!.roomId, isNot(equals(result2.dataOrNull!.roomId)));
        verify(() => mockRepository.createMeeting(params1)).called(1);
        verify(() => mockRepository.createMeeting(params2)).called(1);
      });
    });
  });
}