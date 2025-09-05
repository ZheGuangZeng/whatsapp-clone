import '../../../core/utils/result.dart';
import '../entities/meeting.dart';
import '../entities/meeting_participant.dart';
import '../entities/meeting_recording.dart';

/// Abstract repository interface for meeting operations
abstract class IMeetingRepository {
  /// Create a new meeting
  Future<Result<Meeting>> createMeeting({
    String? roomId,
    required String hostId,
    String? title,
    String? description,
    DateTime? scheduledFor,
    int maxParticipants = 100,
    Map<String, dynamic> metadata = const {},
  });

  /// Get a meeting by ID
  Future<Result<Meeting>> getMeeting(String meetingId);

  /// Get meeting by LiveKit room name
  Future<Result<Meeting>> getMeetingByLivekitRoom(String livekitRoomName);

  /// Update meeting details
  Future<Result<Meeting>> updateMeeting(String meetingId, {
    String? title,
    String? description,
    DateTime? scheduledFor,
    DateTime? startedAt,
    DateTime? endedAt,
    int? maxParticipants,
    Map<String, dynamic>? metadata,
  });

  /// Delete a meeting
  Future<Result<void>> deleteMeeting(String meetingId);

  /// Start a meeting
  Future<Result<Meeting>> startMeeting(String meetingId);

  /// End a meeting
  Future<Result<Meeting>> endMeeting(String meetingId);

  /// Get meetings for a user (as host or participant)
  Future<Result<List<Meeting>>> getUserMeetings(String userId, {
    int limit = 50,
    int offset = 0,
  });

  /// Get meetings for a chat room
  Future<Result<List<Meeting>>> getRoomMeetings(String roomId, {
    int limit = 50,
    int offset = 0,
  });

  /// Get active meetings for a user
  Future<Result<List<Meeting>>> getActiveMeetings(String userId);

  /// Get scheduled meetings for a user
  Future<Result<List<Meeting>>> getScheduledMeetings(String userId);

  // Participant operations

  /// Add participant to meeting
  Future<Result<MeetingParticipant>> addParticipant({
    required String meetingId,
    required String userId,
    ParticipantRole role = ParticipantRole.participant,
    String? livekitParticipantId,
  });

  /// Remove participant from meeting
  Future<Result<void>> removeParticipant(String meetingId, String userId);

  /// Update participant status
  Future<Result<MeetingParticipant>> updateParticipant(
    String meetingId,
    String userId, {
    ParticipantRole? role,
    ConnectionQuality? connectionQuality,
    bool? isAudioEnabled,
    bool? isVideoEnabled,
    bool? isScreenSharing,
    String? livekitParticipantId,
  });

  /// Get meeting participants
  Future<Result<List<MeetingParticipant>>> getMeetingParticipants(String meetingId);

  /// Get active participants for a meeting
  Future<Result<List<MeetingParticipant>>> getActiveParticipants(String meetingId);

  // Recording operations

  /// Create a meeting recording
  Future<Result<MeetingRecording>> createRecording({
    required String meetingId,
    required String livekitEgressId,
    Map<String, dynamic> metadata = const {},
  });

  /// Update recording status
  Future<Result<MeetingRecording>> updateRecording(String recordingId, {
    String? fileUrl,
    int? fileSize,
    int? durationSeconds,
    RecordingStatus? status,
    DateTime? completedAt,
  });

  /// Get meeting recordings
  Future<Result<List<MeetingRecording>>> getMeetingRecordings(String meetingId);

  /// Delete recording
  Future<Result<void>> deleteRecording(String recordingId);

  // Real-time operations

  /// Watch meeting changes (stream)
  Stream<Result<Meeting>> watchMeeting(String meetingId);

  /// Watch participant changes for a meeting (stream)
  Stream<Result<List<MeetingParticipant>>> watchMeetingParticipants(String meetingId);

  /// Watch user's meetings (stream)
  Stream<Result<List<Meeting>>> watchUserMeetings(String userId);

  // LiveKit token generation

  /// Generate LiveKit access token for a participant
  Future<Result<String>> generateLivekitToken({
    required String meetingId,
    required String userId,
    ParticipantRole role = ParticipantRole.participant,
    Duration? ttl,
  });

  /// Validate LiveKit room access
  Future<Result<bool>> validateRoomAccess(String livekitRoomName, String userId);
}