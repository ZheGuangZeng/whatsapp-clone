import '../../domain/entities/participant.dart';
import '../../domain/entities/participant_role.dart';

/// Data model for Participant with JSON serialization
class ParticipantModel extends Participant {
  const ParticipantModel({
    required super.id,
    required super.userId,
    required super.roomId,
    required super.joinedAt,
    super.role = ParticipantRole.member,
    super.isActive = true,
    super.lastActivity,
    super.permissions = const [],
  });

  /// Create ParticipantModel from Participant entity
  factory ParticipantModel.fromEntity(Participant entity) {
    return ParticipantModel(
      id: entity.id,
      userId: entity.userId,
      roomId: entity.roomId,
      joinedAt: entity.joinedAt,
      role: entity.role,
      isActive: entity.isActive,
      lastActivity: entity.lastActivity,
      permissions: entity.permissions,
    );
  }

  /// Create ParticipantModel from JSON data
  factory ParticipantModel.fromJson(Map<String, dynamic> json) {
    if (json['id'] == null) {
      throw Exception('Participant ID is required');
    }
    if (json['user_id'] == null) {
      throw Exception('User ID is required');
    }
    if (json['room_id'] == null) {
      throw Exception('Room ID is required');
    }
    if (json['joined_at'] == null) {
      throw Exception('Joined at is required');
    }

    return ParticipantModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      roomId: json['room_id'] as String,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      role: _parseParticipantRole(json['role'] as String?),
      isActive: json['is_active'] as bool? ?? true,
      lastActivity: json['last_activity'] != null 
        ? DateTime.parse(json['last_activity'] as String)
        : null,
      permissions: _parsePermissions(json['permissions']),
    );
  }

  /// Convert ParticipantModel to JSON data
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'room_id': roomId,
      'joined_at': joinedAt.toIso8601String(),
      'role': role.name,
      'is_active': isActive,
      'last_activity': lastActivity?.toIso8601String(),
      'permissions': permissions,
    };
  }

  /// Convert ParticipantModel to Participant entity
  Participant toEntity() {
    return Participant(
      id: id,
      userId: userId,
      roomId: roomId,
      joinedAt: joinedAt,
      role: role,
      isActive: isActive,
      lastActivity: lastActivity,
      permissions: permissions,
    );
  }

  /// Helper method to parse participant role from string
  static ParticipantRole _parseParticipantRole(String? role) {
    switch (role) {
      case 'member':
        return ParticipantRole.member;
      case 'moderator':
        return ParticipantRole.moderator;
      case 'admin':
        return ParticipantRole.admin;
      default:
        return ParticipantRole.member;
    }
  }

  /// Helper method to parse permissions list
  static List<String> _parsePermissions(dynamic permissions) {
    if (permissions == null) {
      return const <String>[];
    }
    
    if (permissions is List) {
      return permissions.cast<String>();
    }
    
    return const <String>[];
  }
}