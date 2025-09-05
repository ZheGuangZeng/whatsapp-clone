import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/exceptions.dart';
import '../models/message_model.dart';
import '../models/participant_model.dart';
import '../models/room_model.dart';
import '../models/typing_indicator_model.dart';
import '../models/user_presence_model.dart';

/// Remote data source for chat functionality using Supabase
class ChatRemoteSource {
  ChatRemoteSource(this._supabase);

  final SupabaseClient _supabase;

  /// Get current user ID
  String? get _currentUserId => _supabase.auth.currentUser?.id;

  // ========================================
  // ROOM OPERATIONS
  // ========================================

  /// Get all rooms for current user
  Future<List<RoomModel>> getRooms() async {
    try {
      final response = await _supabase
          .from('rooms')
          .select('''
            id, name, description, type, created_by, avatar_url,
            last_message_at, created_at, updated_at
          ''')
          .in_('id', [
            await _supabase
                .from('room_participants')
                .select('room_id')
                .eq('user_id', _currentUserId!)
                .eq('is_active', true)
          ].expand((x) => x).toList())
          .order('last_message_at', ascending: false);

      return response.map<RoomModel>((data) => RoomModel.fromSupabase(data)).toList();
    } catch (e) {
      throw ServerException('Failed to get rooms: $e');
    }
  }

  /// Get a specific room by ID
  Future<RoomModel?> getRoom(String roomId) async {
    try {
      final response = await _supabase
          .from('rooms')
          .select('''
            id, name, description, type, created_by, avatar_url,
            last_message_at, created_at, updated_at
          ''')
          .eq('id', roomId)
          .maybeSingle();

      return response != null ? RoomModel.fromSupabase(response) : null;
    } catch (e) {
      throw ServerException('Failed to get room: $e');
    }
  }

  /// Create a new room
  Future<RoomModel> createRoom({
    String? name,
    String? description,
    required String type,
    List<String> participantIds = const [],
  }) async {
    try {
      final roomData = {
        'name': name,
        'description': description,
        'type': type,
        'created_by': _currentUserId!,
      };

      final roomResponse = await _supabase
          .from('rooms')
          .insert(roomData)
          .select()
          .single();

      final room = RoomModel.fromSupabase(roomResponse);

      // Add creator as admin participant
      await _supabase.from('room_participants').insert({
        'room_id': room.id,
        'user_id': _currentUserId!,
        'role': 'admin',
      });

      // Add other participants
      if (participantIds.isNotEmpty) {
        final participantsData = participantIds.map((userId) => {
              'room_id': room.id,
              'user_id': userId,
              'role': 'member',
            }).toList();

        await _supabase.from('room_participants').insert(participantsData);
      }

      return room;
    } catch (e) {
      throw ServerException('Failed to create room: $e');
    }
  }

  /// Update room information
  Future<RoomModel> updateRoom(
    String roomId, {
    String? name,
    String? description,
    String? avatarUrl,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;

      final response = await _supabase
          .from('rooms')
          .update(updateData)
          .eq('id', roomId)
          .select()
          .single();

      return RoomModel.fromSupabase(response);
    } catch (e) {
      throw ServerException('Failed to update room: $e');
    }
  }

  /// Delete a room
  Future<void> deleteRoom(String roomId) async {
    try {
      await _supabase.from('rooms').delete().eq('id', roomId);
    } catch (e) {
      throw ServerException('Failed to delete room: $e');
    }
  }

  /// Get or create direct message room
  Future<RoomModel> getOrCreateDirectMessage(String otherUserId) async {
    try {
      // Look for existing direct room between current user and other user
      final existingRooms = await _supabase
          .from('rooms')
          .select('id, name, description, type, created_by, avatar_url, last_message_at, created_at, updated_at')
          .eq('type', 'direct')
          .in_('id', [
            await _supabase.rpc('get_shared_rooms', params: {
              'user1': _currentUserId!,
              'user2': otherUserId,
            })
          ].expand((x) => x).toList());

      if (existingRooms.isNotEmpty) {
        return RoomModel.fromSupabase(existingRooms.first);
      }

      // Create new direct room
      return await createRoom(
        type: 'direct',
        participantIds: [otherUserId],
      );
    } catch (e) {
      throw ServerException('Failed to get or create direct message: $e');
    }
  }

