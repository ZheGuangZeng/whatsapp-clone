import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/room.dart';
import '../../domain/repositories/i_message_repository.dart';
import '../datasources/message_local_datasource.dart';
import '../datasources/message_remote_datasource.dart';
import '../models/message_model.dart';

/// Implementation of IMessageRepository
class MessageRepositoryImpl implements IMessageRepository {
  const MessageRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  final MessageRemoteDataSource remoteDataSource;
  final MessageLocalDataSource localDataSource;

  @override
  Future<Result<Message>> sendMessage(Message message) async {
    try {
      final messageModel = MessageModel.fromEntity(message);
      
      try {
        // Try to send message to remote
        final sentMessage = await remoteDataSource.sendMessage(messageModel);
        
        // Cache the sent message locally
        await localDataSource.addToCachedMessages(message.roomId, sentMessage);
        
        return Success(sentMessage.toEntity());
      } catch (e) {
        // If remote fails, queue for offline sync
        await localDataSource.queueMessage(messageModel);
        
        // Return the original message with a temporary status
        return Success(message);
      }
    } catch (e) {
      return ResultFailure(ServerFailure(message: 'Failed to send message: $e'));
    }
  }

  @override
  Future<Result<List<Message>>> getMessages(
    String roomId, {
    int limit = 50,
    String? beforeId,
  }) async {
    try {
      // Try to get from remote first
      try {
        final messages = await remoteDataSource.getMessages(
          roomId,
          limit: limit,
          beforeId: beforeId,
        );
        
        // Cache the messages locally
        await localDataSource.cacheRoomMessages(
          roomId,
          messages,
        );
        
        return Success(
          messages.map((m) => m.toEntity()).toList(),
        );
      } catch (e) {
        // If remote fails, get from cache
        final cachedMessages = await localDataSource.getCachedRoomMessages(roomId);
        return Success(
          cachedMessages.map((m) => m.toEntity()).toList(),
        );
      }
    } catch (e) {
      return ResultFailure(ServerFailure(message: 'Failed to get messages: $e'));
    }
  }

  @override
  Future<Result<void>> markAsRead(String roomId, List<String> messageIds) async {
    try {
      await remoteDataSource.markMessagesAsRead(roomId, messageIds);
      return const Success(null);
    } catch (e) {
      return ResultFailure(ServerFailure(message: 'Failed to mark messages as read: $e'));
    }
  }

  @override
  Future<Result<void>> deleteMessage(String messageId) async {
    try {
      await remoteDataSource.deleteMessage(messageId);
      return const Success(null);
    } catch (e) {
      return ResultFailure(ServerFailure(message: 'Failed to delete message: $e'));
    }
  }

  @override
  Future<Result<Message>> editMessage(String messageId, String newContent) async {
    try {
      final editedMessage = await remoteDataSource.editMessage(messageId, newContent);
      return Success(editedMessage.toEntity());
    } catch (e) {
      return ResultFailure(ServerFailure(message: 'Failed to edit message: $e'));
    }
  }

  @override
  Future<Result<List<MessageStatusEntity>>> getMessageStatus(String messageId) async {
    try {
      final statusList = await remoteDataSource.getMessageStatus(messageId);
      return Success(statusList.map((s) => s.toEntity()).toList());
    } catch (e) {
      return ResultFailure(ServerFailure(message: 'Failed to get message status: $e'));
    }
  }

  @override
  Future<Result<void>> updateMessageStatus(String messageId, MessageStatus status) async {
    try {
      await remoteDataSource.updateMessageStatus(messageId, status);
      return const Success(null);
    } catch (e) {
      return ResultFailure(ServerFailure(message: 'Failed to update message status: $e'));
    }
  }

  @override
  Stream<List<Message>> messagesStream(String roomId) {
    try {
      return remoteDataSource
          .messagesStream(roomId)
          .map((messages) => messages.map((m) => m.toEntity()).toList());
    } catch (e) {
      throw Exception('Failed to create messages stream: $e');
    }
  }

