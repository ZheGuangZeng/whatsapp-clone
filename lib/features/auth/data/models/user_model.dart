import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/user.dart';

part 'user_model.g.dart';

/// Data model for User entity with JSON serialization
@JsonSerializable()
class UserModel {
  const UserModel({
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

  /// Creates a UserModel from JSON map
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  /// Creates a UserModel from Supabase auth user
  factory UserModel.fromSupabaseUser(
    Map<String, dynamic> supabaseUser,
    Map<String, dynamic>? profile,
  ) {
    final createdAt = DateTime.parse(supabaseUser['created_at'] as String);
    final lastSeen = profile?['last_seen'] != null
        ? DateTime.parse(profile!['last_seen'] as String)
        : null;

    return UserModel(
      id: supabaseUser['id'] as String,
      email: supabaseUser['email'] as String,
      phone: supabaseUser['phone'] as String?,
      displayName: profile?['display_name'] as String? ?? 
          supabaseUser['email'] as String,
      avatarUrl: profile?['avatar_url'] as String?,
      status: profile?['status'] as String?,
      createdAt: createdAt,
      lastSeen: lastSeen,
      isOnline: profile?['is_online'] as bool? ?? false,
    );
  }

  /// Creates a UserModel from domain entity
  factory UserModel.fromDomain(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      phone: user.phone,
      displayName: user.displayName,
      avatarUrl: user.avatarUrl,
      status: user.status,
      createdAt: user.createdAt,
      lastSeen: user.lastSeen,
      isOnline: user.isOnline,
    );
  }

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

  /// Converts UserModel to JSON map
  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  /// Converts to domain entity
  User toDomain() {
    return User(
      id: id,
      email: email,
      phone: phone,
      displayName: displayName,
      avatarUrl: avatarUrl,
      status: status,
      createdAt: createdAt,
      lastSeen: lastSeen,
      isOnline: isOnline,
    );
  }
}