import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../../auth/domain/usecases/base_usecase.dart';
import '../../../messaging/domain/entities/message.dart';
import '../entities/chat_message.dart';
import '../repositories/i_chat_repository.dart';

/// Use case for sending a message in a chat room
class SendMessageUseCase implements UseCase<ChatMessage, SendMessageParams> {
  const SendMessageUseCase(this._chatRepository);

  final IChatRepository _chatRepository;

  @override
  Future<Result<ChatMessage>> call(SendMessageParams params) async {
    // Validate input parameters
    if (params.roomId.trim().isEmpty) {
      return const ResultFailure(
        ValidationFailure(message: 'Room ID cannot be empty'),
      );
    }

    if (params.senderId.trim().isEmpty) {
      return const ResultFailure(
        ValidationFailure(message: 'Sender ID cannot be empty'),
      );
    }

    if (params.content.trim().isEmpty) {
      return const ResultFailure(
        ValidationFailure(message: 'Message content cannot be empty'),
      );
    }

    // Send message through repository
    return await _chatRepository.sendMessage(
      roomId: params.roomId,
      senderId: params.senderId,
      content: params.content.trim(),
      messageType: params.messageType,
      threadId: params.threadId,
      replyToMessageId: params.replyToMessageId,
      metadata: params.metadata,
    );
  }
}

/// Parameters for sending a message
class SendMessageParams extends Equatable {
  const SendMessageParams({
    required this.roomId,
    required this.senderId,
    required this.content,
    this.messageType = MessageType.text,
    this.threadId,
    this.replyToMessageId,
    this.metadata,
  });

  /// ID of the room to send the message to
  final String roomId;
  
  /// ID of the user sending the message
  final String senderId;
  
  /// Content of the message
  final String content;
  
  /// Type of message (text, image, file)
  final MessageType messageType;
  
  /// ID of the thread this message belongs to (if it's a thread reply)
  final String? threadId;
  
  /// ID of the message this is replying to
  final String? replyToMessageId;
  
  /// Additional metadata for the message
  final Map<String, String>? metadata;

  @override
  List<Object?> get props => [
    roomId,
    senderId,
    content,
    messageType,
    threadId,
    replyToMessageId,
    metadata,
  ];
}