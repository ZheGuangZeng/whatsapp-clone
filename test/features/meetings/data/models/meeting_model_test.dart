import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_clone/features/meetings/data/models/meeting_model.dart';
import 'package:whatsapp_clone/features/meetings/data/models/meeting_participant_model.dart';
import 'package:whatsapp_clone/features/meetings/data/models/meeting_settings_model.dart';
import 'package:whatsapp_clone/features/meetings/domain/entities/meeting.dart';
import 'package:whatsapp_clone/features/meetings/domain/entities/meeting_participant.dart';
import 'package:whatsapp_clone/features/meetings/domain/entities/meeting_settings.dart';
import 'package:whatsapp_clone/features/meetings/domain/entities/meeting_state.dart';
import 'package:whatsapp_clone/features/meetings/domain/entities/participant_role.dart';

void main() {
  group('MeetingModel', () {
    // Test data setup
    const testSettings = MeetingSettingsModel(
      isPublic: true,
      maxParticipants: 10,
      allowScreenShare: true,
      isRecordingEnabled: false,
    );

    final testParticipant = MeetingParticipantModel(
      userId: 'user123',
      displayName: 'Test User',
      role: ParticipantRole.host,
      joinedAt: DateTime(2024, 1, 15, 14, 30),
      isAudioEnabled: true,
      isVideoEnabled: true,
      avatarUrl: 'https://example.com/avatar.jpg',
    );

    final meetingModel = MeetingModel(
      id: 'meeting-123',
      title: 'Test Meeting',
      description: 'A test meeting',
      hostId: 'user123',
      roomId: 'room-456',
      createdAt: DateTime(2024, 1, 15, 10, 0),
      scheduledStartTime: DateTime(2024, 1, 15, 14, 0),
      actualStartTime: DateTime(2024, 1, 15, 14, 5),
      actualEndTime: DateTime(2024, 1, 15, 15, 30),
      state: MeetingState.ended,
      settings: testSettings,
      participants: [testParticipant],
    );

    final meetingJson = {
      'id': 'meeting-123',
      'title': 'Test Meeting',
      'description': 'A test meeting',
      'hostId': 'user123',
      'roomId': 'room-456',
      'createdAt': '2024-01-15T10:00:00.000',
      'scheduledStartTime': '2024-01-15T14:00:00.000',
      'actualStartTime': '2024-01-15T14:05:00.000',
      'actualEndTime': '2024-01-15T15:30:00.000',
      'state': 'ended',
      'settings': {
        'isPublic': true,
        'maxParticipants': 10,
        'allowScreenShare': true,
        'isRecordingEnabled': false,
        'isWaitingRoomEnabled': false,
        'allowChat': true,
        'requireApproval': false,
        'password': null,
      },
      'participants': [
        {
          'userId': 'user123',
          'displayName': 'Test User',
          'role': 'host',
          'joinedAt': '2024-01-15T14:30:00.000',
          'leftAt': null,
          'isAudioEnabled': true,
          'isVideoEnabled': true,
          'avatarUrl': 'https://example.com/avatar.jpg',
        }
      ],
    };

    group('JSON Serialization', () {
      test('should serialize to JSON correctly', () {
        // Act
        final json = meetingModel.toJson();

        // Assert
        expect(json['id'], meetingModel.id);
        expect(json['title'], meetingModel.title);
        expect(json['description'], meetingModel.description);
        expect(json['hostId'], meetingModel.hostId);
        expect(json['roomId'], meetingModel.roomId);
        expect(json['state'], meetingModel.state.name);
        expect(json['participants'], isA<List>());
        expect(json['settings'], isA<Map<String, dynamic>>());
      });

      test('should deserialize from JSON correctly', () {
        // Act
        final result = MeetingModel.fromJson(meetingJson);

        // Assert
        expect(result.id, meetingModel.id);
        expect(result.title, meetingModel.title);
        expect(result.description, meetingModel.description);
        expect(result.hostId, meetingModel.hostId);
        expect(result.roomId, meetingModel.roomId);
        expect(result.createdAt, meetingModel.createdAt);
        expect(result.scheduledStartTime, meetingModel.scheduledStartTime);
        expect(result.actualStartTime, meetingModel.actualStartTime);
        expect(result.actualEndTime, meetingModel.actualEndTime);
        expect(result.state, meetingModel.state);
        expect(result.participants.length, 1);
        expect(result.participants.first.userId, 'user123');
      });

      test('should handle null optional fields correctly', () {
        final minimalJson = {
          'id': 'meeting-456',
          'title': 'Minimal Meeting',
          'description': null,
          'hostId': 'user456',
          'roomId': 'room-789',
          'createdAt': '2024-01-15T10:00:00.000',
          'scheduledStartTime': null,
          'actualStartTime': null,
          'actualEndTime': null,
          'state': 'scheduled',
          'settings': {
            'isPublic': false,
            'maxParticipants': 5,
            'allowScreenShare': false,
            'isRecordingEnabled': false,
            'isWaitingRoomEnabled': true,
            'allowChat': true,
            'requireApproval': false,
            'password': null,
          },
          'participants': [],
        };

        // Act
        final result = MeetingModel.fromJson(minimalJson);

        // Assert
        expect(result.id, 'meeting-456');
        expect(result.title, 'Minimal Meeting');
        expect(result.description, isNull);
        expect(result.scheduledStartTime, isNull);
        expect(result.actualStartTime, isNull);
        expect(result.actualEndTime, isNull);
        expect(result.state, MeetingState.scheduled);
        expect(result.participants, isEmpty);
      });
    });

    group('Domain Entity Conversion', () {
      test('should convert to domain entity correctly', () {
        // Act
        final domainMeeting = meetingModel.toDomain();

        // Assert
        expect(domainMeeting, isA<Meeting>());
        expect(domainMeeting.id, meetingModel.id);
        expect(domainMeeting.title, meetingModel.title);
        expect(domainMeeting.description, meetingModel.description);
        expect(domainMeeting.hostId, meetingModel.hostId);
        expect(domainMeeting.roomId, meetingModel.roomId);
        expect(domainMeeting.createdAt, meetingModel.createdAt);
        expect(domainMeeting.state, meetingModel.state);
        expect(domainMeeting.participants.length, meetingModel.participants.length);
        expect(domainMeeting.settings.isPublic, meetingModel.settings.isPublic);
      });

      test('should create from domain entity correctly', () {
        // Arrange
        final domainMeeting = Meeting(
          id: 'domain-meeting-789',
          title: 'Domain Meeting',
          description: 'Created from domain',
          hostId: 'domain-host',
          roomId: 'domain-room',
          createdAt: DateTime(2024, 2, 1, 12, 0),
          scheduledStartTime: DateTime(2024, 2, 1, 15, 0),
          state: MeetingState.scheduled,
          settings: const MeetingSettings(),
          participants: const [],
        );

        // Act
        final modelFromDomain = MeetingModel.fromDomain(domainMeeting);

        // Assert
        expect(modelFromDomain.id, domainMeeting.id);
        expect(modelFromDomain.title, domainMeeting.title);
        expect(modelFromDomain.description, domainMeeting.description);
        expect(modelFromDomain.hostId, domainMeeting.hostId);
        expect(modelFromDomain.roomId, domainMeeting.roomId);
        expect(modelFromDomain.createdAt, domainMeeting.createdAt);
        expect(modelFromDomain.scheduledStartTime, domainMeeting.scheduledStartTime);
        expect(modelFromDomain.state, domainMeeting.state);
        expect(modelFromDomain.participants.length, domainMeeting.participants.length);
      });
    });

    group('Supabase Integration', () {
      test('should create from Supabase row correctly', () {
        // Arrange
        final supabaseRow = {
          'id': 'sb-meeting-123',
          'title': 'Supabase Meeting',
          'description': 'Meeting from Supabase',
          'host_id': 'sb-host-456',
          'room_id': 'sb-room-789',
          'created_at': '2024-01-20T09:00:00.000000+00:00',
          'scheduled_start_time': '2024-01-20T14:00:00.000000+00:00',
          'actual_start_time': null,
          'actual_end_time': null,
          'state': 'scheduled',
          'is_public': true,
          'max_participants': 20,
          'allow_screen_share': true,
          'is_recording_enabled': false,
          'is_waiting_room_enabled': true,
          'allow_chat': true,
          'require_approval': false,
          'password': null,
        };

        // Act
        final result = MeetingModel.fromSupabaseRow(supabaseRow, <Map<String, dynamic>>[]);

        // Assert
        expect(result.id, 'sb-meeting-123');
        expect(result.title, 'Supabase Meeting');
        expect(result.description, 'Meeting from Supabase');
        expect(result.hostId, 'sb-host-456');
        expect(result.roomId, 'sb-room-789');
        expect(result.state, MeetingState.scheduled);
        expect(result.settings.isPublic, true);
        expect(result.settings.maxParticipants, 20);
        expect(result.settings.isWaitingRoomEnabled, true);
        expect(result.participants, isEmpty);
      });

      test('should convert to Supabase row format correctly', () {
        // Act
        final supabaseRow = meetingModel.toSupabaseRow();

        // Assert
        expect(supabaseRow['id'], meetingModel.id);
        expect(supabaseRow['title'], meetingModel.title);
        expect(supabaseRow['description'], meetingModel.description);
        expect(supabaseRow['host_id'], meetingModel.hostId);
        expect(supabaseRow['room_id'], meetingModel.roomId);
        expect(supabaseRow['state'], meetingModel.state.name);
        expect(supabaseRow['is_public'], meetingModel.settings.isPublic);
        expect(supabaseRow['max_participants'], meetingModel.settings.maxParticipants);
        expect(supabaseRow['allow_screen_share'], meetingModel.settings.allowScreenShare);
        expect(supabaseRow['is_recording_enabled'], meetingModel.settings.isRecordingEnabled);
      });
    });

    group('Edge Cases', () {
      test('should handle meeting state conversion correctly', () {
        final states = [
          MeetingState.scheduled,
          MeetingState.waiting,
          MeetingState.active,
          MeetingState.ended,
          MeetingState.cancelled,
        ];

        for (final state in states) {
          final json = {'state': state.name};
          final stateFromJson = MeetingState.values.firstWhere(
            (s) => s.name == json['state'],
          );
          expect(stateFromJson, state);
        }
      });

      test('should preserve participant data integrity', () {
        final participantData = {
          'userId': 'preserve-test',
          'displayName': 'Preserve Test User',
          'role': 'attendee',
          'joinedAt': '2024-01-15T14:30:00.000',
          'leftAt': '2024-01-15T15:00:00.000',
          'isAudioEnabled': false,
          'isVideoEnabled': true,
          'avatarUrl': null,
        };

        final meetingWithParticipant = meetingJson;
        meetingWithParticipant['participants'] = [participantData];

        // Act
        final result = MeetingModel.fromJson(meetingWithParticipant);
        final backToJson = result.toJson();

        // Assert
        final resultParticipant = backToJson['participants'][0] as Map<String, dynamic>;
        expect(resultParticipant['userId'], participantData['userId']);
        expect(resultParticipant['displayName'], participantData['displayName']);
        expect(resultParticipant['role'], participantData['role']);
        expect(resultParticipant['isAudioEnabled'], participantData['isAudioEnabled']);
        expect(resultParticipant['isVideoEnabled'], participantData['isVideoEnabled']);
        expect(resultParticipant['avatarUrl'], participantData['avatarUrl']);
      });
    });
  });
}