  /// Stream of room updates
  Stream<List<RoomModel>> watchRooms() {
    return _supabase
        .from('rooms')
        .stream(primaryKey: ['id'])
        .asyncMap((data) async {
          // Filter rooms where current user is a participant
          final userRoomIds = await _supabase
              .from('room_participants')
              .select('room_id')
              .eq('user_id', _currentUserId!)
              .eq('is_active', true);

          final roomIds = userRoomIds.map<String>((e) => e['room_id'] as String).toList();
          
          return data
              .where((room) => roomIds.contains(room['id']))
              .map<RoomModel>((room) => RoomModel.fromSupabase(room))
              .toList();
        });
  }

  // ========================================
  // PARTICIPANT OPERATIONS
  // ========================================

  /// Add participants to a room
  Future<void> addParticipants(String roomId, List<String> userIds) async {
    try {
      final participantsData = userIds.map((userId) => {
            'room_id': roomId,
            'user_id': userId,
            'role': 'member',
          }).toList();

      await _supabase.from('room_participants').insert(participantsData);
    } catch (e) {
      throw ServerException('Failed to add participants: $e');
    }
  }

  /// Remove participant from a room
  Future<void> removeParticipant(String roomId, String userId) async {
    try {
      await _supabase
          .from('room_participants')
          .update({'is_active': false, 'left_at': DateTime.now().toIso8601String()})
          .eq('room_id', roomId)
          .eq('user_id', userId);
    } catch (e) {
      throw ServerException('Failed to remove participant: $e');
    }
  }

  /// Update participant role
  Future<void> updateParticipantRole(String roomId, String userId, String role) async {
    try {
      await _supabase
          .from('room_participants')
          .update({'role': role})
          .eq('room_id', roomId)
          .eq('user_id', userId);
    } catch (e) {
      throw ServerException('Failed to update participant role: $e');
    }
  }

  /// Get room participants
  Future<List<ParticipantModel>> getRoomParticipants(String roomId) async {
    try {
      final response = await _supabase
          .from('room_participants')
          .select('''
            id, room_id, user_id, role, joined_at, left_at, is_active,
            users!inner(display_name, email, avatar_url),
            user_presence(is_online, last_seen)
          ''')
          .eq('room_id', roomId)
          .eq('is_active', true);

      return response.map<ParticipantModel>((data) => 
        ParticipantModel.fromSupabaseWithUser(data)).toList();
    } catch (e) {
      throw ServerException('Failed to get room participants: $e');
    }
  }

  // ========================================
  // MESSAGE OPERATIONS
  // ========================================

  /// Send a new message
  Future<MessageModel> sendMessage({
    required String roomId,
    required String content,
    String type = 'text',
    String? replyTo,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      final messageData = {
        'room_id': roomId,
        'user_id': _currentUserId!,
        'content': content,
        'type': type,
        'reply_to': replyTo,
        'metadata': metadata,
      };

      final response = await _supabase
          .from('messages')
          .insert(messageData)
          .select()
          .single();

      return MessageModel.fromSupabase(response);
    } catch (e) {
      throw ServerException('Failed to send message: $e');
    }
  }

