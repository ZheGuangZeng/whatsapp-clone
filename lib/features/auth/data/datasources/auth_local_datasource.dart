import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth_session_model.dart';

/// Local data source for authentication data using secure storage
class AuthLocalDataSource {
  const AuthLocalDataSource(this._secureStorage);

  final FlutterSecureStorage _secureStorage;

  static const String _sessionKey = 'auth_session';
  static const String _refreshTokenKey = 'refresh_token';

  /// Saves the authentication session to secure storage
  Future<void> saveSession(AuthSessionModel session) async {
    await _secureStorage.write(
      key: _sessionKey,
      value: jsonEncode(session.toJson()),
    );
    await _secureStorage.write(
      key: _refreshTokenKey,
      value: session.refreshToken,
    );
  }

  /// Gets the cached authentication session from secure storage
  Future<AuthSessionModel?> getCachedSession() async {
    try {
      final sessionJson = await _secureStorage.read(key: _sessionKey);
      if (sessionJson == null) return null;

      final sessionMap = jsonDecode(sessionJson) as Map<String, dynamic>;
      return AuthSessionModel.fromJson(sessionMap);
    } catch (e) {
      // If there's an error reading/parsing, clear the stored session
      await clearSession();
      return null;
    }
  }

  /// Gets the cached refresh token from secure storage
  Future<String?> getCachedRefreshToken() async {
    return _secureStorage.read(key: _refreshTokenKey);
  }

  /// Clears the cached session data
  Future<void> clearSession() async {
    await _secureStorage.delete(key: _sessionKey);
    await _secureStorage.delete(key: _refreshTokenKey);
  }

  /// Checks if a cached session exists
  Future<bool> hasSession() async {
    final session = await _secureStorage.read(key: _sessionKey);
    return session != null;
  }
}