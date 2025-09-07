import 'package:equatable/equatable.dart';

/// Domain entity representing a message in the application
class Message extends Equatable {
  const Message({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.type = MessageType.text,
    this.replyTo,
    this.metadata = const {},
    this.editedAt,
    this.deletedAt,
    this.updatedAt,
  });

  /// Unique identifier for the message
  final String id;
  
  /// ID of the room/chat this message belongs to
  final String roomId;
  
  /// ID of the user who sent the message
  final String userId;
  
  /// Content of the message
  final String content;
  
  /// Type of message
  final MessageType type;
  
  /// ID of message being replied to (if any)
  final String? replyTo;
  
  /// Additional metadata as key-value pairs
  final Map<String, dynamic> metadata;
  
  /// When the message was edited (if edited)
  final DateTime? editedAt;
  
  /// When the message was deleted (if deleted)
  final DateTime? deletedAt;
  
  /// When the message was created
  final DateTime createdAt;
  
  /// When the message was last updated
  final DateTime? updatedAt;

  /// Check if message is deleted
  bool get isDeleted => deletedAt != null;
  
  /// Check if message is edited
  bool get isEdited => editedAt != null;

  @override
  List<Object?> get props => [
    id,
    roomId,
    userId,
    content,
    type,
    replyTo,
    metadata,
    editedAt,
    deletedAt,
    createdAt,
    updatedAt,
  ];

  /// Create a copy of this message with some fields updated
  Message copyWith({
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
  }) {
    return Message(
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
    );
  }
}

/// Types of messages supported (matches database schema)
enum MessageType {
  text,
  image,
  file,
  audio,
  video,
  system,
}

/// Message status enum for tracking delivery
enum MessageStatus {
  sent,
  delivered,
  read,
}

/// Domain entity for message status tracking
class MessageStatusEntity extends Equatable {
  const MessageStatusEntity({
    required this.id,
    required this.messageId,
    required this.userId,
    required this.status,
    required this.timestamp,
  });

  final String id;
  final String messageId;
  final String userId;
  final MessageStatus status;
  final DateTime timestamp;

  @override
  List<Object> get props => [id, messageId, userId, status, timestamp];
}

/// Domain entity for typing indicators
class TypingIndicator extends Equatable {
  const TypingIndicator({
    required this.roomId,
    required this.userId,
    required this.isTyping,
    required this.updatedAt,
  });

  final String roomId;
  final String userId;
  final bool isTyping;
  final DateTime updatedAt;

  @override
  List<Object> get props => [roomId, userId, isTyping, updatedAt];
}

/// Domain entity for user presence
class UserPresence extends Equatable {
  const UserPresence({
    required this.userId,
    required this.isOnline,
    required this.lastSeen,
    this.status = PresenceStatus.available,
    required this.updatedAt,
  });

  final String userId;
  final bool isOnline;
  final DateTime lastSeen;
  final PresenceStatus status;
  final DateTime updatedAt;

  @override
  List<Object> get props => [userId, isOnline, lastSeen, status, updatedAt];
}

/// User presence status enum
enum PresenceStatus {
  available,
  away,
  busy,
  invisible,
}