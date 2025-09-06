import 'dart:async';

import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/result.dart';
import '../../domain/entities/meeting.dart';
import '../../domain/entities/meeting_participant.dart';
import '../../domain/entities/meeting_recording.dart';
import '../../domain/entities/meeting_state.dart';
import '../../domain/repositories/i_meeting_repository.dart';
import '../models/meeting_model.dart';
import '../models/meeting_participant_model.dart';
import '../models/meeting_recording_model.dart';
import '../sources/livekit_source.dart';
import '../sources/meeting_remote_source.dart';

/// Implementation of IMeetingRepository
class MeetingRepository implements IMeetingRepository {
  const MeetingRepository({
    required this.remoteSource,
    required this.livekitSource,
  });

  final MeetingRemoteSource remoteSource;
  final LivekitSource livekitSource;

  @override
  Future<Result<Meeting>> createMeeting({
    String? roomId,
    required String hostId,
    String? title,
    String? description,
    DateTime? scheduledFor,
    int maxParticipants = 100,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      final meetingData = {
        'room_id': roomId,
        'host_id': hostId,
        'title': title,
        'description': description,
        'scheduled_for': scheduledFor?.toIso8601String(),
        'max_participants': maxParticipants,
        'metadata': metadata,
      };

      final meetingModel = await remoteSource.createMeeting(meetingData);
      return Success(meetingModel.toDomain());
    } on ServerException catch (e) {
      return ResultFailure(ServerFailure(e.message));
    } on CacheException catch (e) {
      return ResultFailure(CacheFailure(e.message));
    } catch (e) {
      return ResultFailure(UnknownFailure('Failed to create meeting: $e'));
    }
  }

  @override
  Future<Result<Meeting>> getMeeting(String meetingId) async {
    try {
      final meetingModel = await remoteSource.getMeeting(meetingId);
      return Success(meetingModel.toDomain());
    } on ServerException catch (e) {
      return ResultFailure(ServerFailure(e.message));
    } on CacheException catch (e) {
      return ResultFailure(CacheFailure(e.message));
    } catch (e) {
      return ResultFailure(UnknownFailure('Failed to get meeting: $e'));
    }
  }

  @override
  Future<Result<Meeting>> getMeetingByLivekitRoom(String livekitRoomName) async {
    try {
      final meetingModel = await remoteSource.getMeetingByLivekitRoom(livekitRoomName);
      return Success(meetingModel.toDomain());
    } on ServerException catch (e) {
      return ResultFailure(ServerFailure(e.message));
    } on CacheException catch (e) {
      return ResultFailure(CacheFailure(e.message));
    } catch (e) {
      return ResultFailure(UnknownFailure('Failed to get meeting by LiveKit room: $e'));
    }
  }

  @override
  Future<Result<Meeting>> updateMeeting(String meetingId, {
    String? title,
    String? description,
    DateTime? scheduledFor,
    DateTime? startedAt,
    DateTime? endedAt,
    int? maxParticipants,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (scheduledFor != null) updateData['scheduled_for'] = scheduledFor.toIso8601String();
      if (startedAt != null) updateData['started_at'] = startedAt.toIso8601String();
      if (endedAt != null) updateData['ended_at'] = endedAt.toIso8601String();
      if (maxParticipants != null) updateData['max_participants'] = maxParticipants;
      if (metadata != null) updateData['metadata'] = metadata;

      final meetingModel = await remoteSource.updateMeeting(meetingId, updateData);
      return Success(meetingModel.toDomain());
    } on ServerException catch (e) {
      return ResultFailure(ServerFailure(e.message));
    } on CacheException catch (e) {
      return ResultFailure(CacheFailure(e.message));
    } catch (e) {
      return ResultFailure(UnknownFailure('Failed to update meeting: $e'));
    }
  }

  @override
  Future<Result<void>> deleteMeeting(String meetingId) async {
    try {
      await remoteSource.deleteMeeting(meetingId);
      return const Success(null);
    } on ServerException catch (e) {
      return ResultFailure(ServerFailure(e.message));
    } on CacheException catch (e) {
      return ResultFailure(CacheFailure(e.message));
    } catch (e) {
      return ResultFailure(UnknownFailure('Failed to delete meeting: $e'));
    }
  }

