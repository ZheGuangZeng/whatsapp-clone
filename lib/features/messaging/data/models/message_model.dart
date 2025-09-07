import '../../domain/entities/message.dart';

/// Data model for Message entity with JSON serialization
class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.roomId,
    required super.userId,
    required super.content,
    required super.createdAt,
    super.type,
    super.replyTo,
    super.metadata,
    super.editedAt,
    super.deletedAt,
    super.updatedAt,
  });

  /// Create MessageModel from JSON
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      replyTo: json['reply_to'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      editedAt: json['edited_at'] != null 
        ? DateTime.parse(json['edited_at'] as String)
        : null,
      deletedAt: json['deleted_at'] != null
        ? DateTime.parse(json['deleted_at'] as String)
        : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
        ? DateTime.parse(json['updated_at'] as String)
        : null,
    );
  }

  /// Create MessageModel from domain entity
  factory MessageModel.fromEntity(Message message) {
    return MessageModel(
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
    );
  }

  /// Convert MessageModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'user_id': userId,
      'content': content,
      'type': type.name,
      'reply_to': replyTo,
      'metadata': metadata,
      'edited_at': editedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Convert to domain entity
  Message toEntity() {
    return Message(
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
    );
  }
}

/// Data model for MessageStatusEntity
class MessageStatusModel extends MessageStatusEntity {
  const MessageStatusModel({
    required super.id,
    required super.messageId,
    required super.userId,
    required super.status,
    required super.timestamp,
  });

  /// Create from JSON
  factory MessageStatusModel.fromJson(Map<String, dynamic> json) {
    return MessageStatusModel(
      id: json['id'] as String,
      messageId: json['message_id'] as String,
      userId: json['user_id'] as String,
      status: MessageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Create from entity
  factory MessageStatusModel.fromEntity(MessageStatusEntity entity) {
    return MessageStatusModel(
      id: entity.id,
      messageId: entity.messageId,
      userId: entity.userId,
      status: entity.status,
      timestamp: entity.timestamp,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message_id': messageId,
      'user_id': userId,
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Convert to entity
  MessageStatusEntity toEntity() {
    return MessageStatusEntity(
      id: id,
      messageId: messageId,
      userId: userId,
      status: status,
      timestamp: timestamp,
    );
  }
}

/// Data model for TypingIndicator
class TypingIndicatorModel extends TypingIndicator {
  const TypingIndicatorModel({
    required super.roomId,
    required super.userId,
    required super.isTyping,
    required super.updatedAt,
  });

  /// Create from JSON
  factory TypingIndicatorModel.fromJson(Map<String, dynamic> json) {
    return TypingIndicatorModel(
      roomId: json['room_id'] as String,
      userId: json['user_id'] as String,
      isTyping: json['is_typing'] as bool,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Create from entity
  factory TypingIndicatorModel.fromEntity(TypingIndicator entity) {
    return TypingIndicatorModel(
      roomId: entity.roomId,
      userId: entity.userId,
      isTyping: entity.isTyping,
      updatedAt: entity.updatedAt,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'room_id': roomId,
      'user_id': userId,
      'is_typing': isTyping,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert to entity
  TypingIndicator toEntity() {
    return TypingIndicator(
      roomId: roomId,
      userId: userId,
      isTyping: isTyping,
      updatedAt: updatedAt,
    );
  }
}

/// Data model for UserPresence
class UserPresenceModel extends UserPresence {
  const UserPresenceModel({
    required super.userId,
    required super.isOnline,
    required super.lastSeen,
    super.status,
    required super.updatedAt,
  });

  /// Create from JSON
  factory UserPresenceModel.fromJson(Map<String, dynamic> json) {
    return UserPresenceModel(
      userId: json['user_id'] as String,
      isOnline: json['is_online'] as bool,
      lastSeen: DateTime.parse(json['last_seen'] as String),
      status: json['status'] != null
        ? PresenceStatus.values.firstWhere(
            (e) => e.name == json['status'],
            orElse: () => PresenceStatus.available,
          )
        : PresenceStatus.available,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Create from entity
  factory UserPresenceModel.fromEntity(UserPresence entity) {
    return UserPresenceModel(
      userId: entity.userId,
      isOnline: entity.isOnline,
      lastSeen: entity.lastSeen,
      status: entity.status,
      updatedAt: entity.updatedAt,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'is_online': isOnline,
      'last_seen': lastSeen.toIso8601String(),
      'status': status.name,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert to entity
  UserPresence toEntity() {
    return UserPresence(
      userId: userId,
      isOnline: isOnline,
      lastSeen: lastSeen,
      status: status,
      updatedAt: updatedAt,
    );
  }
}