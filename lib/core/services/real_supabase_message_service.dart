import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../features/messaging/domain/entities/message.dart';
import '../../features/messaging/domain/repositories/i_message_repository.dart';
import '../errors/failures.dart';
import '../utils/result.dart';

/// Real Supabase implementation of IMessageRepository
/// Provides actual messaging services using Supabase backend
class RealSupabaseMessageService implements IMessageRepository {
  static const String _logTag = 'RealSupabaseMessageService';
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(milliseconds: 500);
  static const String _messagesTable = 'messages';
  
  final SupabaseClient _client;
  final Uuid _uuid;

  RealSupabaseMessageService({SupabaseClient? client, Uuid? uuid})
      : _client = client ?? Supabase.instance.client,
        _uuid = uuid ?? const Uuid();

  @override
  Future<Result<Message>> sendMessage(Message message) async {
    developer.log('Sending message to room: ${message.roomId}', name: _logTag);
    
    return await _retryOperation(() async {
      // Generate ID and timestamp for the message
      final messageId = message.id.isEmpty ? _uuid.v4() : message.id;
      final timestamp = DateTime.now();
      
      final messageData = {
        'id': messageId,
        'room_id': message.roomId,
        'sender_id': message.senderId,
        'content': message.content,
        'message_type': message.messageType.name,
        'timestamp': timestamp.toIso8601String(),
        'is_read': message.isRead,
      };

      final response = await _client
          .from(_messagesTable)
          .insert(messageData)
          .select()
          .single();

      final sentMessage = _mapRowToMessage(response);
      
      developer.log('Successfully sent message: $messageId', name: _logTag);
      return sentMessage;
    });
  }

  @override
  Future<Result<List<Message>>> getMessages(
    String roomId, {
    int limit = 50,
    String? beforeId,
  }) async {
    developer.log('Getting messages for room: $roomId, limit: $limit', name: _logTag);
    
    return await _retryOperation(() async {
      var query = _client
          .from(_messagesTable)
          .select()
          .eq('room_id', roomId)
            .order('timestamp', ascending: false)
          .limit(limit);

      // Note: Simplified pagination - full implementation would require
      // more complex timestamp-based filtering
      if (beforeId != null) {
        // For now, just limit the query - full implementation would need
        // to filter by timestamp based on beforeId
        developer.log('Pagination with beforeId not fully implemented', name: _logTag);
      }

      final response = await query;
      final messages = (response as List<dynamic>)
          .map((row) => _mapRowToMessage(row as Map<String, dynamic>))
          .toList();

      // Reverse to get chronological order
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      developer.log('Successfully retrieved ${messages.length} messages for room: $roomId', name: _logTag);
      return messages;
    });
  }

  @override
  Future<Result<void>> markAsRead(String roomId, List<String> messageIds) async {
    developer.log('Marking ${messageIds.length} messages as read in room: $roomId', name: _logTag);
    
    return await _retryOperation(() async {
      // Update messages to mark them as read
      await _client
          .from(_messagesTable)
          .update({'is_read': true})
          .inFilter('id', messageIds)
          .eq('room_id', roomId);

      developer.log('Successfully marked ${messageIds.length} messages as read', name: _logTag);
      return;
    });
  }

  @override
  Future<Result<void>> deleteMessage(String messageId) async {
    developer.log('Deleting message: $messageId', name: _logTag);
    
    return await _retryOperation(() async {
      // Soft delete - mark as deleted instead of removing
      await _client
          .from(_messagesTable)
          .update({
            'content': '[Message deleted]',
          })
          .eq('id', messageId);

      developer.log('Successfully deleted message: $messageId', name: _logTag);
      return;
    });
  }

  /// Stream of real-time messages for a room
  Stream<Message> getMessageStream(String roomId) {
    developer.log('Starting message stream for room: $roomId', name: _logTag);
    
    return _client
        .from(_messagesTable)
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('timestamp')
        .map((List<Map<String, dynamic>> data) => data.map((Map<String, dynamic> row) => _mapRowToMessage(row)).toList())
        .expand((List<Message> messages) => messages);
  }

