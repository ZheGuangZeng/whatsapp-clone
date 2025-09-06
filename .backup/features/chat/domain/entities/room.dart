import 'package:equatable/equatable.dart';

import 'message.dart';
import 'participant.dart';

/// Enum for room types
enum RoomType {
  direct('direct'),
  group('group');

  const RoomType(this.value);
  final String value;

  static RoomType fromString(String value) {
    return RoomType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => RoomType.direct,
    );
  }
}

/// Domain entity representing a chat room
class Room extends Equatable {
  const Room({
    required this.id,
    this.name,
    this.description,
    required this.type,
    required this.createdBy,
    this.avatarUrl,
    this.lastMessageAt,
    required this.createdAt,
    required this.updatedAt,
    this.participants = const [],
    this.lastMessage,
    this.unreadCount = 0,
  });

  /// Unique identifier for the room
  final String id;

  /// Name of the room (for group chats, null for direct messages)
  final String? name;

  /// Description of the room (optional, mainly for groups)
  final String? description;

  /// Type of room (direct or group)
  final RoomType type;

  /// ID of the user who created this room
  final String createdBy;

  /// URL to the room's avatar image
  final String? avatarUrl;

  /// When the last message was sent in this room
  final DateTime? lastMessageAt;

  /// When the room was created
  final DateTime createdAt;

  /// When the room was last updated
  final DateTime updatedAt;

  /// List of participants in this room
  final List<Participant> participants;

  /// Last message in this room (for preview)
  final Message? lastMessage;

  /// Number of unread messages for current user
  final int unreadCount;

  /// Whether this is a direct message room
  bool get isDirectMessage => type == RoomType.direct;

  /// Whether this is a group chat room
  bool get isGroupChat => type == RoomType.group;

  /// Whether this room has unread messages
  bool get hasUnreadMessages => unreadCount > 0;

  /// Active participants (not left the room)
  List<Participant> get activeParticipants =>
      participants.where((p) => p.isActive).toList();

  /// Get display name for the room
  String getDisplayName(String currentUserId) {
    if (isGroupChat && name != null) {
      return name!;
    }

    if (isDirectMessage) {
      final otherParticipant = participants
          .where((p) => p.userId != currentUserId && p.isActive)
          .firstOrNull;
      return otherParticipant?.displayName ?? 'Unknown User';
    }

    return name ?? 'Chat Room';
  }

  /// Get avatar URL for the room
  String? getAvatarUrl(String currentUserId) {
    if (avatarUrl != null) {
      return avatarUrl;
    }

    if (isDirectMessage) {
      final otherParticipant = participants
          .where((p) => p.userId != currentUserId && p.isActive)
          .firstOrNull;
      return otherParticipant?.avatarUrl;
    }

    return null;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        type,
        createdBy,
        avatarUrl,
        lastMessageAt,
        createdAt,
        updatedAt,
        participants,
        lastMessage,
        unreadCount,
      ];

  /// Creates an empty room for loading states
  factory Room.empty() {
    return Room(
      id: '',
      type: RoomType.direct,
      createdBy: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Creates a copy of this room with updated fields
  Room copyWith({
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
    return Room(
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