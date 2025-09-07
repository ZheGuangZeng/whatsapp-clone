import 'package:equatable/equatable.dart';

/// Domain entity representing a chat room
class Room extends Equatable {
  const Room({
    required this.id,
    required this.type,
    required this.createdBy,
    required this.createdAt,
    this.name,
    this.description,
    this.avatarUrl,
    this.lastMessageAt,
    this.updatedAt,
  });

  /// Unique identifier for the room
  final String id;
  
  /// Name of the room (for group chats)
  final String? name;
  
  /// Description of the room
  final String? description;
  
  /// Type of room (direct or group)
  final RoomType type;
  
  /// ID of user who created the room
  final String createdBy;
  
  /// Avatar URL for the room
  final String? avatarUrl;
  
  /// Timestamp of the last message
  final DateTime? lastMessageAt;
  
  /// When the room was created
  final DateTime createdAt;
  
  /// When the room was last updated
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    type,
    createdBy,
    avatarUrl,
    lastMessageAt,
    createdAt,
    updatedAt,
  ];

  /// Create a copy of this room with some fields updated
  Room copyWith({
    String? id,
    String? name,
    String? description,
    RoomType? type,
    String? createdBy,
    String? avatarUrl,
    DateTime? lastMessageAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      createdBy: createdBy ?? this.createdBy,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Room type enum
enum RoomType {
  direct,
  group,
}

/// Domain entity for room participants
class RoomParticipant extends Equatable {
  const RoomParticipant({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.leftAt,
    this.isActive = true,
  });

  final String id;
  final String roomId;
  final String userId;
  final ParticipantRole role;
  final DateTime joinedAt;
  final DateTime? leftAt;
  final bool isActive;

  @override
  List<Object?> get props => [
    id,
    roomId,
    userId,
    role,
    joinedAt,
    leftAt,
    isActive,
  ];

  /// Create a copy with some fields updated
  RoomParticipant copyWith({
    String? id,
    String? roomId,
    String? userId,
    ParticipantRole? role,
    DateTime? joinedAt,
    DateTime? leftAt,
    bool? isActive,
  }) {
    return RoomParticipant(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      leftAt: leftAt ?? this.leftAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Participant role in room
enum ParticipantRole {
  admin,
  member,
}