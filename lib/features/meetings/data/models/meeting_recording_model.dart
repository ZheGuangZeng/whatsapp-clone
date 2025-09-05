import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/meeting_recording.dart';

part 'meeting_recording_model.g.dart';

/// Data model for MeetingRecording entity with JSON serialization
@JsonSerializable()
class MeetingRecordingModel {
  const MeetingRecordingModel({
    required this.id,
    required this.meetingId,
    required this.livekitEgressId,
    this.fileUrl,
    this.fileSize,
    this.durationSeconds,
    this.status = 'processing',
    required this.startedAt,
    this.completedAt,
    this.metadata = const {},
  });

  final String id;
  @JsonKey(name: 'meeting_id')
  final String meetingId;
  @JsonKey(name: 'livekit_egress_id')
  final String livekitEgressId;
  @JsonKey(name: 'file_url')
  final String? fileUrl;
  @JsonKey(name: 'file_size')
  final int? fileSize;
  @JsonKey(name: 'duration_seconds')
  final int? durationSeconds;
  final String status;
  @JsonKey(name: 'started_at')
  final DateTime startedAt;
  @JsonKey(name: 'completed_at')
  final DateTime? completedAt;
  final Map<String, dynamic> metadata;

  /// Creates a MeetingRecordingModel from JSON map
  factory MeetingRecordingModel.fromJson(Map<String, dynamic> json) =>
      _$MeetingRecordingModelFromJson(json);

  /// Converts MeetingRecordingModel to JSON map
  Map<String, dynamic> toJson() => _$MeetingRecordingModelToJson(this);

  /// Creates a MeetingRecordingModel from domain entity
  factory MeetingRecordingModel.fromDomain(MeetingRecording recording) {
    return MeetingRecordingModel(
      id: recording.id,
      meetingId: recording.meetingId,
      livekitEgressId: recording.livekitEgressId,
      fileUrl: recording.fileUrl,
      fileSize: recording.fileSize,
      durationSeconds: recording.durationSeconds,
      status: recording.status.value,
      startedAt: recording.startedAt,
      completedAt: recording.completedAt,
      metadata: recording.metadata,
    );
  }

  /// Converts to domain entity
  MeetingRecording toDomain() {
    return MeetingRecording(
      id: id,
      meetingId: meetingId,
      livekitEgressId: livekitEgressId,
      fileUrl: fileUrl,
      fileSize: fileSize,
      durationSeconds: durationSeconds,
      status: RecordingStatus.fromString(status),
      startedAt: startedAt,
      completedAt: completedAt,
      metadata: metadata,
    );
  }

  /// Creates a MeetingRecordingModel from Supabase database row
  factory MeetingRecordingModel.fromSupabase(Map<String, dynamic> json) {
    return MeetingRecordingModel(
      id: json['id'],
      meetingId: json['meeting_id'],
      livekitEgressId: json['livekit_egress_id'],
      fileUrl: json['file_url'],
      fileSize: json['file_size'],
      durationSeconds: json['duration_seconds'],
      status: json['status'] ?? 'processing',
      startedAt: DateTime.parse(json['started_at']),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      metadata: json['metadata'] ?? {},
    );
  }

  /// Converts to Supabase insert format
  Map<String, dynamic> toSupabaseInsert() {
    return {
      'meeting_id': meetingId,
      'livekit_egress_id': livekitEgressId,
      'file_url': fileUrl,
      'file_size': fileSize,
      'duration_seconds': durationSeconds,
      'status': status,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Converts to Supabase update format
  Map<String, dynamic> toSupabaseUpdate() {
    return {
      if (fileUrl != null) 'file_url': fileUrl,
      if (fileSize != null) 'file_size': fileSize,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      'status': status,
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      'metadata': metadata,
    };
  }
}