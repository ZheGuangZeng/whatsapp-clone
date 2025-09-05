import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/user_presence.dart';

part 'user_presence_model.g.dart';

/// Data model for UserPresence entity with JSON serialization
@JsonSerializable()
class UserPresenceModel extends UserPresence {
  const UserPresenceModel({
    required super.userId,
    required super.isOnline,
    required super.lastSeen,
    super.status,
    required super.updatedAt,
  });

  /// Creates UserPresenceModel from JSON
  factory UserPresenceModel.fromJson(Map<String, dynamic> json) =>
      _$UserPresenceModelFromJson(json);

  /// Creates UserPresenceModel from domain entity
  factory UserPresenceModel.fromEntity(UserPresence presence) =>
      UserPresenceModel(
        userId: presence.userId,
        isOnline: presence.isOnline,
        lastSeen: presence.lastSeen,
        status: presence.status,
        updatedAt: presence.updatedAt,
      );

  /// Creates UserPresenceModel from Supabase response
  factory UserPresenceModel.fromSupabase(Map<String, dynamic> data) =>
      UserPresenceModel(
        userId: data['user_id'] as String,
        isOnline: data['is_online'] as bool,
        lastSeen: DateTime.parse(data['last_seen'] as String),
        status: PresenceStatus.fromString(data['status'] as String? ?? 'available'),
        updatedAt: DateTime.parse(data['updated_at'] as String),
      );

  /// Converts to JSON
  Map<String, dynamic> toJson() => _$UserPresenceModelToJson(this);

  /// Converts to Supabase insert format
  Map<String, dynamic> toSupabaseInsert() => {
        'user_id': userId,
        'is_online': isOnline,
        'last_seen': lastSeen.toIso8601String(),
        'status': status.value,
        'updated_at': updatedAt.toIso8601String(),
      };

  /// Converts to domain entity
  UserPresence toEntity() => UserPresence(
        userId: userId,
        isOnline: isOnline,
        lastSeen: lastSeen,
        status: status,
        updatedAt: updatedAt,
      );
}