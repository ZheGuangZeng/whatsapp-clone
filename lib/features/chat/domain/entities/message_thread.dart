import 'package:equatable/equatable.dart';
import '../../../messaging/domain/entities/message.dart';

/// Domain entity representing a message thread for replies
class MessageThread extends Equatable {
  const MessageThread({
    required this.id,
    required this.roomId,
    required this.rootMessage,
    required this.createdAt,
    this.isActive = true,
    this.replyCount = 0,
    this.lastReply,
    this.participants = const [],
  }) : assert(id.length > 0, 'Thread ID cannot be empty'),
       assert(roomId.length > 0, 'Room ID cannot be empty'),
       assert(replyCount >= 0, 'Reply count cannot be negative');

  /// Unique identifier for the thread
  final String id;
  
  /// ID of the room this thread belongs to
  final String roomId;
  
  /// The original message that started this thread
  final Message rootMessage;
  
  /// When the thread was created
  final DateTime createdAt;
  
  /// Whether the thread is currently active
  final bool isActive;
  
  /// Number of replies in this thread
  final int replyCount;
  
  /// The most recent reply message
  final Message? lastReply;
  
  /// List of user IDs who have participated in this thread
  final List<String> participants;

  @override
  List<Object?> get props => [
    id,
    roomId,
    rootMessage,
    createdAt,
    isActive,
    replyCount,
    lastReply,
    participants,
  ];

  /// Creates a copy of this thread with updated fields
  MessageThread copyWith({
    String? id,
    String? roomId,
    Message? rootMessage,
    DateTime? createdAt,
    bool? isActive,
    int? replyCount,
    Message? lastReply,
    List<String>? participants,
  }) {
    return MessageThread(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      rootMessage: rootMessage ?? this.rootMessage,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      replyCount: replyCount ?? this.replyCount,
      lastReply: lastReply ?? this.lastReply,
      participants: participants ?? this.participants,
    );
  }
}