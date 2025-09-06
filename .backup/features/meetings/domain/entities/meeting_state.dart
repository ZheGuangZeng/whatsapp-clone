import 'package:equatable/equatable.dart';
import 'package:livekit_client/livekit_client.dart' as livekit;

import 'meeting.dart';
import 'meeting_participant.dart';

/// Enum for meeting connection state
enum MeetingConnectionState {
  disconnected('disconnected'),
  connecting('connecting'),
  connected('connected'),
  reconnecting('reconnecting'),
  failed('failed');

  const MeetingConnectionState(this.value);
  final String value;

  static MeetingConnectionState fromString(String value) {
    return MeetingConnectionState.values.firstWhere(
      (state) => state.value == value,
      orElse: () => MeetingConnectionState.disconnected,
    );
  }

  /// Convert from LiveKit ConnectionState
  static MeetingConnectionState fromLiveKit(livekit.ConnectionState state) {
    switch (state) {
      case livekit.ConnectionState.disconnected:
        return MeetingConnectionState.disconnected;
      case livekit.ConnectionState.connecting:
        return MeetingConnectionState.connecting;
      case livekit.ConnectionState.connected:
        return MeetingConnectionState.connected;
      case livekit.ConnectionState.reconnecting:
        return MeetingConnectionState.reconnecting;
    }
  }
}

/// Domain entity representing the real-time state of a meeting
class MeetingState extends Equatable {
  const MeetingState({
    this.meeting,
    this.livekitRoom,
    this.connectionState = MeetingConnectionState.disconnected,
    this.localParticipant,
    this.remoteParticipants = const [],
    this.isAudioEnabled = true,
    this.isVideoEnabled = true,
    this.isMicrophoneMuted = false,
    this.isCameraOff = false,
    this.isScreenSharing = false,
    this.isRecording = false,
    this.dominantSpeaker,
    this.networkQuality,
    this.error,
    this.metadata = const {},
  });

  /// The meeting entity
  final Meeting? meeting;

  /// LiveKit room instance (if connected)
  final livekit.Room? livekitRoom;

  /// Current connection state
  final MeetingConnectionState connectionState;

  /// Local participant (current user)
  final MeetingParticipant? localParticipant;

  /// Remote participants (other users)
  final List<MeetingParticipant> remoteParticipants;

  /// Whether audio input is enabled
  final bool isAudioEnabled;

  /// Whether video input is enabled
  final bool isVideoEnabled;

  /// Whether microphone is muted
  final bool isMicrophoneMuted;

  /// Whether camera is turned off
  final bool isCameraOff;

  /// Whether screen sharing is active
  final bool isScreenSharing;

  /// Whether the meeting is being recorded
  final bool isRecording;

  /// Currently dominant speaker
  final MeetingParticipant? dominantSpeaker;

  /// Network quality indicator
  final livekit.ConnectionQuality? networkQuality;

  /// Current error state (if any)
  final String? error;

  /// Additional runtime metadata
  final Map<String, dynamic> metadata;

  /// Whether connected to the meeting
  bool get isConnected => connectionState == MeetingConnectionState.connected;

  /// Whether currently connecting
  bool get isConnecting => connectionState == MeetingConnectionState.connecting;

  /// Whether disconnected from the meeting
  bool get isDisconnected => connectionState == MeetingConnectionState.disconnected;

  /// Whether reconnecting to the meeting
  bool get isReconnecting => connectionState == MeetingConnectionState.reconnecting;

  /// Whether there's a connection error
  bool get hasConnectionError => connectionState == MeetingConnectionState.failed;

  /// Whether there's an error
  bool get hasError => error != null;

  /// All participants (local + remote)
  List<MeetingParticipant> get allParticipants => [
        if (localParticipant != null) localParticipant!,
        ...remoteParticipants,
      ];

  /// Active participants count
  int get activeParticipantsCount => allParticipants.length;

  /// Whether the meeting has multiple participants
  bool get hasMultipleParticipants => activeParticipantsCount > 1;

  /// Whether the local participant is the host
  bool get isLocalParticipantHost => localParticipant?.isHost ?? false;

  /// Whether the local participant has admin privileges
  bool get hasAdminPrivileges => localParticipant?.hasElevatedPrivileges ?? false;

  /// Whether audio is available (enabled and not muted)
  bool get isAudioActive => isAudioEnabled && !isMicrophoneMuted;

  /// Whether video is available (enabled and not off)
  bool get isVideoActive => isVideoEnabled && !isCameraOff;

  /// Number of participants with video enabled
  int get participantsWithVideo => allParticipants
      .where((p) => p.isVideoEnabled)
      .length;

  /// Number of participants sharing screen
  int get participantsSharingScreen => allParticipants
      .where((p) => p.isScreenSharing)
      .length;

  @override
  List<Object?> get props => [
        meeting,
        livekitRoom,
        connectionState,
        localParticipant,
        remoteParticipants,
        isAudioEnabled,
        isVideoEnabled,
        isMicrophoneMuted,
        isCameraOff,
        isScreenSharing,
        isRecording,
        dominantSpeaker,
        networkQuality,
        error,
        metadata,
      ];

  /// Creates a copy of this state with updated fields
  MeetingState copyWith({
    Meeting? meeting,
    livekit.Room? livekitRoom,
    MeetingConnectionState? connectionState,
    MeetingParticipant? localParticipant,
    List<MeetingParticipant>? remoteParticipants,
    bool? isAudioEnabled,
    bool? isVideoEnabled,
    bool? isMicrophoneMuted,
    bool? isCameraOff,
    bool? isScreenSharing,
    bool? isRecording,
    MeetingParticipant? dominantSpeaker,
    livekit.ConnectionQuality? networkQuality,
    String? error,
    Map<String, dynamic>? metadata,
  }) {
    return MeetingState(
      meeting: meeting ?? this.meeting,
      livekitRoom: livekitRoom ?? this.livekitRoom,
      connectionState: connectionState ?? this.connectionState,
      localParticipant: localParticipant ?? this.localParticipant,
      remoteParticipants: remoteParticipants ?? this.remoteParticipants,
      isAudioEnabled: isAudioEnabled ?? this.isAudioEnabled,
      isVideoEnabled: isVideoEnabled ?? this.isVideoEnabled,
      isMicrophoneMuted: isMicrophoneMuted ?? this.isMicrophoneMuted,
      isCameraOff: isCameraOff ?? this.isCameraOff,
      isScreenSharing: isScreenSharing ?? this.isScreenSharing,
      isRecording: isRecording ?? this.isRecording,
      dominantSpeaker: dominantSpeaker ?? this.dominantSpeaker,
      networkQuality: networkQuality ?? this.networkQuality,
      error: error ?? this.error,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Clear error state
  MeetingState clearError() => copyWith(error: null);

  /// Set error state
  MeetingState withError(String errorMessage) => copyWith(error: errorMessage);
}