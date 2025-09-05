import 'dart:convert';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/exceptions.dart';
import '../models/meeting_model.dart';
import '../models/meeting_participant_model.dart';
import '../models/meeting_recording_model.dart';

/// Remote data source for meeting operations using Supabase
class MeetingRemoteSource {
  const MeetingRemoteSource({
    required this.supabaseClient,
  });

  final SupabaseClient supabaseClient;

  // Meeting operations

  /// Create a new meeting
  Future<MeetingModel> createMeeting(Map<String, dynamic> meetingData) async {
    try {
      final response = await supabaseClient
          .from('meetings')
          .insert(meetingData)
          .select()
          .single();

      return MeetingModel.fromSupabase(response);
    } on PostgrestException catch (error) {
      throw ServerException('Failed to create meeting: ${error.message}');
    } catch (error) {
      throw ServerException('Failed to create meeting: $error');
    }
  }

  /// Get meeting by ID
  Future<MeetingModel> getMeeting(String meetingId) async {
    try {
      final response = await supabaseClient
          .from('meetings')
          .select('''
            *,
            participants:meeting_participants(
              *,
              display_name:auth.users!meeting_participants_user_id_fkey(display_name),
              avatar_url:auth.users!meeting_participants_user_id_fkey(avatar_url)
            ),
            recordings:meeting_recordings(*)
          ''')
          .eq('id', meetingId)
          .single();

      return MeetingModel.fromSupabase(response);
    } on PostgrestException catch (error) {
      if (error.code == 'PGRST116') {
        throw CacheException('Meeting not found');
      }
      throw ServerException('Failed to get meeting: ${error.message}');
    } catch (error) {
      throw ServerException('Failed to get meeting: $error');
    }
  }

  /// Get meeting by LiveKit room name
  Future<MeetingModel> getMeetingByLivekitRoom(String livekitRoomName) async {
    try {
      final response = await supabaseClient
          .from('meetings')
          .select('''
            *,
            participants:meeting_participants(
              *,
              display_name:auth.users!meeting_participants_user_id_fkey(display_name),
              avatar_url:auth.users!meeting_participants_user_id_fkey(avatar_url)
            ),
            recordings:meeting_recordings(*)
          ''')
          .eq('livekit_room_name', livekitRoomName)
          .single();

      return MeetingModel.fromSupabase(response);
    } on PostgrestException catch (error) {
      if (error.code == 'PGRST116') {
        throw CacheException('Meeting not found');
      }
      throw ServerException('Failed to get meeting by LiveKit room: ${error.message}');
    } catch (error) {
      throw ServerException('Failed to get meeting by LiveKit room: $error');
    }
  }

  /// Update meeting
  Future<MeetingModel> updateMeeting(String meetingId, Map<String, dynamic> updateData) async {
    try {
      final response = await supabaseClient
          .from('meetings')
          .update(updateData)
          .eq('id', meetingId)
          .select()
          .single();

      return MeetingModel.fromSupabase(response);
    } on PostgrestException catch (error) {
      throw ServerException('Failed to update meeting: ${error.message}');
    } catch (error) {
      throw ServerException('Failed to update meeting: $error');
    }
  }

  /// Delete meeting
  Future<void> deleteMeeting(String meetingId) async {
    try {
      await supabaseClient
          .from('meetings')
          .delete()
          .eq('id', meetingId);
    } on PostgrestException catch (error) {
      throw ServerException('Failed to delete meeting: ${error.message}');
    } catch (error) {
      throw ServerException('Failed to delete meeting: $error');
    }
  }