  /// Edit an existing message
  Future<Result<Message>> editMessage(
    String messageId,
    String newContent,
  ) async {
    developer.log('Editing message: $messageId', name: _logTag);
    
    return await _retryOperation(() async {
      final response = await _client
          .from(_messagesTable)
          .update({
            'content': newContent,
          })
          .eq('id', messageId)
          .select()
          .single();

      final editedMessage = _mapRowToMessage(response);
      
      developer.log('Successfully edited message: $messageId', name: _logTag);
      return editedMessage;
    });
  }

  /// Get message by ID
  Future<Result<Message?>> getMessage(String messageId) async {
    developer.log('Getting message: $messageId', name: _logTag);
    
    return await _retryOperation(() async {
      final response = await _client
          .from(_messagesTable)
          .select()
          .eq('id', messageId)
          .maybeSingle();

      if (response == null) {
        developer.log('Message not found: $messageId', name: _logTag);
        return null;
      }

      final message = _mapRowToMessage(response);
      developer.log('Successfully retrieved message: $messageId', name: _logTag);
      return message;
    });
  }

  /// React to a message
  Future<Result<void>> addReaction(
    String messageId,
    String emoji,
    String userId,
  ) async {
    developer.log('Adding reaction $emoji to message: $messageId', name: _logTag);
    
    return await _retryOperation(() async {
      // Insert or update reaction
      await _client
          .from('message_reactions')
          .upsert({
            'message_id': messageId,
            'user_id': userId,
            'emoji': emoji,
            'created_at': DateTime.now().toIso8601String(),
          });

      developer.log('Successfully added reaction $emoji to message: $messageId', name: _logTag);
      return;
    });
  }

  /// Remove reaction from a message
  Future<Result<void>> removeReaction(
    String messageId,
    String emoji,
    String userId,
  ) async {
    developer.log('Removing reaction $emoji from message: $messageId', name: _logTag);
    
    return await _retryOperation(() async {
      await _client
          .from('message_reactions')
          .delete()
          .eq('message_id', messageId)
          .eq('user_id', userId)
          .eq('emoji', emoji);

      developer.log('Successfully removed reaction $emoji from message: $messageId', name: _logTag);
      return;
    });
  }

  /// Helper method to map database row to Message entity
  Message _mapRowToMessage(Map<String, dynamic> row) {
    return Message(
      id: row['id'] as String,
      roomId: row['room_id'] as String,
      senderId: row['sender_id'] as String,
      content: row['content'] as String,
      messageType: _parseMessageType(row['message_type'] as String?),
      timestamp: DateTime.parse(row['timestamp'] as String),
      isRead: row['is_read'] as bool? ?? false,
    );
  }

  /// Helper method to parse message type from string
  MessageType _parseMessageType(String? type) {
    switch (type) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'file':
        return MessageType.file;
      default:
        return MessageType.text;
    }
  }

  /// Retry mechanism for operations
  Future<Result<T>> _retryOperation<T>(Future<T> Function() operation) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final result = await operation();
        return Success(result);
      } catch (error) {
        developer.log(
          'Operation attempt $attempt failed: $error', 
          name: _logTag, 
          level: attempt == _maxRetries ? 1000 : 500,
        );

        if (attempt == _maxRetries) {
          // Determine appropriate failure type
          if (error is PostgrestException) {
            if (error.code == 'PGRST301') {
              return ResultFailure(UnauthorizedFailure(message: 'Unauthorized: ${error.message}'));
            } else if (error.code?.startsWith('PGRST1') == true) {
              return ResultFailure(ValidationFailure(message: 'Validation error: ${error.message}'));
            } else {
              return ResultFailure(DatabaseFailure(error.message));
            }
          } else if (error.toString().contains('network') || 
                     error.toString().contains('connection')) {
            return ResultFailure(NetworkFailure(message: 'Network error: $error'));
          } else {
            return ResultFailure(UnknownFailure(message: 'Unexpected error: $error'));
          }
        }

        // Wait before retrying
        if (attempt < _maxRetries) {
          await Future<void>.delayed(_retryDelay * attempt);
        }
      }
    }

    return ResultFailure(UnknownFailure(message: 'Operation failed after $_maxRetries attempts'));
  }

  /// Dispose resources
  void dispose() {
    developer.log('RealSupabaseMessageService disposed', name: _logTag);
  }
}