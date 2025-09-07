import 'package:equatable/equatable.dart';
import 'room_type.dart';

/// Domain entity representing a chat room
class Room extends Equatable {
  const Room({
    required this.id,
    required this.name,
    required this.creatorId,
    required this.createdAt,
    this.type = RoomType.group,
    this.description,
    this.avatarUrl,
    this.isActive = true,
    this.participantCount = 0,
    this.lastActivity,
  }) : assert(id.length > 0, 'Room ID cannot be empty'),
       assert(name.length > 0, 'Room name cannot be empty'),
       assert(creatorId.length > 0, 'Creator ID cannot be empty'),
       assert(participantCount >= 0, 'Participant count cannot be negative');

  /// Unique identifier for the room
  final String id;
  
  /// Display name of the room
  final String name;
  
  /// ID of the user who created the room
  final String creatorId;
  
  /// When the room was created
  final DateTime createdAt;
  
  /// Type of room (direct, group, channel)
  final RoomType type;
  
  /// Optional description of the room
  final String? description;
  
  /// URL to room's avatar image
  final String? avatarUrl;
  
  /// Whether the room is currently active
  final bool isActive;
  
  /// Number of participants in the room
  final int participantCount;
  
  /// Timestamp of the last activity in the room
  final DateTime? lastActivity;

  @override
  List<Object?> get props => [
    id,
    name,
    creatorId,
    createdAt,
    type,
    description,
    avatarUrl,
    isActive,
    participantCount,
    lastActivity,
  ];

  /// Creates a copy of this room with updated fields
  Room copyWith({
    String? id,
    String? name,
    String? creatorId,
    DateTime? createdAt,
    RoomType? type,
    String? description,
    String? avatarUrl,
    bool? isActive,
    int? participantCount,
    DateTime? lastActivity,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      creatorId: creatorId ?? this.creatorId,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      description: description ?? this.description,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
      participantCount: participantCount ?? this.participantCount,
      lastActivity: lastActivity ?? this.lastActivity,
    );
  }
}