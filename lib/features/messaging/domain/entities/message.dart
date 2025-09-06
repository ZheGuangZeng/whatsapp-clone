import 'package:equatable/equatable.dart';

/// Domain entity representing a message in the application
class Message extends Equatable {
  const Message({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    required this.roomId,
    this.messageType = MessageType.text,
    this.isRead = false,
  });

  /// Unique identifier for the message
  final String id;
  
  /// ID of the user who sent the message
  final String senderId;
  
  /// Text content of the message
  final String content;
  
  /// When the message was sent
  final DateTime timestamp;
  
  /// ID of the room/chat this message belongs to
  final String roomId;
  
  /// Type of message (text, image, etc.)
  final MessageType messageType;
  
  /// Whether the message has been read
  final bool isRead;

  @override
  List<Object?> get props => [
    id,
    senderId, 
    content,
    timestamp,
    roomId,
    messageType,
    isRead,
  ];

  /// Create a copy of this message with some fields updated
  Message copyWith({
    String? id,
    String? senderId,
    String? content,
    DateTime? timestamp,
    String? roomId,
    MessageType? messageType,
    bool? isRead,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      roomId: roomId ?? this.roomId,
      messageType: messageType ?? this.messageType,
      isRead: isRead ?? this.isRead,
    );
  }
}

/// Types of messages supported
enum MessageType {
  text,
  image,
  file,
}