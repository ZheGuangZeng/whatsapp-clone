import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_clone/core/utils/result.dart';
import 'package:whatsapp_clone/features/chat/domain/entities/participant.dart';
import 'package:whatsapp_clone/features/chat/domain/entities/participant_role.dart';
import 'package:whatsapp_clone/features/chat/domain/entities/room.dart';
import 'package:whatsapp_clone/features/chat/domain/entities/room_type.dart';
import 'package:whatsapp_clone/features/chat/domain/repositories/i_room_repository.dart';

// Mock implementation for testing interface contracts
class MockRoomRepository implements IRoomRepository {
  @override
  Future<Result<Room>> createRoom({
    required String name,
    required String creatorId,
    RoomType type = RoomType.group,
    String? description,
    String? avatarUrl,
    List<String>? initialParticipants,
  }) async {
    // Mock implementation
    final room = Room(
      id: 'mock_room_id',
      name: name,
      creatorId: creatorId,
      createdAt: DateTime.now(),
      type: type,
      description: description,
      avatarUrl: avatarUrl,
      participantCount: (initialParticipants?.length ?? 0) + 1, // +1 for creator
    );
    return Success(room);
  }

  @override
  Future<Result<List<Room>>> getUserRooms(String userId) async {
    return const Success([]);
  }

  @override
  Future<Result<Room>> getRoomById(String roomId) async {
    // Mock implementation
    final room = Room(
      id: roomId,
      name: 'Mock Room',
      creatorId: 'mock_creator',
      createdAt: DateTime.now(),
    );
    return Success(room);
  }

  @override
  Future<Result<Room>> updateRoom({
    required String roomId,
    String? name,
    String? description,
    String? avatarUrl,
    bool? isActive,
  }) async {
    // Mock implementation
    final room = Room(
      id: roomId,
      name: name ?? 'Updated Room',
      creatorId: 'mock_creator',
      createdAt: DateTime.now(),
      description: description,
      avatarUrl: avatarUrl,
      isActive: isActive ?? true,
    );
    return Success(room);
  }

  @override
  Future<Result<void>> deleteRoom(String roomId) async {
    return const Success(null);
  }

  @override
  Future<Result<Participant>> addParticipant({
    required String roomId,
    required String userId,
    ParticipantRole role = ParticipantRole.member,
    List<String>? permissions,
  }) async {
    // Mock implementation
    final participant = Participant(
      id: 'mock_participant_id',
      userId: userId,
      roomId: roomId,
      joinedAt: DateTime.now(),
      role: role,
      permissions: permissions ?? [],
    );
    return Success(participant);
  }

  @override
  Future<Result<void>> removeParticipant({
    required String roomId,
    required String userId,
  }) async {
    return const Success(null);
  }

  @override
  Future<Result<List<Participant>>> getRoomParticipants(String roomId) async {
    return const Success([]);
  }

  @override
  Future<Result<Participant>> updateParticipantRole({
    required String roomId,
    required String userId,
    required ParticipantRole role,
    List<String>? permissions,
  }) async {
    // Mock implementation
    final participant = Participant(
      id: 'mock_participant_id',
      userId: userId,
      roomId: roomId,
      joinedAt: DateTime.now(),
      role: role,
      permissions: permissions ?? [],
    );
    return Success(participant);
  }

  @override
  Future<Result<List<Room>>> searchRooms({
    required String query,
    String? userId,
    RoomType? type,
    int limit = 50,
  }) async {
    return const Success([]);
  }

  @override
  Future<Result<Room>> updateLastActivity({
    required String roomId,
    required DateTime lastActivity,
  }) async {
    // Mock implementation
    final room = Room(
      id: roomId,
      name: 'Mock Room',
      creatorId: 'mock_creator',
      createdAt: DateTime.now(),
      lastActivity: lastActivity,
    );
    return Success(room);
  }
}

