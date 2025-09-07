import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../../auth/domain/usecases/base_usecase.dart';
import '../entities/chat_message.dart';
import '../repositories/i_chat_repository.dart';

/// Use case for getting messages from a chat room
class GetMessagesUseCase implements UseCase<List<ChatMessage>, GetMessagesParams> {
  const GetMessagesUseCase(this._chatRepository);

  final IChatRepository _chatRepository;

  /// Maximum allowed limit for messages per request
  static const int maxLimit = 100;

  @override
  Future<Result<List<ChatMessage>>> call(GetMessagesParams params) async {
    // Validate input parameters
    if (params.roomId.trim().isEmpty) {
      return const ResultFailure(
        ValidationFailure(message: 'Room ID cannot be empty'),
      );
    }

    if (params.limit <= 0) {
      return const ResultFailure(
        ValidationFailure(message: 'Limit must be positive'),
      );
    }

    if (params.limit > maxLimit) {
      return ResultFailure(
        ValidationFailure(message: 'Limit cannot exceed $maxLimit'),
      );
    }

    // Get messages through repository
    return await _chatRepository.getMessages(
      roomId: params.roomId,
      limit: params.limit,
      beforeMessageId: params.beforeMessageId,
      threadId: params.threadId,
    );
  }
}

/// Parameters for getting messages
class GetMessagesParams extends Equatable {
  const GetMessagesParams({
    required this.roomId,
    this.limit = 50,
    this.beforeMessageId,
    this.threadId,
  });

  /// ID of the room to get messages from
  final String roomId;
  
  /// Maximum number of messages to return
  final int limit;
  
  /// ID of the message to get messages before (for pagination)
  final String? beforeMessageId;
  
  /// ID of the thread to get messages from (if getting thread messages)
  final String? threadId;

  @override
  List<Object?> get props => [
    roomId,
    limit,
    beforeMessageId,
    threadId,
  ];
}