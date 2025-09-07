import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_session_model.dart';

/// Implementation of authentication repository using Supabase
class AuthRepository implements IAuthRepository {
  const AuthRepository(
    this._remoteDataSource,
    this._localDataSource,
  );

  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  @override
  Future<Result<AuthSession?>> getCurrentSession() async {
    try {
      // First try to get session from remote (most up-to-date)
      final remoteSession = await _remoteDataSource.getCurrentSession();
      if (remoteSession != null) {
        await _localDataSource.saveSession(remoteSession);
        return Success(remoteSession.toDomain());
      }

      // Fall back to cached session
      final cachedSession = await _localDataSource.getCachedSession();
      if (cachedSession != null && !cachedSession.isExpired) {
        return Success(cachedSession.toDomain());
      }

      // Try to refresh if we have a cached refresh token
      final cachedRefreshToken = await _localDataSource.getCachedRefreshToken();
      if (cachedRefreshToken != null) {
        final refreshResult = await refreshToken(refreshToken: cachedRefreshToken);
        return refreshResult;
      }

      return const Success(null);
    } catch (e) {
      return ResultFailure(
        AuthFailure(message: 'Failed to get current session: $e'),
      );
    }
  }

  @override
  Future<Result<AuthSession>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final session = await _remoteDataSource.signInWithEmail(
        email: email,
        password: password,
      );
      
