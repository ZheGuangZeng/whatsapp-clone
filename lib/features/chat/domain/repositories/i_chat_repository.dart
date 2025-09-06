import 'dart:async';

import '../entities/message.dart';
import '../entities/participant.dart';
import '../entities/room.dart';
import '../entities/typing_indicator.dart';
import '../entities/user_presence.dart';

/// Interface for chat repository
abstract interface class IChatRepository {
  // ========================================
  // ROOM OPERATIONS
  // ========================================

  /// Get all rooms for the current user
  Future<List<Room>> getRooms();

  /// Get a specific room by ID
  Future<Room?> getRoom(String roomId);

  /// Create a new room
  Future<Room> createRoom({
    String? name,
    String? description,
    required String type,
    List<String> participantIds = const [],
  });

  /// Update room information
  Future<Room> updateRoom(String roomId, {
    String? name,
    String? description,
    String? avatarUrl,
  });

  /// Delete a room (only by creator)
  Future<void> deleteRoom(String roomId);

  /// Get or create a direct message room with another user
  Future<Room> getOrCreateDirectMessage(String otherUserId);

  /// Stream of room updates
  Stream<List<Room>> watchRooms();

  // ========================================
  // PARTICIPANT OPERATIONS
  // ========================================

  /// Add participants to a room
  Future<void> addParticipants(String roomId, List<String> userIds);

  /// Remove participant from a room
  Future<void> removeParticipant(String roomId, String userId);

  /// Update participant role
  Future<void> updateParticipantRole(
    String roomId,
    String userId,
    String role,
  );

  /// Leave a room
  Future<void> leaveRoom(String roomId);

  /// Get room participants
  Future<List<Participant>> getRoomParticipants(String roomId);

  // ========================================
  // MESSAGE OPERATIONS
  // ========================================

  /// Send a new message
  Future<Message> sendMessage({
    required String roomId,
    required String content,
    String type = 'text',
    String? replyTo,
    Map<String, dynamic> metadata = const {},
  });

  /// Get messages for a room with pagination
  Future<List<Message>> getMessages(
    String roomId, {
    int limit = 50,
    String? before, // message ID to paginate before
  });

  /// Edit a message
  Future<Message> editMessage(String messageId, String newContent);

  /// Delete a message
  Future<void> deleteMessage(String messageId);

  /// Mark message as read
  Future<void> markMessageAsRead(String messageId);

  /// Mark all messages in a room as read
  Future<void> markRoomAsRead(String roomId);

  /// Get unread message count for a room
  Future<int> getUnreadCount(String roomId);

  /// Stream of messages for a room
  Stream<List<Message>> watchMessages(String roomId);

  /// Stream of new messages (for notifications)
  Stream<Message> watchNewMessages();

  // ========================================
  // MESSAGE REACTIONS
  // ========================================

  /// Add reaction to a message
  Future<void> addReaction(String messageId, String emoji);

  /// Remove reaction from a message
  Future<void> removeReaction(String messageId, String emoji);

  // ========================================
  // TYPING INDICATORS
  // ========================================

  /// Start typing in a room
  Future<void> startTyping(String roomId);

  /// Stop typing in a room
  Future<void> stopTyping(String roomId);

  /// Stream of typing indicators for a room
  Stream<List<TypingIndicator>> watchTypingIndicators(String roomId);

  // ========================================
  // USER PRESENCE
  // ========================================

  /// Update user presence
  Future<void> updatePresence({
    required bool isOnline,
    String status = 'available',
  });

  /// Get user presence
  Future<UserPresence?> getUserPresence(String userId);

  /// Get presence for multiple users
  Future<List<UserPresence>> getUsersPresence(List<String> userIds);

  /// Stream of user presence updates
  Stream<UserPresence> watchUserPresence(String userId);

  // ========================================
  // SEARCH OPERATIONS
  // ========================================

  /// Search messages in a room
  Future<List<Message>> searchMessages(String roomId, String query);

  /// Search messages across all rooms
  Future<List<Message>> searchAllMessages(String query);

  // ========================================
  // OFFLINE OPERATIONS
  // ========================================

  /// Queue message for sending when online
  Future<void> queueMessage({
    required String tempId,
    required String roomId,
    required String content,
    String type = 'text',
    String? replyTo,
    Map<String, dynamic> metadata = const {},
  });

  /// Get queued messages
  Future<List<Message>> getQueuedMessages();

  /// Sync queued messages with server
  Future<void> syncQueuedMessages();

  /// Clear queued messages
  Future<void> clearQueuedMessages();

  // ========================================
  // UTILITY OPERATIONS
  // ========================================

  /// Clean up old messages and optimize storage
  Future<void> cleanup();

  /// Get database statistics
  Future<Map<String, dynamic>> getStatistics();
}