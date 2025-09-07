import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chat_message_model.dart';
import '../models/message_thread_model.dart';

/// Remote data source for chat operations using Supabase
class ChatRemoteDataSource {
  const ChatRemoteDataSource(this._supabase);

  final SupabaseClient _supabase;

  /// Send a message to a room
  Future<ChatMessageModel> sendMessage({
    required String roomId,
    required String senderId,
    required String content,
    String? threadId,
    String? replyToMessageId,
    Map<String, String>? metadata,
  }) async {
    final messageData = {
      'room_id': roomId,
      'sender_id': senderId,
      'content': content,
      'timestamp': DateTime.now().toIso8601String(),
      'message_type': 'text',
      'is_read': false,
      if (threadId != null) 'thread_id': threadId,
      if (replyToMessageId != null) 'reply_to_message_id': replyToMessageId,
      if (metadata != null) 'metadata': metadata,
    };

    final response = await _supabase
        .from('chat_messages')
        .insert(messageData)
        .select()
        .single();

    return ChatMessageModel.fromJson(response);
  }

  /// Get messages for a room with pagination
  Future<List<ChatMessageModel>> getMessages({
    required String roomId,
    int? limit = 50,
    String? before, // message ID to get messages before
    String? after,  // message ID to get messages after
  }) async {
    var query = _supabase
        .from('chat_messages')
        .select()
        .eq('room_id', roomId)
        .order('timestamp', ascending: false);

    if (limit != null) {
      query = query.limit(limit);
    }

    // Simple pagination implementation - can be enhanced later
    if (before != null) {
      // For now, just use basic pagination logic
      // TODO: Implement proper timestamp-based pagination
    }

    if (after != null) {
      // For now, just use basic pagination logic  
      // TODO: Implement proper timestamp-based pagination
    }

    final response = await query;
    return response.map((json) => ChatMessageModel.fromJson(json)).toList();
  }

  /// Get messages for a specific thread
  Future<List<ChatMessageModel>> getThreadMessages({
    required String threadId,
    int? limit = 50,
  }) async {
    var query = _supabase
        .from('chat_messages')
        .select()
        .eq('thread_id', threadId)
        .order('timestamp', ascending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    final response = await query;
    return response.map((json) => ChatMessageModel.fromJson(json)).toList();
  }

  /// Edit a message
  Future<ChatMessageModel> editMessage({
    required String messageId,
    required String content,
  }) async {
    final response = await _supabase
        .from('chat_messages')
        .update({
          'content': content,
          'edited_at': DateTime.now().toIso8601String(),
        })
        .eq('id', messageId)
        .select()
        .single();

    return ChatMessageModel.fromJson(response);
  }

  /// Delete a message (mark as deleted)
  Future<void> deleteMessage({
    required String messageId,
  }) async {
    await _supabase
        .from('chat_messages')
        .update({
          'is_deleted': true,
          'content': '[Deleted]',
          'edited_at': DateTime.now().toIso8601String(),
        })
        .eq('id', messageId);
  }

  /// Add reaction to a message
  Future<void> addReaction({
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    // Get current reactions
    final currentMessage = await _supabase
        .from('chat_messages')
        .select('reactions')
        .eq('id', messageId)
        .single();

    final currentReactions = ChatMessageModel.fromJson(currentMessage).reactions;
    final updatedReactions = Map<String, List<String>>.from(currentReactions);

    // Add user to emoji reaction list
    if (updatedReactions.containsKey(emoji)) {
      if (!updatedReactions[emoji]!.contains(userId)) {
        updatedReactions[emoji]!.add(userId);
      }
    } else {
      updatedReactions[emoji] = [userId];
    }

    await _supabase
        .from('chat_messages')
        .update({'reactions': updatedReactions})
        .eq('id', messageId);
  }

  /// Remove reaction from a message
  Future<void> removeReaction({
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    // Get current reactions
    final currentMessage = await _supabase
        .from('chat_messages')
        .select('reactions')
        .eq('id', messageId)
        .single();

    final currentReactions = ChatMessageModel.fromJson(currentMessage).reactions;
    final updatedReactions = Map<String, List<String>>.from(currentReactions);

    // Remove user from emoji reaction list
    if (updatedReactions.containsKey(emoji)) {
      updatedReactions[emoji]!.remove(userId);
      if (updatedReactions[emoji]!.isEmpty) {
        updatedReactions.remove(emoji);
      }
    }

    await _supabase
        .from('chat_messages')
        .update({'reactions': updatedReactions})
        .eq('id', messageId);
  }

  /// Create a new thread from a message
  Future<MessageThreadModel> createThread({
    required String roomId,
    required String rootMessageId,
  }) async {
    // Get root message
    final rootMessageResponse = await _supabase
        .from('chat_messages')
        .select()
        .eq('id', rootMessageId)
        .single();

    final rootMessage = ChatMessageModel.fromJson(rootMessageResponse);

    final threadData = {
      'room_id': roomId,
      'root_message': rootMessage.toJson(),
      'created_at': DateTime.now().toIso8601String(),
      'is_active': true,
      'reply_count': 0,
      'participants': <String>[],
    };

    final response = await _supabase
        .from('message_threads')
        .insert(threadData)
        .select()
        .single();

    return MessageThreadModel.fromJson(response);
  }

  /// Get threads for a room
  Future<List<MessageThreadModel>> getThreads({
    required String roomId,
    int? limit = 20,
  }) async {
    var query = _supabase
        .from('message_threads')
        .select()
        .eq('room_id', roomId)
        .eq('is_active', true)
        .order('created_at', ascending: false);

    if (limit != null) {
      query = query.limit(limit);
    }

    final response = await query;
    return response.map((json) => MessageThreadModel.fromJson(json)).toList();
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead({
    required String roomId,
    required String userId,
    required DateTime upToTimestamp,
  }) async {
    await _supabase
        .from('chat_messages')
        .update({'is_read': true})
        .eq('room_id', roomId)
        .neq('sender_id', userId)  // Don't mark own messages
        .lte('timestamp', upToTimestamp.toIso8601String());
  }

  /// Search messages in a room
  Future<List<ChatMessageModel>> searchMessages({
    required String roomId,
    required String query,
    int? limit = 20,
  }) async {
    final response = await _supabase
        .from('chat_messages')
        .select()
        .eq('room_id', roomId)
        .textSearch('content', query)
        .order('timestamp', ascending: false)
        .limit(limit ?? 20);

    return response.map((json) => ChatMessageModel.fromJson(json)).toList();
  }

  /// Subscribe to real-time messages for a room
  Stream<ChatMessageModel> subscribeToMessages({
    required String roomId,
  }) {
    return _supabase
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .map((events) {
          return events.map((data) => ChatMessageModel.fromJson(data));
        })
        .expand((messages) => messages);
  }
}