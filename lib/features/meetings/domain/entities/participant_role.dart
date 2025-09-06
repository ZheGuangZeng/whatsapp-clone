/// Enum representing the role of a participant in a meeting
enum ParticipantRole {
  /// Host of the meeting with full control
  host,
  
  /// Moderator with some administrative privileges
  moderator,
  
  /// Regular participant with basic privileges
  attendee;

  /// Returns true if this role is a host
  bool get isHost => this == ParticipantRole.host;
  
  /// Returns true if this role can moderate the meeting
  bool get canModerate => this == ParticipantRole.host || 
                         this == ParticipantRole.moderator;
  
  /// Returns true if this role can manage other participants
  bool get canManageParticipants => this == ParticipantRole.host || 
                                   this == ParticipantRole.moderator;
  
  /// Returns true if this role can control others' audio/video
  bool get canControlOthersMedia => this == ParticipantRole.host || 
                                   this == ParticipantRole.moderator;
  
  /// Returns true if this role can end the meeting
  bool get canEndMeeting => this == ParticipantRole.host;
  
  /// Returns true if this role can modify meeting settings
  bool get canModifySettings => this == ParticipantRole.host;
  
  /// Returns true if this role can start recording
  bool get canStartRecording => this == ParticipantRole.host || 
                               this == ParticipantRole.moderator;
}