import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_clone/features/chat/domain/entities/participant.dart';
import 'package:whatsapp_clone/features/chat/domain/entities/participant_role.dart';

void main() {
  group('Participant Entity Tests', () {
    test('should create a valid Participant with required fields', () {
      // Arrange
      const participantId = 'participant_123';
      const userId = 'user_123';
      const roomId = 'room_123';
      final joinedAt = DateTime.now();
      
      // Act
      final participant = Participant(
        id: participantId,
        userId: userId,
        roomId: roomId,
        joinedAt: joinedAt,
      );
      
      // Assert
      expect(participant.id, equals(participantId));
      expect(participant.userId, equals(userId));
      expect(participant.roomId, equals(roomId));
      expect(participant.joinedAt, equals(joinedAt));
      expect(participant.role, equals(ParticipantRole.member)); // default
      expect(participant.isActive, isTrue); // default
      expect(participant.lastActivity, isNull);
      expect(participant.permissions, isEmpty);
    });

    test('should create a Participant with all optional fields', () {
      // Arrange
      const participantId = 'participant_123';
      const userId = 'user_123';
      const roomId = 'room_123';
      final joinedAt = DateTime.now();
      final lastActivity = DateTime.now();
      const permissions = ['read', 'write', 'admin'];
      
      // Act
      final participant = Participant(
        id: participantId,
        userId: userId,
        roomId: roomId,
        joinedAt: joinedAt,
        role: ParticipantRole.admin,
        isActive: false,
        lastActivity: lastActivity,
        permissions: permissions,
      );
      
      // Assert
      expect(participant.id, equals(participantId));
      expect(participant.userId, equals(userId));
      expect(participant.roomId, equals(roomId));
      expect(participant.joinedAt, equals(joinedAt));
      expect(participant.role, equals(ParticipantRole.admin));
      expect(participant.isActive, isFalse);
      expect(participant.lastActivity, equals(lastActivity));
      expect(participant.permissions, equals(permissions));
    });

    test('should support equality comparison', () {
      // Arrange
      final joinedAt = DateTime.now();
      final participant1 = Participant(
        id: 'participant_123',
        userId: 'user_123',
        roomId: 'room_123',
        joinedAt: joinedAt,
      );
      final participant2 = Participant(
        id: 'participant_123',
        userId: 'user_123',
        roomId: 'room_123',
        joinedAt: joinedAt,
      );
      final participant3 = Participant(
        id: 'participant_456',
        userId: 'user_123',
        roomId: 'room_123',
        joinedAt: joinedAt,
      );
      
      // Act & Assert
      expect(participant1, equals(participant2));
      expect(participant1, isNot(equals(participant3)));
      expect(participant1.hashCode, equals(participant2.hashCode));
      expect(participant1.hashCode, isNot(equals(participant3.hashCode)));
    });

    test('should create a copy with updated fields', () {
      // Arrange
      final originalParticipant = Participant(
        id: 'participant_123',
        userId: 'user_123',
        roomId: 'room_123',
        joinedAt: DateTime.now(),
        role: ParticipantRole.member,
        isActive: true,
      );
      final newLastActivity = DateTime.now();
      
      // Act
      final updatedParticipant = originalParticipant.copyWith(
        role: ParticipantRole.admin,
        isActive: false,
        lastActivity: newLastActivity,
        permissions: const ['admin', 'moderate'],
      );
      
      // Assert
      expect(updatedParticipant.id, equals(originalParticipant.id));
      expect(updatedParticipant.userId, equals(originalParticipant.userId));
      expect(updatedParticipant.roomId, equals(originalParticipant.roomId));
      expect(updatedParticipant.joinedAt, equals(originalParticipant.joinedAt));
      expect(updatedParticipant.role, equals(ParticipantRole.admin));
      expect(updatedParticipant.isActive, isFalse);
      expect(updatedParticipant.lastActivity, equals(newLastActivity));
      expect(updatedParticipant.permissions, equals(['admin', 'moderate']));
    });

    test('should validate participant ID is not empty', () {
      // Arrange
      final joinedAt = DateTime.now();
      
      // Act & Assert
      expect(
        () => Participant(
          id: '',
          userId: 'user_123',
          roomId: 'room_123',
          joinedAt: joinedAt,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('should validate user ID is not empty', () {
      // Arrange
      final joinedAt = DateTime.now();
      
      // Act & Assert
      expect(
        () => Participant(
          id: 'participant_123',
          userId: '',
          roomId: 'room_123',
          joinedAt: joinedAt,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('should validate room ID is not empty', () {
      // Arrange
      final joinedAt = DateTime.now();
      
      // Act & Assert
      expect(
        () => Participant(
          id: 'participant_123',
          userId: 'user_123',
          roomId: '',
          joinedAt: joinedAt,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('should handle role changes correctly', () {
      // Arrange
      final participant = Participant(
        id: 'participant_123',
        userId: 'user_123',
        roomId: 'room_123',
        joinedAt: DateTime.now(),
        role: ParticipantRole.member,
      );
      
      // Act
      final moderatorParticipant = participant.copyWith(role: ParticipantRole.moderator);
      final adminParticipant = participant.copyWith(role: ParticipantRole.admin);
      
      // Assert
      expect(moderatorParticipant.role, equals(ParticipantRole.moderator));
      expect(adminParticipant.role, equals(ParticipantRole.admin));
      expect(participant.role, equals(ParticipantRole.member)); // original unchanged
    });

    test('should handle permission updates correctly', () {
      // Arrange
      final participant = Participant(
        id: 'participant_123',
        userId: 'user_123',
        roomId: 'room_123',
        joinedAt: DateTime.now(),
        permissions: ['read'],
      );
      
      // Act
      final updatedParticipant = participant.copyWith(
        permissions: ['read', 'write', 'delete'],
      );
      
      // Assert
      expect(updatedParticipant.permissions, equals(['read', 'write', 'delete']));
      expect(participant.permissions, equals(['read'])); // original unchanged
    });

    test('should handle activity status changes correctly', () {
      // Arrange
      final participant = Participant(
        id: 'participant_123',
        userId: 'user_123',
        roomId: 'room_123',
        joinedAt: DateTime.now(),
        isActive: true,
      );
      final newActivity = DateTime.now();
      
      // Act
      final inactiveParticipant = participant.copyWith(
        isActive: false,
        lastActivity: newActivity,
      );
      
      // Assert
      expect(inactiveParticipant.isActive, isFalse);
      expect(inactiveParticipant.lastActivity, equals(newActivity));
      expect(participant.isActive, isTrue); // original unchanged
    });
  });
}