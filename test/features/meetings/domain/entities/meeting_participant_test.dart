import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_clone/features/meetings/domain/entities/meeting_participant.dart';
import 'package:whatsapp_clone/features/meetings/domain/entities/participant_role.dart';

void main() {
  group('MeetingParticipant Entity', () {
    late MeetingParticipant testParticipant;
    late DateTime testJoinedAt;

    setUp(() {
      testJoinedAt = DateTime(2024, 1, 15, 10, 30);
      testParticipant = MeetingParticipant(
        userId: 'user-123',
        displayName: 'John Doe',
        role: ParticipantRole.attendee,
        joinedAt: testJoinedAt,
        isAudioEnabled: true,
        isVideoEnabled: false,
      );
    });

    group('Participant Creation', () {
      test('should create participant with all required fields', () {
        // Assert
        expect(testParticipant.userId, equals('user-123'));
        expect(testParticipant.displayName, equals('John Doe'));
        expect(testParticipant.role, equals(ParticipantRole.attendee));
        expect(testParticipant.joinedAt, equals(testJoinedAt));
        expect(testParticipant.isAudioEnabled, isTrue);
        expect(testParticipant.isVideoEnabled, isFalse);
        expect(testParticipant.leftAt, isNull);
        expect(testParticipant.isPresent, isTrue);
      });

      test('should create participant with optional fields', () {
        // Arrange & Act
        final participantWithOptionals = MeetingParticipant(
          userId: 'user-456',
          displayName: 'Jane Smith',
          role: ParticipantRole.moderator,
          joinedAt: testJoinedAt,
          leftAt: testJoinedAt.add(const Duration(hours: 1)),
          isAudioEnabled: false,
          isVideoEnabled: true,
          avatarUrl: 'https://example.com/avatar.jpg',
        );

        // Assert
        expect(participantWithOptionals.leftAt, isNotNull);
        expect(participantWithOptionals.avatarUrl, equals('https://example.com/avatar.jpg'));
        expect(participantWithOptionals.isPresent, isFalse);
      });

      test('should validate participant roles', () {
        // Test that all participant roles are available
        expect(ParticipantRole.values, contains(ParticipantRole.host));
        expect(ParticipantRole.values, contains(ParticipantRole.moderator));
        expect(ParticipantRole.values, contains(ParticipantRole.attendee));
      });
    });

    group('Participant Status Management', () {
      test('should determine if participant is present', () {
        // Arrange - Participant without leftAt time
        final presentParticipant = testParticipant;
        
        // Arrange - Participant with leftAt time
        final leftParticipant = testParticipant.copyWith(
          leftAt: testJoinedAt.add(const Duration(minutes: 30)),
        );

        // Assert
        expect(presentParticipant.isPresent, isTrue);
        expect(leftParticipant.isPresent, isFalse);
      });

      test('should calculate session duration for left participant', () {
        // Arrange
        final leftTime = testJoinedAt.add(const Duration(minutes: 45));
        final leftParticipant = testParticipant.copyWith(leftAt: leftTime);

        // Act
        final duration = leftParticipant.sessionDuration;

        // Assert
        expect(duration, equals(const Duration(minutes: 45)));
      });

      test('should return null duration for present participant', () {
        // Act & Assert
        expect(testParticipant.sessionDuration, isNull);
      });

      test('should toggle audio status', () {
        // Act
        final mutedParticipant = testParticipant.copyWith(isAudioEnabled: false);
        final unmutedParticipant = mutedParticipant.copyWith(isAudioEnabled: true);

        // Assert
        expect(testParticipant.isAudioEnabled, isTrue);
        expect(mutedParticipant.isAudioEnabled, isFalse);
        expect(unmutedParticipant.isAudioEnabled, isTrue);
      });

      test('should toggle video status', () {
        // Act
        final videoOnParticipant = testParticipant.copyWith(isVideoEnabled: true);
        final videoOffParticipant = videoOnParticipant.copyWith(isVideoEnabled: false);

        // Assert
        expect(testParticipant.isVideoEnabled, isFalse);
        expect(videoOnParticipant.isVideoEnabled, isTrue);
        expect(videoOffParticipant.isVideoEnabled, isFalse);
      });
    });

    group('Role-based Permissions', () {
      test('should identify host permissions', () {
        // Arrange
        final hostParticipant = testParticipant.copyWith(role: ParticipantRole.host);

        // Act & Assert
        expect(hostParticipant.isHost, isTrue);
        expect(hostParticipant.canModerate, isTrue);
        expect(hostParticipant.canManageParticipants, isTrue);
      });

      test('should identify moderator permissions', () {
        // Arrange
        final moderatorParticipant = testParticipant.copyWith(role: ParticipantRole.moderator);

        // Act & Assert
        expect(moderatorParticipant.isHost, isFalse);
        expect(moderatorParticipant.canModerate, isTrue);
        expect(moderatorParticipant.canManageParticipants, isTrue);
      });

      test('should identify attendee permissions', () {
        // Arrange - testParticipant is already an attendee
        final attendeeParticipant = testParticipant;

        // Act & Assert
        expect(attendeeParticipant.isHost, isFalse);
        expect(attendeeParticipant.canModerate, isFalse);
        expect(attendeeParticipant.canManageParticipants, isFalse);
      });

      test('should determine if participant can control others audio/video', () {
        // Arrange
        final host = testParticipant.copyWith(role: ParticipantRole.host);
        final moderator = testParticipant.copyWith(role: ParticipantRole.moderator);
        final attendee = testParticipant;

        // Assert
        expect(host.canControlOthersMedia, isTrue);
        expect(moderator.canControlOthersMedia, isTrue);
        expect(attendee.canControlOthersMedia, isFalse);
      });
    });

    group('Participant Validation', () {
      test('should validate user ID is not empty', () {
        expect(testParticipant.userId.isNotEmpty, isTrue);
      });

      test('should validate display name is not empty', () {
        expect(testParticipant.displayName.isNotEmpty, isTrue);
      });

      test('should validate joined time is not null', () {
        expect(testParticipant.joinedAt, isNotNull);
      });

      test('should validate left time is after joined time when present', () {
        // Arrange
        final leftParticipant = testParticipant.copyWith(
          leftAt: testJoinedAt.add(const Duration(minutes: 30)),
        );

        // Assert
        expect(leftParticipant.leftAt!.isAfter(leftParticipant.joinedAt), isTrue);
      });
    });

    group('Equatable Implementation', () {
      test('should be equal when all properties match', () {
        // Arrange
        final participant1 = MeetingParticipant(
          userId: 'user-123',
          displayName: 'John Doe',
          role: ParticipantRole.attendee,
          joinedAt: testJoinedAt,
          isAudioEnabled: true,
          isVideoEnabled: false,
        );

        final participant2 = MeetingParticipant(
          userId: 'user-123',
          displayName: 'John Doe',
          role: ParticipantRole.attendee,
          joinedAt: testJoinedAt,
          isAudioEnabled: true,
          isVideoEnabled: false,
        );

        // Assert
        expect(participant1, equals(participant2));
      });

      test('should not be equal when properties differ', () {
        // Arrange
        final participant1 = testParticipant;
        final participant2 = testParticipant.copyWith(displayName: 'Different Name');

        // Assert
        expect(participant1, isNot(equals(participant2)));
      });
    });

    group('CopyWith Functionality', () {
      test('should create copy with updated fields', () {
        // Arrange
        final newRole = ParticipantRole.moderator;
        final newAudioStatus = false;

        // Act
        final updatedParticipant = testParticipant.copyWith(
          role: newRole,
          isAudioEnabled: newAudioStatus,
        );

        // Assert
        expect(updatedParticipant.role, equals(newRole));
        expect(updatedParticipant.isAudioEnabled, equals(newAudioStatus));
        expect(updatedParticipant.userId, equals(testParticipant.userId)); // Unchanged
        expect(updatedParticipant.displayName, equals(testParticipant.displayName)); // Unchanged
      });

      test('should preserve original values when no updates provided', () {
        // Act
        final copiedParticipant = testParticipant.copyWith();

        // Assert
        expect(copiedParticipant, equals(testParticipant));
      });

      test('should handle leaving participant correctly', () {
        // Arrange
        final leaveTime = testJoinedAt.add(const Duration(hours: 2));

        // Act
        final leftParticipant = testParticipant.copyWith(leftAt: leaveTime);

        // Assert
        expect(leftParticipant.leftAt, equals(leaveTime));
        expect(leftParticipant.isPresent, isFalse);
        expect(leftParticipant.sessionDuration, equals(const Duration(hours: 2)));
      });
    });
  });
}