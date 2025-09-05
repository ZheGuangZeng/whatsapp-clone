import 'package:equatable/equatable.dart';

/// Domain entity representing a user in the application
class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    this.phone,
    required this.displayName,
    this.avatarUrl,
    this.status,
    required this.createdAt,
    this.lastSeen,
    this.isOnline = false,
  });

  /// Unique identifier for the user
  final String id;
  
  /// User's email address (required for authentication)
  final String email;
  
  /// User's phone number (optional, used for phone auth)
  final String? phone;
  
  /// Display name shown to other users
  final String displayName;
  
  /// URL to user's profile avatar image
  final String? avatarUrl;
  
  /// User's status message
  final String? status;
  
  /// When the user account was created
  final DateTime createdAt;
  
  /// When the user was last seen online
  final DateTime? lastSeen;
  
  /// Whether the user is currently online
  final bool isOnline;

  @override
  List<Object?> get props => [
        id,
        email,
        phone,
        displayName,
        avatarUrl,
        status,
        createdAt,
        lastSeen,
        isOnline,
      ];

  /// Creates a copy of this user with updated fields
  User copyWith({
    String? id,
    String? email,
    String? phone,
    String? displayName,
    String? avatarUrl,
    String? status,
    DateTime? createdAt,
    DateTime? lastSeen,
    bool? isOnline,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}