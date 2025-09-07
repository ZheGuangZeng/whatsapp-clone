import 'dart:async';
import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../features/auth/data/models/auth_session_model.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/auth/domain/entities/auth_session.dart';
import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/domain/repositories/i_auth_repository.dart';
import '../errors/failures.dart';
import '../utils/result.dart';

/// Real Supabase implementation of IAuthRepository
/// Provides actual authentication services using Supabase backend
class RealSupabaseAuthService implements IAuthRepository {
  static const String _logTag = 'RealSupabaseAuthService';
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(milliseconds: 500);

  final SupabaseClient _client;
  late final StreamController<AuthSession?> _authController;
  StreamSubscription<AuthState>? _authSubscription;

  RealSupabaseAuthService({SupabaseClient? client}) 
      : _client = client ?? Supabase.instance.client {
    _authController = StreamController<AuthSession?>.broadcast();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    _authSubscription = _client.auth.onAuthStateChange.listen(
      (data) {
        final session = data.session;
        developer.log('Auth state changed: ${session?.user.id}', name: _logTag);
        
        if (session != null) {
          final authSession = _sessionToAuthSession(session);
          _authController.add(authSession);
        } else {
          _authController.add(null);
        }
      },
      onError: (Object error) {
        developer.log('Auth state error: $error', name: _logTag, level: 1000);
        _authController.addError(AuthFailure(message: 'Auth state error: $error'));
      },
    );
  }

