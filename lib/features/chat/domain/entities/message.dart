import 'package:equatable/equatable.dart';

/// Enum for message types
enum MessageType {
  text('text'),
  image('image'),
  file('file'),
  audio('audio'),
  video('video'),
  system('system');

  const MessageType(this.value);
  final String value;

  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => MessageType.text,
    );
  }
}

/// Enum for message status
enum MessageStatus {
  sent('sent'),
  delivered('delivered'),
  read('read');

  const MessageStatus(this.value);
  final String value;

  static MessageStatus fromString(String value) {
    return MessageStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => MessageStatus.sent,
    );
  }
}

/// Domain entity representing a chat message
class Message extends Equatable {
  const Message({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.content,
    this.type = MessageType.text,
    this.replyTo,
    this.metadata = const <String, dynamic>{},
    this.editedAt,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    this.status = MessageStatus.sent,
    this.reactions = const [],
  });

  /// Unique identifier for the message
  final String id;

  /// ID of the room this message belongs to
  final String roomId;

  /// ID of the user who sent this message
  final String userId;

  /// Text content of the message
  final String content;

  /// Type of message (text, image, file, etc.)
  final MessageType type;

  /// ID of message this is replying to (if any)
  final String? replyTo;

  /// Additional metadata for the message (file info, etc.)
  final Map<String, dynamic> metadata;

  /// When the message was edited (if edited)
  final DateTime? editedAt;

  /// When the message was deleted (soft delete)
  final DateTime? deletedAt;

  /// When the message was created
  final DateTime createdAt;

  /// When the message was last updated
  final DateTime updatedAt;

  /// Delivery status of the message
  final MessageStatus status;

  /// Reactions to this message
  final List<MessageReaction> reactions;

  /// Whether this message has been edited
  bool get isEdited => editedAt != null;

  /// Whether this message has been deleted
  bool get isDeleted => deletedAt != null;

  /// Whether this message is a reply to another message
  bool get isReply => replyTo != null;

  /// Whether this message is a system message
  bool get isSystemMessage => type == MessageType.text;

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
        status,
        reactions,
      ];

  /// Creates a copy of this message with updated fields
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
    MessageStatus? status,
    List<MessageReaction>? reactions,
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
      status: status ?? this.status,
      reactions: reactions ?? this.reactions,
    );
  }
}

/// Domain entity representing a message reaction
class MessageReaction extends Equatable {
  const MessageReaction({
    required this.id,
    required this.messageId,
    required this.userId,
    required this.emoji,
    required this.createdAt,
  });

  /// Unique identifier for the reaction
  final String id;

  /// ID of the message being reacted to
  final String messageId;

  /// ID of the user who added the reaction
  final String userId;

  /// Emoji used for the reaction
  final String emoji;

  /// When the reaction was added
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, messageId, userId, emoji, createdAt];

  /// Creates a copy of this reaction with updated fields
  MessageReaction copyWith({
    String? id,
    String? messageId,
    String? userId,
    String? emoji,
    DateTime? createdAt,
  }) {
    return MessageReaction(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      userId: userId ?? this.userId,
      emoji: emoji ?? this.emoji,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}