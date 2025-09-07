import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../../messaging/domain/entities/message.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/message_thread.dart';
import '../../domain/repositories/i_chat_repository.dart';
import '../datasources/chat_local_datasource.dart';
import '../datasources/chat_remote_datasource.dart';

/// Implementation of IChatRepository using remote and local data sources
class ChatRepository implements IChatRepository {
  const ChatRepository({
    required ChatRemoteDataSource remoteDataSource,
    required ChatLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  final ChatRemoteDataSource _remoteDataSource;
  final ChatLocalDataSource _localDataSource;

  @override
  Future<Result<ChatMessage>> sendMessage({
    required String roomId,
    required String senderId,
    required String content,
    MessageType messageType = MessageType.text,
    String? threadId,
    String? replyToMessageId,
    Map<String, String>? metadata,
  }) async {
    try {
      final messageModel = await _remoteDataSource.sendMessage(
        roomId: roomId,
        senderId: senderId,
        content: content,
        threadId: threadId,
        replyToMessageId: replyToMessageId,
        metadata: metadata,
      );

      // Cache the sent message
      await _localDataSource.cacheMessage(
        roomId: roomId,
        message: messageModel,
      );

      return Success(messageModel.toEntity());
    } catch (e) {
      return ResultFailure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<ChatMessage>>> getMessages({
    required String roomId,
    int limit = 50,
    String? beforeMessageId,
    String? threadId,
  }) async {
    try {
      final remoteMessages = await _remoteDataSource.getMessages(
        roomId: roomId,
        limit: limit,
        before: beforeMessageId,
      );

      // Cache the messages
      await _localDataSource.cacheMessages(
        roomId: roomId,
        messages: remoteMessages,
      );

      final entities = remoteMessages.map((m) => m.toEntity()).toList();
      return Success(entities);
    } catch (e) {
      // Fallback to cached messages
      try {
        final cachedMessages = await _localDataSource.getCachedMessages(
          roomId: roomId,
        );
        final entities = cachedMessages.map((m) => m.toEntity()).toList();
        return Success(entities);
      } catch (cacheError) {
        return ResultFailure(ServerFailure(message: 'Failed to get messages: $e'));
      }
    }
  }

  @override
  Future<Result<ChatMessage>> editMessage({
    required String messageId,
    required String content,
  }) async {
    try {
      final updatedMessage = await _remoteDataSource.editMessage(
        messageId: messageId,
        content: content,
      );

      // Update cached message
      final roomId = updatedMessage.roomId;
      await _localDataSource.cacheMessage(
        roomId: roomId,
        message: updatedMessage,
      );

      return Success(updatedMessage.toEntity());
    } catch (e) {
      return ResultFailure(ServerFailure(message: 'Failed to edit message: $e'));
    }
  }

  @override
  Future<Result<void>> deleteMessage(String messageId) async {
    try {
      await _remoteDataSource.deleteMessage(messageId: messageId);
      return const Success(null);
    } catch (e) {
      return ResultFailure(ServerFailure(message: 'Failed to delete message: $e'));
    }
  }

  @override
  Future<Result<ChatMessage>> addReaction({
    required String messageId,
    required String userId,
    required String reaction,
  }) async {
    try {
      await _remoteDataSource.addReaction(
        messageId: messageId,
        userId: userId,
        emoji: reaction,
      );

      // Get updated message to return
      // For now, create a simple success response
      // TODO: Get and return the updated message with reactions
      return const ResultFailure(NotImplementedFailure('addReaction result not implemented'));
    } catch (e) {
      return ResultFailure(ServerFailure(message: 'Failed to add reaction: $e'));
    }
  }

  @override
  Future<Result<ChatMessage>> removeReaction({
    required String messageId,
    required String userId,
    required String reaction,
  }) async {
    try {
      await _remoteDataSource.removeReaction(
        messageId: messageId,
        userId: userId,
        emoji: reaction,
      );

      // Get updated message to return
      // For now, create a simple success response  
      // TODO: Get and return the updated message with reactions
      return const ResultFailure(NotImplementedFailure('removeReaction result not implemented'));
    } catch (e) {
      return ResultFailure(ServerFailure(message: 'Failed to remove reaction: $e'));
    }
  }

  @override
  Future<Result<MessageThread>> createThread({
    required String roomId,
    required String rootMessageId,
  }) async {
    try {
      final threadModel = await _remoteDataSource.createThread(
        roomId: roomId,
        rootMessageId: rootMessageId,
      );

      // Cache the thread
      await _localDataSource.cacheThread(
        roomId: roomId,
        thread: threadModel,
      );

      return Success(threadModel.toEntity());
    } catch (e) {
      return ResultFailure(ServerFailure(message: 'Failed to create thread: $e'));
    }
  }

  @override
  Future<Result<List<MessageThread>>> getThreads(String roomId) async {
    try {
      final threadModels = await _remoteDataSource.getThreads(
        roomId: roomId,
        limit: 20,
      );

      // Cache the threads
      await _localDataSource.cacheThreads(
        roomId: roomId,
        threads: threadModels,
      );

      final entities = threadModels.map((t) => t.toEntity()).toList();
      return Success(entities);
    } catch (e) {
      // Fallback to cached threads
      try {
        final cachedThreads = await _localDataSource.getCachedThreads(
          roomId: roomId,
        );
        final entities = cachedThreads.map((t) => t.toEntity()).toList();
        return Success(entities);
      } catch (cacheError) {
        return ResultFailure(ServerFailure(message: 'Failed to get threads: $e'));
      }
    }
  }

  @override
  Future<Result<void>> markMessagesAsRead({
    required String roomId,
    required String userId,
    String? lastMessageId,
  }) async {
    try {
      // Use current time if no specific message timestamp is provided
      await _remoteDataSource.markMessagesAsRead(
        roomId: roomId,
        userId: userId,
        upToTimestamp: DateTime.now(),
      );
      return const Success(null);
    } catch (e) {
      return ResultFailure(ServerFailure(message: 'Failed to mark messages as read: $e'));
    }
  }

  @override
  Future<Result<List<ChatMessage>>> searchMessages({
    required String roomId,
    required String query,
    int limit = 50,
  }) async {
    try {
      final messages = await _remoteDataSource.searchMessages(
        roomId: roomId,
        query: query,
        limit: limit,
      );

      final entities = messages.map((m) => m.toEntity()).toList();
      return Success(entities);
    } catch (e) {
      return ResultFailure(ServerFailure(message: 'Failed to search messages: $e'));
    }
  }
}