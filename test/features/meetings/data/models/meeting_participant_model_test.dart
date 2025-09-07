import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_clone/features/meetings/data/models/meeting_participant_model.dart';
import 'package:whatsapp_clone/features/meetings/domain/entities/meeting_participant.dart';
import 'package:whatsapp_clone/features/meetings/domain/entities/participant_role.dart';

void main() {
  group('MeetingParticipantModel', () {
    final participantModel = MeetingParticipantModel(
      userId: 'user123',
      displayName: 'Test User',
      role: ParticipantRole.host,
      joinedAt: DateTime(2024, 1, 15, 14, 30),
      leftAt: DateTime(2024, 1, 15, 15, 45),
      isAudioEnabled: true,
      isVideoEnabled: false,
      avatarUrl: 'https://example.com/avatar.jpg',
    );

    final participantJson = {
      'userId': 'user123',
      'displayName': 'Test User',
      'role': 'host',
      'joinedAt': '2024-01-15T14:30:00.000',
      'leftAt': '2024-01-15T15:45:00.000',
      'isAudioEnabled': true,
      'isVideoEnabled': false,
      'avatarUrl': 'https://example.com/avatar.jpg',
    };

    group('JSON Serialization', () {
      test('should serialize to JSON correctly', () {
        // Act
        final json = participantModel.toJson();

        // Assert
        expect(json, equals(participantJson));
      });

      test('should deserialize from JSON correctly', () {
        // Act
        final result = MeetingParticipantModel.fromJson(participantJson);

        // Assert
        expect(result.userId, participantModel.userId);
        expect(result.displayName, participantModel.displayName);
        expect(result.role, participantModel.role);
        expect(result.joinedAt, participantModel.joinedAt);
        expect(result.leftAt, participantModel.leftAt);
        expect(result.isAudioEnabled, participantModel.isAudioEnabled);
        expect(result.isVideoEnabled, participantModel.isVideoEnabled);
        expect(result.avatarUrl, participantModel.avatarUrl);
      });

      test('should handle null values correctly', () {
        final minimalJson = {
          'userId': 'user456',
          'displayName': 'Minimal User',
          'role': 'attendee',
          'joinedAt': '2024-01-15T14:30:00.000',
          'leftAt': null,
          'isAudioEnabled': false,
          'isVideoEnabled': false,
          'avatarUrl': null,
        };

        // Act
        final result = MeetingParticipantModel.fromJson(minimalJson);

        // Assert
        expect(result.userId, 'user456');
        expect(result.displayName, 'Minimal User');
        expect(result.role, ParticipantRole.attendee);
        expect(result.leftAt, isNull);
        expect(result.avatarUrl, isNull);
      });
    });

    group('Domain Entity Conversion', () {
      test('should convert to domain entity correctly', () {
        // Act
        final domainParticipant = participantModel.toDomain();

        // Assert
        expect(domainParticipant, isA<MeetingParticipant>());
        expect(domainParticipant.userId, participantModel.userId);
        expect(domainParticipant.displayName, participantModel.displayName);
        expect(domainParticipant.role, participantModel.role);
        expect(domainParticipant.joinedAt, participantModel.joinedAt);
        expect(domainParticipant.leftAt, participantModel.leftAt);
        expect(domainParticipant.isAudioEnabled, participantModel.isAudioEnabled);
        expect(domainParticipant.isVideoEnabled, participantModel.isVideoEnabled);
        expect(domainParticipant.avatarUrl, participantModel.avatarUrl);
      });

      test('should create from domain entity correctly', () {
        // Arrange
        final domainParticipant = MeetingParticipant(
          userId: 'domain456',
          displayName: 'Domain User',
          role: ParticipantRole.moderator,
          joinedAt: DateTime(2024, 2, 1, 16, 0),
          isAudioEnabled: false,
          isVideoEnabled: true,
        );

        // Act
        final modelFromDomain = MeetingParticipantModel.fromDomain(domainParticipant);

        // Assert
        expect(modelFromDomain.userId, domainParticipant.userId);
        expect(modelFromDomain.displayName, domainParticipant.displayName);
        expect(modelFromDomain.role, domainParticipant.role);
        expect(modelFromDomain.joinedAt, domainParticipant.joinedAt);
        expect(modelFromDomain.leftAt, domainParticipant.leftAt);
        expect(modelFromDomain.isAudioEnabled, domainParticipant.isAudioEnabled);
        expect(modelFromDomain.isVideoEnabled, domainParticipant.isVideoEnabled);
        expect(modelFromDomain.avatarUrl, domainParticipant.avatarUrl);
      });
    });

    group('Role Conversion', () {
      test('should convert all participant roles correctly', () {
        final roles = [
          ParticipantRole.host,
          ParticipantRole.moderator,
          ParticipantRole.attendee,
        ];

        for (final role in roles) {
          // Convert to string
          final roleString = role.name;
          
          // Convert back from string
          final roleFromString = ParticipantRole.values.firstWhere(
            (r) => r.name == roleString,
          );
          
          expect(roleFromString, role);
        }
      });
    });

    group('Supabase Integration', () {
      test('should create from Supabase participant row correctly', () {
        // Arrange
        final supabaseRow = {
          'user_id': 'sb-user-123',
          'display_name': 'Supabase User',
          'role': 'moderator',
          'joined_at': '2024-01-20T14:30:00.000000+00:00',
          'left_at': null,
          'is_audio_enabled': true,
          'is_video_enabled': true,
          'avatar_url': 'https://example.com/sb-avatar.jpg',
        };

        // Act
        final result = MeetingParticipantModel.fromSupabaseRow(supabaseRow);

        // Assert
        expect(result.userId, 'sb-user-123');
        expect(result.displayName, 'Supabase User');
        expect(result.role, ParticipantRole.moderator);
        expect(result.leftAt, isNull);
        expect(result.isAudioEnabled, true);
        expect(result.isVideoEnabled, true);
        expect(result.avatarUrl, 'https://example.com/sb-avatar.jpg');
      });

      test('should convert to Supabase row format correctly', () {
        // Act
        final supabaseRow = participantModel.toSupabaseRow();

        // Assert
        expect(supabaseRow['user_id'], participantModel.userId);
        expect(supabaseRow['display_name'], participantModel.displayName);
        expect(supabaseRow['role'], participantModel.role.name);
        expect(supabaseRow['is_audio_enabled'], participantModel.isAudioEnabled);
        expect(supabaseRow['is_video_enabled'], participantModel.isVideoEnabled);
        expect(supabaseRow['avatar_url'], participantModel.avatarUrl);
      });
    });

    group('Status Updates', () {
      test('should handle audio toggle correctly', () {
        final toggledAudio = participantModel.copyWith(isAudioEnabled: false);
        
        expect(toggledAudio.userId, participantModel.userId);
        expect(toggledAudio.isAudioEnabled, false);
        expect(toggledAudio.isVideoEnabled, participantModel.isVideoEnabled);
      });

      test('should handle video toggle correctly', () {
        final toggledVideo = participantModel.copyWith(isVideoEnabled: true);
        
        expect(toggledVideo.userId, participantModel.userId);
        expect(toggledVideo.isAudioEnabled, participantModel.isAudioEnabled);
        expect(toggledVideo.isVideoEnabled, true);
      });

      test('should handle participant leaving correctly', () {
        final leftTime = DateTime(2024, 1, 15, 16, 0);
        final leftParticipant = participantModel.copyWith(leftAt: leftTime);
        
        expect(leftParticipant.leftAt, leftTime);
        expect(leftParticipant.userId, participantModel.userId);
      });
    });

    group('Real-time State Updates', () {
      test('should preserve essential data during status updates', () {
        // Simulate real-time updates
        var currentState = participantModel;
        
        // Audio toggle
        currentState = currentState.copyWith(isAudioEnabled: false);
        expect(currentState.userId, participantModel.userId);
        expect(currentState.joinedAt, participantModel.joinedAt);
        
        // Video toggle  
        currentState = currentState.copyWith(isVideoEnabled: true);
        expect(currentState.userId, participantModel.userId);
        expect(currentState.joinedAt, participantModel.joinedAt);
        expect(currentState.isAudioEnabled, false);
        
        // Leave meeting
        final leaveTime = DateTime.now();
        currentState = currentState.copyWith(leftAt: leaveTime);
        expect(currentState.leftAt, leaveTime);
        expect(currentState.userId, participantModel.userId);
      });
    });
  });
}