import 'package:equatable/equatable.dart';
import 'meeting_participant.dart';
import 'meeting_settings.dart';
import 'meeting_state.dart';

/// Domain entity representing a meeting
class Meeting extends Equatable {
  const Meeting({
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
  final MeetingSettings settings;
  
  /// List of participants in the meeting
  final List<MeetingParticipant> participants;

  /// Returns true if the meeting is currently active
  bool get isActive => state.isActive;
  
  /// Returns true if the meeting has ended
  bool get isEnded => state.isEnded;
  
  /// Returns true if the meeting is scheduled
  bool get isScheduled => state.isScheduled;
  
  /// Returns the number of participants in the meeting
  int get participantCount => participants.length;
  
  /// Returns the host participant if they are in the meeting
  MeetingParticipant? get hostParticipant {
    try {
      return participants.firstWhere((p) => p.userId == hostId);
    } catch (e) {
      return null;
    }
  }
  
  /// Returns the duration of the meeting if it has ended
  Duration? get duration {
    if (actualStartTime == null || actualEndTime == null) return null;
    return actualEndTime!.difference(actualStartTime!);
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        hostId,
        roomId,
        createdAt,
        scheduledStartTime,
        actualStartTime,
        actualEndTime,
        state,
        settings,
        participants,
      ];

  /// Creates a copy of this meeting with updated fields
  Meeting copyWith({
    String? id,
    String? title,
    String? description,
    String? hostId,
    String? roomId,
    DateTime? createdAt,
    DateTime? scheduledStartTime,
    DateTime? actualStartTime,
    DateTime? actualEndTime,
    MeetingState? state,
    MeetingSettings? settings,
    List<MeetingParticipant>? participants,
  }) {
    return Meeting(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      hostId: hostId ?? this.hostId,
      roomId: roomId ?? this.roomId,
      createdAt: createdAt ?? this.createdAt,
      scheduledStartTime: scheduledStartTime ?? this.scheduledStartTime,
      actualStartTime: actualStartTime ?? this.actualStartTime,
      actualEndTime: actualEndTime ?? this.actualEndTime,
      state: state ?? this.state,
      settings: settings ?? this.settings,
      participants: participants ?? this.participants,
    );
  }
}