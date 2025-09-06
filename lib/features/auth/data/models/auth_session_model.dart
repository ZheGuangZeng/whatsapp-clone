import 'package:json_annotation/json_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user.dart';
import 'user_model.dart';

part 'auth_session_model.g.dart';

/// Data model for AuthSession entity with JSON serialization
@JsonSerializable()
class AuthSessionModel {
  const AuthSessionModel({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.expiresAt,
    required this.tokenType,
  });

  final String accessToken;
  final String refreshToken;
  final UserModel user;
  final DateTime expiresAt;
  final String tokenType;

  /// Creates an AuthSessionModel from JSON map
  factory AuthSessionModel.fromJson(Map<String, dynamic> json) =>
      _$AuthSessionModelFromJson(json);

  /// Converts AuthSessionModel to JSON map
  Map<String, dynamic> toJson() => _$AuthSessionModelToJson(this);

  /// Creates an AuthSessionModel from Supabase session
  factory AuthSessionModel.fromSupabaseSession(
    Session session,
    UserModel user,
  ) {
    return AuthSessionModel(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken ?? '',
      user: user,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000),
      tokenType: session.tokenType ?? 'Bearer',
    );
  }

  /// Creates an AuthSessionModel from domain entity
  factory AuthSessionModel.fromDomain(AuthSession session) {
    return AuthSessionModel(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      user: UserModel.fromDomain(session.user),
      expiresAt: session.expiresAt,
      tokenType: session.tokenType,
    );
  }

  /// Converts to domain entity
  AuthSession toDomain() {
    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user.toDomain(),
      expiresAt: expiresAt,
      tokenType: tokenType,
    );
  }

  /// Checks if the session is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}