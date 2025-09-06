import 'package:equatable/equatable.dart';

/// Enum for user presence status
enum PresenceStatus {
  available('available'),
  away('away'),
  busy('busy'),
  invisible('invisible');

  const PresenceStatus(this.value);
  final String value;

  static PresenceStatus fromString(String value) {
    return PresenceStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => PresenceStatus.available,
    );
  }
}

/// Domain entity representing user presence information
class UserPresence extends Equatable {
  const UserPresence({
    required this.userId,
    required this.isOnline,
    required this.lastSeen,
    this.status = PresenceStatus.available,
    required this.updatedAt,
  });

  /// ID of the user
  final String userId;

  /// Whether the user is currently online
  final bool isOnline;

  /// When the user was last seen online
  final DateTime lastSeen;

  /// Current presence status of the user
  final PresenceStatus status;

  /// When the presence was last updated
  final DateTime updatedAt;

  /// Whether the user is available
  bool get isAvailable => status == PresenceStatus.available && isOnline;

  /// Whether the user is away
  bool get isAway => status == PresenceStatus.away;

  /// Whether the user is busy
  bool get isBusy => status == PresenceStatus.busy;

  /// Whether the user is invisible
  bool get isInvisible => status == PresenceStatus.invisible;

  /// Get formatted last seen text
  String getLastSeenText() {
    if (isOnline && !isInvisible) {
      return 'Online';
    }

    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return 'Last seen ${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
    }
  }

  @override
  List<Object?> get props => [userId, isOnline, lastSeen, status, updatedAt];

  /// Creates a copy of this user presence with updated fields
  UserPresence copyWith({
    String? userId,
    bool? isOnline,
    DateTime? lastSeen,
    PresenceStatus? status,
    DateTime? updatedAt,
  }) {
    return UserPresence(
      userId: userId ?? this.userId,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}