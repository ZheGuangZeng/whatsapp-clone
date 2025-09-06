import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/participant.dart';

part 'participant_model.g.dart';

/// Data model for Participant entity with JSON serialization
@JsonSerializable()
class ParticipantModel extends Participant {
  const ParticipantModel({
    required super.id,
    required super.roomId,
    required super.userId,
    required super.displayName,
    super.email,
    super.avatarUrl,
    super.role,
    required super.joinedAt,
    super.leftAt,
    super.isActive,
    super.isOnline,
    super.lastSeen,
  });

  /// Creates ParticipantModel from JSON
  factory ParticipantModel.fromJson(Map<String, dynamic> json) =>
      _$ParticipantModelFromJson(json);

  /// Creates ParticipantModel from domain entity
  factory ParticipantModel.fromEntity(Participant participant) =>
      ParticipantModel(
        id: participant.id,
        roomId: participant.roomId,
        userId: participant.userId,
        displayName: participant.displayName,
        email: participant.email,
        avatarUrl: participant.avatarUrl,
        role: participant.role,
        joinedAt: participant.joinedAt,
        leftAt: participant.leftAt,
        isActive: participant.isActive,
        isOnline: participant.isOnline,
        lastSeen: participant.lastSeen,
      );

  /// Creates ParticipantModel from Supabase response
  factory ParticipantModel.fromSupabase(Map<String, dynamic> data) =>
      ParticipantModel(
        id: data['id'] as String,
        roomId: data['room_id'] as String,
        userId: data['user_id'] as String,
        displayName: data['display_name'] as String? ?? 'Unknown User',
        email: data['email'] as String?,
        avatarUrl: data['avatar_url'] as String?,
        role: ParticipantRole.fromString(data['role'] as String? ?? 'member'),
        joinedAt: DateTime.parse(data['joined_at'] as String),
        leftAt: data['left_at'] != null
            ? DateTime.parse(data['left_at'] as String)
            : null,
        isActive: data['is_active'] as bool? ?? true,
        isOnline: data['is_online'] as bool? ?? false,
        lastSeen: data['last_seen'] != null
            ? DateTime.parse(data['last_seen'] as String)
            : null,
      );

  /// Creates ParticipantModel from joined Supabase query with user data
  factory ParticipantModel.fromSupabaseWithUser(Map<String, dynamic> data) =>
      ParticipantModel(
        id: data['id'] as String,
        roomId: data['room_id'] as String,
        userId: data['user_id'] as String,
        displayName: data['users']?['display_name'] as String? ?? 
                    data['users']?['email'] as String? ?? 
                    'Unknown User',
        email: data['users']?['email'] as String?,
        avatarUrl: data['users']?['avatar_url'] as String?,
        role: ParticipantRole.fromString(data['role'] as String? ?? 'member'),
        joinedAt: DateTime.parse(data['joined_at'] as String),
        leftAt: data['left_at'] != null
            ? DateTime.parse(data['left_at'] as String)
            : null,
        isActive: data['is_active'] as bool? ?? true,
        isOnline: data['user_presence']?['is_online'] as bool? ?? false,
        lastSeen: data['user_presence']?['last_seen'] != null
            ? DateTime.parse(data['user_presence']['last_seen'] as String)
            : null,
      );

  /// Converts to JSON
  Map<String, dynamic> toJson() => _$ParticipantModelToJson(this);

  /// Converts to Supabase insert format
  Map<String, dynamic> toSupabaseInsert() => {
        'room_id': roomId,
        'user_id': userId,
        'role': role.value,
      };

  /// Converts to Supabase update format
  Map<String, dynamic> toSupabaseUpdate() => {
        'role': role.value,
        'is_active': isActive,
        if (leftAt != null) 'left_at': leftAt!.toIso8601String(),
      };

  /// Converts to domain entity
  Participant toEntity() => Participant(
        id: id,
        roomId: roomId,
        userId: userId,
        displayName: displayName,
        email: email,
        avatarUrl: avatarUrl,
        role: role,
        joinedAt: joinedAt,
        leftAt: leftAt,
        isActive: isActive,
        isOnline: isOnline,
        lastSeen: lastSeen,
      );

  /// Create a copy with updated fields
  @override
  ParticipantModel copyWith({
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
    return ParticipantModel(
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