import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/meeting.dart';
import '../../domain/repositories/i_meeting_repository.dart';
import '../datasources/meeting_remote_datasource.dart';
import '../models/meeting_model.dart';
import '../models/meeting_settings_model.dart';

/// Implementation of meeting repository using remote data source
class MeetingRepository implements IMeetingRepository {
  const MeetingRepository(this._remoteDataSource);

  final MeetingRemoteDataSource _remoteDataSource;

  @override
  Future<Result<Meeting>> createMeeting(CreateMeetingParams params) async {
    try {
      final meetingModel = await _remoteDataSource.createMeeting(params);
      final meeting = meetingModel.toDomain();
      
      return Success(meeting);
    } catch (e) {
      return ResultFailure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Meeting>> getMeeting(String meetingId) async {
    try {
      final meetingModel = await _remoteDataSource.getMeeting(meetingId);
      final meeting = meetingModel.toDomain();
      
      return Success(meeting);
    } catch (e) {
      return ResultFailure(ServerFailure(message: 'Failed to get meeting: ${e.toString()}'));
    }
  }

  @override
  Future<Result<Meeting>> updateMeeting(Meeting meeting) async {
    try {
      final meetingModel = MeetingModel.fromDomain(meeting);
      final updatedModel = await _remoteDataSource.updateMeeting(meetingModel);
      final updatedMeeting = updatedModel.toDomain();
      
      return Success(updatedMeeting);
    } catch (e) {
      return ResultFailure(ServerFailure(message: 'Failed to update meeting: ${e.toString()}'));
    }
  }

  @override
  Future<Result<void>> deleteMeeting(String meetingId) async {
    try {
      await _remoteDataSource.deleteMeeting(meetingId);
      return const Success(null);
    } catch (e) {
      return ResultFailure(ServerFailure(message: 'Failed to delete meeting: ${e.toString()}'));
    }
  }

  @override
  Future<Result<List<Meeting>>> getUserMeetings(String userId) async {
    try {
      final meetingModels = await _remoteDataSource.getUserMeetings(userId);
      final meetings = meetingModels.map((model) => model.toDomain()).toList();
      
      return Success(meetings);
    } catch (e) {
      return ResultFailure(ServerFailure(message: 'Failed to get user meetings: ${e.toString()}'));
    }
  }

  @override
  Future<Result<Meeting>> joinMeeting(JoinMeetingParams params) async {
    try {
      final meetingModel = await _remoteDataSource.joinMeeting(params);
      final meeting = meetingModel.toDomain();
      
      return Success(meeting);
    } catch (e) {
      return ResultFailure(ServerFailure(message: 'Failed to join meeting: ${e.toString()}'));
    }
  }

  @override
  Future<Result<Meeting>> leaveMeeting(LeaveMeetingParams params) async {
    try {
      final meetingModel = await _remoteDataSource.leaveMeeting(params);
      final meeting = meetingModel.toDomain();
      
      return Success(meeting);
    } catch (e) {
      return ResultFailure(ServerFailure(message: 'Failed to leave meeting: ${e.toString()}'));
    }
  }

  @override
  Future<Result<Meeting>> endMeeting(EndMeetingParams params) async {
    try {
      final meetingModel = await _remoteDataSource.endMeeting(params);
      final meeting = meetingModel.toDomain();
      
      return Success(meeting);
    } catch (e) {
      return ResultFailure(ServerFailure(message: 'Failed to end meeting: ${e.toString()}'));
    }
  }

  /// Starts a meeting (convenience method)
  Future<Result<Meeting>> startMeeting(String meetingId, String hostId) async {
    try {
      final meetingModel = await _remoteDataSource.startMeeting(meetingId, hostId);
      final meeting = meetingModel.toDomain();
      
      return Success(meeting);
    } catch (e) {
      return ResultFailure(ServerFailure(message: 'Failed to start meeting: ${e.toString()}'));
    }
  }

  /// Updates participant status
  Future<Result<void>> updateParticipantStatus({
    required String meetingId,
    required String userId,
    bool? isAudioEnabled,
    bool? isVideoEnabled,
  }) async {
    try {
      await _remoteDataSource.updateParticipantStatus(
        meetingId: meetingId,
        userId: userId,
        isAudioEnabled: isAudioEnabled,
        isVideoEnabled: isVideoEnabled,
      );
      
      return const Success(null);
    } catch (e) {
      return ResultFailure(ServerFailure(message: 'Failed to update participant status: ${e.toString()}'));
    }
  }

  /// Gets meeting by room ID (for LiveKit integration)
  Future<Result<Meeting?>> getMeetingByRoomId(String roomId) async {
    try {
      final meetingModel = await _remoteDataSource.getMeetingByRoomId(roomId);
      final meeting = meetingModel?.toDomain();
      
      return Success(meeting);
    } catch (e) {
      return ResultFailure(ServerFailure(message: 'Failed to get meeting by room ID: ${e.toString()}'));
    }
  }

  /// Subscribes to real-time meeting changes
  Stream<Meeting> subscribeMeetingChanges(String meetingId) {
    return _remoteDataSource
        .subscribeMeetingChanges(meetingId)
        .map((model) => model.toDomain());
  }

  /// Subscribes to real-time participant changes  
  Stream<List<Meeting>> subscribeParticipantChanges(String meetingId) {
    return _remoteDataSource
        .subscribeParticipantChanges(meetingId)
        .asyncMap((participants) async {
          // Get the updated meeting with new participants
          try {
            final meeting = await getMeeting(meetingId);
            return meeting.isSuccess ? [meeting.dataOrNull!] : <Meeting>[];
          } catch (e) {
            return <Meeting>[];
          }
        });
  }
}

