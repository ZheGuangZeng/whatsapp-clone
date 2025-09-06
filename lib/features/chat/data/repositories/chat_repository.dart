import 'dart:async';

import '../../domain/entities/message.dart';
import '../../domain/entities/participant.dart';
import '../../domain/entities/room.dart';
import '../../domain/entities/typing_indicator.dart';
import '../../domain/entities/user_presence.dart';
import '../../domain/repositories/i_chat_repository.dart';
import '../sources/chat_remote_source.dart';

/// Implementation of IChatRepository
class ChatRepository implements IChatRepository {
  ChatRepository(this._remoteSource);

  final ChatRemoteSource _remoteSource;

  // ========================================
  // ROOM OPERATIONS
  // ========================================

  @override
  Future<List<Room>> getRooms() async {
    final roomModels = await _remoteSource.getRooms();
    return roomModels.map((model) => model.toEntity()).toList();
  }

  @override
  Future<Room?> getRoom(String roomId) async {
    final roomModel = await _remoteSource.getRoom(roomId);
    return roomModel?.toEntity();
  }

  @override
  Future<Room> createRoom({
    String? name,
    String? description,
    required String type,
    List<String> participantIds = const [],
  }) async {
    final roomModel = await _remoteSource.createRoom(
      name: name,
      description: description,
      type: type,
      participantIds: participantIds,
    );
    return roomModel.toEntity();
  }

  @override
  Future<Room> updateRoom(
    String roomId, {
    String? name,
    String? description,
    String? avatarUrl,
  }) async {
    final roomModel = await _remoteSource.updateRoom(
      roomId,
      name: name,
      description: description,
      avatarUrl: avatarUrl,
    );
    return roomModel.toEntity();
  }

  @override
  Future<void> deleteRoom(String roomId) async {
    await _remoteSource.deleteRoom(roomId);
  }

  @override
  Future<Room> getOrCreateDirectMessage(String otherUserId) async {
    final roomModel = await _remoteSource.getOrCreateDirectMessage(otherUserId);
    return roomModel.toEntity();
  }

  @override
  Stream<List<Room>> watchRooms() {
    return _remoteSource.watchRooms().map((models) =>
        models.map((model) => model.toEntity()).toList());
  }

  // ========================================
  // PARTICIPANT OPERATIONS
  // ========================================

  @override
  Future<void> addParticipants(String roomId, List<String> userIds) async {
    await _remoteSource.addParticipants(roomId, userIds);
  }

  @override
  Future<void> removeParticipant(String roomId, String userId) async {
    await _remoteSource.removeParticipant(roomId, userId);
  }

  @override
  Future<void> updateParticipantRole(String roomId, String userId, String role) async {
    await _remoteSource.updateParticipantRole(roomId, userId, role);
  }

  @override
  Future<void> leaveRoom(String roomId) async {
    // TODO: Get current user ID from auth service
    // For now, we'll use the same method as removeParticipant
    throw UnimplementedError('leaveRoom requires current user ID from auth service');
  }

  @override
  Future<List<Participant>> getRoomParticipants(String roomId) async {
    final participantModels = await _remoteSource.getRoomParticipants(roomId);
    return participantModels.map((model) => model.toEntity()).toList();
  }

  // ========================================
  // MESSAGE OPERATIONS
  // ========================================

  @override
  Future<Message> sendMessage({
    required String roomId,
    required String content,
    String type = 'text',
    String? replyTo,
    Map<String, dynamic> metadata = const {},
  }) async {
    final messageModel = await _remoteSource.sendMessage(
      roomId: roomId,
      content: content,
      type: type,
      replyTo: replyTo,
      metadata: metadata,
    );
    return messageModel.toEntity();
  }

  @override
  Future<List<Message>> getMessages(
    String roomId, {
    int limit = 50,
    String? before,
  }) async {
    final messageModels = await _remoteSource.getMessages(
      roomId,
      limit: limit,
      before: before,
    );
    return messageModels.map((model) => model.toEntity()).toList();
  }

  @override
  Future<Message> editMessage(String messageId, String newContent) async {
    final messageModel = await _remoteSource.editMessage(messageId, newContent);
    return messageModel.toEntity();
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    await _remoteSource.deleteMessage(messageId);
  }

