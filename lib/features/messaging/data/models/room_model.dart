import '../../domain/entities/room.dart';

/// Data model for Room entity with JSON serialization
class RoomModel extends Room {
  const RoomModel({
    required super.id,
    required super.type,
    required super.createdBy,
    required super.createdAt,
    super.name,
    super.description,
    super.avatarUrl,
    super.lastMessageAt,
    super.updatedAt,
  });

  /// Create RoomModel from JSON
  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] as String,
      name: json['name'] as String?,
      description: json['description'] as String?,
      type: RoomType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => RoomType.direct,
      ),
      createdBy: json['created_by'] as String,
      avatarUrl: json['avatar_url'] as String?,
      lastMessageAt: json['last_message_at'] != null
        ? DateTime.parse(json['last_message_at'] as String)
        : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
        ? DateTime.parse(json['updated_at'] as String)
        : null,
    );
  }

  /// Create RoomModel from domain entity
  factory RoomModel.fromEntity(Room room) {
    return RoomModel(
      id: room.id,
      name: room.name,
      description: room.description,
      type: room.type,
      createdBy: room.createdBy,
      avatarUrl: room.avatarUrl,
      lastMessageAt: room.lastMessageAt,
      createdAt: room.createdAt,
      updatedAt: room.updatedAt,
    );
  }

  /// Convert RoomModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'created_by': createdBy,
      'avatar_url': avatarUrl,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Convert to domain entity
  Room toEntity() {
    return Room(
      id: id,
      name: name,
      description: description,
      type: type,
      createdBy: createdBy,
      avatarUrl: avatarUrl,
      lastMessageAt: lastMessageAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Data model for RoomParticipant entity
class RoomParticipantModel extends RoomParticipant {
  const RoomParticipantModel({
    required super.id,
    required super.roomId,
    required super.userId,
    required super.role,
    required super.joinedAt,
    super.leftAt,
    super.isActive,
  });

  /// Create from JSON
  factory RoomParticipantModel.fromJson(Map<String, dynamic> json) {
    return RoomParticipantModel(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      userId: json['user_id'] as String,
      role: ParticipantRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => ParticipantRole.member,
      ),
      joinedAt: DateTime.parse(json['joined_at'] as String),
      leftAt: json['left_at'] != null
        ? DateTime.parse(json['left_at'] as String)
        : null,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// Create from entity
  factory RoomParticipantModel.fromEntity(RoomParticipant participant) {
    return RoomParticipantModel(
      id: participant.id,
      roomId: participant.roomId,
      userId: participant.userId,
      role: participant.role,
      joinedAt: participant.joinedAt,
      leftAt: participant.leftAt,
      isActive: participant.isActive,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'user_id': userId,
      'role': role.name,
      'joined_at': joinedAt.toIso8601String(),
      'left_at': leftAt?.toIso8601String(),
      'is_active': isActive,
    };
  }

  /// Convert to entity
  RoomParticipant toEntity() {
    return RoomParticipant(
      id: id,
      roomId: roomId,
      userId: userId,
      role: role,
      joinedAt: joinedAt,
      leftAt: leftAt,
      isActive: isActive,
    );
  }
}