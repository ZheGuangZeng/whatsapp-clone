import 'package:equatable/equatable.dart';

/// Domain entity representing typing indicator status
class TypingIndicator extends Equatable {
  const TypingIndicator({
    required this.roomId,
    required this.userId,
    required this.displayName,
    required this.isTyping,
    required this.updatedAt,
  });

  /// ID of the room where typing is happening
  final String roomId;

  /// ID of the user who is typing
  final String userId;

  /// Display name of the user who is typing
  final String displayName;

  /// Whether the user is currently typing
  final bool isTyping;

  /// When the typing status was last updated
  final DateTime updatedAt;

  @override
  List<Object?> get props => [roomId, userId, displayName, isTyping, updatedAt];

  /// Creates a copy of this typing indicator with updated fields
  TypingIndicator copyWith({
    String? roomId,
    String? userId,
    String? displayName,
    bool? isTyping,
    DateTime? updatedAt,
  }) {
    return TypingIndicator(
      roomId: roomId ?? this.roomId,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      isTyping: isTyping ?? this.isTyping,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}