  @override
  Future<Result<Meeting>> startMeeting(String meetingId) async {
    try {
      final updateData = {
        'started_at': DateTime.now().toIso8601String(),
      };
      final meetingModel = await remoteSource.updateMeeting(meetingId, updateData);
      return Success(meetingModel.toDomain());
    } on ServerException catch (e) {
      return ResultFailure(ServerFailure(e.message));
    } on CacheException catch (e) {
      return ResultFailure(CacheFailure(e.message));
    } catch (e) {
      return ResultFailure(UnknownFailure('Failed to start meeting: $e'));
    }
  }

  @override
  Future<Result<Meeting>> endMeeting(String meetingId) async {
    try {
      final updateData = {
        'ended_at': DateTime.now().toIso8601String(),
      };
      final meetingModel = await remoteSource.updateMeeting(meetingId, updateData);
      return Success(meetingModel.toDomain());
    } on ServerException catch (e) {
      return ResultFailure(ServerFailure(e.message));
    } on CacheException catch (e) {
      return ResultFailure(CacheFailure(e.message));
    } catch (e) {
      return ResultFailure(UnknownFailure('Failed to end meeting: $e'));
    }
  }

  @override
  Future<Result<List<Meeting>>> getUserMeetings(String userId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final meetingModels = await remoteSource.getUserMeetings(
        userId,
        limit: limit,
        offset: offset,
      );
      final meetings = meetingModels.map((m) => m.toDomain()).toList();
      return Success(meetings);
    } on ServerException catch (e) {
      return ResultFailure(ServerFailure(e.message));
    } on CacheException catch (e) {
      return ResultFailure(CacheFailure(e.message));
    } catch (e) {
      return ResultFailure(UnknownFailure('Failed to get user meetings: $e'));
    }
  }

  @override
  Future<Result<List<Meeting>>> getRoomMeetings(String roomId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final meetingModels = await remoteSource.getRoomMeetings(
        roomId,
        limit: limit,
        offset: offset,
      );
      final meetings = meetingModels.map((m) => m.toDomain()).toList();
      return Success(meetings);
    } on ServerException catch (e) {
      return ResultFailure(ServerFailure(e.message));
    } on CacheException catch (e) {
      return ResultFailure(CacheFailure(e.message));
    } catch (e) {
      return ResultFailure(UnknownFailure('Failed to get room meetings: $e'));
    }
  }

  @override
  Future<Result<List<Meeting>>> getActiveMeetings(String userId) async {
    try {
      final meetingModels = await remoteSource.getActiveMeetings(userId);
      final meetings = meetingModels.map((m) => m.toDomain()).toList();
      return Success(meetings);
    } on ServerException catch (e) {
      return ResultFailure(ServerFailure(e.message));
    } on CacheException catch (e) {
      return ResultFailure(CacheFailure(e.message));
    } catch (e) {
      return ResultFailure(UnknownFailure('Failed to get active meetings: $e'));
    }
  }

  @override
  Future<Result<List<Meeting>>> getScheduledMeetings(String userId) async {
    // For now, filter scheduled meetings on the client side
    // In a real app, you'd add a database query for this
    final result = await getUserMeetings(userId);
    return result.map((meetings) => 
      meetings.where((m) => m.isScheduled).toList()
    );
  }

  @override
  Future<Result<MeetingParticipant>> addParticipant({
    required String meetingId,
    required String userId,
    ParticipantRole role = ParticipantRole.participant,
    String? livekitParticipantId,
  }) async {
    try {
      final participantData = {
        'meeting_id': meetingId,
        'user_id': userId,
        'role': role.value,
        'livekit_participant_id': livekitParticipantId,
      };

      final participantModel = await remoteSource.addParticipant(participantData);
      return Success(participantModel.toDomain());
    } on ServerException catch (e) {
      return ResultFailure(ServerFailure(e.message));
    } on CacheException catch (e) {
      return ResultFailure(CacheFailure(e.message));
    } catch (e) {
      return ResultFailure(UnknownFailure('Failed to add participant: $e'));
    }
  }

  @override
  Future<Result<void>> removeParticipant(String meetingId, String userId) async {
    try {
      await remoteSource.removeParticipant(meetingId, userId);
      return const Success(null);
    } on ServerException catch (e) {
      return ResultFailure(ServerFailure(e.message));
    } on CacheException catch (e) {
      return ResultFailure(CacheFailure(e.message));
    } catch (e) {
      return ResultFailure(UnknownFailure('Failed to remove participant: $e'));
    }
  }

  @override
  Future<Result<MeetingParticipant>> updateParticipant(
    String meetingId,
    String userId, {
    ParticipantRole? role,
    ConnectionQuality? connectionQuality,
    bool? isAudioEnabled,
    bool? isVideoEnabled,
    bool? isScreenSharing,
    String? livekitParticipantId,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (role != null) updateData['role'] = role.value;
      if (connectionQuality != null) updateData['connection_quality'] = connectionQuality.value;
      if (isAudioEnabled != null) updateData['is_audio_enabled'] = isAudioEnabled;
      if (isVideoEnabled != null) updateData['is_video_enabled'] = isVideoEnabled;
      if (isScreenSharing != null) updateData['is_screen_sharing'] = isScreenSharing;
      if (livekitParticipantId != null) updateData['livekit_participant_id'] = livekitParticipantId;

      final participantModel = await remoteSource.updateParticipant(
        meetingId,
        userId,
        updateData,
      );
      return Success(participantModel.toDomain());
    } on ServerException catch (e) {
      return ResultFailure(ServerFailure(e.message));
    } on CacheException catch (e) {
      return ResultFailure(CacheFailure(e.message));
    } catch (e) {
      return ResultFailure(UnknownFailure('Failed to update participant: $e'));
    }
  }

  @override
  Future<Result<List<MeetingParticipant>>> getMeetingParticipants(String meetingId) async {
    try {
      final participantModels = await remoteSource.getMeetingParticipants(meetingId);
      final participants = participantModels.map((p) => p.toDomain()).toList();
      return Success(participants);
    } on ServerException catch (e) {
      return ResultFailure(ServerFailure(e.message));
    } on CacheException catch (e) {
      return ResultFailure(CacheFailure(e.message));
    } catch (e) {
      return ResultFailure(UnknownFailure('Failed to get meeting participants: $e'));
    }
  }

  @override
  Future<Result<List<MeetingParticipant>>> getActiveParticipants(String meetingId) async {
    final result = await getMeetingParticipants(meetingId);
    return result.map((participants) => 
      participants.where((p) => p.isActive).toList()
    );
  }

  @override
  Future<Result<MeetingRecording>> createRecording({
    required String meetingId,
    required String livekitEgressId,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      final recordingData = {
        'meeting_id': meetingId,
        'livekit_egress_id': livekitEgressId,
        'metadata': metadata,
      };

      final recordingModel = await remoteSource.createRecording(recordingData);
      return Success(recordingModel.toDomain());
    } on ServerException catch (e) {
      return ResultFailure(ServerFailure(e.message));
    } on CacheException catch (e) {
      return ResultFailure(CacheFailure(e.message));
    } catch (e) {
      return ResultFailure(UnknownFailure('Failed to create recording: $e'));
    }
  }

  @override
  Future<Result<MeetingRecording>> updateRecording(String recordingId, {
    String? fileUrl,
    int? fileSize,
    int? durationSeconds,
    RecordingStatus? status,
    DateTime? completedAt,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (fileUrl != null) updateData['file_url'] = fileUrl;
      if (fileSize != null) updateData['file_size'] = fileSize;
      if (durationSeconds != null) updateData['duration_seconds'] = durationSeconds;
      if (status != null) updateData['status'] = status.value;
      if (completedAt != null) updateData['completed_at'] = completedAt.toIso8601String();

      final recordingModel = await remoteSource.updateRecording(recordingId, updateData);
      return Success(recordingModel.toDomain());
    } on ServerException catch (e) {
      return ResultFailure(ServerFailure(e.message));
    } on CacheException catch (e) {
      return ResultFailure(CacheFailure(e.message));
    } catch (e) {
      return ResultFailure(UnknownFailure('Failed to update recording: $e'));
    }
  }

  @override
  Future<Result<List<MeetingRecording>>> getMeetingRecordings(String meetingId) async {
    try {
      final recordingModels = await remoteSource.getMeetingRecordings(meetingId);
      final recordings = recordingModels.map((r) => r.toDomain()).toList();
      return Success(recordings);
    } on ServerException catch (e) {
      return ResultFailure(ServerFailure(e.message));
    } on CacheException catch (e) {
      return ResultFailure(CacheFailure(e.message));
    } catch (e) {
      return ResultFailure(UnknownFailure('Failed to get meeting recordings: $e'));
    }
  }

  @override
  Future<Result<void>> deleteRecording(String recordingId) async {
    try {
      // Implementation depends on your storage solution
      // For now, just mark as deleted in database
      await remoteSource.updateRecording(recordingId, {'status': 'deleted'});
      return const Success(null);
    } on ServerException catch (e) {
      return ResultFailure(ServerFailure(e.message));
    } on CacheException catch (e) {
      return ResultFailure(CacheFailure(e.message));
    } catch (e) {
      return ResultFailure(UnknownFailure('Failed to delete recording: $e'));
    }
  }

  @override
  Stream<Result<Meeting>> watchMeeting(String meetingId) {
    final controller = StreamController<Result<Meeting>>();
    
    remoteSource.subscribeMeetingChanges(meetingId, (meetingData) {
      try {
        final meetingModel = MeetingModel.fromSupabase(meetingData);
        controller.add(Success(meetingModel.toDomain()));
      } catch (e) {
        controller.add(ResultFailure(UnknownFailure('Failed to parse meeting update: $e')));
      }
    });

    return controller.stream;
  }

  @override
  Stream<Result<List<MeetingParticipant>>> watchMeetingParticipants(String meetingId) {
    final controller = StreamController<Result<List<MeetingParticipant>>>();
    
    remoteSource.subscribeParticipantChanges(meetingId, (participantsData) {
      try {
        final participants = participantsData
            .map((data) => MeetingParticipantModel.fromSupabase(data).toDomain())
            .toList();
        controller.add(Success(participants));
      } catch (e) {
        controller.add(ResultFailure(UnknownFailure('Failed to parse participant update: $e')));
      }
    });

    return controller.stream;
  }

  @override
  Stream<Result<List<Meeting>>> watchUserMeetings(String userId) {
    // Implementation would require a more complex real-time subscription
    // For now, return a simple stream that fetches data periodically
    return Stream.periodic(const Duration(seconds: 30))
        .asyncMap((_) => getUserMeetings(userId));
  }

  @override
  Future<Result<String>> generateLivekitToken({
    required String meetingId,
    required String userId,
    ParticipantRole role = ParticipantRole.participant,
    Duration? ttl,
  }) async {
    try {
      final token = await remoteSource.generateLivekitToken(
        meetingId: meetingId,
        userId: userId,
        participantRole: role.value,
        ttl: ttl,
      );
      return Success(token);
    } on ServerException catch (e) {
      return ResultFailure(ServerFailure(e.message));
    } on CacheException catch (e) {
      return ResultFailure(CacheFailure(e.message));
    } catch (e) {
      return ResultFailure(UnknownFailure('Failed to generate LiveKit token: $e'));
    }
  }

  @override
  Future<Result<bool>> validateRoomAccess(String livekitRoomName, String userId) async {
    try {
      final hasAccess = await remoteSource.validateRoomAccess(livekitRoomName, userId);
      return Success(hasAccess);
    } on ServerException catch (e) {
      return ResultFailure(ServerFailure(e.message));
    } on CacheException catch (e) {
      return ResultFailure(CacheFailure(e.message));
    } catch (e) {
      return ResultFailure(UnknownFailure('Failed to validate room access: $e'));
    }
  }

  /// Get LiveKit source for real-time operations
  LivekitSource get livekit => livekitSource;

  /// Get meeting state stream from LiveKit
  Stream<MeetingState> get meetingStateStream => livekitSource.meetingStateStream;
}