  @override
  Stream<List<MessageStatusEntity>> messageStatusStream(String messageId) {
    try {
      return remoteDataSource
          .messageStatusStream(messageId)
          .map((statusList) => statusList.map((s) => s.toEntity()).toList());
    } catch (e) {
      throw Exception('Failed to create message status stream: $e');
    }
  }

  @override
  Stream<List<TypingIndicator>> typingIndicatorsStream(String roomId) {
    try {
      return remoteDataSource
          .typingIndicatorsStream(roomId)
          .map((indicators) => indicators.map((i) => i.toEntity()).toList());
    } catch (e) {
      throw Exception('Failed to create typing indicators stream: $e');
    }
  }

  @override
  Future<Result<void>> setTyping(String roomId, bool isTyping) async {
    try {
      await remoteDataSource.setTyping(roomId, isTyping);
      return const Success(null);
    } catch (e) {
      return ResultFailure(ServerFailure(message: 'Failed to set typing status: $e'));
    }
  }

  @override
  Stream<List<UserPresence>> presenceStream() {
    try {
      return remoteDataSource
          .presenceStream()
          .map((presenceList) => presenceList.map((p) => p.toEntity()).toList());
    } catch (e) {
      throw Exception('Failed to create presence stream: $e');
    }
  }

  @override
  Future<Result<void>> updatePresence(bool isOnline, PresenceStatus status) async {
    try {
      await remoteDataSource.updatePresence(isOnline, status);
      return const Success(null);
    } catch (e) {
      return ResultFailure(ServerFailure(message: 'Failed to update presence: $e'));
    }
  }

  @override
  Future<Result<void>> queueOfflineMessage(Message message) async {
    try {
      await localDataSource.queueMessage(MessageModel.fromEntity(message));
      return const Success(null);
    } catch (e) {
      return ResultFailure(ServerFailure(message: 'Failed to queue offline message: $e'));
    }
  }

  @override
  Future<Result<void>> syncOfflineMessages() async {
    try {
      final queuedMessages = await localDataSource.getQueuedMessages();
      
      for (final message in queuedMessages) {
        try {
          await remoteDataSource.sendMessage(message);
          await localDataSource.removeFromQueue(message.id);
        } catch (e) {
          // Continue with other messages if one fails
          continue;
        }
      }
      
      return const Success(null);
    } catch (e) {
      return ResultFailure(ServerFailure(message: 'Failed to sync offline messages: $e'));
    }
  }

  @override
  Future<Result<List<Room>>> getUserRooms() async {
    try {
      final rooms = await remoteDataSource.getUserRooms();
      return Success(rooms.map((r) => r.toEntity()).toList());
    } catch (e) {
      return ResultFailure(ServerFailure(message: 'Failed to get user rooms: $e'));
    }
  }

  @override
  Future<Result<Room>> getOrCreateDirectRoom(String otherUserId) async {
    try {
      final room = await remoteDataSource.getOrCreateDirectRoom(otherUserId);
      return Success(room.toEntity());
    } catch (e) {
      return ResultFailure(ServerFailure(message: 'Failed to get/create direct room: $e'));
    }
  }

  @override
  Future<Result<Room>> createGroupRoom(String name, List<String> participantIds) async {
    try {
      final room = await remoteDataSource.createGroupRoom(name, participantIds);
      return Success(room.toEntity());
    } catch (e) {
      return ResultFailure(ServerFailure(message: 'Failed to create group room: $e'));
    }
  }

  @override
  Future<Result<List<RoomParticipant>>> getRoomParticipants(String roomId) async {
    try {
      final participants = await remoteDataSource.getRoomParticipants(roomId);
      return Success(participants.map((p) => p.toEntity()).toList());
    } catch (e) {
      return ResultFailure(ServerFailure(message: 'Failed to get room participants: $e'));
    }
  }
}