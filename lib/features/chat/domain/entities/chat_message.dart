import 'package:equatable/equatable.dart';
import '../../../messaging/domain/entities/message.dart';

/// Enhanced domain entity representing a message in chat with additional features
class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.content,
    required this.roomId,
    required this.timestamp,
    this.messageType = MessageType.text,
    this.isRead = false,
    this.threadId,
    this.replyToMessageId,
    this.reactions = const {},
    this.editedAt,
    this.isDeleted = false,
    this.metadata = const {},
  }) : assert(id.length > 0, 'Message ID cannot be empty'),
       assert(senderId.length > 0, 'Sender ID cannot be empty'),
       assert(roomId.length > 0, 'Room ID cannot be empty');

  /// Unique identifier for the message
  final String id;
  
  /// ID of the user who sent the message
  final String senderId;
  
  /// Text content of the message
  final String content;
  
  /// ID of the room/chat this message belongs to
  final String roomId;
  
  /// When the message was sent
  final DateTime timestamp;
  
  /// Type of message (text, image, etc.)
  final MessageType messageType;
  
  /// Whether the message has been read
  final bool isRead;
  
  /// ID of the thread this message belongs to (if it's a thread reply)
  final String? threadId;
  
  /// ID of the message this is replying to
  final String? replyToMessageId;
  
  /// Map of reactions to lists of user IDs who reacted
  final Map<String, List<String>> reactions;
  
  /// When the message was last edited
  final DateTime? editedAt;
  
  /// Whether the message has been deleted
  final bool isDeleted;
  
  /// Additional metadata for the message (file info, etc.)
  final Map<String, String> metadata;

  /// Whether this message is part of a thread
  bool get isThreadMessage => threadId != null;
  
  /// Whether this message has been edited
  bool get isEdited => editedAt != null;

  @override
  List<Object?> get props => [
    id,
    senderId,
    content,
    roomId,
    timestamp,
    messageType,
    isRead,
    threadId,
    replyToMessageId,
    reactions,
    editedAt,
    isDeleted,
    metadata,
  ];

  /// Creates a copy of this message with updated fields
  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? content,
    String? roomId,
    DateTime? timestamp,
    MessageType? messageType,
    bool? isRead,
    String? threadId,
    String? replyToMessageId,
    Map<String, List<String>>? reactions,
    DateTime? editedAt,
    bool? isDeleted,
    Map<String, String>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      roomId: roomId ?? this.roomId,
      timestamp: timestamp ?? this.timestamp,
      messageType: messageType ?? this.messageType,
      isRead: isRead ?? this.isRead,
      threadId: threadId ?? this.threadId,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      reactions: reactions ?? this.reactions,
      editedAt: editedAt ?? this.editedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to basic Message entity for compatibility
  Message toMessage() {
    return Message(
      id: id,
      senderId: senderId,
      content: content,
      timestamp: timestamp,
      roomId: roomId,
      messageType: messageType,
      isRead: isRead,
    );
  }

  /// Create ChatMessage from basic Message entity
  static ChatMessage fromMessage(Message message) {
    return ChatMessage(
      id: message.id,
      senderId: message.senderId,
      content: message.content,
      roomId: message.roomId,
      timestamp: message.timestamp,
      messageType: message.messageType,
      isRead: message.isRead,
    );
  }
}