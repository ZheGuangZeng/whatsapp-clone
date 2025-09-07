import '../../../../core/utils/result.dart';
import '../entities/meeting.dart';
import '../entities/meeting_settings.dart';

/// Abstract repository interface for meeting operations
abstract class IMeetingRepository {
  /// Creates a new meeting with the given parameters
  Future<Result<Meeting>> createMeeting(CreateMeetingParams params);
  
  /// Retrieves a meeting by its ID
  Future<Result<Meeting>> getMeeting(String meetingId);
  
  /// Updates an existing meeting
  Future<Result<Meeting>> updateMeeting(Meeting meeting);
  
  /// Deletes a meeting by its ID
  Future<Result<void>> deleteMeeting(String meetingId);
  
  /// Gets all meetings for a user
  Future<Result<List<Meeting>>> getUserMeetings(String userId);
  
  /// Joins a meeting as a participant
  Future<Result<Meeting>> joinMeeting(JoinMeetingParams params);
  
  /// Leaves a meeting
  Future<Result<Meeting>> leaveMeeting(LeaveMeetingParams params);
  
  /// Ends a meeting
  Future<Result<Meeting>> endMeeting(EndMeetingParams params);
}

/// Parameters for creating a meeting
class CreateMeetingParams {
  const CreateMeetingParams({
    required this.title,
    this.description,
    required this.hostId,
    this.scheduledStartTime,
    required this.settings,
  });

  final String title;
  final String? description;
  final String hostId;
  final DateTime? scheduledStartTime;
  final MeetingSettings settings;
}

/// Parameters for joining a meeting
class JoinMeetingParams {
  const JoinMeetingParams({
    required this.meetingId,
    required this.userId,
    required this.displayName,
    this.password,
  });

  final String meetingId;
  final String userId;
  final String displayName;
  final String? password;
}

/// Parameters for leaving a meeting
class LeaveMeetingParams {
  const LeaveMeetingParams({
    required this.meetingId,
    required this.userId,
  });

  final String meetingId;
  final String userId;
}

/// Parameters for ending a meeting
class EndMeetingParams {
  const EndMeetingParams({
    required this.meetingId,
    required this.hostId,
  });

  final String meetingId;
  final String hostId;
}