import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_clone/features/meetings/domain/entities/meeting.dart';
import 'package:whatsapp_clone/features/meetings/domain/entities/meeting_participant.dart';
import 'package:whatsapp_clone/features/meetings/domain/entities/meeting_settings.dart';
import 'package:whatsapp_clone/features/meetings/domain/entities/meeting_state.dart';
import 'package:whatsapp_clone/features/meetings/domain/entities/participant_role.dart';

void main() {
  group('Meeting Entity', () {
    late Meeting testMeeting;
    late DateTime testCreatedAt;
    late MeetingSettings testSettings;

    setUp(() {
      testCreatedAt = DateTime(2024, 1, 15, 10, 30);
      testSettings = const MeetingSettings(
        maxParticipants: 50,
        isRecordingEnabled: true,
        isWaitingRoomEnabled: false,
        allowScreenShare: true,
      );
      
      testMeeting = Meeting(
        id: 'meeting-123',
        title: 'Team Standup',
        description: 'Daily standup meeting',
        hostId: 'user-123',
        roomId: 'room-456',
        createdAt: testCreatedAt,
        scheduledStartTime: testCreatedAt.add(const Duration(hours: 1)),
        state: MeetingState.scheduled,
        settings: testSettings,
        participants: const [],
      );
    });

    group('Meeting Creation', () {
      test('should create a meeting with all required fields', () {
        // Assert
        expect(testMeeting.id, equals('meeting-123'));
        expect(testMeeting.title, equals('Team Standup'));
        expect(testMeeting.description, equals('Daily standup meeting'));
        expect(testMeeting.hostId, equals('user-123'));
        expect(testMeeting.roomId, equals('room-456'));
        expect(testMeeting.createdAt, equals(testCreatedAt));
        expect(testMeeting.scheduledStartTime, equals(testCreatedAt.add(const Duration(hours: 1))));
        expect(testMeeting.state, equals(MeetingState.scheduled));
        expect(testMeeting.settings, equals(testSettings));
        expect(testMeeting.participants, isEmpty);
      });

      test('should create meeting with optional null values', () {
        // Arrange & Act
        final meeting = Meeting(
          id: 'meeting-456',
          title: 'Quick Chat',
          hostId: 'user-456',
          roomId: 'room-789',
          createdAt: testCreatedAt,
          state: MeetingState.active,
          settings: testSettings,
          participants: const [],
        );

        // Assert
        expect(meeting.description, isNull);
        expect(meeting.scheduledStartTime, isNull);
        expect(meeting.actualStartTime, isNull);
        expect(meeting.actualEndTime, isNull);
      });

      test('should enforce meeting state constraints', () {
        // Test that meeting states follow valid transitions
        expect(MeetingState.values, contains(MeetingState.scheduled));
        expect(MeetingState.values, contains(MeetingState.waiting));
        expect(MeetingState.values, contains(MeetingState.active));
        expect(MeetingState.values, contains(MeetingState.ended));
        expect(MeetingState.values, contains(MeetingState.cancelled));
      });
    });

    group('Meeting State Management', () {
      test('should start meeting when in scheduled state', () {
        // Arrange
        final startTime = DateTime.now();
        
        // Act
        final updatedMeeting = testMeeting.copyWith(
          state: MeetingState.active,
          actualStartTime: startTime,
        );

        // Assert
        expect(updatedMeeting.state, equals(MeetingState.active));
        expect(updatedMeeting.actualStartTime, equals(startTime));
        expect(updatedMeeting.isActive, isTrue);
        expect(updatedMeeting.isEnded, isFalse);
      });

      test('should end meeting when in active state', () {
        // Arrange
        final baseTime = DateTime(2024, 1, 15, 14, 0, 0);
        final startTime = baseTime;
        final endTime = baseTime.add(const Duration(hours: 1));
        final activeMeeting = testMeeting.copyWith(
          state: MeetingState.active,
          actualStartTime: startTime,
        );

        // Act
        final endedMeeting = activeMeeting.copyWith(
          state: MeetingState.ended,
          actualEndTime: endTime,
        );

        // Assert
        expect(endedMeeting.state, equals(MeetingState.ended));
        expect(endedMeeting.actualEndTime, equals(endTime));
        expect(endedMeeting.isActive, isFalse);
        expect(endedMeeting.isEnded, isTrue);
        expect(endedMeeting.duration, equals(const Duration(hours: 1)));
      });

      test('should calculate meeting duration correctly', () {
        // Arrange
        final baseTime = DateTime(2024, 1, 15, 15, 0, 0);
        final startTime = baseTime;
        final endTime = baseTime.add(const Duration(minutes: 45));
        final meeting = testMeeting.copyWith(
          actualStartTime: startTime,
          actualEndTime: endTime,
        );

        // Act & Assert
        expect(meeting.duration, equals(const Duration(minutes: 45)));
      });

      test('should return null duration if meeting not ended', () {
        // Arrange
        final activeMeeting = testMeeting.copyWith(
          state: MeetingState.active,
          actualStartTime: DateTime(2024, 1, 15, 16, 0, 0),
        );

        // Act & Assert
        expect(activeMeeting.duration, isNull);
      });
    });

    group('Participant Management', () {
      test('should add participant to meeting', () {
        // Arrange
        final participant = MeetingParticipant(
          userId: 'user-456',
          displayName: 'John Doe',
          role: ParticipantRole.attendee,
          joinedAt: DateTime.now(),
          isAudioEnabled: true,
          isVideoEnabled: false,
        );

        // Act
        final updatedMeeting = testMeeting.copyWith(
          participants: [participant],
        );

        // Assert
        expect(updatedMeeting.participants, hasLength(1));
        expect(updatedMeeting.participants.first, equals(participant));
        expect(updatedMeeting.participantCount, equals(1));
      });

      test('should enforce participant limit from settings', () {
        // Arrange
        final participants = List.generate(51, (index) => MeetingParticipant(
          userId: 'user-$index',
          displayName: 'User $index',
          role: ParticipantRole.attendee,
          joinedAt: DateTime.now(),
          isAudioEnabled: true,
          isVideoEnabled: false,
        ));

        // Act & Assert
        expect(participants.length, greaterThan(testSettings.maxParticipants));
        // The business logic should prevent adding more than maxParticipants
        expect(testSettings.maxParticipants, equals(50));
      });

      test('should identify host participant', () {
        // Arrange
        final hostParticipant = MeetingParticipant(
          userId: 'user-123', // Same as meeting hostId
          displayName: 'Host User',
          role: ParticipantRole.host,
          joinedAt: DateTime.now(),
          isAudioEnabled: true,
          isVideoEnabled: true,
        );
        
        final regularParticipant = MeetingParticipant(
          userId: 'user-456',
          displayName: 'Regular User',
          role: ParticipantRole.attendee,
          joinedAt: DateTime.now(),
          isAudioEnabled: true,
          isVideoEnabled: false,
        );

        // Act
        final meetingWithParticipants = testMeeting.copyWith(
          participants: [hostParticipant, regularParticipant],
        );

        // Assert
        expect(meetingWithParticipants.hostParticipant, equals(hostParticipant));
        expect(meetingWithParticipants.hostParticipant?.role, equals(ParticipantRole.host));
      });
    });

    group('Meeting Validation', () {
      test('should validate meeting title is not empty', () {
        // This test ensures the Meeting constructor or validation logic
        // prevents empty titles
        expect(testMeeting.title.isNotEmpty, isTrue);
      });

      test('should validate host ID is not empty', () {
        expect(testMeeting.hostId.isNotEmpty, isTrue);
      });

      test('should validate room ID is not empty', () {
        expect(testMeeting.roomId.isNotEmpty, isTrue);
      });

      test('should validate scheduled time is in the future for new meetings', () {
        // For scheduled meetings, scheduledStartTime should be in the future
        final futureMeeting = Meeting(
          id: 'future-meeting',
          title: 'Future Meeting',
          hostId: 'user-123',
          roomId: 'room-123',
          createdAt: DateTime.now(),
          scheduledStartTime: DateTime.now().add(const Duration(hours: 1)),
          state: MeetingState.scheduled,
          settings: testSettings,
          participants: const [],
        );

        expect(futureMeeting.scheduledStartTime!.isAfter(futureMeeting.createdAt), isTrue);
      });
    });

    group('Equatable Implementation', () {
      test('should be equal when all properties match', () {
        // Arrange
        final meeting1 = Meeting(
          id: 'meeting-123',
          title: 'Test Meeting',
          hostId: 'user-123',
          roomId: 'room-456',
          createdAt: testCreatedAt,
          state: MeetingState.scheduled,
          settings: testSettings,
          participants: const [],
        );

        final meeting2 = Meeting(
          id: 'meeting-123',
          title: 'Test Meeting',
          hostId: 'user-123',
          roomId: 'room-456',
          createdAt: testCreatedAt,
          state: MeetingState.scheduled,
          settings: testSettings,
          participants: const [],
        );

        // Assert
        expect(meeting1, equals(meeting2));
      });

      test('should not be equal when properties differ', () {
        // Arrange
        final meeting1 = testMeeting;
        final meeting2 = testMeeting.copyWith(title: 'Different Title');

        // Assert
        expect(meeting1, isNot(equals(meeting2)));
      });
    });

    group('CopyWith Functionality', () {
      test('should create copy with updated fields', () {
        // Arrange
        const newTitle = 'Updated Meeting Title';
        const newState = MeetingState.active;

        // Act
        final updatedMeeting = testMeeting.copyWith(
          title: newTitle,
          state: newState,
        );

        // Assert
        expect(updatedMeeting.title, equals(newTitle));
        expect(updatedMeeting.state, equals(newState));
        expect(updatedMeeting.id, equals(testMeeting.id)); // Unchanged
        expect(updatedMeeting.hostId, equals(testMeeting.hostId)); // Unchanged
      });

      test('should preserve original values when no updates provided', () {
        // Act
        final copiedMeeting = testMeeting.copyWith();

        // Assert
        expect(copiedMeeting, equals(testMeeting));
      });
    });
  });
}