      await _localDataSource.saveSession(session);
      return Success(session.toDomain());
    } on supabase.AuthException catch (e) {
      return ResultFailure(
        AuthFailure(message: e.message),
      );
    } catch (e) {
      return ResultFailure(
        AuthFailure(message: 'Failed to sign in with email: $e'),
      );
    }
  }

  @override
  Future<Result<AuthSession>> signInWithPhone({
    required String phone,
    required String password,
  }) async {
    try {
      final session = await _remoteDataSource.signInWithPhone(
        phone: phone,
        password: password,
      );
      
      await _localDataSource.saveSession(session);
      return Success(session.toDomain());
    } on supabase.AuthException catch (e) {
      return ResultFailure(
        AuthFailure(message: e.message),
      );
    } catch (e) {
      return ResultFailure(
        AuthFailure(message: 'Failed to sign in with phone: $e'),
      );
    }
  }

  @override
  Future<Result<AuthSession>> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final session = await _remoteDataSource.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      
      // Only save to local storage if it's a complete session
      if (session.accessToken.isNotEmpty) {
        await _localDataSource.saveSession(session);
      }
      
      return Success(session.toDomain());
    } on supabase.AuthException catch (e) {
      return ResultFailure(
        AuthFailure(message: e.message),
      );
    } catch (e) {
      return ResultFailure(
        AuthFailure(message: 'Failed to sign up with email: $e'),
      );
    }
  }

  @override
  Future<Result<AuthSession>> signUpWithPhone({
    required String phone,
    required String password,
    required String displayName,
  }) async {
    try {
      final session = await _remoteDataSource.signUpWithPhone(
        phone: phone,
        password: password,
        displayName: displayName,
      );
      
      // Only save to local storage if it's a complete session
      if (session.accessToken.isNotEmpty) {
        await _localDataSource.saveSession(session);
      }
      
      return Success(session.toDomain());
    } on supabase.AuthException catch (e) {
      return ResultFailure(
        AuthFailure(message: e.message),
      );
    } catch (e) {
      return ResultFailure(
        AuthFailure(message: 'Failed to sign up with phone: $e'),
      );
    }
  }

  @override
  Future<Result<void>> sendEmailVerification({required String email}) async {
    try {
      await _remoteDataSource.sendEmailVerification(email: email);
      return const Success(null);
    } on supabase.AuthException catch (e) {
      return ResultFailure(
        AuthFailure(message: e.message),
      );
    } catch (e) {
      return ResultFailure(
        AuthFailure(message: 'Failed to send email verification: $e'),
      );
    }
  }

  @override
  Future<Result<void>> sendPhoneVerification({required String phone}) async {
    try {
      await _remoteDataSource.sendPhoneVerification(phone: phone);
      return const Success(null);
    } on supabase.AuthException catch (e) {
      return ResultFailure(
        AuthFailure(message: e.message),
      );
    } catch (e) {
      return ResultFailure(
        AuthFailure(message: 'Failed to send phone verification: $e'),
      );
    }
  }

  @override
  Future<Result<AuthSession>> verifyEmail({
    required String email,
    required String otp,
  }) async {
    try {
      final session = await _remoteDataSource.verifyEmail(
        email: email,
        otp: otp,
      );
      
      await _localDataSource.saveSession(session);
      return Success(session.toDomain());
    } on supabase.AuthException catch (e) {
      return ResultFailure(
        AuthFailure(message: e.message),
      );
    } catch (e) {
      return ResultFailure(
        AuthFailure(message: 'Failed to verify email: $e'),
      );
    }
  }

  @override
  Future<Result<AuthSession>> verifyPhone({
    required String phone,
    required String otp,
  }) async {
    try {
      final session = await _remoteDataSource.verifyPhone(
        phone: phone,
        otp: otp,
      );
      
      await _localDataSource.saveSession(session);
      return Success(session.toDomain());
    } on supabase.AuthException catch (e) {
      return ResultFailure(
        AuthFailure(message: e.message),
      );
    } catch (e) {
      return ResultFailure(
        AuthFailure(message: 'Failed to verify phone: $e'),
      );
    }
  }

  @override
  Future<Result<AuthSession>> refreshToken({
    required String refreshToken,
  }) async {
    try {
      final session = await _remoteDataSource.refreshToken(
        refreshToken: refreshToken,
      );
      
      await _localDataSource.saveSession(session);
      return Success(session.toDomain());
    } on supabase.AuthException catch (e) {
      return ResultFailure(
        AuthFailure(message: e.message),
      );
    } catch (e) {
      return ResultFailure(
        AuthFailure(message: 'Failed to refresh token: $e'),
      );
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _remoteDataSource.signOut();
      await _localDataSource.clearSession();
      return const Success(null);
    } on supabase.AuthException catch (e) {
      return ResultFailure(
        AuthFailure(message: e.message),
      );
    } catch (e) {
      return ResultFailure(
        AuthFailure(message: 'Failed to sign out: $e'),
      );
    }
  }

  @override
  Future<Result<void>> sendPasswordReset({required String email}) async {
    try {
      await _remoteDataSource.sendPasswordReset(email: email);
      return const Success(null);
    } on supabase.AuthException catch (e) {
      return ResultFailure(
        AuthFailure(message: e.message),
      );
    } catch (e) {
      return ResultFailure(
        AuthFailure(message: 'Failed to send password reset: $e'),
      );
    }
  }

  @override
  Future<Result<void>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      // Note: Supabase handles password reset differently
      // This would typically be handled through email link flow
      return const ResultFailure(
        AuthFailure(message: 'Password reset is handled through email flow'),
      );
    } catch (e) {
      return ResultFailure(
        AuthFailure(message: 'Failed to reset password: $e'),
      );
    }
  }

  @override
  Future<Result<User>> updateProfile({
    required String userId,
    String? displayName,
    String? status,
    String? avatarUrl,
  }) async {
    try {
      final userModel = await _remoteDataSource.updateProfile(
        userId: userId,
        displayName: displayName,
        status: status,
        avatarUrl: avatarUrl,
      );
      
      // Update cached session if available
      final cachedSession = await _localDataSource.getCachedSession();
      if (cachedSession != null) {
        final updatedSession = AuthSessionModel(
          accessToken: cachedSession.accessToken,
          refreshToken: cachedSession.refreshToken,
          user: userModel,
          expiresAt: cachedSession.expiresAt,
          tokenType: cachedSession.tokenType,
        );
        await _localDataSource.saveSession(updatedSession);
      }
      
      return Success(userModel.toDomain());
    } on supabase.AuthException catch (e) {
      return ResultFailure(
        AuthFailure(message: e.message),
      );
    } catch (e) {
      return ResultFailure(
        AuthFailure(message: 'Failed to update profile: $e'),
      );
    }
  }

  @override
  Future<Result<void>> updateOnlineStatus({
    required String userId,
    required bool isOnline,
  }) async {
    try {
      await _remoteDataSource.updateOnlineStatus(
        userId: userId,
        isOnline: isOnline,
      );
      return const Success(null);
    } catch (e) {
      return ResultFailure(
        AuthFailure(message: 'Failed to update online status: $e'),
      );
    }
  }

  @override
  Future<Result<User>> getUserProfile({required String userId}) async {
    try {
      final userModel = await _remoteDataSource.getUserProfile(userId);
      return Success(userModel.toDomain());
    } catch (e) {
      return ResultFailure(
        AuthFailure(message: 'Failed to get user profile: $e'),
      );
    }
  }

  @override
  Stream<AuthSession?> get authStateChanges {
    return _remoteDataSource.authStateChanges.map(
      (sessionModel) => sessionModel?.toDomain(),
    );
  }
}