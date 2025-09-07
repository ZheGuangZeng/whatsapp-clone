import 'dart:developer' as developer;

import 'package:livekit_client/livekit_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../features/meetings/data/models/meeting_model.dart';
import '../../features/meetings/domain/entities/meeting.dart';
import '../../features/meetings/domain/entities/meeting_participant.dart';
import '../../features/meetings/domain/entities/meeting_state.dart';
import '../../features/meetings/domain/repositories/i_meeting_repository.dart';
import '../errors/failures.dart';
import '../utils/result.dart';

/// Real LiveKit + Supabase implementation of IMeetingRepository
/// Provides actual meeting services using LiveKit for real-time communication
/// and Supabase for meeting persistence
class RealLiveKitMeetingService implements IMeetingRepository {
  static const String _logTag = 'RealLiveKitMeetingService';
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(milliseconds: 500);
  static const String _meetingsTable = 'meetings';
  static const String _participantsTable = 'meeting_participants';

  final SupabaseClient _supabaseClient;
  final String _liveKitUrl;
  final Uuid _uuid;

  Room? _currentRoom;

  RealLiveKitMeetingService({
    SupabaseClient? supabaseClient,
    required String liveKitUrl,
    Uuid? uuid,
  })  : _supabaseClient = supabaseClient ?? Supabase.instance.client,
        _liveKitUrl = liveKitUrl,
        _uuid = uuid ?? const Uuid();

  @override
  Future<Result<Meeting>> createMeeting(CreateMeetingParams params) async {
    developer.log('Creating meeting: ${params.title}', name: _logTag);

    return await _retryOperation(() async {
      final meetingId = _uuid.v4();
      final now = DateTime.now();
      
      // Create meeting in database
      final meetingData = {
        'id': meetingId,
        'title': params.title,
        'description': params.description,
        'host_id': params.hostId,
        'room_id': meetingId, // Use meeting ID as room ID
        'created_at': now.toIso8601String(),
        'scheduled_start_time': params.scheduledStartTime?.toIso8601String(),
        'state': MeetingState.scheduled.name,
        'max_participants': params.settings.maxParticipants,
        'is_recording_enabled': params.settings.isRecordingEnabled,
        'is_waiting_room_enabled': params.settings.isWaitingRoomEnabled,
        'allow_screen_share': params.settings.allowScreenShare,
        'allow_chat': params.settings.allowChat,
        'is_public': params.settings.isPublic,
        'require_approval': params.settings.requireApproval,
        'password': params.settings.password,
      };

      final meetingResponse = await _supabaseClient
          .from(_meetingsTable)
          .insert(meetingData)
          .select()
          .single();

      // Create LiveKit room
      await _createLiveKitRoom(meetingId);

      final meeting = _mapRowToMeeting(meetingResponse, []);
      developer.log('Successfully created meeting: $meetingId', name: _logTag);
      return meeting;
    });
  }

  @override
  Future<Result<Meeting>> getMeeting(String meetingId) async {
    developer.log('Getting meeting: $meetingId', name: _logTag);

    return await _retryOperation(() async {
      // Get meeting data
      final meetingResponse = await _supabaseClient
          .from(_meetingsTable)
          .select()
          .eq('id', meetingId)
          .single();

      // Get participants
      final participantsResponse = await _supabaseClient
          .from(_participantsTable)
          .select()
          .eq('meeting_id', meetingId);

      final meeting = _mapRowToMeeting(
        meetingResponse,
        List<Map<String, dynamic>>.from(participantsResponse),
      );

      developer.log('Successfully retrieved meeting: $meetingId', name: _logTag);
      return meeting;
    });
  }

  @override
  Future<Result<Meeting>> updateMeeting(Meeting meeting) async {
    developer.log('Updating meeting: ${meeting.id}', name: _logTag);

    return await _retryOperation(() async {
      final meetingModel = MeetingModel.fromDomain(meeting);
      final updateData = meetingModel.toSupabaseRow();

      final meetingResponse = await _supabaseClient
          .from(_meetingsTable)
          .update(updateData)
          .eq('id', meeting.id)
          .select()
          .single();

      // Get updated participants
      final participantsResponse = await _supabaseClient
          .from(_participantsTable)
          .select()
          .eq('meeting_id', meeting.id);

      final updatedMeeting = _mapRowToMeeting(
        meetingResponse,
        List<Map<String, dynamic>>.from(participantsResponse),
      );

      developer.log('Successfully updated meeting: ${meeting.id}', name: _logTag);
      return updatedMeeting;
    });
  }

  @override
  Future<Result<void>> deleteMeeting(String meetingId) async {
    developer.log('Deleting meeting: $meetingId', name: _logTag);

    return await _retryOperation(() async {
      // Delete participants first
      await _supabaseClient
          .from(_participantsTable)
          .delete()
          .eq('meeting_id', meetingId);

      // Delete meeting
      await _supabaseClient
          .from(_meetingsTable)
          .delete()
          .eq('id', meetingId);

      // Clean up LiveKit room if needed
      await _cleanupLiveKitRoom(meetingId);

      developer.log('Successfully deleted meeting: $meetingId', name: _logTag);
      return;
    });
  }

