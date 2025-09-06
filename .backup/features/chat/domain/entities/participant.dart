import 'package:equatable/equatable.dart';

/// Enum for participant roles in a room
enum ParticipantRole {
  admin('admin'),
  member('member');

  const ParticipantRole(this.value);
  final String value;

  static ParticipantRole fromString(String value) {
    return ParticipantRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => ParticipantRole.member,
    );
  }
}

/// Domain entity representing a room participant
class Participant extends Equatable {
  const Participant({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.displayName,
    this.email,
    this.avatarUrl,
    this.role = ParticipantRole.member,
    required this.joinedAt,
    this.leftAt,
    this.isActive = true,
    this.isOnline = false,
    this.lastSeen,
  });

  /// Unique identifier for the participation record
  final String id;

  /// ID of the room
  final String roomId;

  /// ID of the user
  final String userId;

  /// Display name of the participant
  final String displayName;

  /// Email of the participant
  final String? email;

  /// Avatar URL of the participant
  final String? avatarUrl;

  /// Role of the participant in the room
  final ParticipantRole role;

  /// When the participant joined the room
  final DateTime joinedAt;

  /// When the participant left the room (if they left)
  final DateTime? leftAt;

  /// Whether the participant is still active in the room
  final bool isActive;

  /// Whether the participant is currently online
  final bool isOnline;

  /// When the participant was last seen online
  final DateTime? lastSeen;

  /// Whether the participant is an admin
  bool get isAdmin => role == ParticipantRole.admin;

  /// Whether the participant is a regular member
  bool get isMember => role == ParticipantRole.member;

  /// Whether the participant has left the room
  bool get hasLeft => leftAt != null;

  @override
  List<Object?> get props => [
        id,
        roomId,
        userId,
        displayName,
        email,
        avatarUrl,
        role,
        joinedAt,
        leftAt,
        isActive,
        isOnline,
        lastSeen,
      ];

  /// Creates a copy of this participant with updated fields
  Participant copyWith({
    String? id,
    String? roomId,
    String? userId,
    String? displayName,
    String? email,
    String? avatarUrl,
    ParticipantRole? role,
    DateTime? joinedAt,
    DateTime? leftAt,
    bool? isActive,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return Participant(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      leftAt: leftAt ?? this.leftAt,
      isActive: isActive ?? this.isActive,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}