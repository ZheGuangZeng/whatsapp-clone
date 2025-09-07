import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../../auth/domain/usecases/base_usecase.dart';
import '../entities/room.dart';
import '../entities/room_type.dart';
import '../repositories/i_room_repository.dart';

/// Use case for creating a new chat room
class CreateRoomUseCase implements UseCase<Room, CreateRoomParams> {
  const CreateRoomUseCase(this._roomRepository);

  final IRoomRepository _roomRepository;

  @override
  Future<Result<Room>> call(CreateRoomParams params) async {
    // Validate input parameters
    if (params.name.trim().isEmpty) {
      return const ResultFailure(
        ValidationFailure(message: 'Room name cannot be empty'),
      );
    }

    if (params.creatorId.trim().isEmpty) {
      return const ResultFailure(
        ValidationFailure(message: 'Creator ID cannot be empty'),
      );
    }

    // Create the room through repository
    return await _roomRepository.createRoom(
      name: params.name.trim(),
      creatorId: params.creatorId,
      type: params.type,
      description: params.description?.trim(),
      avatarUrl: params.avatarUrl,
      initialParticipants: params.initialParticipants,
    );
  }
}

/// Parameters for creating a room
class CreateRoomParams extends Equatable {
  const CreateRoomParams({
    required this.name,
    required this.creatorId,
    this.type = RoomType.group,
    this.description,
    this.avatarUrl,
    this.initialParticipants,
  });

  /// Name of the room
  final String name;
  
  /// ID of the user creating the room
  final String creatorId;
  
  /// Type of room (group, direct, channel)
  final RoomType type;
  
  /// Optional description for the room
  final String? description;
  
  /// Optional avatar URL for the room
  final String? avatarUrl;
  
  /// List of initial participant user IDs
  final List<String>? initialParticipants;

  @override
  List<Object?> get props => [
    name,
    creatorId,
    type,
    description,
    avatarUrl,
    initialParticipants,
  ];
}