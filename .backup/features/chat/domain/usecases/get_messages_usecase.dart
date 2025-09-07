import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../../auth/domain/usecases/base_usecase.dart';
import '../entities/message.dart';
import '../repositories/i_chat_repository.dart';

/// Use case for getting messages from a room
class GetMessagesUseCase implements UseCase<List<Message>, GetMessagesParams> {
  GetMessagesUseCase(this._chatRepository);

  final IChatRepository _chatRepository;

  @override
  Future<Result<List<Message>>> call(GetMessagesParams params) async {
    try {
      final messages = await _chatRepository.getMessages(
        params.roomId,
        limit: params.limit,
        before: params.before,
      );

      return Success(messages);
    } catch (e) {
      return const ResultFailure(
        ServerFailure(message: 'Failed to get messages'),
      );
    }
  }
}

/// Parameters for getting messages
class GetMessagesParams extends Equatable {
  const GetMessagesParams({
    required this.roomId,
    this.limit = 50,
    this.before,
  });

  /// ID of the room to get messages from
  final String roomId;

  /// Maximum number of messages to retrieve
  final int limit;

  /// Message ID to paginate before (for older messages)
  final String? before;

  @override
  List<Object?> get props => [roomId, limit, before];
}