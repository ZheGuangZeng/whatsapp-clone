import '../../domain/entities/chat_message.dart';
import '../../../messaging/domain/entities/message.dart';

/// Data model for ChatMessage with JSON serialization
class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.senderId,
    required super.content,
    required super.roomId,
    required super.timestamp,
    super.messageType = MessageType.text,
    super.isRead = false,
    super.threadId,
    super.replyToMessageId,
    super.reactions = const {},
    super.editedAt,
    super.isDeleted = false,
    super.metadata = const {},
  });

  /// Create ChatMessageModel from JSON data
  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    if (json['id'] == null) {
      throw Exception('Message ID is required');
    }
    if (json['sender_id'] == null) {
      throw Exception('Sender ID is required');  
    }
    if (json['content'] == null) {
      throw Exception('Content is required');
    }
    if (json['room_id'] == null) {
      throw Exception('Room ID is required');
    }
    if (json['timestamp'] == null) {
      throw Exception('Timestamp is required');
    }

    return ChatMessageModel(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      roomId: json['room_id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      messageType: _parseMessageType(json['message_type'] as String?),
      isRead: json['is_read'] as bool? ?? false,
      threadId: json['thread_id'] as String?,
      replyToMessageId: json['reply_to_message_id'] as String?,
      reactions: _parseReactions(json['reactions']),
      editedAt: json['edited_at'] != null 
        ? DateTime.parse(json['edited_at'] as String)
        : null,
      isDeleted: json['is_deleted'] as bool? ?? false,
      metadata: _parseMetadata(json['metadata']),
    );
  }

  /// Convert ChatMessageModel to JSON data
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'content': content,
      'room_id': roomId,
      'timestamp': timestamp.toIso8601String(),
      'message_type': messageType.name,
      'is_read': isRead,
      'thread_id': threadId,
      'reply_to_message_id': replyToMessageId,
      'reactions': reactions,
      'edited_at': editedAt?.toIso8601String(),
      'is_deleted': isDeleted,
      'metadata': metadata,
    };
  }

  /// Create ChatMessageModel from ChatMessage entity
  factory ChatMessageModel.fromEntity(ChatMessage entity) {
    return ChatMessageModel(
      id: entity.id,
      senderId: entity.senderId,
      content: entity.content,
      roomId: entity.roomId,
      timestamp: entity.timestamp,
      messageType: entity.messageType,
      isRead: entity.isRead,
      threadId: entity.threadId,
      replyToMessageId: entity.replyToMessageId,
      reactions: entity.reactions,
      editedAt: entity.editedAt,
      isDeleted: entity.isDeleted,
      metadata: entity.metadata,
    );
  }

  /// Convert ChatMessageModel to ChatMessage entity
  ChatMessage toEntity() {
    return ChatMessage(
      id: id,
      senderId: senderId,
      content: content,
      roomId: roomId,
      timestamp: timestamp,
      messageType: messageType,
      isRead: isRead,
      threadId: threadId,
      replyToMessageId: replyToMessageId,
      reactions: reactions,
      editedAt: editedAt,
      isDeleted: isDeleted,
      metadata: metadata,
    );
  }

  /// Helper method to parse message type from string
  static MessageType _parseMessageType(String? type) {
    switch (type) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'file':
        return MessageType.file;
      default:
        return MessageType.text;
    }
  }

  /// Helper method to parse reactions map
  static Map<String, List<String>> _parseReactions(dynamic reactions) {
    if (reactions == null) {
      return const <String, List<String>>{};
    }
    
    if (reactions is Map<String, dynamic>) {
      final result = <String, List<String>>{};
      reactions.forEach((key, value) {
        if (value is List) {
          result[key] = value.cast<String>();
        }
      });
      return result;
    }
    
    return const <String, List<String>>{};
  }

  /// Helper method to parse metadata map  
  static Map<String, String> _parseMetadata(dynamic metadata) {
    if (metadata == null) {
      return const <String, String>{};
    }
    
    if (metadata is Map<String, dynamic>) {
      return metadata.cast<String, String>();
    }
    
    return const <String, String>{};
  }
}