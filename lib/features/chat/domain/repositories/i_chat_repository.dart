import '../../../../core/utils/result.dart';
import '../entities/chat_message.dart';
import '../entities/message_thread.dart';
import '../../../messaging/domain/entities/message.dart';

/// Repository interface for chat-related operations
abstract class IChatRepository {
  /// Send a new message to a room
  Future<Result<ChatMessage>> sendMessage({
    required String roomId,
    required String senderId,
    required String content,
    MessageType messageType = MessageType.text,
    String? threadId,
    String? replyToMessageId,
    Map<String, String>? metadata,
  });

  /// Get messages from a room with optional pagination and thread filtering
  Future<Result<List<ChatMessage>>> getMessages({
    required String roomId,
    int limit = 50,
    String? beforeMessageId,
    String? threadId,
  });

  /// Edit an existing message
  Future<Result<ChatMessage>> editMessage({
    required String messageId,
    required String content,
  });

  /// Delete a message
  Future<Result<void>> deleteMessage(String messageId);

  /// Add a reaction to a message
  Future<Result<ChatMessage>> addReaction({
    required String messageId,
    required String userId,
    required String reaction,
  });

  /// Remove a reaction from a message
  Future<Result<ChatMessage>> removeReaction({
    required String messageId,
    required String userId,
    required String reaction,
  });

  /// Create a new thread from a message
  Future<Result<MessageThread>> createThread({
    required String roomId,
    required String rootMessageId,
  });

  /// Get all threads in a room
  Future<Result<List<MessageThread>>> getThreads(String roomId);

  /// Mark messages as read for a user in a room
  Future<Result<void>> markMessagesAsRead({
    required String roomId,
    required String userId,
    String? lastMessageId,
  });

  /// Search messages in a room
  Future<Result<List<ChatMessage>>> searchMessages({
    required String roomId,
    required String query,
    int limit = 50,
  });
}