import '../../../messaging/domain/entities/message.dart';
import '../../domain/entities/message_thread.dart';

/// Data model for MessageThread with JSON serialization
class MessageThreadModel extends MessageThread {
  const MessageThreadModel({
    required super.id,
    required super.roomId,
    required super.rootMessage,
    required super.createdAt,
    super.isActive = true,
    super.replyCount = 0,
    super.lastReply,
    super.participants = const [],
  });

  /// Create MessageThreadModel from MessageThread entity
  factory MessageThreadModel.fromEntity(MessageThread entity) {
    return MessageThreadModel(
      id: entity.id,
      roomId: entity.roomId,
      rootMessage: entity.rootMessage,
      createdAt: entity.createdAt,
      isActive: entity.isActive,
      replyCount: entity.replyCount,
      lastReply: entity.lastReply,
      participants: entity.participants,
    );
  }

  /// Create MessageThreadModel from JSON data
  factory MessageThreadModel.fromJson(Map<String, dynamic> json) {
    if (json['id'] == null) {
      throw Exception('Thread ID is required');
    }
    if (json['room_id'] == null) {
      throw Exception('Room ID is required');
    }
    if (json['root_message'] == null) {
      throw Exception('Root message is required');
    }
    if (json['created_at'] == null) {
      throw Exception('Created at is required');
    }

    return MessageThreadModel(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      rootMessage: _parseMessage(json['root_message']),
      createdAt: DateTime.parse(json['created_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
      replyCount: json['reply_count'] as int? ?? 0,
      lastReply: json['last_reply'] != null 
        ? _parseMessage(json['last_reply']) 
        : null,
      participants: _parseParticipants(json['participants']),
    );
  }

  /// Convert MessageThreadModel to JSON data
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'root_message': _messageToJson(rootMessage),
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
      'reply_count': replyCount,
      'last_reply': lastReply != null ? _messageToJson(lastReply!) : null,
      'participants': participants,
    };
  }

  /// Convert MessageThreadModel to MessageThread entity
  MessageThread toEntity() {
    return MessageThread(
      id: id,
      roomId: roomId,
      rootMessage: rootMessage,
      createdAt: createdAt,
      isActive: isActive,
      replyCount: replyCount,
      lastReply: lastReply,
      participants: participants,
    );
  }

  /// Helper method to parse Message from JSON
  static Message _parseMessage(dynamic messageData) {
    if (messageData is Map<String, dynamic>) {
      return Message(
        id: messageData['id'] as String,
        senderId: messageData['sender_id'] as String,
        content: messageData['content'] as String,
        timestamp: DateTime.parse(messageData['timestamp'] as String),
        roomId: messageData['room_id'] as String,
        messageType: _parseMessageType(messageData['message_type'] as String?),
        isRead: messageData['is_read'] as bool? ?? false,
      );
    }
    throw Exception('Invalid message data format');
  }

  /// Helper method to convert Message to JSON
  static Map<String, dynamic> _messageToJson(Message message) {
    return {
      'id': message.id,
      'sender_id': message.senderId,
      'content': message.content,
      'timestamp': message.timestamp.toIso8601String(),
      'room_id': message.roomId,
      'message_type': message.messageType.name,
      'is_read': message.isRead,
    };
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

  /// Helper method to parse participants list
  static List<String> _parseParticipants(dynamic participants) {
    if (participants == null) {
      return const <String>[];
    }
    
    if (participants is List) {
      return participants.cast<String>();
    }
    
    return const <String>[];
  }
}