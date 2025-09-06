import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_clone/features/meetings/domain/entities/meeting.dart';
import 'package:whatsapp_clone/features/meetings/domain/entities/meeting_participant.dart';
import 'package:whatsapp_clone/features/meetings/domain/entities/meeting_recording.dart';

void main() {
  group('MeetingStatus', () {
    test('should create status from string', () {
      expect(MeetingStatus.fromString('scheduled'), MeetingStatus.scheduled);
      expect(MeetingStatus.fromString('active'), MeetingStatus.active);
      expect(MeetingStatus.fromString('ended'), MeetingStatus.ended);
      expect(MeetingStatus.fromString('cancelled'), MeetingStatus.cancelled);
    });

    test('should return default status for invalid string', () {
      expect(MeetingStatus.fromString('invalid'), MeetingStatus.scheduled);
    });

    test('should have correct string values', () {
      expect(MeetingStatus.scheduled.value, 'scheduled');
      expect(MeetingStatus.active.value, 'active');
      expect(MeetingStatus.ended.value, 'ended');
      expect(MeetingStatus.cancelled.value, 'cancelled');
    });
  });

  group('Meeting', () {
    late DateTime now;
    late DateTime future;
    late DateTime past;

    setUp(() {
      now = DateTime.utc(2023, 6, 15, 10, 0);
      future = DateTime.utc(2023, 6, 15, 14, 0);
      past = DateTime.utc(2023, 6, 15, 8, 0);
    });

    final testParticipant = MeetingParticipant(
      id: 'participant-1',
      meetingId: 'meeting-123',
      userId: 'user-1',
      role: ParticipantRole.participant,
      joinedAt: DateTime.utc(2023, 6, 15, 10, 5),
      isAudioEnabled: true,
      isVideoEnabled: false,
    );

    final testHostParticipant = MeetingParticipant(
      id: 'participant-host',
      meetingId: 'meeting-123',
      userId: 'host-user',
      role: ParticipantRole.host,
      joinedAt: DateTime.utc(2023, 6, 15, 10, 0),
    );

    final testAdminParticipant = MeetingParticipant(
      id: 'participant-admin',
      meetingId: 'meeting-123',
      userId: 'admin-user',
      role: ParticipantRole.admin,
      joinedAt: DateTime.utc(2023, 6, 15, 10, 2),
    );

    final testRecording = MeetingRecording(
      id: 'recording-1',
      meetingId: 'meeting-123',
      livekitEgressId: 'egress-123',
      status: RecordingStatus.completed,
      startedAt: DateTime.utc(2023, 6, 15, 10, 0),
      completedAt: DateTime.utc(2023, 6, 15, 11, 0),
      fileUrl: 'https://example.com/recording.mp4',
      durationSeconds: 3600,
      fileSize: 1024000,
    );

    test('should create Meeting with required properties', () {
      final meeting = Meeting(
        id: 'meeting-123',
        livekitRoomName: 'room-123',
        hostId: 'host-123',
        createdAt: now,
        updatedAt: now,
      );

      expect(meeting.id, 'meeting-123');
      expect(meeting.livekitRoomName, 'room-123');
      expect(meeting.hostId, 'host-123');
      expect(meeting.createdAt, now);
      expect(meeting.updatedAt, now);
      expect(meeting.maxParticipants, 100);
      expect(meeting.metadata, isEmpty);
      expect(meeting.participants, isEmpty);
      expect(meeting.recordings, isEmpty);
    });

    test('should create Meeting with all properties', () {
      final metadata = {'key': 'value'};
      final participants = [testParticipant, testHostParticipant];
      final recordings = [testRecording];

      final meeting = Meeting(
        id: 'meeting-123',
        roomId: 'room-456',
        livekitRoomName: 'room-123',
        hostId: 'host-123',
        title: 'Team Meeting',
        description: 'Weekly team sync',
        scheduledFor: future,
        startedAt: now,
        endedAt: future,
        recordingUrl: 'https://example.com/recording.mp4',
        maxParticipants: 50,
        metadata: metadata,
        createdAt: past,
        updatedAt: now,
        participants: participants,
        recordings: recordings,
      );

      expect(meeting.roomId, 'room-456');
      expect(meeting.title, 'Team Meeting');
      expect(meeting.description, 'Weekly team sync');
      expect(meeting.scheduledFor, future);
      expect(meeting.startedAt, now);
      expect(meeting.endedAt, future);
      expect(meeting.recordingUrl, 'https://example.com/recording.mp4');
      expect(meeting.maxParticipants, 50);
      expect(meeting.metadata, metadata);
      expect(meeting.participants, participants);
      expect(meeting.recordings, recordings);
    });

    group('status computation', () {
      test('should return ended when endedAt is set', () {
        final meeting = Meeting(
          id: 'meeting-123',
          livekitRoomName: 'room-123',
          hostId: 'host-123',
          startedAt: past,
          endedAt: now,
          createdAt: past,
          updatedAt: now,
        );

        expect(meeting.status, MeetingStatus.ended);
        expect(meeting.hasEnded, true);
        expect(meeting.isActive, false);
        expect(meeting.isScheduled, false);
      });

      test('should return active when started but not ended', () {
        final meeting = Meeting(
          id: 'meeting-123',
          livekitRoomName: 'room-123',
          hostId: 'host-123',
          startedAt: past,
          createdAt: past,
          updatedAt: now,
        );

        expect(meeting.status, MeetingStatus.active);
        expect(meeting.isActive, true);
        expect(meeting.hasEnded, false);
        expect(meeting.isScheduled, false);
      });

      test('should return scheduled for future meetings', () {
        final meeting = Meeting(
          id: 'meeting-123',
          livekitRoomName: 'room-123',
          hostId: 'host-123',
          scheduledFor: future,
          createdAt: past,
          updatedAt: now,
        );

        expect(meeting.status, MeetingStatus.scheduled);
        expect(meeting.isScheduled, true);
        expect(meeting.isActive, false);
        expect(meeting.hasEnded, false);
      });

      test('should return scheduled as default', () {
        final meeting = Meeting(
          id: 'meeting-123',
          livekitRoomName: 'room-123',
          hostId: 'host-123',
          createdAt: past,
          updatedAt: now,
        );

        expect(meeting.status, MeetingStatus.scheduled);
        expect(meeting.isScheduled, true);
      });
    });

    group('duration calculation', () {
      test('should return null duration if not started', () {
        final meeting = Meeting(
          id: 'meeting-123',
          livekitRoomName: 'room-123',
          hostId: 'host-123',
          createdAt: past,
          updatedAt: now,
        );

        expect(meeting.durationMinutes, isNull);
      });

      test('should return null duration if not ended', () {
        final meeting = Meeting(
          id: 'meeting-123',
          livekitRoomName: 'room-123',
          hostId: 'host-123',
          startedAt: past,
          createdAt: past,
          updatedAt: now,
        );

        expect(meeting.durationMinutes, isNull);
      });

      test('should calculate duration when both started and ended', () {
        final startTime = DateTime.utc(2023, 6, 15, 10, 0);
        final endTime = DateTime.utc(2023, 6, 15, 11, 30);
        
        final meeting = Meeting(
          id: 'meeting-123',
          livekitRoomName: 'room-123',
          hostId: 'host-123',
          startedAt: startTime,
          endedAt: endTime,
          createdAt: past,
          updatedAt: now,
        );

        expect(meeting.durationMinutes, 90);
      });
    });

    group('participant management', () {
      test('should count active participants correctly', () {
        final activeParticipant = testParticipant;
        final leftParticipant = testParticipant.copyWith(
          id: 'participant-2',
          leftAt: now,
        );

        final meeting = Meeting(
          id: 'meeting-123',
          livekitRoomName: 'room-123',
          hostId: 'host-123',
          participants: [activeParticipant, leftParticipant],
          createdAt: past,
          updatedAt: now,
        );

        expect(meeting.activeParticipantsCount, 1);
        expect(meeting.activeParticipants, [activeParticipant]);
      });

      test('should identify capacity status', () {
        final participants = List.generate(
          2,
          (i) => MeetingParticipant(
            id: 'participant-$i',
            meetingId: 'meeting-123',
            userId: 'user-$i',
            role: ParticipantRole.participant,
            joinedAt: DateTime.utc(2023, 6, 15, 10, i),
          ),
        );

        final meeting = Meeting(
          id: 'meeting-123',
          livekitRoomName: 'room-123',
          hostId: 'host-123',
          maxParticipants: 2,
          participants: participants,
          createdAt: past,
          updatedAt: now,
        );

        expect(meeting.isAtCapacity, true);
      });

      test('should find host participant', () {
        final meeting = Meeting(
          id: 'meeting-123',
          livekitRoomName: 'room-123',
          hostId: 'host-123',
          participants: [testParticipant, testHostParticipant],
          createdAt: past,
          updatedAt: now,
        );

        expect(meeting.hostParticipant, testHostParticipant);
      });

      test('should find admin participants', () {
        final meeting = Meeting(
          id: 'meeting-123',
          livekitRoomName: 'room-123',
          hostId: 'host-123',
          participants: [testParticipant, testHostParticipant, testAdminParticipant],
          createdAt: past,
          updatedAt: now,
        );

        expect(meeting.adminParticipants, [testAdminParticipant]);
      });
    });

    group('recording management', () {
      test('should identify meetings with recordings', () {
        final meeting = Meeting(
          id: 'meeting-123',
          livekitRoomName: 'room-123',
          hostId: 'host-123',
          recordings: [testRecording],
          createdAt: past,
          updatedAt: now,
        );

        expect(meeting.hasRecordings, true);
        expect(meeting.completedRecordings, [testRecording]);
      });

      test('should filter completed recordings', () {
        final processingRecording = testRecording.copyWith(
          id: 'recording-2',
          status: RecordingStatus.processing,
          completedAt: null,
        );

        final meeting = Meeting(
          id: 'meeting-123',
          livekitRoomName: 'room-123',
          hostId: 'host-123',
          recordings: [testRecording, processingRecording],
          createdAt: past,
          updatedAt: now,
        );

        expect(meeting.completedRecordings, [testRecording]);
      });
    });

    group('display utilities', () {
      test('should use provided title as display title', () {
        final meeting = Meeting(
          id: 'meeting-123',
          livekitRoomName: 'room-123',
          hostId: 'host-123',
          title: 'Team Meeting',
          createdAt: past,
          updatedAt: now,
        );

        expect(meeting.displayTitle, 'Team Meeting');
      });

      test('should generate fallback display title from date', () {
        final createdDate = DateTime.utc(2023, 6, 15);
        final meeting = Meeting(
          id: 'meeting-123',
          livekitRoomName: 'room-123',
          hostId: 'host-123',
          createdAt: createdDate,
          updatedAt: now,
        );

        expect(meeting.displayTitle, 'Meeting 15/6/2023');
      });

      test('should generate fallback when title is empty', () {
        final createdDate = DateTime.utc(2023, 6, 15);
        final meeting = Meeting(
          id: 'meeting-123',
          livekitRoomName: 'room-123',
          hostId: 'host-123',
          title: '',
          createdAt: createdDate,
          updatedAt: now,
        );

        expect(meeting.displayTitle, 'Meeting 15/6/2023');
      });
    });

    test('should support copyWith for all fields', () {
      final originalMeeting = Meeting(
        id: 'meeting-123',
        livekitRoomName: 'room-123',
        hostId: 'host-123',
        title: 'Original Title',
        maxParticipants: 100,
        createdAt: past,
        updatedAt: now,
      );

      final updatedMeeting = originalMeeting.copyWith(
        title: 'Updated Title',
        maxParticipants: 50,
        startedAt: now,
      );

      expect(updatedMeeting.id, originalMeeting.id);
      expect(updatedMeeting.title, 'Updated Title');
      expect(updatedMeeting.maxParticipants, 50);
      expect(updatedMeeting.startedAt, now);
      expect(updatedMeeting.createdAt, originalMeeting.createdAt);
    });

    test('should support equality comparison', () {
      final meeting1 = Meeting(
        id: 'meeting-123',
        livekitRoomName: 'room-123',
        hostId: 'host-123',
        createdAt: past,
        updatedAt: now,
      );

      final meeting2 = Meeting(
        id: 'meeting-123',
        livekitRoomName: 'room-123',
        hostId: 'host-123',
        createdAt: past,
        updatedAt: now,
      );

      final meeting3 = Meeting(
        id: 'meeting-456',
        livekitRoomName: 'room-123',
        hostId: 'host-123',
        createdAt: past,
        updatedAt: now,
      );

      expect(meeting1, equals(meeting2));
      expect(meeting1, isNot(equals(meeting3)));
    });

    test('should have consistent hashCode for equal objects', () {
      final meeting1 = Meeting(
        id: 'meeting-123',
        livekitRoomName: 'room-123',
        hostId: 'host-123',
        createdAt: past,
        updatedAt: now,
      );

      final meeting2 = Meeting(
        id: 'meeting-123',
        livekitRoomName: 'room-123',
        hostId: 'host-123',
        createdAt: past,
        updatedAt: now,
      );

      expect(meeting1.hashCode, meeting2.hashCode);
    });

    test('should include all properties in props', () {
      final meeting = Meeting(
        id: 'meeting-123',
        roomId: 'room-456',
        livekitRoomName: 'room-123',
        hostId: 'host-123',
        title: 'Test Meeting',
        description: 'Test Description',
        scheduledFor: future,
        startedAt: now,
        endedAt: future,
        recordingUrl: 'https://example.com/recording.mp4',
        maxParticipants: 50,
        metadata: const {'key': 'value'},
        createdAt: past,
        updatedAt: now,
        participants: [testParticipant],
        recordings: [testRecording],
      );

      final props = meeting.props;
      expect(props, contains(meeting.id));
      expect(props, contains(meeting.roomId));
      expect(props, contains(meeting.livekitRoomName));
      expect(props, contains(meeting.hostId));
      expect(props, contains(meeting.title));
      expect(props, contains(meeting.description));
      expect(props, contains(meeting.scheduledFor));
      expect(props, contains(meeting.startedAt));
      expect(props, contains(meeting.endedAt));
      expect(props, contains(meeting.recordingUrl));
      expect(props, contains(meeting.maxParticipants));
      expect(props, contains(meeting.metadata));
      expect(props, contains(meeting.createdAt));
      expect(props, contains(meeting.updatedAt));
      expect(props, contains(meeting.participants));
      expect(props, contains(meeting.recordings));
    });
  });
}