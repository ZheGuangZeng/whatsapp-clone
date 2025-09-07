import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../../auth/domain/usecases/base_usecase.dart';
import '../entities/participant.dart';
import '../entities/participant_role.dart';
import '../repositories/i_room_repository.dart';

/// Use case for joining a chat room as a participant
class JoinRoomUseCase implements UseCase<Participant, JoinRoomParams> {
  const JoinRoomUseCase(this._roomRepository);

  final IRoomRepository _roomRepository;

  @override
  Future<Result<Participant>> call(JoinRoomParams params) async {
    // Validate input parameters
    if (params.roomId.trim().isEmpty) {
      return const ResultFailure(
        ValidationFailure(message: 'Room ID cannot be empty'),
      );
    }

    if (params.userId.trim().isEmpty) {
      return const ResultFailure(
        ValidationFailure(message: 'User ID cannot be empty'),
      );
    }

    // Add participant to room through repository
    return await _roomRepository.addParticipant(
      roomId: params.roomId,
      userId: params.userId,
      role: params.role,
      permissions: params.permissions,
    );
  }
}

/// Parameters for joining a room
class JoinRoomParams extends Equatable {
  const JoinRoomParams({
    required this.roomId,
    required this.userId,
    this.role = ParticipantRole.member,
    this.permissions,
  });

  /// ID of the room to join
  final String roomId;
  
  /// ID of the user joining the room
  final String userId;
  
  /// Role to assign to the participant
  final ParticipantRole role;
  
  /// Optional specific permissions for the participant
  final List<String>? permissions;

  @override
  List<Object?> get props => [
    roomId,
    userId,
    role,
    permissions,
  ];
}