  @override
  Future<void> markMessageAsRead(String messageId) async {
    await _remoteSource.markMessageAsRead(messageId);
  }

  @override
  Future<void> markRoomAsRead(String roomId) async {
    await _remoteSource.markRoomAsRead(roomId);
  }

  @override
  Future<int> getUnreadCount(String roomId) async {
    return await _remoteSource.getUnreadCount(roomId);
  }

  @override
  Stream<List<Message>> watchMessages(String roomId) {
    return _remoteSource.watchMessages(roomId).map((models) =>
        models.map((model) => model.toEntity()).toList());
  }

  @override
  Stream<Message> watchNewMessages() {
    return _remoteSource.watchNewMessages().map((model) => model.toEntity());
  }

  // ========================================
  // MESSAGE REACTIONS
  // ========================================

  @override
  Future<void> addReaction(String messageId, String emoji) async {
    await _remoteSource.addReaction(messageId, emoji);
  }

  @override
  Future<void> removeReaction(String messageId, String emoji) async {
    await _remoteSource.removeReaction(messageId, emoji);
  }

  // ========================================
  // TYPING INDICATORS
  // ========================================

  @override
  Future<void> startTyping(String roomId) async {
    await _remoteSource.startTyping(roomId);
  }

  @override
  Future<void> stopTyping(String roomId) async {
    await _remoteSource.stopTyping(roomId);
  }

  @override
  Stream<List<TypingIndicator>> watchTypingIndicators(String roomId) {
    return _remoteSource.watchTypingIndicators(roomId).map((models) =>
        models.map((model) => model.toEntity()).toList());
  }

  // ========================================
  // USER PRESENCE
  // ========================================

  @override
  Future<void> updatePresence({
    required bool isOnline,
    String status = 'available',
  }) async {
    await _remoteSource.updatePresence(isOnline: isOnline, status: status);
  }

  @override
  Future<UserPresence?> getUserPresence(String userId) async {
    final presenceModel = await _remoteSource.getUserPresence(userId);
    return presenceModel?.toEntity();
  }

  @override
  Future<List<UserPresence>> getUsersPresence(List<String> userIds) async {
    final presenceModels = await _remoteSource.getUsersPresence(userIds);
    return presenceModels.map((model) => model.toEntity()).toList();
  }

  @override
  Stream<UserPresence> watchUserPresence(String userId) {
    return _remoteSource.watchUserPresence(userId).map((model) => model.toEntity());
  }

  // ========================================
  // SEARCH OPERATIONS
  // ========================================

  @override
  Future<List<Message>> searchMessages(String roomId, String query) async {
    final messageModels = await _remoteSource.searchMessages(roomId, query);
    return messageModels.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<Message>> searchAllMessages(String query) async {
    // TODO: Implement search across all rooms
    throw UnimplementedError('searchAllMessages not implemented yet');
  }

  // ========================================
  // OFFLINE OPERATIONS
  // ========================================

  @override
  Future<void> queueMessage({
    required String tempId,
    required String roomId,
    required String content,
    String type = 'text',
    String? replyTo,
    Map<String, dynamic> metadata = const {},
  }) async {
    // TODO: Implement offline message queuing with local storage
    throw UnimplementedError('queueMessage not implemented yet');
  }

  @override
  Future<List<Message>> getQueuedMessages() async {
    // TODO: Implement get queued messages from local storage
    throw UnimplementedError('getQueuedMessages not implemented yet');
  }

  @override
  Future<void> syncQueuedMessages() async {
    // TODO: Implement sync queued messages with server
    throw UnimplementedError('syncQueuedMessages not implemented yet');
  }

  @override
  Future<void> clearQueuedMessages() async {
    // TODO: Implement clear queued messages
    throw UnimplementedError('clearQueuedMessages not implemented yet');
  }

  // ========================================
  // UTILITY OPERATIONS
  // ========================================

  @override
  Future<void> cleanup() async {
    // TODO: Implement database cleanup
    throw UnimplementedError('cleanup not implemented yet');
  }

  @override
  Future<Map<String, dynamic>> getStatistics() async {
    // TODO: Implement get database statistics
    throw UnimplementedError('getStatistics not implemented yet');
  }
}