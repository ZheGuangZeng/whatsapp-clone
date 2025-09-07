import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/meeting_participant.dart';
import '../../domain/entities/participant_role.dart';

part 'meeting_participant_model.g.dart';

/// Data model for MeetingParticipant entity with JSON serialization
@JsonSerializable()
class MeetingParticipantModel {
  const MeetingParticipantModel({
    required this.userId,
    required this.displayName,
    required this.role,
    required this.joinedAt,
    this.leftAt,
    required this.isAudioEnabled,
    required this.isVideoEnabled,
    this.avatarUrl,
  });

  /// Creates a MeetingParticipantModel from JSON map
  factory MeetingParticipantModel.fromJson(Map<String, dynamic> json) =>
      _$MeetingParticipantModelFromJson(json);

  /// Creates a MeetingParticipantModel from Supabase participant row
  factory MeetingParticipantModel.fromSupabaseRow(Map<String, dynamic> row) {
    return MeetingParticipantModel(
      userId: row['user_id'] as String,
      displayName: row['display_name'] as String,
      role: ParticipantRole.values.firstWhere(
        (r) => r.name == row['role'],
      ),
      joinedAt: DateTime.parse(row['joined_at'] as String),
      leftAt: row['left_at'] != null 
          ? DateTime.parse(row['left_at'] as String) 
          : null,
      isAudioEnabled: row['is_audio_enabled'] as bool,
      isVideoEnabled: row['is_video_enabled'] as bool,
      avatarUrl: row['avatar_url'] as String?,
    );
  }

  /// Creates a MeetingParticipantModel from domain entity
  factory MeetingParticipantModel.fromDomain(MeetingParticipant participant) {
    return MeetingParticipantModel(
      userId: participant.userId,
      displayName: participant.displayName,
      role: participant.role,
      joinedAt: participant.joinedAt,
      leftAt: participant.leftAt,
      isAudioEnabled: participant.isAudioEnabled,
      isVideoEnabled: participant.isVideoEnabled,
      avatarUrl: participant.avatarUrl,
    );
  }

  /// Unique identifier for the user
  final String userId;
  
  /// Display name of the participant
  final String displayName;
  
  /// Role of the participant in the meeting
  final ParticipantRole role;
  
  /// When the participant joined the meeting
  final DateTime joinedAt;
  
  /// When the participant left the meeting (null if still present)
  final DateTime? leftAt;
  
  /// Whether the participant's audio is enabled
  final bool isAudioEnabled;
  
  /// Whether the participant's video is enabled
  final bool isVideoEnabled;
  
  /// URL to participant's avatar image
  final String? avatarUrl;

  /// Converts MeetingParticipantModel to JSON map
  Map<String, dynamic> toJson() => _$MeetingParticipantModelToJson(this);

  /// Converts to Supabase row format
  Map<String, dynamic> toSupabaseRow() {
    return {
      'user_id': userId,
      'display_name': displayName,
      'role': role.name,
      'joined_at': joinedAt.toIso8601String(),
      'left_at': leftAt?.toIso8601String(),
      'is_audio_enabled': isAudioEnabled,
      'is_video_enabled': isVideoEnabled,
      'avatar_url': avatarUrl,
    };
  }

  /// Converts to domain entity
  MeetingParticipant toDomain() {
    return MeetingParticipant(
      userId: userId,
      displayName: displayName,
      role: role,
      joinedAt: joinedAt,
      leftAt: leftAt,
      isAudioEnabled: isAudioEnabled,
      isVideoEnabled: isVideoEnabled,
      avatarUrl: avatarUrl,
    );
  }

  /// Creates a copy of this participant with updated fields
  MeetingParticipantModel copyWith({
    String? userId,
    String? displayName,
    ParticipantRole? role,
    DateTime? joinedAt,
    DateTime? leftAt,
    bool? isAudioEnabled,
    bool? isVideoEnabled,
    String? avatarUrl,
  }) {
    return MeetingParticipantModel(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      leftAt: leftAt ?? this.leftAt,
      isAudioEnabled: isAudioEnabled ?? this.isAudioEnabled,
      isVideoEnabled: isVideoEnabled ?? this.isVideoEnabled,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}