import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/meeting_settings.dart';

part 'meeting_settings_model.g.dart';

/// Data model for MeetingSettings entity with JSON serialization
@JsonSerializable()
class MeetingSettingsModel {
  const MeetingSettingsModel({
    this.maxParticipants = 100,
    this.isRecordingEnabled = false,
    this.isWaitingRoomEnabled = false,
    this.allowScreenShare = true,
    this.allowChat = true,
    this.isPublic = false,
    this.requireApproval = false,
    this.password,
  });

  /// Creates a MeetingSettingsModel from JSON map
  factory MeetingSettingsModel.fromJson(Map<String, dynamic> json) =>
      _$MeetingSettingsModelFromJson(json);

  /// Creates a MeetingSettingsModel from domain entity
  factory MeetingSettingsModel.fromDomain(MeetingSettings settings) {
    return MeetingSettingsModel(
      maxParticipants: settings.maxParticipants,
      isRecordingEnabled: settings.isRecordingEnabled,
      isWaitingRoomEnabled: settings.isWaitingRoomEnabled,
      allowScreenShare: settings.allowScreenShare,
      allowChat: settings.allowChat,
      isPublic: settings.isPublic,
      requireApproval: settings.requireApproval,
      password: settings.password,
    );
  }

  /// Maximum number of participants allowed in the meeting
  final int maxParticipants;
  
  /// Whether recording is enabled for this meeting
  final bool isRecordingEnabled;
  
  /// Whether participants wait in a waiting room before joining
  final bool isWaitingRoomEnabled;
  
  /// Whether screen sharing is allowed for participants
  final bool allowScreenShare;
  
  /// Whether chat is enabled during the meeting
  final bool allowChat;
  
  /// Whether this is a public meeting (anyone can join)
  final bool isPublic;
  
  /// Whether participants require host approval to join
  final bool requireApproval;
  
  /// Optional password to join the meeting
  final String? password;

  /// Converts MeetingSettingsModel to JSON map
  Map<String, dynamic> toJson() => _$MeetingSettingsModelToJson(this);

  /// Converts to domain entity
  MeetingSettings toDomain() {
    return MeetingSettings(
      maxParticipants: maxParticipants,
      isRecordingEnabled: isRecordingEnabled,
      isWaitingRoomEnabled: isWaitingRoomEnabled,
      allowScreenShare: allowScreenShare,
      allowChat: allowChat,
      isPublic: isPublic,
      requireApproval: requireApproval,
      password: password,
    );
  }
}