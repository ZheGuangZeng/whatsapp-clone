import '../../../../core/utils/result.dart';
import '../entities/message.dart';
import '../entities/room.dart';

/// Interface for real-time message repository
abstract class IMessageRepository {
  /// Send a message and return the sent message with generated ID and timestamp
  Future<Result<Message>> sendMessage(Message message);
  
  /// Get messages for a specific room with pagination
  Future<Result<List<Message>>> getMessages(String roomId, {
    int limit = 50,
    String? beforeId,
  });
  
  /// Mark messages as read for the current user
  Future<Result<void>> markAsRead(String roomId, List<String> messageIds);
  
  /// Delete a message (soft delete)
  Future<Result<void>> deleteMessage(String messageId);
  
  /// Edit a message
  Future<Result<Message>> editMessage(String messageId, String newContent);
  
  /// Get message status for a specific message
  Future<Result<List<MessageStatusEntity>>> getMessageStatus(String messageId);
  
  /// Update message status (delivered/read)
  Future<Result<void>> updateMessageStatus(String messageId, MessageStatus status);
  
  /// Stream real-time messages for a room
  Stream<List<Message>> messagesStream(String roomId);
  
  /// Stream real-time message status updates
  Stream<List<MessageStatusEntity>> messageStatusStream(String messageId);
  
  /// Stream typing indicators for a room
  Stream<List<TypingIndicator>> typingIndicatorsStream(String roomId);
  
  /// Update typing status
  Future<Result<void>> setTyping(String roomId, bool isTyping);
  
  /// Stream user presence updates
  Stream<List<UserPresence>> presenceStream();
  
  /// Update user presence
  Future<Result<void>> updatePresence(bool isOnline, PresenceStatus status);
  
  /// Queue message for offline sync
  Future<Result<void>> queueOfflineMessage(Message message);
  
  /// Sync queued offline messages when coming online
  Future<Result<void>> syncOfflineMessages();
  
  /// Get all rooms for current user
  Future<Result<List<Room>>> getUserRooms();
  
  /// Create or get direct message room between two users
  Future<Result<Room>> getOrCreateDirectRoom(String otherUserId);
  
  /// Create group room
  Future<Result<Room>> createGroupRoom(String name, List<String> participantIds);
  
  /// Get room participants
  Future<Result<List<RoomParticipant>>> getRoomParticipants(String roomId);
}