  /// Get messages for a room with pagination
  Future<List<MessageModel>> getMessages(
    String roomId, {
    int limit = 50,
    String? before,
  }) async {
    try {
      var query = _supabase
          .from('messages')
          .select('''
            id, room_id, user_id, content, type, reply_to, metadata,
            edited_at, deleted_at, created_at, updated_at,
            message_status!inner(status)
          ''')
          .eq('room_id', roomId)
          .is_('deleted_at', null)
          .order('created_at', ascending: false)
          .limit(limit);

      if (before != null) {
        final beforeMessage = await _supabase
            .from('messages')
            .select('created_at')
            .eq('id', before)
            .single();

        query = query.lt('created_at', beforeMessage['created_at']);
      }

      final response = await query;
      
      return response.map<MessageModel>((data) {
        final message = MessageModel.fromSupabase(data);
        
        // Get status for current user from message_status
        MessageStatus status = MessageStatus.sent;
        if (data['message_status'] != null && data['message_status'].isNotEmpty) {
          final statusData = data['message_status'] as List;
          final userStatus = statusData.firstWhere(
            (s) => s['user_id'] == _currentUserId,
            orElse: () => {'status': 'sent'},
          );
          status = MessageStatus.fromString(userStatus['status']);
        }
        
        return message.copyWith(status: status) as MessageModel;
      }).toList();
    } catch (e) {
      throw ServerException('Failed to get messages: $e');
    }
  }

  /// Edit a message
  Future<MessageModel> editMessage(String messageId, String newContent) async {
    try {
      final response = await _supabase
          .from('messages')
          .update({
            'content': newContent,
            'edited_at': DateTime.now().toIso8601String(),
          })
          .eq('id', messageId)
          .eq('user_id', _currentUserId!)
          .select()
          .single();

      return MessageModel.fromSupabase(response);
    } catch (e) {
      throw ServerException('Failed to edit message: $e');
    }
  }

  /// Delete a message (soft delete)
  Future<void> deleteMessage(String messageId) async {
    try {
      await _supabase
          .from('messages')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', messageId)
          .eq('user_id', _currentUserId!);
    } catch (e) {
      throw ServerException('Failed to delete message: $e');
    }
  }

