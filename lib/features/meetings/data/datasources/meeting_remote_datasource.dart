import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../domain/repositories/i_meeting_repository.dart';
import '../models/meeting_model.dart';
import '../models/meeting_participant_model.dart';

/// Remote data source for meeting operations using Supabase
class MeetingRemoteDataSource {
  const MeetingRemoteDataSource(this._supabase);

  final SupabaseClient _supabase;
  final _uuid = const Uuid();

  /// Creates a new meeting in Supabase
  Future<MeetingModel> createMeeting(CreateMeetingParams params) async {
    final meetingId = _uuid.v4();
    final roomId = _uuid.v4();
    
    final meetingData = {
      'id': meetingId,
      'title': params.title,
      'description': params.description,
      'host_id': params.hostId,
      'room_id': roomId,
      'created_at': DateTime.now().toIso8601String(),
      'scheduled_start_time': params.scheduledStartTime?.toIso8601String(),
      'actual_start_time': null,
      'actual_end_time': null,
      'state': 'scheduled',
      'is_public': params.settings.isPublic,
      'max_participants': params.settings.maxParticipants,
      'is_recording_enabled': params.settings.isRecordingEnabled,
      'is_waiting_room_enabled': params.settings.isWaitingRoomEnabled,
      'allow_screen_share': params.settings.allowScreenShare,
      'allow_chat': params.settings.allowChat,
      'require_approval': params.settings.requireApproval,
      'password': params.settings.password,
    };

    final response = await _supabase
        .from('meetings')
        .insert(meetingData)
        .select()
        .single();

    return MeetingModel.fromSupabaseRow(response, []);
  }

  /// Gets a meeting by ID from Supabase
  Future<MeetingModel> getMeeting(String meetingId) async {
    final meetingResponse = await _supabase
        .from('meetings')
        .select()
        .eq('id', meetingId)
        .single();

    final participantsResponse = await _supabase
        .from('meeting_participants')
        .select()
        .eq('meeting_id', meetingId)
        .order('joined_at');

    return MeetingModel.fromSupabaseRow(
      meetingResponse,
      List<Map<String, dynamic>>.from(participantsResponse),
    );
  }

  /// Updates a meeting in Supabase
  Future<MeetingModel> updateMeeting(MeetingModel meeting) async {
    final updateData = meeting.toSupabaseRow();
    updateData.remove('id'); // Don't update ID
    updateData.remove('created_at'); // Don't update creation time

    final response = await _supabase
        .from('meetings')
        .update(updateData)
        .eq('id', meeting.id)
        .select()
        .single();

    final participantsResponse = await _supabase
        .from('meeting_participants')
        .select()
        .eq('meeting_id', meeting.id)
        .order('joined_at');

    return MeetingModel.fromSupabaseRow(
      response,
      List<Map<String, dynamic>>.from(participantsResponse),
    );
  }

  /// Deletes a meeting from Supabase
  Future<void> deleteMeeting(String meetingId) async {
    await _supabase
        .from('meetings')
        .delete()
        .eq('id', meetingId);
  }

  /// Gets all meetings for a user
  Future<List<MeetingModel>> getUserMeetings(String userId) async {
    final meetingsResponse = await _supabase
        .from('meetings')
        .select()
        .eq('host_id', userId)
        .order('created_at', ascending: false);

    if (meetingsResponse.isEmpty) {
      return [];
    }

    final meetingIds = meetingsResponse
        .map((row) => row['id'] as String)
        .toList();

    final participantsResponse = await _supabase
        .from('meeting_participants')
        .select()
        .inFilter('meeting_id', meetingIds)
        .order('joined_at');

    // Group participants by meeting ID
    final participantsByMeeting = <String, List<Map<String, dynamic>>>{};
    final participantsData = List<Map<String, dynamic>>.from(participantsResponse);
    for (final participant in participantsData) {
      final meetingId = participant['meeting_id'] as String;
      participantsByMeeting.putIfAbsent(meetingId, () => []);
      participantsByMeeting[meetingId]!.add(participant);
    }

    return meetingsResponse
        .map((meetingRow) {
          final meetingId = meetingRow['id'] as String;
          final participants = participantsByMeeting[meetingId] ?? [];
          return MeetingModel.fromSupabaseRow(meetingRow, participants);
        })
        .toList();
  }

  /// Joins a meeting as a participant
  Future<MeetingModel> joinMeeting(JoinMeetingParams params) async {
    // First check if meeting exists and can be joined
    final meeting = await getMeeting(params.meetingId);
    
    // Check if user is already a participant
    final existingParticipant = meeting.participants
        .where((p) => p.userId == params.userId && p.leftAt == null)
        .firstOrNull;

    if (existingParticipant != null) {
      // User is already in the meeting
      return meeting;
    }

    // Add participant
    final participantData = {
      'meeting_id': params.meetingId,
      'user_id': params.userId,
      'display_name': params.displayName,
      'role': 'attendee', // Default role for joining
      'joined_at': DateTime.now().toIso8601String(),
      'left_at': null,
      'is_audio_enabled': true,
      'is_video_enabled': true,
      'avatar_url': null,
    };

    await _supabase
        .from('meeting_participants')
        .insert(participantData);

    // Return updated meeting
    return getMeeting(params.meetingId);
  }