  /// Get meetings for a user
  Future<List<MeetingModel>> getUserMeetings(
    String userId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await supabaseClient
          .from('meetings')
          .select('''
            *,
            participants:meeting_participants(
              *,
              display_name:auth.users!meeting_participants_user_id_fkey(display_name),
              avatar_url:auth.users!meeting_participants_user_id_fkey(avatar_url)
            ),
            recordings:meeting_recordings(*)
          ''')
          .or('host_id.eq.$userId,id.in.(${_getParticipantMeetingsSubquery(userId)})')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map((json) => MeetingModel.fromSupabase(json)).toList();
    } on PostgrestException catch (error) {
      throw ServerException('Failed to get user meetings: ${error.message}');
    } catch (error) {
      throw ServerException('Failed to get user meetings: $error');
    }
  }

  /// Get meetings for a chat room
  Future<List<MeetingModel>> getRoomMeetings(
    String roomId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await supabaseClient
          .from('meetings')
          .select('''
            *,
            participants:meeting_participants(*),
            recordings:meeting_recordings(*)
          ''')
          .eq('room_id', roomId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map((json) => MeetingModel.fromSupabase(json)).toList();
    } on PostgrestException catch (error) {
      throw ServerException('Failed to get room meetings: ${error.message}');
    } catch (error) {
      throw ServerException('Failed to get room meetings: $error');
    }
  }

  /// Get active meetings for a user
  Future<List<MeetingModel>> getActiveMeetings(String userId) async {
    try {
      final response = await supabaseClient
          .from('meetings')
          .select('''
            *,
            participants:meeting_participants(
              *,
              display_name:auth.users!meeting_participants_user_id_fkey(display_name),
              avatar_url:auth.users!meeting_participants_user_id_fkey(avatar_url)
            )
          ''')
          .or('host_id.eq.$userId,id.in.(${_getParticipantMeetingsSubquery(userId)})')
          .not('started_at', 'is', null)
          .is_('ended_at', null)
          .order('started_at', ascending: false);

      return response.map((json) => MeetingModel.fromSupabase(json)).toList();
    } on PostgrestException catch (error) {
      throw ServerException('Failed to get active meetings: ${error.message}');
    } catch (error) {
      throw ServerException('Failed to get active meetings: $error');
    }
  }

  // Participant operations

  /// Add participant to meeting
  Future<MeetingParticipantModel> addParticipant(Map<String, dynamic> participantData) async {
    try {
      final response = await supabaseClient
          .from('meeting_participants')
          .insert(participantData)
          .select('''
            *,
            display_name:auth.users!meeting_participants_user_id_fkey(display_name),
            avatar_url:auth.users!meeting_participants_user_id_fkey(avatar_url)
          ''')
          .single();

      return MeetingParticipantModel.fromSupabase(response);
    } on PostgrestException catch (error) {
      throw ServerException('Failed to add participant: ${error.message}');
    } catch (error) {
      throw ServerException('Failed to add participant: $error');
    }
  }

  /// Remove participant from meeting
  Future<void> removeParticipant(String meetingId, String userId) async {
    try {
      await supabaseClient
          .from('meeting_participants')
          .update({'left_at': DateTime.now().toIso8601String()})
          .eq('meeting_id', meetingId)
          .eq('user_id', userId);
    } on PostgrestException catch (error) {
      throw ServerException('Failed to remove participant: ${error.message}');
    } catch (error) {
      throw ServerException('Failed to remove participant: $error');
    }
  }

  /// Update participant
  Future<MeetingParticipantModel> updateParticipant(
    String meetingId,
    String userId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final response = await supabaseClient
          .from('meeting_participants')
          .update(updateData)
          .eq('meeting_id', meetingId)
          .eq('user_id', userId)
          .select('''
            *,
            display_name:auth.users!meeting_participants_user_id_fkey(display_name),
            avatar_url:auth.users!meeting_participants_user_id_fkey(avatar_url)
          ''')
          .single();

      return MeetingParticipantModel.fromSupabase(response);
    } on PostgrestException catch (error) {
      throw ServerException('Failed to update participant: ${error.message}');
    } catch (error) {
      throw ServerException('Failed to update participant: $error');
    }
  }

  /// Get meeting participants
  Future<List<MeetingParticipantModel>> getMeetingParticipants(String meetingId) async {
    try {
      final response = await supabaseClient
          .from('meeting_participants')
          .select('''
            *,
            display_name:auth.users!meeting_participants_user_id_fkey(display_name),
            avatar_url:auth.users!meeting_participants_user_id_fkey(avatar_url)
          ''')
          .eq('meeting_id', meetingId)
          .order('joined_at');

      return response.map((json) => MeetingParticipantModel.fromSupabase(json)).toList();
    } on PostgrestException catch (error) {
      throw ServerException('Failed to get meeting participants: ${error.message}');
    } catch (error) {
      throw ServerException('Failed to get meeting participants: $error');
    }
  }

  // Recording operations

  /// Create recording
  Future<MeetingRecordingModel> createRecording(Map<String, dynamic> recordingData) async {
    try {
      final response = await supabaseClient
          .from('meeting_recordings')
          .insert(recordingData)
          .select()
          .single();

      return MeetingRecordingModel.fromSupabase(response);
    } on PostgrestException catch (error) {
      throw ServerException('Failed to create recording: ${error.message}');
    } catch (error) {
      throw ServerException('Failed to create recording: $error');
    }
  }

  /// Update recording
  Future<MeetingRecordingModel> updateRecording(
    String recordingId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final response = await supabaseClient
          .from('meeting_recordings')
          .update(updateData)
          .eq('id', recordingId)
          .select()
          .single();

      return MeetingRecordingModel.fromSupabase(response);
    } on PostgrestException catch (error) {
      throw ServerException('Failed to update recording: ${error.message}');
    } catch (error) {
      throw ServerException('Failed to update recording: $error');
    }
  }

  /// Get meeting recordings
  Future<List<MeetingRecordingModel>> getMeetingRecordings(String meetingId) async {
    try {
      final response = await supabaseClient
          .from('meeting_recordings')
          .select()
          .eq('meeting_id', meetingId)
          .order('started_at', ascending: false);

      return response.map((json) => MeetingRecordingModel.fromSupabase(json)).toList();
    } on PostgrestException catch (error) {
      throw ServerException('Failed to get meeting recordings: ${error.message}');
    } catch (error) {
      throw ServerException('Failed to get meeting recordings: $error');
    }
  }

  // Real-time subscriptions

  /// Subscribe to meeting changes
  RealtimeChannel subscribeMeetingChanges(String meetingId, void Function(Map<String, dynamic>) onUpdate) {
    return supabaseClient
        .channel('meeting_$meetingId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'meetings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: meetingId,
          ),
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .subscribe();
  }

  /// Subscribe to participant changes
  RealtimeChannel subscribeParticipantChanges(String meetingId, void Function(List<Map<String, dynamic>>) onUpdate) {
    return supabaseClient
        .channel('participants_$meetingId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'meeting_participants',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'meeting_id',
            value: meetingId,
          ),
          callback: (payload) async {
            // Fetch updated participant list
            try {
              final participants = await getMeetingParticipants(meetingId);
              onUpdate(participants.map((p) => p.toJson()).toList());
            } catch (error) {
              // Handle error silently or log it
            }
          },
        )
        .subscribe();
  }

  // LiveKit token generation

  /// Generate LiveKit JWT token
  Future<String> generateLivekitToken({
    required String meetingId,
    required String userId,
    required String participantRole,
    Duration? ttl,
  }) async {
    try {
      // Call Supabase Edge Function for JWT generation
      final response = await supabaseClient.functions.invoke(
        'generate-livekit-token',
        body: {
          'meeting_id': meetingId,
          'user_id': userId,
          'role': participantRole,
          'ttl_seconds': (ttl ?? const Duration(hours: 2)).inSeconds,
        },
      );

      if (response.status != 200) {
        throw ServerException('Failed to generate LiveKit token: ${response.status}');
      }

      final data = response.data as Map<String, dynamic>;
      return data['token'] as String;
    } catch (error) {
      throw ServerException('Failed to generate LiveKit token: $error');
    }
  }

  /// Validate room access
  Future<bool> validateRoomAccess(String livekitRoomName, String userId) async {
    try {
      final response = await supabaseClient
          .from('meetings')
          .select('id')
          .eq('livekit_room_name', livekitRoomName)
          .or('host_id.eq.$userId,id.in.(${_getParticipantMeetingsSubquery(userId)})')
          .maybeSingle();

      return response != null;
    } on PostgrestException catch (error) {
      throw ServerException('Failed to validate room access: ${error.message}');
    } catch (error) {
      throw ServerException('Failed to validate room access: $error');
    }
  }

  /// Helper function to get subquery for participant meetings
  String _getParticipantMeetingsSubquery(String userId) {
    return 'select meeting_id from meeting_participants where user_id = $userId';
  }
}