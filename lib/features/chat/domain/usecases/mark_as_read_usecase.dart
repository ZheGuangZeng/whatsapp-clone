import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart' as failures;
import '../../../../core/utils/result.dart';
import '../../../auth/domain/usecases/base_usecase.dart';
import '../repositories/i_chat_repository.dart';

/// Use case for marking a message as read
class MarkMessageAsReadUseCase implements UseCase<void, MarkMessageAsReadParams> {
  MarkMessageAsReadUseCase(this._chatRepository);

  final IChatRepository _chatRepository;

  @override
  Future<Result<void>> call(MarkMessageAsReadParams params) async {
    try {
      await _chatRepository.markMessageAsRead(params.messageId);
      return const Success(null);
    } catch (e) {
      return const ResultFailure(
        failures.ServerFailure('Failed to mark message as read'),
      );
    }
  }
}

/// Use case for marking all messages in a room as read
class MarkRoomAsReadUseCase implements UseCase<void, MarkRoomAsReadParams> {
  MarkRoomAsReadUseCase(this._chatRepository);

  final IChatRepository _chatRepository;

  @override
  Future<Result<void>> call(MarkRoomAsReadParams params) async {
    try {
      await _chatRepository.markRoomAsRead(params.roomId);
      return const Success(null);
    } catch (e) {
      return const ResultFailure(
        failures.ServerFailure('Failed to mark room as read'),
      );
    }
  }
}

/// Parameters for marking a message as read
class MarkMessageAsReadParams extends Equatable {
  const MarkMessageAsReadParams({required this.messageId});

  /// ID of the message to mark as read
  final String messageId;

  @override
  List<Object?> get props => [messageId];
}

/// Parameters for marking a room as read
class MarkRoomAsReadParams extends Equatable {
  const MarkRoomAsReadParams({required this.roomId});

  /// ID of the room to mark as read
  final String roomId;

  @override
  List<Object?> get props => [roomId];
}