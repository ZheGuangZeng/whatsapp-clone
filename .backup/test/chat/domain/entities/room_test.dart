import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_clone/features/chat/domain/entities/message.dart';
import 'package:whatsapp_clone/features/chat/domain/entities/participant.dart';
import 'package:whatsapp_clone/features/chat/domain/entities/room.dart';

void main() {
  group('RoomType', () {
    test('should create room type from string', () {
      expect(RoomType.fromString('direct'), RoomType.direct);
      expect(RoomType.fromString('group'), RoomType.group);
    });

    test('should return default type for invalid string', () {
      expect(RoomType.fromString('invalid'), RoomType.direct);
    });

    test('should have correct string values', () {
      expect(RoomType.direct.value, 'direct');
      expect(RoomType.group.value, 'group');
    });
  });

  group('Room', () {
    late DateTime now;
    late DateTime past;

    setUp(() {
      now = DateTime.utc(2023, 6, 15, 10, 0);
      past = DateTime.utc(2023, 6, 15, 8, 0);
    });

    final testParticipant1 = Participant(
      id: 'participant-1',
      roomId: 'room-123',
      userId: 'user-1',
      displayName: 'User One',
      email: 'user1@example.com',
      joinedAt: past,
      isActive: true,
      isOnline: true,
    );

    final testParticipant2 = Participant(
      id: 'participant-2',
      roomId: 'room-123',
      userId: 'user-2',
      displayName: 'User Two',
      email: 'user2@example.com',
      avatarUrl: 'https://example.com/avatar2.jpg',
      joinedAt: past,
      isActive: true,
      isOnline: false,
    );


    final testInactiveParticipant = Participant(
      id: 'participant-inactive',
      roomId: 'room-123',
      userId: 'inactive-user',
      displayName: 'Inactive User',
      joinedAt: past,
      leftAt: now,
      isActive: false,
    );

    final testMessage = Message(
      id: 'message-123',
      roomId: 'room-123',
      userId: 'user-1',
      content: 'Hello, World!',
      type: MessageType.text,
      createdAt: now,
      updatedAt: now,
    );

    test('should create Room with required properties', () {
      final room = Room(
        id: 'room-123',
        type: RoomType.direct,
        createdBy: 'user-1',
        createdAt: past,
        updatedAt: now,
      );

      expect(room.id, 'room-123');
      expect(room.type, RoomType.direct);
      expect(room.createdBy, 'user-1');
      expect(room.createdAt, past);
      expect(room.updatedAt, now);
      expect(room.participants, isEmpty);
      expect(room.unreadCount, 0);
      expect(room.name, isNull);
      expect(room.description, isNull);
    });

    test('should create Room with all properties', () {
      final participants = [testParticipant1, testParticipant2];

      final room = Room(
        id: 'room-123',
        name: 'Test Group',
        description: 'A test group chat',
        type: RoomType.group,
        createdBy: 'user-1',
        avatarUrl: 'https://example.com/avatar.jpg',
        lastMessageAt: now,
        createdAt: past,
        updatedAt: now,
        participants: participants,
        lastMessage: testMessage,
        unreadCount: 5,
      );

      expect(room.name, 'Test Group');
      expect(room.description, 'A test group chat');
      expect(room.avatarUrl, 'https://example.com/avatar.jpg');
      expect(room.lastMessageAt, now);
      expect(room.participants, participants);
      expect(room.lastMessage, testMessage);
      expect(room.unreadCount, 5);
    });

    group('type checking', () {
      test('should correctly identify direct message room', () {
        final room = Room(
          id: 'room-123',
          type: RoomType.direct,
          createdBy: 'user-1',
          createdAt: past,
          updatedAt: now,
        );

        expect(room.isDirectMessage, true);
        expect(room.isGroupChat, false);
      });

      test('should correctly identify group chat room', () {
        final room = Room(
          id: 'room-123',
          type: RoomType.group,
          createdBy: 'user-1',
          createdAt: past,
          updatedAt: now,
        );

        expect(room.isGroupChat, true);
        expect(room.isDirectMessage, false);
      });
    });

    group('unread message handling', () {
      test('should correctly identify rooms with unread messages', () {
        final roomWithUnread = Room(
          id: 'room-123',
          type: RoomType.direct,
          createdBy: 'user-1',
          createdAt: past,
          updatedAt: now,
          unreadCount: 3,
        );

        expect(roomWithUnread.hasUnreadMessages, true);
      });

      test('should correctly identify rooms without unread messages', () {
        final roomWithoutUnread = Room(
          id: 'room-123',
          type: RoomType.direct,
          createdBy: 'user-1',
          createdAt: past,
          updatedAt: now,
          unreadCount: 0,
        );

        expect(roomWithoutUnread.hasUnreadMessages, false);
      });
    });

    group('participant management', () {
      test('should filter active participants', () {
        final participants = [testParticipant1, testInactiveParticipant];

        final room = Room(
          id: 'room-123',
          type: RoomType.group,
          createdBy: 'user-1',
          createdAt: past,
          updatedAt: now,
          participants: participants,
        );

        expect(room.activeParticipants, [testParticipant1]);
        expect(room.activeParticipants.length, 1);
      });
    });

    group('display name logic', () {
      test('should use room name for group chat', () {
        final room = Room(
          id: 'room-123',
          name: 'Team Chat',
          type: RoomType.group,
          createdBy: 'user-1',
          createdAt: past,
          updatedAt: now,
          participants: [testParticipant1, testParticipant2],
        );

        expect(room.getDisplayName('user-1'), 'Team Chat');
      });

      test('should use other participant name for direct message', () {
        final room = Room(
          id: 'room-123',
          type: RoomType.direct,
          createdBy: 'user-1',
          createdAt: past,
          updatedAt: now,
          participants: [testParticipant1, testParticipant2],
        );

        expect(room.getDisplayName('user-1'), 'User Two');
        expect(room.getDisplayName('user-2'), 'User One');
      });

      test('should handle direct message with unknown participant', () {
        final room = Room(
          id: 'room-123',
          type: RoomType.direct,
          createdBy: 'user-1',
          createdAt: past,
          updatedAt: now,
          participants: [testInactiveParticipant], // No active other participant
        );

        expect(room.getDisplayName('user-1'), 'Unknown User');
      });

      test('should use fallback name when group has no name', () {
        final room = Room(
          id: 'room-123',
          type: RoomType.group,
          createdBy: 'user-1',
          createdAt: past,
          updatedAt: now,
        );

        expect(room.getDisplayName('user-1'), 'Chat Room');
      });
    });

    group('avatar URL logic', () {
      test('should use room avatar URL when available', () {
        final room = Room(
          id: 'room-123',
          type: RoomType.group,
          createdBy: 'user-1',
          avatarUrl: 'https://example.com/room-avatar.jpg',
          createdAt: past,
          updatedAt: now,
          participants: [testParticipant1, testParticipant2],
        );

        expect(room.getAvatarUrl('user-1'), 'https://example.com/room-avatar.jpg');
      });

      test('should use other participant avatar for direct message', () {
        final room = Room(
          id: 'room-123',
          type: RoomType.direct,
          createdBy: 'user-1',
          createdAt: past,
          updatedAt: now,
          participants: [testParticipant1, testParticipant2],
        );

        expect(room.getAvatarUrl('user-1'), 'https://example.com/avatar2.jpg');
      });

      test('should return null when no avatar available', () {
        final room = Room(
          id: 'room-123',
          type: RoomType.direct,
          createdBy: 'user-1',
          createdAt: past,
          updatedAt: now,
          participants: [testParticipant1], // No avatar URL
        );

        expect(room.getAvatarUrl('user-1'), isNull);
      });
    });

    group('factory constructors', () {
      test('should create empty room', () {
        final emptyRoom = Room.empty();

        expect(emptyRoom.id, isEmpty);
        expect(emptyRoom.type, RoomType.direct);
        expect(emptyRoom.createdBy, isEmpty);
        expect(emptyRoom.participants, isEmpty);
        expect(emptyRoom.unreadCount, 0);
        expect(emptyRoom.createdAt, isA<DateTime>());
        expect(emptyRoom.updatedAt, isA<DateTime>());
      });
    });

    test('should support copyWith for all fields', () {
      final originalRoom = Room(
        id: 'room-123',
        name: 'Original Name',
        type: RoomType.direct,
        createdBy: 'user-1',
        createdAt: past,
        updatedAt: now,
        unreadCount: 0,
      );

      final updatedRoom = originalRoom.copyWith(
        name: 'Updated Name',
        type: RoomType.group,
        unreadCount: 5,
        participants: [testParticipant1],
      );

      expect(updatedRoom.id, originalRoom.id);
      expect(updatedRoom.name, 'Updated Name');
      expect(updatedRoom.type, RoomType.group);
      expect(updatedRoom.unreadCount, 5);
      expect(updatedRoom.participants, [testParticipant1]);
      expect(updatedRoom.createdBy, originalRoom.createdBy);
      expect(updatedRoom.createdAt, originalRoom.createdAt);
    });

    test('should support copyWith with partial updates', () {
      final originalRoom = Room(
        id: 'room-123',
        name: 'Original Name',
        type: RoomType.direct,
        createdBy: 'user-1',
        createdAt: past,
        updatedAt: now,
      );

      final updatedRoom = originalRoom.copyWith(
        unreadCount: 3,
      );

      expect(updatedRoom.name, originalRoom.name);
      expect(updatedRoom.type, originalRoom.type);
      expect(updatedRoom.unreadCount, 3);
      expect(updatedRoom.id, originalRoom.id);
    });

    test('should support equality comparison', () {
      final room1 = Room(
        id: 'room-123',
        type: RoomType.direct,
        createdBy: 'user-1',
        createdAt: past,
        updatedAt: now,
      );

      final room2 = Room(
        id: 'room-123',
        type: RoomType.direct,
        createdBy: 'user-1',
        createdAt: past,
        updatedAt: now,
      );

      final room3 = Room(
        id: 'room-456',
        type: RoomType.direct,
        createdBy: 'user-1',
        createdAt: past,
        updatedAt: now,
      );

      expect(room1, equals(room2));
      expect(room1, isNot(equals(room3)));
    });

    test('should have consistent hashCode for equal objects', () {
      final room1 = Room(
        id: 'room-123',
        type: RoomType.direct,
        createdBy: 'user-1',
        createdAt: past,
        updatedAt: now,
      );

      final room2 = Room(
        id: 'room-123',
        type: RoomType.direct,
        createdBy: 'user-1',
        createdAt: past,
        updatedAt: now,
      );

      expect(room1.hashCode, room2.hashCode);
    });

    test('should include all properties in props', () {
      final room = Room(
        id: 'room-123',
        name: 'Test Room',
        description: 'Test Description',
        type: RoomType.group,
        createdBy: 'user-1',
        avatarUrl: 'https://example.com/avatar.jpg',
        lastMessageAt: now,
        createdAt: past,
        updatedAt: now,
        participants: [testParticipant1],
        lastMessage: testMessage,
        unreadCount: 3,
      );

      final props = room.props;
      expect(props, contains(room.id));
      expect(props, contains(room.name));
      expect(props, contains(room.description));
      expect(props, contains(room.type));
      expect(props, contains(room.createdBy));
      expect(props, contains(room.avatarUrl));
      expect(props, contains(room.lastMessageAt));
      expect(props, contains(room.createdAt));
      expect(props, contains(room.updatedAt));
      expect(props, contains(room.participants));
      expect(props, contains(room.lastMessage));
      expect(props, contains(room.unreadCount));
    });

    group('edge cases', () {
      test('should handle empty participants list gracefully', () {
        final room = Room(
          id: 'room-123',
          type: RoomType.direct,
          createdBy: 'user-1',
          createdAt: past,
          updatedAt: now,
          participants: const [],
        );

        expect(room.activeParticipants, isEmpty);
        expect(room.getDisplayName('user-1'), 'Unknown User');
        expect(room.getAvatarUrl('user-1'), isNull);
      });

      test('should handle direct message with self only', () {
        final selfParticipant = Participant(
          id: 'participant-self',
          roomId: 'room-123',
          userId: 'user-1',
          displayName: 'Self',
          joinedAt: past,
          isActive: true,
        );

        final room = Room(
          id: 'room-123',
          type: RoomType.direct,
          createdBy: 'user-1',
          createdAt: past,
          updatedAt: now,
          participants: [selfParticipant],
        );

        expect(room.getDisplayName('user-1'), 'Unknown User');
      });
    });
  });
}