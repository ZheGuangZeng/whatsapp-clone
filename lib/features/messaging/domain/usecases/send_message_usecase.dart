import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../../auth/domain/usecases/base_usecase.dart';
import '../entities/message.dart';
import '../repositories/i_message_repository.dart';

/// Use case for sending messages
class SendMessageUseCase implements UseCase<Message, SendMessageParams> {
  const SendMessageUseCase(this._repository);

  final IMessageRepository _repository;
  static const _uuid = Uuid();

  @override
  Future<Result<Message>> call(SendMessageParams params) async {
    // Validate input parameters
    final validationResult = _validateParams(params);
    if (validationResult.isFailure) {
      return ResultFailure(validationResult.failureOrNull!);
    }

    // Create message with generated ID and timestamp
    final message = Message(
      id: _uuid.v4(),
      senderId: params.senderId,
      roomId: params.roomId,
      content: params.content,
      timestamp: DateTime.now(),
      messageType: params.messageType,
      isRead: false,
    );

    // Send message through repository
    return await _repository.sendMessage(message);
  }

  /// Validate send message parameters
  Result<void> _validateParams(SendMessageParams params) {
    if (params.senderId.trim().isEmpty) {
      return const ResultFailure(
        ValidationFailure(message: 'senderId cannot be empty'),
      );
    }

    if (params.roomId.trim().isEmpty) {
      return const ResultFailure(
        ValidationFailure(message: 'roomId cannot be empty'),
      );
    }

    if (params.content.trim().isEmpty) {
      return const ResultFailure(
        ValidationFailure(message: 'Message content cannot be empty'),
      );
    }

    return const Success(null);
  }
}

/// Parameters for sending a message
class SendMessageParams extends Equatable {
  const SendMessageParams({
    required this.senderId,
    required this.roomId,
    required this.content,
    this.messageType = MessageType.text,
  });

  final String senderId;
  final String roomId;
  final String content;
  final MessageType messageType;

  @override
  List<Object?> get props => [senderId, roomId, content, messageType];

  /// Create a copy with some fields updated
  SendMessageParams copyWith({
    String? senderId,
    String? roomId,
    String? content,
    MessageType? messageType,
  }) {
    return SendMessageParams(
      senderId: senderId ?? this.senderId,
      roomId: roomId ?? this.roomId,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
    );
  }
}