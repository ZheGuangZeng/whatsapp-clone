import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/meeting_participant.dart';

part 'meeting_participant_model.g.dart';

/// Data model for MeetingParticipant entity with JSON serialization
@JsonSerializable()
class MeetingParticipantModel {
  const MeetingParticipantModel({
    required this.id,
    required this.meetingId,
    required this.userId,
    this.livekitParticipantId,
    required this.role,
    required this.joinedAt,
    this.leftAt,
    this.connectionQuality = 'good',
    this.isAudioEnabled = true,
    this.isVideoEnabled = true,
    this.isScreenSharing = false,
    this.metadata = const {},
    this.displayName,
    this.avatarUrl,
  });

  final String id;
  @JsonKey(name: 'meeting_id')
  final String meetingId;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'livekit_participant_id')
  final String? livekitParticipantId;
  final String role;
  @JsonKey(name: 'joined_at')
  final DateTime joinedAt;
  @JsonKey(name: 'left_at')
  final DateTime? leftAt;
  @JsonKey(name: 'connection_quality')
  final String connectionQuality;
  @JsonKey(name: 'is_audio_enabled')
  final bool isAudioEnabled;
  @JsonKey(name: 'is_video_enabled')
  final bool isVideoEnabled;
  @JsonKey(name: 'is_screen_sharing')
  final bool isScreenSharing;
  final Map<String, dynamic> metadata;
  @JsonKey(name: 'display_name')
  final String? displayName;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;

  /// Creates a MeetingParticipantModel from JSON map
  factory MeetingParticipantModel.fromJson(Map<String, dynamic> json) =>
      _$MeetingParticipantModelFromJson(json);

  /// Converts MeetingParticipantModel to JSON map
  Map<String, dynamic> toJson() => _$MeetingParticipantModelToJson(this);

  /// Creates a MeetingParticipantModel from domain entity
  factory MeetingParticipantModel.fromDomain(MeetingParticipant participant) {
    return MeetingParticipantModel(
      id: participant.id,
      meetingId: participant.meetingId,
      userId: participant.userId,
      livekitParticipantId: participant.livekitParticipantId,
      role: participant.role.value,
      joinedAt: participant.joinedAt,
      leftAt: participant.leftAt,
      connectionQuality: participant.connectionQuality.value,
      isAudioEnabled: participant.isAudioEnabled,
      isVideoEnabled: participant.isVideoEnabled,
      isScreenSharing: participant.isScreenSharing,
      metadata: participant.metadata,
      displayName: participant.displayName,
      avatarUrl: participant.avatarUrl,
    );
  }

  /// Converts to domain entity
  MeetingParticipant toDomain() {
    return MeetingParticipant(
      id: id,
      meetingId: meetingId,
      userId: userId,
      livekitParticipantId: livekitParticipantId,
      role: ParticipantRole.fromString(role),
      joinedAt: joinedAt,
      leftAt: leftAt,
      connectionQuality: ConnectionQuality.fromString(connectionQuality),
      isAudioEnabled: isAudioEnabled,
      isVideoEnabled: isVideoEnabled,
      isScreenSharing: isScreenSharing,
      metadata: metadata,
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
  }

  /// Creates a MeetingParticipantModel from Supabase database row
  factory MeetingParticipantModel.fromSupabase(Map<String, dynamic> json) {
    return MeetingParticipantModel(
      id: json['id'],
      meetingId: json['meeting_id'],
      userId: json['user_id'],
      livekitParticipantId: json['livekit_participant_id'],
      role: json['role'],
      joinedAt: DateTime.parse(json['joined_at']),
      leftAt: json['left_at'] != null
          ? DateTime.parse(json['left_at'])
          : null,
      connectionQuality: json['connection_quality'] ?? 'good',
      isAudioEnabled: json['is_audio_enabled'] ?? true,
      isVideoEnabled: json['is_video_enabled'] ?? true,
      isScreenSharing: json['is_screen_sharing'] ?? false,
      metadata: json['metadata'] ?? {},
      // These fields might come from a joined query with users table
      displayName: json['display_name'],
      avatarUrl: json['avatar_url'],
    );
  }

  /// Converts to Supabase insert format
  Map<String, dynamic> toSupabaseInsert() {
    return {
      'meeting_id': meetingId,
      'user_id': userId,
      'livekit_participant_id': livekitParticipantId,
      'role': role,
      'joined_at': joinedAt.toIso8601String(),
      'left_at': leftAt?.toIso8601String(),
      'connection_quality': connectionQuality,
      'is_audio_enabled': isAudioEnabled,
      'is_video_enabled': isVideoEnabled,
      'is_screen_sharing': isScreenSharing,
      'metadata': metadata,
    };
  }

  /// Converts to Supabase update format
  Map<String, dynamic> toSupabaseUpdate() {
    return {
      if (livekitParticipantId != null)
        'livekit_participant_id': livekitParticipantId,
      'role': role,
      if (leftAt != null) 'left_at': leftAt!.toIso8601String(),
      'connection_quality': connectionQuality,
      'is_audio_enabled': isAudioEnabled,
      'is_video_enabled': isVideoEnabled,
      'is_screen_sharing': isScreenSharing,
      'metadata': metadata,
    };
  }
}