void main() {
  group('IRoomRepository Interface Tests', () {
    late IRoomRepository repository;

    setUp(() {
      repository = MockRoomRepository();
    });

    test('should create a room successfully', () async {
      // Arrange
      const name = 'Test Room';
      const creatorId = 'user_123';
      const description = 'Test description';
      const initialParticipants = ['user_456', 'user_789'];
      
      // Act
      final result = await repository.createRoom(
        name: name,
        creatorId: creatorId,
        type: RoomType.group,
        description: description,
        initialParticipants: initialParticipants,
      );
      
      // Assert
      expect(result.isSuccess, isTrue);
      final room = result.dataOrNull!;
      expect(room.name, equals(name));
      expect(room.creatorId, equals(creatorId));
      expect(room.type, equals(RoomType.group));
      expect(room.description, equals(description));
      expect(room.participantCount, equals(3)); // 2 initial + 1 creator
    });

    test('should create a direct room', () async {
      // Arrange
      const name = 'Direct Chat';
      const creatorId = 'user_123';
      
      // Act
      final result = await repository.createRoom(
        name: name,
        creatorId: creatorId,
        type: RoomType.direct,
      );
      
      // Assert
      expect(result.isSuccess, isTrue);
      final room = result.dataOrNull!;
      expect(room.type, equals(RoomType.direct));
    });

    test('should get user rooms', () async {
      // Arrange
      const userId = 'user_123';
      
      // Act
      final result = await repository.getUserRooms(userId);
      
      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isA<List<Room>>());
    });

    test('should get room by ID', () async {
      // Arrange
      const roomId = 'room_123';
      
      // Act
      final result = await repository.getRoomById(roomId);
      
      // Assert
      expect(result.isSuccess, isTrue);
      final room = result.dataOrNull!;
      expect(room.id, equals(roomId));
    });

    test('should update room details', () async {
      // Arrange
      const roomId = 'room_123';
      const newName = 'Updated Room';
      const newDescription = 'Updated description';
      
      // Act
      final result = await repository.updateRoom(
        roomId: roomId,
        name: newName,
        description: newDescription,
        isActive: false,
      );
      
      // Assert
      expect(result.isSuccess, isTrue);
      final room = result.dataOrNull!;
      expect(room.id, equals(roomId));
      expect(room.name, equals(newName));
      expect(room.description, equals(newDescription));
      expect(room.isActive, isFalse);
    });

    test('should delete a room', () async {
      // Arrange
      const roomId = 'room_123';
      
      // Act
      final result = await repository.deleteRoom(roomId);
      
      // Assert
      expect(result.isSuccess, isTrue);
    });

    test('should add participant to room', () async {
      // Arrange
      const roomId = 'room_123';
      const userId = 'user_456';
      const role = ParticipantRole.moderator;
      const permissions = ['read', 'write'];
      
      // Act
      final result = await repository.addParticipant(
        roomId: roomId,
        userId: userId,
        role: role,
        permissions: permissions,
      );
      
      // Assert
      expect(result.isSuccess, isTrue);
      final participant = result.dataOrNull!;
      expect(participant.userId, equals(userId));
      expect(participant.roomId, equals(roomId));
      expect(participant.role, equals(role));
      expect(participant.permissions, equals(permissions));
    });

    test('should remove participant from room', () async {
      // Arrange
      const roomId = 'room_123';
      const userId = 'user_456';
      
      // Act
      final result = await repository.removeParticipant(
        roomId: roomId,
        userId: userId,
      );
      
      // Assert
      expect(result.isSuccess, isTrue);
    });

    test('should get room participants', () async {
      // Arrange
      const roomId = 'room_123';
      
      // Act
      final result = await repository.getRoomParticipants(roomId);
      
      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isA<List<Participant>>());
    });

    test('should update participant role', () async {
      // Arrange
      const roomId = 'room_123';
      const userId = 'user_456';
      const newRole = ParticipantRole.admin;
      const newPermissions = ['admin', 'moderate'];
      
      // Act
      final result = await repository.updateParticipantRole(
        roomId: roomId,
        userId: userId,
        role: newRole,
        permissions: newPermissions,
      );
      
      // Assert
      expect(result.isSuccess, isTrue);
      final participant = result.dataOrNull!;
      expect(participant.userId, equals(userId));
      expect(participant.role, equals(newRole));
      expect(participant.permissions, equals(newPermissions));
    });

    test('should search rooms', () async {
      // Arrange
      const query = 'test room';
      const userId = 'user_123';
      const type = RoomType.group;
      const limit = 25;
      
      // Act
      final result = await repository.searchRooms(
        query: query,
        userId: userId,
        type: type,
        limit: limit,
      );
      
      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isA<List<Room>>());
    });

    test('should update room last activity', () async {
      // Arrange
      const roomId = 'room_123';
      final lastActivity = DateTime.now();
      
      // Act
      final result = await repository.updateLastActivity(
        roomId: roomId,
        lastActivity: lastActivity,
      );
      
      // Assert
      expect(result.isSuccess, isTrue);
      final room = result.dataOrNull!;
      expect(room.id, equals(roomId));
      expect(room.lastActivity, equals(lastActivity));
    });

    test('should handle room types correctly', () async {
      // Test creating different room types
      final groupResult = await repository.createRoom(
        name: 'Group Chat',
        creatorId: 'user_123',
        type: RoomType.group,
      );
      
      final directResult = await repository.createRoom(
        name: 'Direct Chat',
        creatorId: 'user_123',
        type: RoomType.direct,
      );
      
      final channelResult = await repository.createRoom(
        name: 'Channel',
        creatorId: 'user_123',
        type: RoomType.channel,
      );
      
      expect(groupResult.isSuccess, isTrue);
      expect(directResult.isSuccess, isTrue);
      expect(channelResult.isSuccess, isTrue);
      
      expect(groupResult.dataOrNull!.type, equals(RoomType.group));
      expect(directResult.dataOrNull!.type, equals(RoomType.direct));
      expect(channelResult.dataOrNull!.type, equals(RoomType.channel));
    });
  });
}