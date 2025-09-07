import 'package:equatable/equatable.dart';

/// Domain entity representing meeting configuration settings
class MeetingSettings extends Equatable {
  const MeetingSettings({
    this.maxParticipants = 100,
    this.isRecordingEnabled = false,
    this.isWaitingRoomEnabled = false,
    this.allowScreenShare = true,
    this.allowChat = true,
    this.isPublic = false,
    this.requireApproval = false,
    this.password,
  });

  /// Creates default settings for an open meeting
  const MeetingSettings.openMeeting() : 
    maxParticipants = 100,
    isRecordingEnabled = false,
    isWaitingRoomEnabled = false,
    allowScreenShare = true,
    allowChat = true,
    isPublic = true,
    requireApproval = false,
    password = null;

  /// Creates default settings for a secure meeting
  const MeetingSettings.secureMeeting() : 
    maxParticipants = 100,
    isRecordingEnabled = false,
    isWaitingRoomEnabled = true,
    allowScreenShare = true,
    allowChat = true,
    isPublic = false,
    requireApproval = true,
    password = 'secure123';

  /// Creates default settings for a webinar
  const MeetingSettings.webinar() : 
    maxParticipants = 500,
    isRecordingEnabled = true,
    isWaitingRoomEnabled = false,
    allowScreenShare = false,
    allowChat = true,
    isPublic = false,
    requireApproval = true,
    password = null;

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

  /// Returns true if the meeting has a password
  bool get hasPassword => password != null && password!.isNotEmpty;
  
  /// Returns true if the meeting is secure (has password, approval, or waiting room)
  bool get isSecure => hasPassword || requireApproval || isWaitingRoomEnabled;
  
  /// Returns true if anonymous users can join without approval
  bool get allowsAnonymousJoin => isPublic && !requireApproval && !isWaitingRoomEnabled;
  
  /// Returns true if host approval is required for joining
  bool get requiresHostApproval => requireApproval || isWaitingRoomEnabled;
  
  /// Checks if the meeting can accommodate the given number of participants
  bool canAccommodate(int participantCount) => participantCount <= maxParticipants;

  @override
  List<Object?> get props => [
        maxParticipants,
        isRecordingEnabled,
        isWaitingRoomEnabled,
        allowScreenShare,
        allowChat,
        isPublic,
        requireApproval,
        password,
      ];

  /// Creates a copy of this settings with updated fields
  MeetingSettings copyWith({
    int? maxParticipants,
    bool? isRecordingEnabled,
    bool? isWaitingRoomEnabled,
    bool? allowScreenShare,
    bool? allowChat,
    bool? isPublic,
    bool? requireApproval,
    Object? password = _undefined,
  }) {
    return MeetingSettings(
      maxParticipants: maxParticipants ?? this.maxParticipants,
      isRecordingEnabled: isRecordingEnabled ?? this.isRecordingEnabled,
      isWaitingRoomEnabled: isWaitingRoomEnabled ?? this.isWaitingRoomEnabled,
      allowScreenShare: allowScreenShare ?? this.allowScreenShare,
      allowChat: allowChat ?? this.allowChat,
      isPublic: isPublic ?? this.isPublic,
      requireApproval: requireApproval ?? this.requireApproval,
      password: password == _undefined ? this.password : password as String?,
    );
  }
}

const _undefined = Object();