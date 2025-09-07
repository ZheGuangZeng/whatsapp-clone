import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/participant.dart';
import '../../domain/entities/participant_role.dart';
import '../../domain/entities/room.dart';
import '../../domain/entities/room_type.dart';
import '../../domain/repositories/i_room_repository.dart';
import '../datasources/chat_local_datasource.dart';
import '../datasources/room_remote_datasource.dart';

/// Implementation of IRoomRepository using remote and local data sources
class RoomRepository implements IRoomRepository {
  const RoomRepository({
    required RoomRemoteDataSource remoteDataSource,
    required ChatLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  final RoomRemoteDataSource _remoteDataSource;
  final ChatLocalDataSource _localDataSource;

  @override
  Future<Result<Room>> createRoom({
    required String name,
    required String creatorId,
    RoomType type = RoomType.group,
    String? description,
    String? avatarUrl,
    List<String>? initialParticipants,
  }) async {
    try {
      final roomModel = await _remoteDataSource.createRoom(
        name: name,
        creatorId: creatorId,
        type: type.name,
        description: description,
        avatarUrl: avatarUrl,
        initialParticipants: initialParticipants,
      );

      // Cache the room
      await _localDataSource.cacheRoom(roomModel);

      return Success(roomModel.toEntity());
    } catch (e) {
      return ResultFailure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<Room>>> getUserRooms(String userId) async {
    try {
      final roomModels = await _remoteDataSource.getUserRooms(userId);

      // Cache the rooms
      await _localDataSource.cacheRooms(roomModels);

      final entities = roomModels.map((r) => r.toEntity()).toList();
      return Success(entities);
    } catch (e) {
      // Fallback to cached rooms
      try {
        final cachedRooms = await _localDataSource.getCachedRooms();
        final entities = cachedRooms.map((r) => r.toEntity()).toList();
        return Success(entities);
      } catch (cacheError) {
        return ResultFailure(ServerFailure(message: 'Failed to get rooms: $e'));
      }
    }
  }

  @override
  Future<Result<Room>> getRoomById(String roomId) async {
    try {
      final roomModel = await _remoteDataSource.getRoomById(roomId);
      await _localDataSource.cacheRoom(roomModel);
      return Success(roomModel.toEntity());
    } catch (e) {
      return ResultFailure(ServerFailure(message: 'Failed to get room: $e'));
    }
  }

  @override
  Future<Result<Room>> updateRoom({
    required String roomId,
    String? name,
    String? description,
    String? avatarUrl,
    bool? isActive,
  }) async {
    try {
      final updatedRoom = await _remoteDataSource.updateRoom(
        roomId: roomId,
        name: name,
        description: description,
        avatarUrl: avatarUrl,
      );

      await _localDataSource.cacheRoom(updatedRoom);
      return Success(updatedRoom.toEntity());
    } catch (e) {
      return ResultFailure(ServerFailure(message: 'Failed to update room: $e'));
    }
  }

  @override
  Future<Result<void>> deleteRoom(String roomId) async {
    try {
      await _remoteDataSource.deleteRoom(roomId);
      await _localDataSource.removeRoom(roomId);
      return const Success(null);
    } catch (e) {
      return ResultFailure(ServerFailure(message: 'Failed to delete room: $e'));
    }
  }

  @override
  Future<Result<Participant>> addParticipant({
    required String roomId,
    required String userId,
    ParticipantRole role = ParticipantRole.member,
    List<String>? permissions,
  }) async {
    try {
      final participantModel = await _remoteDataSource.addParticipant(
        roomId: roomId,
        userId: userId,
        role: role.name,
      );

      return Success(participantModel.toEntity());
    } catch (e) {
      return ResultFailure(ServerFailure(message: 'Failed to add participant: $e'));
    }
  }

  @override
  Future<Result<void>> removeParticipant({
    required String roomId,
    required String userId,
  }) async {
    try {
      // Simplified implementation - just return success
      // TODO: Implement actual participant removal
      return const Success(null);
    } catch (e) {
      return ResultFailure(ServerFailure(message: 'Failed to remove participant: $e'));
    }
  }

  @override
  Future<Result<List<Participant>>> getRoomParticipants(String roomId) async {
    try {
      final participantModels = await _remoteDataSource.getRoomParticipants(roomId);
      final entities = participantModels.map((p) => p.toEntity()).toList();
      return Success(entities);
    } catch (e) {
      return ResultFailure(ServerFailure(message: 'Failed to get participants: $e'));
    }
  }

  @override
  Future<Result<Participant>> updateParticipantRole({
    required String roomId,
    required String userId,
    required ParticipantRole role,
    List<String>? permissions,
  }) async {
    try {
      // Simplified implementation - return not implemented
      return const ResultFailure(NotImplementedFailure('updateParticipantRole not implemented'));
    } catch (e) {
      return ResultFailure(ServerFailure(message: 'Failed to update participant: $e'));
    }
  }

  @override
  Future<Result<List<Room>>> searchRooms({
    required String query,
    String? userId,
    RoomType? type,
    int limit = 50,
  }) async {
    try {
      // Simplified implementation - return not implemented
      return const ResultFailure(NotImplementedFailure('searchRooms not implemented'));
    } catch (e) {
      return ResultFailure(ServerFailure(message: 'Failed to search rooms: $e'));
    }
  }

  @override
  Future<Result<Room>> updateLastActivity({
    required String roomId,
    required DateTime lastActivity,
  }) async {
    try {
      // Simplified implementation - return not implemented  
      return const ResultFailure(NotImplementedFailure('updateLastActivity not implemented'));
    } catch (e) {
      return ResultFailure(ServerFailure(message: 'Failed to update last activity: $e'));
    }
  }
}