  @override
  Future<Result<AuthSession?>> getCurrentSession() async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) {
        developer.log('No current session found', name: _logTag);
        return const Success(null);
      }

      final authSession = _sessionToAuthSession(session);
      developer.log('Retrieved current session for user: ${authSession.user.id}', name: _logTag);
      return Success(authSession);
    } catch (error) {
      developer.log('Failed to get current session: $error', name: _logTag, level: 1000);
      return ResultFailure(AuthFailure(message: 'Failed to get current session: $error'));
    }
  }

  @override
  Future<Result<AuthSession>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    developer.log('Signing in with email: $email', name: _logTag);
    
    return await _retryOperation(() async {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session == null) {
        throw Exception('Sign in failed: No session returned');
      }

      final authSession = _sessionToAuthSession(response.session!);
      developer.log('Successfully signed in user: ${authSession.user.email}', name: _logTag);
      return authSession;
    });
  }

  @override
  Future<Result<AuthSession>> signInWithPhone({
    required String phone,
    required String password,
  }) async {
    developer.log('Signing in with phone: $phone', name: _logTag);
    
    return await _retryOperation(() async {
      final response = await _client.auth.signInWithPassword(
        phone: phone,
        password: password,
      );

      if (response.session == null) {
        throw Exception('Sign in failed: No session returned');
      }

      final authSession = _sessionToAuthSession(response.session!);
      developer.log('Successfully signed in user: ${authSession.user.phone}', name: _logTag);
      return authSession;
    });
  }

  @override
  Future<Result<AuthSession>> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    developer.log('Signing up with email: $email', name: _logTag);
    
    return await _retryOperation(() async {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'display_name': displayName,
        },
      );

      if (response.session == null) {
        throw Exception('Sign up failed: No session returned - email verification may be required');
      }

      // Create user profile in profiles table
      await _createUserProfile(response.session!.user.id, displayName, email);

      final authSession = _sessionToAuthSession(response.session!);
      developer.log('Successfully signed up user: ${authSession.user.email}', name: _logTag);
      return authSession;
    });
  }

  @override
  Future<Result<AuthSession>> signUpWithPhone({
    required String phone,
    required String password,
    required String displayName,
  }) async {
    developer.log('Signing up with phone: $phone', name: _logTag);
    
    return await _retryOperation(() async {
      final response = await _client.auth.signUp(
        phone: phone,
        password: password,
        data: {
          'display_name': displayName,
        },
      );

      if (response.session == null) {
        throw Exception('Sign up failed: No session returned - phone verification may be required');
      }

      // Create user profile in profiles table
      await _createUserProfile(response.session!.user.id, displayName, null, phone);

      final authSession = _sessionToAuthSession(response.session!);
      developer.log('Successfully signed up user: ${authSession.user.phone}', name: _logTag);
      return authSession;
    });
  }

  @override
  Future<Result<void>> sendEmailVerification({required String email}) async {
    developer.log('Sending email verification to: $email', name: _logTag);
    
    return await _retryOperation(() async {
      await _client.auth.resend(
        type: OtpType.signup,
        email: email,
      );

      developer.log('Email verification sent successfully to: $email', name: _logTag);
      return;
    });
  }

  @override
  Future<Result<void>> sendPhoneVerification({required String phone}) async {
    developer.log('Sending phone verification to: $phone', name: _logTag);
    
    return await _retryOperation(() async {
      await _client.auth.resend(
        type: OtpType.sms,
        phone: phone,
      );

      developer.log('Phone verification sent successfully to: $phone', name: _logTag);
      return;
    });
  }

  @override
  Future<Result<AuthSession>> verifyEmail({
    required String email,
    required String otp,
  }) async {
    developer.log('Verifying email OTP for: $email', name: _logTag);
    
    return await _retryOperation(() async {
      final response = await _client.auth.verifyOTP(
        type: OtpType.signup,
        email: email,
        token: otp,
      );

      if (response.session == null) {
        throw Exception('Email verification failed: No session returned');
      }

      final authSession = _sessionToAuthSession(response.session!);
      developer.log('Successfully verified email for user: ${authSession.user.email}', name: _logTag);
      return authSession;
    });
  }

  @override
  Future<Result<AuthSession>> verifyPhone({
    required String phone,
    required String otp,
  }) async {
    developer.log('Verifying phone OTP for: $phone', name: _logTag);
    
    return await _retryOperation(() async {
      final response = await _client.auth.verifyOTP(
        type: OtpType.sms,
        phone: phone,
        token: otp,
      );

      if (response.session == null) {
        throw Exception('Phone verification failed: No session returned');
      }

      final authSession = _sessionToAuthSession(response.session!);
      developer.log('Successfully verified phone for user: ${authSession.user.phone}', name: _logTag);
      return authSession;
    });
  }

  @override
  Future<Result<AuthSession>> refreshToken({required String refreshToken}) async {
    developer.log('Refreshing token', name: _logTag);
    
    return await _retryOperation(() async {
      final response = await _client.auth.refreshSession(refreshToken);

      if (response.session == null) {
        throw Exception('Token refresh failed: No session returned');
      }

      final authSession = _sessionToAuthSession(response.session!);
      developer.log('Successfully refreshed token for user: ${authSession.user.id}', name: _logTag);
      return authSession;
    });
  }

  @override
  Future<Result<void>> signOut() async {
    developer.log('Signing out current user', name: _logTag);
    
    return await _retryOperation(() async {
      await _client.auth.signOut();
      developer.log('Successfully signed out', name: _logTag);
      return;
    });
  }

  @override
  Future<Result<void>> sendPasswordReset({required String email}) async {
    developer.log('Sending password reset to: $email', name: _logTag);
    
    return await _retryOperation(() async {
      await _client.auth.resetPasswordForEmail(email);
      developer.log('Password reset sent successfully to: $email', name: _logTag);
      return;
    });
  }

  @override
  Future<Result<void>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    developer.log('Resetting password with token', name: _logTag);
    
    return await _retryOperation(() async {
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      developer.log('Password reset successfully', name: _logTag);
      return;
    });
  }

  @override
  Future<Result<User>> updateProfile({
    required String userId,
    String? displayName,
    String? status,
    String? avatarUrl,
  }) async {
    developer.log('Updating profile for user: $userId', name: _logTag);
    
    return await _retryOperation(() async {
      final updates = <String, dynamic>{};
      if (displayName != null) updates['display_name'] = displayName;
      if (status != null) updates['status'] = status;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      // Update auth user metadata
      await _client.auth.updateUser(UserAttributes(data: updates));

      // Update profiles table
      await _client
          .from('profiles')
          .update(updates)
          .eq('id', userId);

      // Fetch updated profile
      final profileResult = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      final authUser = _client.auth.currentUser;
      if (authUser == null) {
        throw Exception('No authenticated user found');
      }

      final userModel = UserModel.fromSupabaseUser(
        authUser.toJson(),
        profileResult,
      );

      developer.log('Successfully updated profile for user: $userId', name: _logTag);
      return userModel.toDomain();
    });
  }

  @override
  Future<Result<void>> updateOnlineStatus({
    required String userId,
    required bool isOnline,
  }) async {
    developer.log('Updating online status for user: $userId to $isOnline', name: _logTag);
    
    return await _retryOperation(() async {
      await _client
          .from('profiles')
          .update({
            'is_online': isOnline,
            'last_seen': isOnline ? null : DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      developer.log('Successfully updated online status for user: $userId', name: _logTag);
      return;
    });
  }

  @override
  Future<Result<User>> getUserProfile({required String userId}) async {
    developer.log('Fetching user profile: $userId', name: _logTag);
    
    return await _retryOperation(() async {
      final profileResult = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      // For user profiles, we need to construct a minimal user object
      // since we don't have access to the auth user data
      final userModel = UserModel(
        id: profileResult['id'] as String,
        email: profileResult['email'] as String? ?? '',
        phone: profileResult['phone'] as String?,
        displayName: profileResult['display_name'] as String? ?? 'Unknown User',
        avatarUrl: profileResult['avatar_url'] as String?,
        status: profileResult['status'] as String?,
        createdAt: DateTime.parse(profileResult['created_at'] as String),
        lastSeen: profileResult['last_seen'] != null
            ? DateTime.parse(profileResult['last_seen'] as String)
            : null,
        isOnline: profileResult['is_online'] as bool? ?? false,
      );

      developer.log('Successfully fetched user profile: $userId', name: _logTag);
      return userModel.toDomain();
    });
  }

  @override
  Stream<AuthSession?> get authStateChanges => _authController.stream;

  /// Helper method to create user profile in profiles table
  Future<void> _createUserProfile(
    String userId,
    String displayName,
    String? email,
    [String? phone]
  ) async {
    try {
      await _client.from('profiles').insert({
        'id': userId,
        'display_name': displayName,
        'email': email,
        'phone': phone,
        'is_online': true,
        'created_at': DateTime.now().toIso8601String(),
      });
      developer.log('Created user profile for: $userId', name: _logTag);
    } catch (error) {
      developer.log('Failed to create user profile: $error', name: _logTag, level: 1000);
      // Don't throw here - profile creation might fail due to race conditions
    }
  }

  /// Helper method to convert Supabase Session to AuthSession
  AuthSession _sessionToAuthSession(Session session) {
    final authUser = session.user;
    
    final userModel = UserModel(
      id: authUser.id,
      email: authUser.email ?? '',
      phone: authUser.phone,
      displayName: authUser.userMetadata?['display_name'] as String? ?? 
                   authUser.email ?? 
                   'Unknown User',
      avatarUrl: authUser.userMetadata?['avatar_url'] as String?,
      status: authUser.userMetadata?['status'] as String?,
      createdAt: DateTime.parse(authUser.createdAt),
      lastSeen: DateTime.now(),
      isOnline: true,
    );

    return AuthSessionModel(
      user: userModel,
      accessToken: session.accessToken,
      refreshToken: session.refreshToken ?? '',
      expiresAt: DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000),
      tokenType: session.tokenType ?? 'bearer',
    ).toDomain();
  }

  /// Retry mechanism for operations
  Future<Result<T>> _retryOperation<T>(Future<T> Function() operation) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final result = await operation();
        return Success(result);
      } catch (error) {
        developer.log(
          'Operation attempt $attempt failed: $error', 
          name: _logTag, 
          level: attempt == _maxRetries ? 1000 : 500,
        );

        if (attempt == _maxRetries) {
          // Determine appropriate failure type
          if (error is AuthException) {
            if (error.statusCode == '401' || error.statusCode == '403') {
              return ResultFailure(UnauthorizedFailure(message: error.message));
            } else {
              return ResultFailure(AuthFailure(message: error.message));
            }
          } else if (error is PostgrestException) {
            return ResultFailure(DatabaseFailure(error.message));
          } else if (error.toString().contains('network') || 
                     error.toString().contains('connection')) {
            return ResultFailure(NetworkFailure(message: 'Network error: $error'));
          } else {
            return ResultFailure(UnknownFailure(message: 'Unexpected error: $error'));
          }
        }

        // Wait before retrying
        if (attempt < _maxRetries) {
          await Future<void>.delayed(_retryDelay * attempt);
        }
      }
    }

    return ResultFailure(UnknownFailure(message: 'Operation failed after $_maxRetries attempts'));
  }

  /// Dispose resources
  void dispose() {
    _authSubscription?.cancel();
    _authController.close();
    developer.log('RealSupabaseAuthService disposed', name: _logTag);
  }
}