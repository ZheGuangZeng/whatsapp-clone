import 'package:equatable/equatable.dart';

import 'user.dart';

/// Domain entity representing an authenticated user session
class AuthSession extends Equatable {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.expiresAt,
    required this.tokenType,
  });

  /// JWT access token for API authentication
  final String accessToken;
  
  /// Refresh token used to obtain new access tokens
  final String refreshToken;
  
  /// The authenticated user
  final User user;
  
  /// When the access token expires
  final DateTime expiresAt;
  
  /// Type of token (typically "Bearer")
  final String tokenType;
  
  /// Whether the access token is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  /// Whether the access token will expire within the next 5 minutes
  bool get isExpiringSoon {
    final fiveMinutesFromNow = DateTime.now().add(const Duration(minutes: 5));
    return fiveMinutesFromNow.isAfter(expiresAt);
  }

  @override
  List<Object?> get props => [
        accessToken,
        refreshToken,
        user,
        expiresAt,
        tokenType,
      ];

  /// Creates a copy of this session with updated fields
  AuthSession copyWith({
    String? accessToken,
    String? refreshToken,
    User? user,
    DateTime? expiresAt,
    String? tokenType,
  }) {
    return AuthSession(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      user: user ?? this.user,
      expiresAt: expiresAt ?? this.expiresAt,
      tokenType: tokenType ?? this.tokenType,
    );
  }
}