  /// Mark message as read
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _supabase
          .from('message_status')
          .upsert({
            'message_id': messageId,
            'user_id': _currentUserId!,
            'status': 'read',
            'timestamp': DateTime.now().toIso8601String(),
          })
          .eq('message_id', messageId)
          .eq('user_id', _currentUserId!);
    } catch (e) {
      throw ServerException('Failed to mark message as read: $e');
    }
  }

  /// Mark all messages in a room as read
  Future<void> markRoomAsRead(String roomId) async {
    try {
      await _supabase.rpc('mark_room_messages_read', params: {
        'room_id_param': roomId,
        'user_id_param': _currentUserId!,
      });
    } catch (e) {
      throw ServerException('Failed to mark room as read: $e');
    }
  }

  /// Get unread count for a room
  Future<int> getUnreadCount(String roomId) async {
    try {
      final result = await _supabase.rpc('get_unread_count', params: {
        'room_id_param': roomId,
        'user_id_param': _currentUserId!,
      });

      return result as int;
    } catch (e) {
      throw ServerException('Failed to get unread count: $e');
    }
  }

  /// Stream of messages for a room
  Stream<List<MessageModel>> watchMessages(String roomId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .is_('deleted_at', null)
        .order('created_at', ascending: false)
        .limit(50)
        .map((data) => data
            .map<MessageModel>((message) => MessageModel.fromSupabase(message))
            .toList());
  }

  /// Stream of new messages for notifications
  Stream<MessageModel> watchNewMessages() {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .neq('user_id', _currentUserId!)
        .is_('deleted_at', null)
        .map((data) => data.isNotEmpty
            ? MessageModel.fromSupabase(data.last)
            : null)
        .where((message) => message != null)
        .cast<MessageModel>();
  }

  // ========================================
  // REACTIONS
  // ========================================

  /// Add reaction to a message
  Future<void> addReaction(String messageId, String emoji) async {
    try {
      await _supabase.from('message_reactions').insert({
        'message_id': messageId,
        'user_id': _currentUserId!,
        'emoji': emoji,
      });
    } catch (e) {
      throw ServerException('Failed to add reaction: $e');
    }
  }

  /// Remove reaction from a message
  Future<void> removeReaction(String messageId, String emoji) async {
    try {
      await _supabase
          .from('message_reactions')
          .delete()
          .eq('message_id', messageId)
          .eq('user_id', _currentUserId!)
          .eq('emoji', emoji);
    } catch (e) {
      throw ServerException('Failed to remove reaction: $e');
    }
  }

  // ========================================
  // TYPING INDICATORS
  // ========================================

  /// Start typing in a room
  Future<void> startTyping(String roomId) async {
    try {
      await _supabase.from('typing_indicators').upsert({
        'room_id': roomId,
        'user_id': _currentUserId!,
        'is_typing': true,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw ServerException('Failed to start typing: $e');
    }
  }

  /// Stop typing in a room
  Future<void> stopTyping(String roomId) async {
    try {
      await _supabase.from('typing_indicators').upsert({
        'room_id': roomId,
        'user_id': _currentUserId!,
        'is_typing': false,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw ServerException('Failed to stop typing: $e');
    }
  }

  /// Stream of typing indicators for a room
  Stream<List<TypingIndicatorModel>> watchTypingIndicators(String roomId) {
    return _supabase
        .from('typing_indicators')
        .stream(primaryKey: ['room_id', 'user_id'])
        .eq('room_id', roomId)
        .neq('user_id', _currentUserId!)
        .map((data) => data
            .where((indicator) => 
                indicator['is_typing'] == true &&
                DateTime.now().difference(DateTime.parse(indicator['updated_at'])).inSeconds < 10
            )
            .map<TypingIndicatorModel>((indicator) => TypingIndicatorModel.fromSupabase(indicator))
            .toList());
  }

  // ========================================
  // USER PRESENCE
  // ========================================

  /// Update user presence
  Future<void> updatePresence({
    required bool isOnline,
    String status = 'available',
  }) async {
    try {
      await _supabase.from('user_presence').upsert({
        'user_id': _currentUserId!,
        'is_online': isOnline,
        'status': status,
        'last_seen': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw ServerException('Failed to update presence: $e');
    }
  }

  /// Get user presence
  Future<UserPresenceModel?> getUserPresence(String userId) async {
    try {
      final response = await _supabase
          .from('user_presence')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      return response != null ? UserPresenceModel.fromSupabase(response) : null;
    } catch (e) {
      throw ServerException('Failed to get user presence: $e');
    }
  }

  /// Get presence for multiple users
  Future<List<UserPresenceModel>> getUsersPresence(List<String> userIds) async {
    try {
      final response = await _supabase
          .from('user_presence')
          .select()
          .in_('user_id', userIds);

      return response.map<UserPresenceModel>((data) => UserPresenceModel.fromSupabase(data)).toList();
    } catch (e) {
      throw ServerException('Failed to get users presence: $e');
    }
  }

  /// Stream of user presence updates
  Stream<UserPresenceModel> watchUserPresence(String userId) {
    return _supabase
        .from('user_presence')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', userId)
        .map((data) => data.isNotEmpty
            ? UserPresenceModel.fromSupabase(data.first)
            : null)
        .where((presence) => presence != null)
        .cast<UserPresenceModel>();
  }

  // ========================================
  // SEARCH OPERATIONS
  // ========================================

  /// Search messages in a room
  Future<List<MessageModel>> searchMessages(String roomId, String query) async {
    try {
      final response = await _supabase
          .from('messages')
          .select()
          .eq('room_id', roomId)
          .ilike('content', '%$query%')
          .is_('deleted_at', null)
          .order('created_at', ascending: false);

      return response.map<MessageModel>((data) => MessageModel.fromSupabase(data)).toList();
    } catch (e) {
      throw ServerException('Failed to search messages: $e');
    }
  }
}