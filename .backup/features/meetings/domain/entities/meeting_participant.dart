import 'package:equatable/equatable.dart';

/// Enum for participant roles in a meeting
enum ParticipantRole {
  host('host'),
  admin('admin'),
  participant('participant');

  const ParticipantRole(this.value);
  final String value;

  static ParticipantRole fromString(String value) {
    return ParticipantRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => ParticipantRole.participant,
    );
  }
}

/// Enum for connection quality
enum ConnectionQuality {
  excellent('excellent'),
  good('good'),
  poor('poor'),
  lost('lost');

  const ConnectionQuality(this.value);
  final String value;

  static ConnectionQuality fromString(String value) {
    return ConnectionQuality.values.firstWhere(
      (quality) => quality.value == value,
      orElse: () => ConnectionQuality.good,
    );
  }

  /// Get icon representation of connection quality
  String get icon {
    switch (this) {
      case ConnectionQuality.excellent:
        return '📶';
      case ConnectionQuality.good:
        return '📶';
      case ConnectionQuality.poor:
        return '📶';
      case ConnectionQuality.lost:
        return '❌';
    }
  }
}

/// Domain entity representing a meeting participant
class MeetingParticipant extends Equatable {
  const MeetingParticipant({
    required this.id,
    required this.meetingId,
    required this.userId,
    this.livekitParticipantId,
    required this.role,
    required this.joinedAt,
    this.leftAt,
    this.connectionQuality = ConnectionQuality.good,
    this.isAudioEnabled = true,
    this.isVideoEnabled = true,
    this.isScreenSharing = false,
    this.metadata = const {},
    this.displayName,
    this.avatarUrl,
  });

  /// Unique identifier for this participant record
  final String id;

  /// ID of the meeting this participant belongs to
  final String meetingId;

  /// ID of the user participating
  final String userId;

  /// LiveKit participant ID for WebRTC connection
  final String? livekitParticipantId;

  /// Role of the participant in the meeting
  final ParticipantRole role;

  /// When the participant joined the meeting
  final DateTime joinedAt;

  /// When the participant left the meeting (null if still active)
  final DateTime? leftAt;

  /// Current connection quality
  final ConnectionQuality connectionQuality;

  /// Whether the participant's audio is enabled
  final bool isAudioEnabled;

  /// Whether the participant's video is enabled
  final bool isVideoEnabled;

  /// Whether the participant is sharing their screen
  final bool isScreenSharing;

  /// Additional metadata as JSON
  final Map<String, dynamic> metadata;

  /// Display name of the participant (cached for performance)
  final String? displayName;

  /// Avatar URL of the participant (cached for performance)
  final String? avatarUrl;

  /// Whether the participant is currently active in the meeting
  bool get isActive => leftAt == null;

  /// Whether this participant has left the meeting
  bool get hasLeft => leftAt != null;

  /// Whether the participant is the host
  bool get isHost => role == ParticipantRole.host;

  /// Whether the participant is an admin
  bool get isAdmin => role == ParticipantRole.admin;

  /// Whether the participant has elevated privileges (host or admin)
  bool get hasElevatedPrivileges => isHost || isAdmin;

  /// Duration of participation in minutes (if left)
  int? get participationMinutes {
    final endTime = leftAt ?? DateTime.now();
    return endTime.difference(joinedAt).inMinutes;
  }

  /// Whether the participant has good connection quality
  bool get hasGoodConnection => 
      connectionQuality == ConnectionQuality.excellent ||
      connectionQuality == ConnectionQuality.good;

  /// Whether the participant has poor connection
  bool get hasPoorConnection => 
      connectionQuality == ConnectionQuality.poor ||
      connectionQuality == ConnectionQuality.lost;

  /// Whether the participant is contributing media (audio or video)
  bool get isContributingMedia => isAudioEnabled || isVideoEnabled || isScreenSharing;

  /// Display name with fallback
  String get displayNameOrFallback => displayName ?? 'Participant';

  @override
  List<Object?> get props => [
        id,
        meetingId,
        userId,
        livekitParticipantId,
        role,
        joinedAt,
        leftAt,
        connectionQuality,
        isAudioEnabled,
        isVideoEnabled,
        isScreenSharing,
        metadata,
        displayName,
        avatarUrl,
      ];

  /// Creates a copy of this participant with updated fields
  MeetingParticipant copyWith({
    String? id,
    String? meetingId,
    String? userId,
    String? livekitParticipantId,
    ParticipantRole? role,
    DateTime? joinedAt,
    DateTime? leftAt,
    ConnectionQuality? connectionQuality,
    bool? isAudioEnabled,
    bool? isVideoEnabled,
    bool? isScreenSharing,
    Map<String, dynamic>? metadata,
    String? displayName,
    String? avatarUrl,
  }) {
    return MeetingParticipant(
      id: id ?? this.id,
      meetingId: meetingId ?? this.meetingId,
      userId: userId ?? this.userId,
      livekitParticipantId: livekitParticipantId ?? this.livekitParticipantId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      leftAt: leftAt ?? this.leftAt,
      connectionQuality: connectionQuality ?? this.connectionQuality,
      isAudioEnabled: isAudioEnabled ?? this.isAudioEnabled,
      isVideoEnabled: isVideoEnabled ?? this.isVideoEnabled,
      isScreenSharing: isScreenSharing ?? this.isScreenSharing,
      metadata: metadata ?? this.metadata,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}