import 'dart:async';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/message.dart';
import '../models/message_model.dart';
import '../models/room_model.dart';

/// Remote datasource for message-related operations using Supabase
class MessageRemoteDataSource {
  const MessageRemoteDataSource(this._supabase);
  
  final SupabaseClient _supabase;

  /// Send a message to the database
  Future<MessageModel> sendMessage(MessageModel message) async {
    try {
      final response = await _supabase
          .from('messages')
          .insert(message.toJson())
          .select()
          .single();
      
      return MessageModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to send message: ${e.message}');
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Get messages for a room with pagination
  Future<List<MessageModel>> getMessages(
    String roomId, {
    int limit = 50,
    String? beforeId,
  }) async {
    try {
      var query = _supabase
          .from('messages')
          .select('*')
          .eq('room_id', roomId)
          .order('created_at', ascending: false)
          .limit(limit);

      if (beforeId != null) {
        // Get the timestamp of the beforeId message for cursor-based pagination
        final beforeMessage = await _supabase
            .from('messages')
            .select('created_at')
            .eq('id', beforeId)
            .single();
        
        query = query.lte('created_at', beforeMessage['created_at']);
      }

      final response = await query;
      return response
          .map<MessageModel>((json) => MessageModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get messages: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get messages: $e');
    }
  }

  /// Update message status for a user
  Future<void> updateMessageStatus(
    String messageId,
    MessageStatus status,
  ) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('message_status')
          .upsert({
            'message_id': messageId,
            'user_id': userId,
            'status': status.name,
            'timestamp': DateTime.now().toIso8601String(),
          });
    } on PostgrestException catch (e) {
      throw Exception('Failed to update message status: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update message status: $e');
    }
  }

  /// Mark multiple messages as read
  Future<void> markMessagesAsRead(String roomId, List<String> messageIds) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final updates = messageIds.map((messageId) => {
        'message_id': messageId,
        'user_id': userId,
        'status': MessageStatus.read.name,
        'timestamp': DateTime.now().toIso8601String(),
      }).toList();

      await _supabase.from('message_status').upsert(updates);
    } on PostgrestException catch (e) {
      throw Exception('Failed to mark messages as read: ${e.message}');
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  /// Edit a message
  Future<MessageModel> editMessage(String messageId, String newContent) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('messages')
          .update({
            'content': newContent,
            'edited_at': DateTime.now().toIso8601String(),
          })
          .eq('id', messageId)
          .eq('user_id', userId) // Only allow editing own messages
          .select()
          .single();

      return MessageModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to edit message: ${e.message}');
    } catch (e) {
      throw Exception('Failed to edit message: $e');
    }
  }

  /// Delete a message (soft delete)
  Future<void> deleteMessage(String messageId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('messages')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', messageId)
          .eq('user_id', userId); // Only allow deleting own messages
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete message: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  /// Get message status for a message
  Future<List<MessageStatusModel>> getMessageStatus(String messageId) async {
    try {
      final response = await _supabase
          .from('message_status')
          .select('*')
          .eq('message_id', messageId);

      return response
          .map<MessageStatusModel>((json) => MessageStatusModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get message status: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get message status: $e');
    }
  }

  /// Stream real-time messages for a room
  Stream<List<MessageModel>> messagesStream(String roomId) {
    try {
      return _supabase
          .from('messages')
          .stream(primaryKey: ['id'])
          .eq('room_id', roomId)
          .order('created_at', ascending: false)
          .map((data) => data
              .map<MessageModel>((json) => MessageModel.fromJson(json))
              .toList());
    } catch (e) {
      throw Exception('Failed to create messages stream: $e');
    }
  }

  /// Stream real-time message status updates
  Stream<List<MessageStatusModel>> messageStatusStream(String messageId) {
    try {
      return _supabase
          .from('message_status')
          .stream(primaryKey: ['id'])
          .eq('message_id', messageId)
          .map((data) => data
              .map<MessageStatusModel>((json) => MessageStatusModel.fromJson(json))
              .toList());
    } catch (e) {
      throw Exception('Failed to create message status stream: $e');
    }
  }

  /// Update typing status
  Future<void> setTyping(String roomId, bool isTyping) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('typing_indicators')
          .upsert({
            'room_id': roomId,
            'user_id': userId,
            'is_typing': isTyping,
            'updated_at': DateTime.now().toIso8601String(),
          });
    } on PostgrestException catch (e) {
      throw Exception('Failed to update typing status: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update typing status: $e');
    }
  }

  /// Stream typing indicators for a room
  Stream<List<TypingIndicatorModel>> typingIndicatorsStream(String roomId) {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      return _supabase
          .from('typing_indicators')
          .stream(primaryKey: ['room_id', 'user_id'])
          .eq('room_id', roomId)
          .not('user_id', 'eq', userId) // Don't include current user's typing
          .eq('is_typing', true)
          .map((List<Map<String, dynamic>> data) => data
              .map<TypingIndicatorModel>((Map<String, dynamic> json) => TypingIndicatorModel.fromJson(json))
              .toList());
    } catch (e) {
      throw Exception('Failed to create typing indicators stream: $e');
    }
  }

  /// Update user presence
  Future<void> updatePresence(bool isOnline, PresenceStatus status) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('user_presence')
          .upsert({
            'user_id': userId,
            'is_online': isOnline,
            'last_seen': DateTime.now().toIso8601String(),
            'status': status.name,
            'updated_at': DateTime.now().toIso8601String(),
          });
    } on PostgrestException catch (e) {
      throw Exception('Failed to update presence: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update presence: $e');
    }
  }

  /// Stream user presence updates
  Stream<List<UserPresenceModel>> presenceStream() {
    try {
      return _supabase
          .from('user_presence')
          .stream(primaryKey: ['user_id'])
          .map((data) => data
              .map<UserPresenceModel>((json) => UserPresenceModel.fromJson(json))
              .toList());
    } catch (e) {
      throw Exception('Failed to create presence stream: $e');
    }
  }

  /// Get user rooms
  Future<List<RoomModel>> getUserRooms() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get room IDs where user is a participant first
      final participantRooms = await _supabase
          .from('room_participants')
          .select('room_id')
          .eq('user_id', userId)
          .eq('is_active', true);
          
      final roomIds = participantRooms.map((p) => p['room_id']).toList();
      if (roomIds.isEmpty) return [];

      final response = await _supabase
          .from('rooms')
          .select('*')
          .inFilter('id', roomIds)
          .order('last_message_at', ascending: false);

      return response
          .map<RoomModel>((Map<String, dynamic> json) => RoomModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get user rooms: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get user rooms: $e');
    }
  }

  /// Get or create direct message room
  Future<RoomModel> getOrCreateDirectRoom(String otherUserId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Try to find existing direct room between these users
      final existingRooms = await _supabase
          .from('rooms')
          .select('*, room_participants!inner(*)')
          .eq('type', 'direct');

      // Find room that has exactly these two participants
      for (final roomData in existingRooms) {
        final participants = await _supabase
            .from('room_participants')
            .select('user_id')
            .eq('room_id', roomData['id'])
            .eq('is_active', true);
        
        final userIds = participants.map((p) => p['user_id']).toSet();
        if (userIds.length == 2 && 
            userIds.contains(currentUserId) && 
            userIds.contains(otherUserId)) {
          return RoomModel.fromJson(roomData);
        }
      }

      // Create new direct room if none exists
      final newRoom = await _supabase
          .from('rooms')
          .insert({
            'type': 'direct',
            'created_by': currentUserId,
          })
          .select()
          .single();

      // Add both users as participants
      await _supabase.from('room_participants').insert([
        {
          'room_id': newRoom['id'],
          'user_id': currentUserId,
          'role': 'member',
        },
        {
          'room_id': newRoom['id'],
          'user_id': otherUserId,
          'role': 'member',
        },
      ]);

      return RoomModel.fromJson(newRoom);
    } on PostgrestException catch (e) {
      throw Exception('Failed to get/create direct room: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get/create direct room: $e');
    }
  }

  /// Create group room
  Future<RoomModel> createGroupRoom(
    String name,
    List<String> participantIds,
  ) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Create the room
      final newRoom = await _supabase
          .from('rooms')
          .insert({
            'name': name,
            'type': 'group',
            'created_by': currentUserId,
          })
          .select()
          .single();

      // Add creator as admin
      final participants = [
        {
          'room_id': newRoom['id'],
          'user_id': currentUserId,
          'role': 'admin',
        }
      ];

      // Add other participants as members
      participants.addAll(participantIds.map((userId) => {
        'room_id': newRoom['id'],
        'user_id': userId,
        'role': 'member',
      }));

      await _supabase.from('room_participants').insert(participants);

      return RoomModel.fromJson(newRoom);
    } on PostgrestException catch (e) {
      throw Exception('Failed to create group room: ${e.message}');
    } catch (e) {
      throw Exception('Failed to create group room: $e');
    }
  }

  /// Get room participants
  Future<List<RoomParticipantModel>> getRoomParticipants(String roomId) async {
    try {
      final response = await _supabase
          .from('room_participants')
          .select('*')
          .eq('room_id', roomId)
          .eq('is_active', true);

      return response
          .map<RoomParticipantModel>((json) => RoomParticipantModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get room participants: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get room participants: $e');
    }
  }
}