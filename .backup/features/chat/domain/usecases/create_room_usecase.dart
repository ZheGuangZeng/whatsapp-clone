import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart' as failures;
import '../../../../core/utils/result.dart';
import '../../../auth/domain/usecases/base_usecase.dart';
import '../entities/room.dart';
import '../repositories/i_chat_repository.dart';

/// Use case for creating a new room
class CreateRoomUseCase implements UseCase<Room, CreateRoomParams> {
  CreateRoomUseCase(this._chatRepository);

  final IChatRepository _chatRepository;

  @override
  Future<Result<Room>> call(CreateRoomParams params) async {
    try {
      final room = await _chatRepository.createRoom(
        name: params.name,
        description: params.description,
        type: params.type.value,
        participantIds: params.participantIds,
      );

      return Success(room);
    } catch (e) {
      return const ResultFailure(
        failures.ServerFailure('Failed to create room'),
      );
    }
  }
}

/// Use case for getting or creating a direct message room
class GetOrCreateDirectMessageUseCase implements UseCase<Room, GetOrCreateDirectMessageParams> {
  GetOrCreateDirectMessageUseCase(this._chatRepository);

  final IChatRepository _chatRepository;

  @override
  Future<Result<Room>> call(GetOrCreateDirectMessageParams params) async {
    try {
      final room = await _chatRepository.getOrCreateDirectMessage(params.otherUserId);
      return Success(room);
    } catch (e) {
      return const ResultFailure(
        failures.ServerFailure('Failed to get or create direct message'),
      );
    }
  }
}

/// Parameters for creating a room
class CreateRoomParams extends Equatable {
  const CreateRoomParams({
    this.name,
    this.description,
    required this.type,
    this.participantIds = const [],
  });

  /// Name of the room (for group chats)
  final String? name;

  /// Description of the room
  final String? description;

  /// Type of room (direct or group)
  final RoomType type;

  /// List of participant user IDs to add to the room
  final List<String> participantIds;

  @override
  List<Object?> get props => [name, description, type, participantIds];
}

/// Parameters for getting or creating a direct message
class GetOrCreateDirectMessageParams extends Equatable {
  const GetOrCreateDirectMessageParams({required this.otherUserId});

  /// ID of the other user for direct message
  final String otherUserId;

  @override
  List<Object?> get props => [otherUserId];
}