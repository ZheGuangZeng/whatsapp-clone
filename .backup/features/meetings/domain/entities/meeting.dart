import 'package:equatable/equatable.dart';

import 'meeting_participant.dart';
import 'meeting_recording.dart';

/// Enum for meeting status
enum MeetingStatus {
  scheduled('scheduled'),
  active('active'),
  ended('ended'),
  cancelled('cancelled');

  const MeetingStatus(this.value);
  final String value;

  static MeetingStatus fromString(String value) {
    return MeetingStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => MeetingStatus.scheduled,
    );
  }
}

/// Domain entity representing a video/audio meeting
class Meeting extends Equatable {
  const Meeting({
    required this.id,
    this.roomId,
    required this.livekitRoomName,
    required this.hostId,
    this.title,
    this.description,
    this.scheduledFor,
    this.startedAt,
    this.endedAt,
    this.recordingUrl,
    this.maxParticipants = 100,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
    this.participants = const [],
    this.recordings = const [],
  });

  /// Unique identifier for the meeting
  final String id;

  /// Associated chat room ID (optional for standalone meetings)
  final String? roomId;

  /// LiveKit room name for WebRTC connection
  final String livekitRoomName;

  /// ID of the user who created/hosts this meeting
  final String hostId;

  /// Human-readable title of the meeting
  final String? title;

  /// Optional description of the meeting
  final String? description;

  /// When the meeting is scheduled to start
  final DateTime? scheduledFor;

  /// When the meeting actually started
  final DateTime? startedAt;

  /// When the meeting ended
  final DateTime? endedAt;

  /// URL to the recording (deprecated - use recordings list)
  final String? recordingUrl;

  /// Maximum number of participants allowed
  final int maxParticipants;

  /// Additional metadata as JSON
  final Map<String, dynamic> metadata;

  /// When the meeting was created
  final DateTime createdAt;

  /// When the meeting was last updated
  final DateTime updatedAt;

  /// List of participants in this meeting
  final List<MeetingParticipant> participants;

  /// List of recordings for this meeting
  final List<MeetingRecording> recordings;

  /// Current status of the meeting
  MeetingStatus get status {
    if (endedAt != null) return MeetingStatus.ended;
    if (startedAt != null) return MeetingStatus.active;
    if (scheduledFor != null && scheduledFor!.isAfter(DateTime.now())) {
      return MeetingStatus.scheduled;
    }
    return MeetingStatus.scheduled;
  }

  /// Whether the meeting is currently active
  bool get isActive => status == MeetingStatus.active;

  /// Whether the meeting has ended
  bool get hasEnded => status == MeetingStatus.ended;

  /// Whether the meeting is scheduled for the future
  bool get isScheduled => status == MeetingStatus.scheduled;

  /// Duration of the meeting in minutes (if ended)
  int? get durationMinutes {
    if (startedAt == null || endedAt == null) return null;
    return endedAt!.difference(startedAt!).inMinutes;
  }

  /// Number of currently active participants
  int get activeParticipantsCount => participants.where((p) => p.isActive).length;

  /// Whether the meeting has reached max capacity
  bool get isAtCapacity => activeParticipantsCount >= maxParticipants;

  /// Active participants (currently in the meeting)
  List<MeetingParticipant> get activeParticipants =>
      participants.where((p) => p.isActive).toList();

  /// Host participant
  MeetingParticipant? get hostParticipant =>
      participants.where((p) => p.role == ParticipantRole.host).firstOrNull;

  /// Admin participants
  List<MeetingParticipant> get adminParticipants =>
      participants.where((p) => p.role == ParticipantRole.admin).toList();

  /// Whether the meeting has any recordings
  bool get hasRecordings => recordings.isNotEmpty;

  /// Completed recordings
  List<MeetingRecording> get completedRecordings =>
      recordings.where((r) => r.isCompleted).toList();

  /// Display title with fallback
  String get displayTitle {
    if (title != null && title!.isNotEmpty) return title!;
    return 'Meeting ${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  @override
  List<Object?> get props => [
        id,
        roomId,
        livekitRoomName,
        hostId,
        title,
        description,
        scheduledFor,
        startedAt,
        endedAt,
        recordingUrl,
        maxParticipants,
        metadata,
        createdAt,
        updatedAt,
        participants,
        recordings,
      ];

  /// Creates a copy of this meeting with updated fields
  Meeting copyWith({
    String? id,
    String? roomId,
    String? livekitRoomName,
    String? hostId,
    String? title,
    String? description,
    DateTime? scheduledFor,
    DateTime? startedAt,
    DateTime? endedAt,
    String? recordingUrl,
    int? maxParticipants,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<MeetingParticipant>? participants,
    List<MeetingRecording>? recordings,
  }) {
    return Meeting(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      livekitRoomName: livekitRoomName ?? this.livekitRoomName,
      hostId: hostId ?? this.hostId,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      recordingUrl: recordingUrl ?? this.recordingUrl,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      participants: participants ?? this.participants,
      recordings: recordings ?? this.recordings,
    );
  }
}