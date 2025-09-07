import '../../domain/entities/room.dart';
import '../../domain/entities/room_type.dart';

/// Data model for Room with JSON serialization
class RoomModel extends Room {
  const RoomModel({
    required super.id,
    required super.name,
    required super.creatorId,
    required super.createdAt,
    super.type = RoomType.group,
    super.description,
    super.avatarUrl,
    super.isActive = true,
    super.participantCount = 0,
    super.lastActivity,
  });

  /// Create RoomModel from JSON data
  factory RoomModel.fromJson(Map<String, dynamic> json) {
    if (json['id'] == null) {
      throw Exception('Room ID is required');
    }
    if (json['name'] == null) {
      throw Exception('Room name is required');
    }
    if (json['creator_id'] == null) {
      throw Exception('Creator ID is required');
    }
    if (json['created_at'] == null) {
      throw Exception('Created at is required');
    }

    return RoomModel(
      id: json['id'] as String,
      name: json['name'] as String,
      creatorId: json['creator_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      type: _parseRoomType(json['type'] as String?),
      description: json['description'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      participantCount: json['participant_count'] as int? ?? 0,
      lastActivity: json['last_activity'] != null 
        ? DateTime.parse(json['last_activity'] as String)
        : null,
    );
  }

  /// Convert RoomModel to JSON data
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'creator_id': creatorId,
      'created_at': createdAt.toIso8601String(),
      'type': type.name,
      'description': description,
      'avatar_url': avatarUrl,
      'is_active': isActive,
      'participant_count': participantCount,
      'last_activity': lastActivity?.toIso8601String(),
    };
  }

  /// Create RoomModel from Room entity
  factory RoomModel.fromEntity(Room entity) {
    return RoomModel(
      id: entity.id,
      name: entity.name,
      creatorId: entity.creatorId,
      createdAt: entity.createdAt,
      type: entity.type,
      description: entity.description,
      avatarUrl: entity.avatarUrl,
      isActive: entity.isActive,
      participantCount: entity.participantCount,
      lastActivity: entity.lastActivity,
    );
  }

  /// Convert RoomModel to Room entity
  Room toEntity() {
    return Room(
      id: id,
      name: name,
      creatorId: creatorId,
      createdAt: createdAt,
      type: type,
      description: description,
      avatarUrl: avatarUrl,
      isActive: isActive,
      participantCount: participantCount,
      lastActivity: lastActivity,
    );
  }

  /// Helper method to parse room type from string
  static RoomType _parseRoomType(String? type) {
    switch (type) {
      case 'direct':
        return RoomType.direct;
      case 'group':
        return RoomType.group;
      case 'channel':
        return RoomType.channel;
      default:
        return RoomType.group;
    }
  }
}