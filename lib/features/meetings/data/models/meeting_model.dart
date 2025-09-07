import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/meeting.dart';
import '../../domain/entities/meeting_state.dart';
import 'meeting_participant_model.dart';
import 'meeting_settings_model.dart';

part 'meeting_model.g.dart';

/// Data model for Meeting entity with JSON serialization
@JsonSerializable(explicitToJson: true)
class MeetingModel {
  const MeetingModel({
    required this.id,
    required this.title,
    this.description,
    required this.hostId,
    required this.roomId,
    required this.createdAt,
    this.scheduledStartTime,
    this.actualStartTime,
    this.actualEndTime,
    required this.state,
    required this.settings,
    required this.participants,
  });

  /// Creates a MeetingModel from JSON map
  factory MeetingModel.fromJson(Map<String, dynamic> json) =>
      _$MeetingModelFromJson(json);

  /// Creates a MeetingModel from Supabase row
  factory MeetingModel.fromSupabaseRow(
    Map<String, dynamic> meetingRow,
    List<Map<String, dynamic>> participantRows,
  ) {
    return MeetingModel(
      id: meetingRow['id'] as String,
      title: meetingRow['title'] as String,
      description: meetingRow['description'] as String?,
      hostId: meetingRow['host_id'] as String,
      roomId: meetingRow['room_id'] as String,
      createdAt: DateTime.parse(meetingRow['created_at'] as String),
      scheduledStartTime: meetingRow['scheduled_start_time'] != null
          ? DateTime.parse(meetingRow['scheduled_start_time'] as String)
          : null,
      actualStartTime: meetingRow['actual_start_time'] != null
          ? DateTime.parse(meetingRow['actual_start_time'] as String)
          : null,
      actualEndTime: meetingRow['actual_end_time'] != null
          ? DateTime.parse(meetingRow['actual_end_time'] as String)
          : null,
      state: MeetingState.values.firstWhere(
        (s) => s.name == meetingRow['state'],
      ),
      settings: MeetingSettingsModel(
        maxParticipants: meetingRow['max_participants'] as int? ?? 100,
        isRecordingEnabled: meetingRow['is_recording_enabled'] as bool? ?? false,
        isWaitingRoomEnabled: meetingRow['is_waiting_room_enabled'] as bool? ?? false,
        allowScreenShare: meetingRow['allow_screen_share'] as bool? ?? true,
        allowChat: meetingRow['allow_chat'] as bool? ?? true,
        isPublic: meetingRow['is_public'] as bool? ?? false,
        requireApproval: meetingRow['require_approval'] as bool? ?? false,
        password: meetingRow['password'] as String?,
      ),
      participants: participantRows
          .map((row) => MeetingParticipantModel.fromSupabaseRow(row))
          .toList(),
    );
  }

  /// Creates a MeetingModel from domain entity
  factory MeetingModel.fromDomain(Meeting meeting) {
    return MeetingModel(
      id: meeting.id,
      title: meeting.title,
      description: meeting.description,
      hostId: meeting.hostId,
      roomId: meeting.roomId,
      createdAt: meeting.createdAt,
      scheduledStartTime: meeting.scheduledStartTime,
      actualStartTime: meeting.actualStartTime,
      actualEndTime: meeting.actualEndTime,
      state: meeting.state,
      settings: MeetingSettingsModel.fromDomain(meeting.settings),
      participants: meeting.participants
          .map((p) => MeetingParticipantModel.fromDomain(p))
          .toList(),
    );
  }

  /// Unique identifier for the meeting
  final String id;
  
  /// Title of the meeting
  final String title;
  
  /// Optional description of the meeting
  final String? description;
  
  /// ID of the user who is hosting the meeting
  final String hostId;
  
  /// ID of the room/channel where the meeting takes place
  final String roomId;
  
  /// When the meeting was created
  final DateTime createdAt;
  
  /// When the meeting is scheduled to start (optional for instant meetings)
  final DateTime? scheduledStartTime;
  
  /// When the meeting actually started
  final DateTime? actualStartTime;
  
  /// When the meeting actually ended
  final DateTime? actualEndTime;
  
  /// Current state of the meeting
  final MeetingState state;
  
  /// Meeting configuration settings
  final MeetingSettingsModel settings;
  
  /// List of participants in the meeting
  final List<MeetingParticipantModel> participants;

  /// Converts MeetingModel to JSON map
  Map<String, dynamic> toJson() => _$MeetingModelToJson(this);

  /// Converts to Supabase row format
  Map<String, dynamic> toSupabaseRow() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'host_id': hostId,
      'room_id': roomId,
      'created_at': createdAt.toIso8601String(),
      'scheduled_start_time': scheduledStartTime?.toIso8601String(),
      'actual_start_time': actualStartTime?.toIso8601String(),
      'actual_end_time': actualEndTime?.toIso8601String(),
      'state': state.name,
      'max_participants': settings.maxParticipants,
      'is_recording_enabled': settings.isRecordingEnabled,
      'is_waiting_room_enabled': settings.isWaitingRoomEnabled,
      'allow_screen_share': settings.allowScreenShare,
      'allow_chat': settings.allowChat,
      'is_public': settings.isPublic,
      'require_approval': settings.requireApproval,
      'password': settings.password,
    };
  }

  /// Converts to domain entity
  Meeting toDomain() {
    return Meeting(
      id: id,
      title: title,
      description: description,
      hostId: hostId,
      roomId: roomId,
      createdAt: createdAt,
      scheduledStartTime: scheduledStartTime,
      actualStartTime: actualStartTime,
      actualEndTime: actualEndTime,
      state: state,
      settings: settings.toDomain(),
      participants: participants.map((p) => p.toDomain()).toList(),
    );
  }
}