import '../../../../core/utils/result.dart';
import '../entities/message.dart';

/// Interface for message repository
abstract class IMessageRepository {
  /// Send a message and return the sent message with generated ID and timestamp
  Future<Result<Message>> sendMessage(Message message);
  
  /// Get messages for a specific room
  Future<Result<List<Message>>> getMessages(String roomId, {
    int limit = 50,
    String? beforeId,
  });
  
  /// Mark messages as read
  Future<Result<void>> markAsRead(String roomId, List<String> messageIds);
  
  /// Delete a message
  Future<Result<void>> deleteMessage(String messageId);
}