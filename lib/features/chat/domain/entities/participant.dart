import 'package:equatable/equatable.dart';
import 'participant_role.dart';

/// Domain entity representing a participant in a chat room
class Participant extends Equatable {
  const Participant({
    required this.id,
    required this.userId,
    required this.roomId,
    required this.joinedAt,
    this.role = ParticipantRole.member,
    this.isActive = true,
    this.lastActivity,
    this.permissions = const [],
  }) : assert(id.length > 0, 'Participant ID cannot be empty'),
       assert(userId.length > 0, 'User ID cannot be empty'),
       assert(roomId.length > 0, 'Room ID cannot be empty');

  /// Unique identifier for the participant
  final String id;
  
  /// ID of the user this participant represents
  final String userId;
  
  /// ID of the room this participant belongs to
  final String roomId;
  
  /// When the participant joined the room
  final DateTime joinedAt;
  
  /// Role of the participant in the room
  final ParticipantRole role;
  
  /// Whether the participant is currently active
  final bool isActive;
  
  /// Timestamp of the participant's last activity
  final DateTime? lastActivity;
  
  /// List of specific permissions for this participant
  final List<String> permissions;

  @override
  List<Object?> get props => [
    id,
    userId,
    roomId,
    joinedAt,
    role,
    isActive,
    lastActivity,
    permissions,
  ];

  /// Creates a copy of this participant with updated fields
  Participant copyWith({
    String? id,
    String? userId,
    String? roomId,
    DateTime? joinedAt,
    ParticipantRole? role,
    bool? isActive,
    DateTime? lastActivity,
    List<String>? permissions,
  }) {
    return Participant(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      roomId: roomId ?? this.roomId,
      joinedAt: joinedAt ?? this.joinedAt,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      lastActivity: lastActivity ?? this.lastActivity,
      permissions: permissions ?? this.permissions,
    );
  }
}