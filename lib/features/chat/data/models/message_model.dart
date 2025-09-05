import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/message.dart';

part 'message_model.g.dart';

/// Data model for Message entity with JSON serialization
@JsonSerializable()
class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.roomId,
    required super.userId,
    required super.content,
    super.type,
    super.replyTo,
    super.metadata,
    super.editedAt,
    super.deletedAt,
    required super.createdAt,
    required super.updatedAt,
    super.status,
    super.reactions,
  });

  /// Creates MessageModel from JSON
  factory MessageModel.fromJson(Map<String, dynamic> json) =>
      _$MessageModelFromJson(json);

  /// Creates MessageModel from domain entity
  factory MessageModel.fromEntity(Message message) => MessageModel(
        id: message.id,
        roomId: message.roomId,
        userId: message.userId,
        content: message.content,
        type: message.type,
        replyTo: message.replyTo,
        metadata: message.metadata,
        editedAt: message.editedAt,
        deletedAt: message.deletedAt,
        createdAt: message.createdAt,
        updatedAt: message.updatedAt,
        status: message.status,
        reactions: message.reactions,
      );

  /// Creates MessageModel from Supabase response
  factory MessageModel.fromSupabase(Map<String, dynamic> data) {
    return MessageModel(
      id: data['id'] as String,
      roomId: data['room_id'] as String,
      userId: data['user_id'] as String,
      content: data['content'] as String,
      type: MessageType.fromString(data['type'] as String? ?? 'text'),
      replyTo: data['reply_to'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>? ?? {},
      editedAt: data['edited_at'] != null
          ? DateTime.parse(data['edited_at'] as String)
          : null,
      deletedAt: data['deleted_at'] != null
          ? DateTime.parse(data['deleted_at'] as String)
          : null,
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: DateTime.parse(data['updated_at'] as String),
      status: MessageStatus.sent, // Default, will be updated from message_status
      reactions: [], // Will be loaded separately
    );
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() => _$MessageModelToJson(this);

  /// Converts to Supabase insert format
  Map<String, dynamic> toSupabaseInsert() => {
        'room_id': roomId,
        'user_id': userId,
        'content': content,
        'type': type.value,
        'reply_to': replyTo,
        'metadata': metadata,
      };

  /// Converts to domain entity
  Message toEntity() => Message(
        id: id,
        roomId: roomId,
        userId: userId,
        content: content,
        type: type,
        replyTo: replyTo,
        metadata: metadata,
        editedAt: editedAt,
        deletedAt: deletedAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
        status: status,
        reactions: reactions,
      );

  /// Create a copy with updated fields
  MessageModel copyWith({
    String? id,
    String? roomId,
    String? userId,
    String? content,
    MessageType? type,
    String? replyTo,
    Map<String, dynamic>? metadata,
    DateTime? editedAt,
    DateTime? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    MessageStatus? status,
    List<MessageReaction>? reactions,
  }) {
    return MessageModel(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      type: type ?? this.type,
      replyTo: replyTo ?? this.replyTo,
      metadata: metadata ?? this.metadata,
      editedAt: editedAt ?? this.editedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      reactions: reactions ?? this.reactions,
    );
  }
}

/// Data model for MessageReaction entity with JSON serialization
@JsonSerializable()
class MessageReactionModel extends MessageReaction {
  const MessageReactionModel({
    required super.id,
    required super.messageId,
    required super.userId,
    required super.emoji,
    required super.createdAt,
  });

  /// Creates MessageReactionModel from JSON
  factory MessageReactionModel.fromJson(Map<String, dynamic> json) =>
      _$MessageReactionModelFromJson(json);

  /// Creates MessageReactionModel from domain entity
  factory MessageReactionModel.fromEntity(MessageReaction reaction) =>
      MessageReactionModel(
        id: reaction.id,
        messageId: reaction.messageId,
        userId: reaction.userId,
        emoji: reaction.emoji,
        createdAt: reaction.createdAt,
      );

  /// Creates MessageReactionModel from Supabase response
  factory MessageReactionModel.fromSupabase(Map<String, dynamic> data) =>
      MessageReactionModel(
        id: data['id'] as String,
        messageId: data['message_id'] as String,
        userId: data['user_id'] as String,
        emoji: data['emoji'] as String,
        createdAt: DateTime.parse(data['created_at'] as String),
      );

  /// Converts to JSON
  Map<String, dynamic> toJson() => _$MessageReactionModelToJson(this);

  /// Converts to Supabase insert format
  Map<String, dynamic> toSupabaseInsert() => {
        'message_id': messageId,
        'user_id': userId,
        'emoji': emoji,
      };

  /// Converts to domain entity
  MessageReaction toEntity() => MessageReaction(
        id: id,
        messageId: messageId,
        userId: userId,
        emoji: emoji,
        createdAt: createdAt,
      );
}