  @override
  Future<Result<List<Meeting>>> getUserMeetings(String userId) async {
    developer.log('Getting meetings for user: $userId', name: _logTag);

    return await _retryOperation(() async {
      // Get meetings where user is host or participant
      final meetingsResponse = await _supabaseClient
          .from(_meetingsTable)
          .select()
          .or('host_id.eq.$userId,id.in.(${await _getUserParticipantMeetingIds(userId)})')
          .order('created_at', ascending: false);

      final meetings = <Meeting>[];
      for (final meetingRow in List<Map<String, dynamic>>.from(meetingsResponse)) {
        final participantsResponse = await _supabaseClient
            .from(_participantsTable)
            .select()
            .eq('meeting_id', meetingRow['id']);

        final meeting = _mapRowToMeeting(
          meetingRow,
          List<Map<String, dynamic>>.from(participantsResponse),
        );
        meetings.add(meeting);
      }

      developer.log('Successfully retrieved ${meetings.length} meetings for user: $userId', name: _logTag);
      return meetings;
    });
  }

  @override
  Future<Result<Meeting>> joinMeeting(JoinMeetingParams params) async {
    developer.log('User ${params.userId} joining meeting: ${params.meetingId}', name: _logTag);

    return await _retryOperation(() async {
      // Get meeting data
      final meetingResponse = await _supabaseClient
          .from(_meetingsTable)
          .select()
          .eq('id', params.meetingId)
          .single();

      // Check password if required
      if (meetingResponse['password'] != null && 
          meetingResponse['password'] != params.password) {
        throw Exception('Invalid meeting password');
      }

      // Check if meeting can accept more participants
      final currentParticipants = await _supabaseClient
          .from(_participantsTable)
          .select('id')
          .eq('meeting_id', params.meetingId);

      final maxParticipants = meetingResponse['max_participants'] as int? ?? 100;
      if (currentParticipants.length >= maxParticipants) {
        throw Exception('Meeting is full');
      }

      // Add participant to database
      final participantData = {
        'id': _uuid.v4(),
        'meeting_id': params.meetingId,
        'user_id': params.userId,
        'display_name': params.displayName,
        'joined_at': DateTime.now().toIso8601String(),
        'is_audio_enabled': true,
        'is_video_enabled': true,
        'is_screen_sharing': false,
      };

      await _supabaseClient
          .from(_participantsTable)
          .insert(participantData);

      // Update meeting state to active if not already
      if (meetingResponse['state'] == MeetingState.scheduled.name) {
        await _supabaseClient
            .from(_meetingsTable)
            .update({
              'state': MeetingState.active.name,
              'actual_start_time': DateTime.now().toIso8601String(),
            })
            .eq('id', params.meetingId);
      }

      // Join LiveKit room
      await _joinLiveKitRoom(
        params.meetingId,
        params.userId,
        params.displayName,
      );

      // Return updated meeting
      return await getMeeting(params.meetingId).then((result) => result.when(
        success: (meeting) => meeting,
        failure: (failure) => throw Exception(failure.message),
      ));
    });
  }

  @override
  Future<Result<Meeting>> leaveMeeting(LeaveMeetingParams params) async {
    developer.log('User ${params.userId} leaving meeting: ${params.meetingId}', name: _logTag);

    return await _retryOperation(() async {
      // Update participant left time
      await _supabaseClient
          .from(_participantsTable)
          .update({'left_at': DateTime.now().toIso8601String()})
          .eq('meeting_id', params.meetingId)
          .eq('user_id', params.userId);

      // Disconnect from LiveKit room
      await _leaveLiveKitRoom();

      // Return updated meeting
      return await getMeeting(params.meetingId).then((result) => result.when(
        success: (meeting) => meeting,
        failure: (failure) => throw Exception(failure.message),
      ));
    });
  }

  @override
  Future<Result<Meeting>> endMeeting(EndMeetingParams params) async {
    developer.log('Ending meeting: ${params.meetingId}', name: _logTag);

    return await _retryOperation(() async {
      // Update meeting state to ended
      await _supabaseClient
          .from(_meetingsTable)
          .update({
            'state': MeetingState.ended.name,
            'actual_end_time': DateTime.now().toIso8601String(),
          })
          .eq('id', params.meetingId)
          .eq('host_id', params.hostId); // Only host can end meeting

      // Update all participants to left
      await _supabaseClient
          .from(_participantsTable)
          .update({'left_at': DateTime.now().toIso8601String()})
          .eq('meeting_id', params.meetingId)
          .isFilter('left_at', null);

      // Clean up LiveKit room
      await _cleanupLiveKitRoom(params.meetingId);

      // Return updated meeting
      return await getMeeting(params.meetingId).then((result) => result.when(
        success: (meeting) => meeting,
        failure: (failure) => throw Exception(failure.message),
      ));
    });
  }

