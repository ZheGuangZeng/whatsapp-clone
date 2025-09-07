import 'package:equatable/equatable.dart';
import 'participant_role.dart';

/// Domain entity representing a participant in a meeting
class MeetingParticipant extends Equatable {
  const MeetingParticipant({
    required this.userId,
    required this.displayName,
    required this.role,
    required this.joinedAt,
    this.leftAt,
    required this.isAudioEnabled,
    required this.isVideoEnabled,
    this.avatarUrl,
  });

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

  /// Returns true if the participant is currently present in the meeting
  bool get isPresent => leftAt == null;
  
  /// Returns the duration of the participant's session (null if still present)
  Duration? get sessionDuration {
    if (leftAt == null) return null;
    return leftAt!.difference(joinedAt);
  }
  
  /// Returns true if this participant is the host
  bool get isHost => role.isHost;
  
  /// Returns true if this participant can moderate the meeting
  bool get canModerate => role.canModerate;
  
  /// Returns true if this participant can manage other participants
  bool get canManageParticipants => role.canManageParticipants;
  
  /// Returns true if this participant can control others' media
  bool get canControlOthersMedia => role.canControlOthersMedia;

  @override
  List<Object?> get props => [
        userId,
        displayName,
        role,
        joinedAt,
        leftAt,
        isAudioEnabled,
        isVideoEnabled,
        avatarUrl,
      ];

  /// Creates a copy of this participant with updated fields
  MeetingParticipant copyWith({
    String? userId,
    String? displayName,
    ParticipantRole? role,
    DateTime? joinedAt,
    DateTime? leftAt,
    bool? isAudioEnabled,
    bool? isVideoEnabled,
    String? avatarUrl,
  }) {
    return MeetingParticipant(
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