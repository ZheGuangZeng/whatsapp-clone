import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/participant_model.dart';
import '../models/room_model.dart';

/// Remote data source for room operations using Supabase
class RoomRemoteDataSource {
  const RoomRemoteDataSource(this._supabase);

  final SupabaseClient _supabase;

  /// Create a new room
  Future<RoomModel> createRoom({
    required String name,
    required String creatorId,
    String type = 'group',
    String? description,
    String? avatarUrl,
    List<String>? initialParticipants,
  }) async {
    final roomData = {
      'name': name,
      'creator_id': creatorId,
      'type': type,
      'description': description,
      'avatar_url': avatarUrl,
      'created_at': DateTime.now().toIso8601String(),
      'is_active': true,
    };

    final response = await _supabase
        .from('chat_rooms')
        .insert(roomData)
        .select()
        .single();

    final room = RoomModel.fromJson(response);

    // Add creator as admin participant
    await addParticipant(
      roomId: room.id,
      userId: creatorId,
      role: 'admin',
    );

    // Add initial participants if provided
    if (initialParticipants != null) {
      for (final userId in initialParticipants) {
        if (userId != creatorId) {
          await addParticipant(
            roomId: room.id,
            userId: userId,
            role: 'member',
          );
        }
      }
    }

    return room;
  }

  /// Get user's rooms
  Future<List<RoomModel>> getUserRooms(String userId) async {
    final response = await _supabase
        .from('chat_rooms')
        .select()
        .eq('is_active', true)
        .order('updated_at', ascending: false);

    return response.map((json) => RoomModel.fromJson(json)).toList();
  }

  /// Get room by ID
  Future<RoomModel> getRoomById(String roomId) async {
    final response = await _supabase
        .from('chat_rooms')
        .select()
        .eq('id', roomId)
        .single();

    return RoomModel.fromJson(response);
  }

  /// Add participant to room
  Future<ParticipantModel> addParticipant({
    required String roomId,
    required String userId,
    required String role,
  }) async {
    final participantData = {
      'room_id': roomId,
      'user_id': userId,
      'role': role,
      'joined_at': DateTime.now().toIso8601String(),
      'is_active': true,
    };

    final response = await _supabase
        .from('room_participants')
        .insert(participantData)
        .select()
        .single();

    return ParticipantModel.fromJson(response);
  }

  /// Get room participants
  Future<List<ParticipantModel>> getRoomParticipants(String roomId) async {
    final response = await _supabase
        .from('room_participants')
        .select()
        .eq('room_id', roomId)
        .eq('is_active', true);

    return response.map((json) => ParticipantModel.fromJson(json)).toList();
  }

  /// Update room
  Future<RoomModel> updateRoom({
    required String roomId,
    String? name,
    String? description,
    String? avatarUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    updates['updated_at'] = DateTime.now().toIso8601String();

    final response = await _supabase
        .from('chat_rooms')
        .update(updates)
        .eq('id', roomId)
        .select()
        .single();

    return RoomModel.fromJson(response);
  }

  /// Delete room (mark as inactive)
  Future<void> deleteRoom(String roomId) async {
    await _supabase
        .from('chat_rooms')
        .update({
          'is_active': false,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', roomId);
  }
}