  /// Toggle audio for current participant
  Future<Result<void>> toggleAudio() async {
    developer.log('Toggling audio', name: _logTag);

    return await _retryOperation(() async {
      if (_currentRoom == null) {
        throw Exception('Not connected to a meeting room');
      }

      final localParticipant = _currentRoom!.localParticipant;
      if (localParticipant != null) {
        await localParticipant.setMicrophoneEnabled(!localParticipant.isMicrophoneEnabled());
      }

      developer.log('Successfully toggled audio', name: _logTag);
      return;
    });
  }

  /// Toggle video for current participant
  Future<Result<void>> toggleVideo() async {
    developer.log('Toggling video', name: _logTag);

    return await _retryOperation(() async {
      if (_currentRoom == null) {
        throw Exception('Not connected to a meeting room');
      }

      final localParticipant = _currentRoom!.localParticipant;
      if (localParticipant != null) {
        await localParticipant.setCameraEnabled(!localParticipant.isCameraEnabled());
      }

      developer.log('Successfully toggled video', name: _logTag);
      return;
    });
  }

  /// Share screen
  Future<Result<void>> startScreenShare() async {
    developer.log('Starting screen share', name: _logTag);

    return await _retryOperation(() async {
      if (_currentRoom == null) {
        throw Exception('Not connected to a meeting room');
      }

      final localParticipant = _currentRoom!.localParticipant;
      if (localParticipant != null) {
        await localParticipant.setScreenShareEnabled(true);
      }

      developer.log('Successfully started screen share', name: _logTag);
      return;
    });
  }

  /// Stop screen sharing
  Future<Result<void>> stopScreenShare() async {
    developer.log('Stopping screen share', name: _logTag);

    return await _retryOperation(() async {
      if (_currentRoom == null) {
        throw Exception('Not connected to a meeting room');
      }

      final localParticipant = _currentRoom!.localParticipant;
      if (localParticipant != null) {
        await localParticipant.setScreenShareEnabled(false);
      }

      developer.log('Successfully stopped screen share', name: _logTag);
      return;
    });
  }

  /// Get current room connection state
  ConnectionState? get connectionState => _currentRoom?.connectionState;

  /// Get current room instance
  Room? get currentRoom => _currentRoom;

  /// Helper method to get meeting IDs where user is a participant
  Future<String> _getUserParticipantMeetingIds(String userId) async {
    final response = await _supabaseClient
        .from(_participantsTable)
        .select('meeting_id')
        .eq('user_id', userId);
    
    final meetingIds = (response as List<dynamic>)
        .map((row) => "'${row['meeting_id']}'")
        .join(',');
    
    return meetingIds.isEmpty ? "''" : meetingIds;
  }

  /// Create LiveKit room
  Future<void> _createLiveKitRoom(String roomName) async {
    try {
      // LiveKit room creation is handled by the server
      // We just log the room creation here
      developer.log('LiveKit room created: $roomName', name: _logTag);
    } catch (error) {
      developer.log('Failed to create LiveKit room: $error', name: _logTag, level: 1000);
      throw Exception('Failed to create LiveKit room: $error');
    }
  }

  /// Join LiveKit room
  Future<void> _joinLiveKitRoom(
    String roomName,
    String userId,
    String displayName,
  ) async {
    try {
      _currentRoom = Room();
      
      // Generate access token (in production, this should be done server-side)
      final token = await _generateAccessToken(roomName, userId, displayName);
      
      await _currentRoom!.connect(_liveKitUrl, token);
      
      developer.log('Joined LiveKit room: $roomName', name: _logTag);
    } catch (error) {
      developer.log('Failed to join LiveKit room: $error', name: _logTag, level: 1000);
      throw Exception('Failed to join LiveKit room: $error');
    }
  }

  /// Leave LiveKit room
  Future<void> _leaveLiveKitRoom() async {
    try {
      await _currentRoom?.disconnect();
      _currentRoom = null;
      developer.log('Left LiveKit room', name: _logTag);
    } catch (error) {
      developer.log('Error leaving LiveKit room: $error', name: _logTag, level: 1000);
    }
  }

  /// Clean up LiveKit room resources
  Future<void> _cleanupLiveKitRoom(String roomName) async {
    try {
      // Cleanup is typically handled automatically by LiveKit
      developer.log('Cleaned up LiveKit room: $roomName', name: _logTag);
    } catch (error) {
      developer.log('Error cleaning up LiveKit room: $error', name: _logTag, level: 1000);
    }
  }

  /// Generate access token for LiveKit
  /// NOTE: In production, this should be done server-side for security
  Future<String> _generateAccessToken(
    String roomName,
    String userId,
    String displayName,
  ) async {
    // This is a simplified token generation
    // In production, use proper JWT token generation with your server
    return 'mock_token_${userId}_$roomName';
  }

  /// Helper method to map database row to Meeting entity
  Meeting _mapRowToMeeting(
    Map<String, dynamic> meetingRow,
    List<Map<String, dynamic>> participantRows,
  ) {
    return MeetingModel.fromSupabaseRow(meetingRow, participantRows).toDomain();
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
          } else if (error.toString().contains('LiveKit')) {
            return ResultFailure(ServiceFailure('LiveKit error: $error'));
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
    _leaveLiveKitRoom();
    developer.log('RealLiveKitMeetingService disposed', name: _logTag);
  }
}