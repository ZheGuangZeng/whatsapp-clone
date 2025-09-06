import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/message.dart';
import '../../domain/entities/participant.dart';
import '../../domain/entities/room.dart';

part 'room_model.g.dart';

/// Data model for Room entity with JSON serialization
@JsonSerializable()
class RoomModel extends Room {
  const RoomModel({
    required super.id,
    super.name,
    super.description,
    required super.type,
    required super.createdBy,
    super.avatarUrl,
    super.lastMessageAt,
    required super.createdAt,
    required super.updatedAt,
    super.unreadCount,
  }) : super(participants: const [], lastMessage: null);

  /// Creates RoomModel from JSON
  factory RoomModel.fromJson(Map<String, dynamic> json) =>
      _$RoomModelFromJson(json);

  /// Creates RoomModel from domain entity
  factory RoomModel.fromEntity(Room room) => RoomModel(
        id: room.id,
        name: room.name,
        description: room.description,
        type: room.type,
        createdBy: room.createdBy,
        avatarUrl: room.avatarUrl,
        lastMessageAt: room.lastMessageAt,
        createdAt: room.createdAt,
        updatedAt: room.updatedAt,
        participants: room.participants,
        lastMessage: room.lastMessage,
        unreadCount: room.unreadCount,
      );

  /// Creates RoomModel from Supabase response
  factory RoomModel.fromSupabase(Map<String, dynamic> data) => RoomModel(
        id: data['id'] as String,
        name: data['name'] as String?,
        description: data['description'] as String?,
        type: RoomType.fromString(data['type'] as String),
        createdBy: data['created_by'] as String,
        avatarUrl: data['avatar_url'] as String?,
        lastMessageAt: data['last_message_at'] != null
            ? DateTime.parse(data['last_message_at'] as String)
            : null,
        createdAt: DateTime.parse(data['created_at'] as String),
        updatedAt: DateTime.parse(data['updated_at'] as String),
        participants: [], // Will be loaded separately
        lastMessage: null, // Will be loaded separately
        unreadCount: 0, // Will be calculated separately
      );

  /// Converts to JSON
  Map<String, dynamic> toJson() => _$RoomModelToJson(this);

  /// Converts to Supabase insert format
  Map<String, dynamic> toSupabaseInsert() => {
        'name': name,
        'description': description,
        'type': type.value,
        'created_by': createdBy,
        'avatar_url': avatarUrl,
      };

  /// Converts to Supabase update format
  Map<String, dynamic> toSupabaseUpdate() => {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };

  /// Converts to domain entity
  Room toEntity() => Room(
        id: id,
        name: name,
        description: description,
        type: type,
        createdBy: createdBy,
        avatarUrl: avatarUrl,
        lastMessageAt: lastMessageAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
        participants: participants,
        lastMessage: lastMessage,
        unreadCount: unreadCount,
      );

  /// Create a copy with updated fields
  @override
  RoomModel copyWith({
    String? id,
    String? name,
    String? description,
    RoomType? type,
    String? createdBy,
    String? avatarUrl,
    DateTime? lastMessageAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Participant>? participants,
    Message? lastMessage,
    int? unreadCount,
  }) {
    return RoomModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      createdBy: createdBy ?? this.createdBy,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}