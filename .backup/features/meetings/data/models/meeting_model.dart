import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/meeting.dart';
import '../../domain/entities/meeting_participant.dart';
import '../../domain/entities/meeting_recording.dart';
import 'meeting_participant_model.dart';
import 'meeting_recording_model.dart';

part 'meeting_model.g.dart';

/// Data model for Meeting entity with JSON serialization
@JsonSerializable()
class MeetingModel {
  const MeetingModel({
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

  final String id;
  @JsonKey(name: 'room_id')
  final String? roomId;
  @JsonKey(name: 'livekit_room_name')
  final String livekitRoomName;
  @JsonKey(name: 'host_id')
  final String hostId;
  final String? title;
  final String? description;
  @JsonKey(name: 'scheduled_for')
  final DateTime? scheduledFor;
  @JsonKey(name: 'started_at')
  final DateTime? startedAt;
  @JsonKey(name: 'ended_at')
  final DateTime? endedAt;
  @JsonKey(name: 'recording_url')
  final String? recordingUrl;
  @JsonKey(name: 'max_participants')
  final int maxParticipants;
  final Map<String, dynamic> metadata;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  final List<MeetingParticipantModel> participants;
  final List<MeetingRecordingModel> recordings;

  /// Creates a MeetingModel from JSON map
  factory MeetingModel.fromJson(Map<String, dynamic> json) =>
      _$MeetingModelFromJson(json);

  /// Converts MeetingModel to JSON map
  Map<String, dynamic> toJson() => _$MeetingModelToJson(this);

  /// Creates a MeetingModel from domain entity
  factory MeetingModel.fromDomain(Meeting meeting) {
    return MeetingModel(
      id: meeting.id,
      roomId: meeting.roomId,
      livekitRoomName: meeting.livekitRoomName,
      hostId: meeting.hostId,
      title: meeting.title,
      description: meeting.description,
      scheduledFor: meeting.scheduledFor,
      startedAt: meeting.startedAt,
      endedAt: meeting.endedAt,
      recordingUrl: meeting.recordingUrl,
      maxParticipants: meeting.maxParticipants,
      metadata: meeting.metadata,
      createdAt: meeting.createdAt,
      updatedAt: meeting.updatedAt,
      participants: meeting.participants
          .map((p) => MeetingParticipantModel.fromDomain(p))
          .toList(),
      recordings: meeting.recordings
          .map((r) => MeetingRecordingModel.fromDomain(r))
          .toList(),
    );
  }

  /// Converts to domain entity
  Meeting toDomain() {
    return Meeting(
      id: id,
      roomId: roomId,
      livekitRoomName: livekitRoomName,
      hostId: hostId,
      title: title,
      description: description,
      scheduledFor: scheduledFor,
      startedAt: startedAt,
      endedAt: endedAt,
      recordingUrl: recordingUrl,
      maxParticipants: maxParticipants,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
      participants: participants.map((p) => p.toDomain()).toList(),
      recordings: recordings.map((r) => r.toDomain()).toList(),
    );
  }

  /// Creates a MeetingModel from Supabase database row
  factory MeetingModel.fromSupabase(Map<String, dynamic> json) {
    // Handle participants and recordings which might be separate queries
    final participantsData = json['participants'] as List<dynamic>? ?? [];
    final recordingsData = json['recordings'] as List<dynamic>? ?? [];

    return MeetingModel(
      id: json['id'],
      roomId: json['room_id'],
      livekitRoomName: json['livekit_room_name'],
      hostId: json['host_id'],
      title: json['title'],
      description: json['description'],
      scheduledFor: json['scheduled_for'] != null
          ? DateTime.parse(json['scheduled_for'])
          : null,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'])
          : null,
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'])
          : null,
      recordingUrl: json['recording_url'],
      maxParticipants: json['max_participants'] ?? 100,
      metadata: json['metadata'] ?? {},
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      participants: participantsData
          .map((p) => MeetingParticipantModel.fromSupabase(p))
          .toList(),
      recordings: recordingsData
          .map((r) => MeetingRecordingModel.fromSupabase(r))
          .toList(),
    );
  }

  /// Converts to Supabase insert format
  Map<String, dynamic> toSupabaseInsert() {
    return {
      'room_id': roomId,
      'livekit_room_name': livekitRoomName,
      'host_id': hostId,
      'title': title,
      'description': description,
      'scheduled_for': scheduledFor?.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'recording_url': recordingUrl,
      'max_participants': maxParticipants,
      'metadata': metadata,
    };
  }

  /// Converts to Supabase update format
  Map<String, dynamic> toSupabaseUpdate() {
    return {
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (scheduledFor != null) 'scheduled_for': scheduledFor!.toIso8601String(),
      if (startedAt != null) 'started_at': startedAt!.toIso8601String(),
      if (endedAt != null) 'ended_at': endedAt!.toIso8601String(),
      if (recordingUrl != null) 'recording_url': recordingUrl,
      'max_participants': maxParticipants,
      'metadata': metadata,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}