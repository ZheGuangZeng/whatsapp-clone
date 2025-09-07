/// Enum representing the current state of a meeting
enum MeetingState {
  /// Meeting is scheduled but hasn't started yet
  scheduled,
  
  /// Meeting is in waiting room phase (participants waiting for host)
  waiting,
  
  /// Meeting is currently active with participants
  active,
  
  /// Meeting has ended normally
  ended,
  
  /// Meeting was cancelled before starting
  cancelled;

  /// Returns true if the meeting is currently active
  bool get isActive => this == MeetingState.active;
  
  /// Returns true if the meeting has ended
  bool get isEnded => this == MeetingState.ended;
  
  /// Returns true if the meeting is scheduled
  bool get isScheduled => this == MeetingState.scheduled;
  
  /// Returns true if the meeting is cancelled
  bool get isCancelled => this == MeetingState.cancelled;
  
  /// Returns true if the meeting is in waiting room
  bool get isWaiting => this == MeetingState.waiting;
  
  /// Returns true if the meeting can be joined
  bool get canJoin => this == MeetingState.scheduled || 
                     this == MeetingState.waiting || 
                     this == MeetingState.active;
  
  /// Returns true if the meeting can be cancelled
  bool get canCancel => this == MeetingState.scheduled || 
                       this == MeetingState.waiting;
  
  /// Returns true if the meeting can be ended
  bool get canEnd => this == MeetingState.active || 
                    this == MeetingState.waiting;
}