  /// Leaves a meeting
  Future<MeetingModel> leaveMeeting(LeaveMeetingParams params) async {
    await _supabase
        .from('meeting_participants')
        .update({'left_at': DateTime.now().toIso8601String()})
        .eq('meeting_id', params.meetingId)
        .eq('user_id', params.userId)
        .isFilter('left_at', null); // Only update if not already left

    return getMeeting(params.meetingId);
  }

  /// Ends a meeting
  Future<MeetingModel> endMeeting(EndMeetingParams params) async {
    final now = DateTime.now().toIso8601String();
    
    // Update meeting state and end time
    await _supabase
        .from('meetings')
        .update({
          'state': 'ended',
          'actual_end_time': now,
        })
        .eq('id', params.meetingId)
        .eq('host_id', params.hostId); // Only host can end meeting

    // Mark all active participants as left
    await _supabase
        .from('meeting_participants')
        .update({'left_at': now})
        .eq('meeting_id', params.meetingId)
        .isFilter('left_at', null);

    return getMeeting(params.meetingId);
  }

  /// Updates participant status (audio/video)
  Future<void> updateParticipantStatus({
    required String meetingId,
    required String userId,
    bool? isAudioEnabled,
    bool? isVideoEnabled,
  }) async {
    final updates = <String, dynamic>{};
    if (isAudioEnabled != null) updates['is_audio_enabled'] = isAudioEnabled;
    if (isVideoEnabled != null) updates['is_video_enabled'] = isVideoEnabled;
    
    if (updates.isNotEmpty) {
      await _supabase
          .from('meeting_participants')
          .update(updates)
          .eq('meeting_id', meetingId)
          .eq('user_id', userId)
          .isFilter('left_at', null);
    }
  }

  /// Subscribes to real-time meeting changes
  Stream<MeetingModel> subscribeMeetingChanges(String meetingId) {
    final controller = StreamController<MeetingModel>();
    
    final channel = _supabase.channel('meeting:$meetingId');
    
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'meetings',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id',
        value: meetingId,
      ),
      callback: (payload) async {
        try {
          final meeting = await getMeeting(meetingId);
          controller.add(meeting);
        } catch (e) {
          controller.addError(e);
        }
      },
    );

    // Subscribe to the channel - no need to await or handle result
    channel.subscribe();

    controller.onCancel = () {
      channel.unsubscribe();
    };

    return controller.stream;
  }

  /// Subscribes to real-time participant changes
  Stream<List<MeetingParticipantModel>> subscribeParticipantChanges(String meetingId) {
    final controller = StreamController<List<MeetingParticipantModel>>();
    
    final channel = _supabase.channel('participants:$meetingId');
    
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'meeting_participants',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'meeting_id',
        value: meetingId,
      ),
      callback: (payload) async {
        try {
          final participantsResponse = await _supabase
              .from('meeting_participants')
              .select()
              .eq('meeting_id', meetingId)
              .order('joined_at');

          final participants = List<Map<String, dynamic>>.from(participantsResponse)
              .map((row) => MeetingParticipantModel.fromSupabaseRow(row))
              .toList();
          
          controller.add(participants);
        } catch (e) {
          controller.addError(e);
        }
      },
    );

    // Subscribe to the channel - no need to await or handle result
    channel.subscribe();

    controller.onCancel = () {
      channel.unsubscribe();
    };

    return controller.stream;
  }

  /// Starts a meeting
  Future<MeetingModel> startMeeting(String meetingId, String hostId) async {
    await _supabase
        .from('meetings')
        .update({
          'state': 'active',
          'actual_start_time': DateTime.now().toIso8601String(),
        })
        .eq('id', meetingId)
        .eq('host_id', hostId);

    return getMeeting(meetingId);
  }

  /// Gets meeting by room ID (for LiveKit integration)
  Future<MeetingModel?> getMeetingByRoomId(String roomId) async {
    try {
      final meetingResponse = await _supabase
          .from('meetings')
          .select()
          .eq('room_id', roomId)
          .single();

      final participantsResponse = await _supabase
          .from('meeting_participants')
          .select()
          .eq('meeting_id', meetingResponse['id'] as String)
          .order('joined_at');

      return MeetingModel.fromSupabaseRow(
        meetingResponse,
        List<Map<String, dynamic>>.from(participantsResponse),
      );
    } catch (e) {
      return null;
    }
  }
}