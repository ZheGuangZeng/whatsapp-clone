import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart' as failures;
import '../../../../core/utils/result.dart';
import '../../../auth/domain/usecases/base_usecase.dart';
import '../entities/message.dart';
import '../repositories/i_chat_repository.dart';

/// Use case for sending a message
class SendMessageUseCase implements UseCase<Message, SendMessageParams> {
  SendMessageUseCase(this._chatRepository);

  final IChatRepository _chatRepository;

  @override
  Future<Result<Message>> call(SendMessageParams params) async {
    try {
      final message = await _chatRepository.sendMessage(
        roomId: params.roomId,
        content: params.content,
        type: params.type,
        replyTo: params.replyTo,
        metadata: params.metadata,
      );

      return Success(message);
    } catch (e) {
      return const ResultFailure(
        failures.ServerFailure(message: 'Failed to send message'),
      );
    }
  }
}

/// Parameters for sending a message
class SendMessageParams extends Equatable {
  const SendMessageParams({
    required this.roomId,
    required this.content,
    this.type = 'text',
    this.replyTo,
    this.metadata = const {},
  });

  /// ID of the room to send message to
  final String roomId;

  /// Content of the message
  final String content;

  /// Type of message (text, image, file, etc.)
  final String type;

  /// ID of message this is replying to (if any)
  final String? replyTo;

  /// Additional metadata for the message
  final Map<String, dynamic> metadata;

  @override
  List<Object?> get props => [roomId, content, type, replyTo, metadata];
}