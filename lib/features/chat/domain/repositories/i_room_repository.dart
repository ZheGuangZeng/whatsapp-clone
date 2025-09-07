import '../../../../core/utils/result.dart';
import '../entities/participant.dart';
import '../entities/participant_role.dart';
import '../entities/room.dart';
import '../entities/room_type.dart';

/// Repository interface for room-related operations
abstract class IRoomRepository {
  /// Create a new room
  Future<Result<Room>> createRoom({
    required String name,
    required String creatorId,
    RoomType type = RoomType.group,
    String? description,
    String? avatarUrl,
    List<String>? initialParticipants,
  });

  /// Get all rooms for a user
  Future<Result<List<Room>>> getUserRooms(String userId);

  /// Get a room by its ID
  Future<Result<Room>> getRoomById(String roomId);

  /// Update room details
  Future<Result<Room>> updateRoom({
    required String roomId,
    String? name,
    String? description,
    String? avatarUrl,
    bool? isActive,
  });

  /// Delete a room
  Future<Result<void>> deleteRoom(String roomId);

  /// Add a participant to a room
  Future<Result<Participant>> addParticipant({
    required String roomId,
    required String userId,
    ParticipantRole role = ParticipantRole.member,
    List<String>? permissions,
  });

  /// Remove a participant from a room
  Future<Result<void>> removeParticipant({
    required String roomId,
    required String userId,
  });

  /// Get all participants in a room
  Future<Result<List<Participant>>> getRoomParticipants(String roomId);

  /// Update a participant's role and permissions
  Future<Result<Participant>> updateParticipantRole({
    required String roomId,
    required String userId,
    required ParticipantRole role,
    List<String>? permissions,
  });

  /// Search for rooms
  Future<Result<List<Room>>> searchRooms({
    required String query,
    String? userId,
    RoomType? type,
    int limit = 50,
  });

  /// Update room's last activity timestamp
  Future<Result<Room>> updateLastActivity({
    required String roomId,
    required DateTime lastActivity,
  });
}