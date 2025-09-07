import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/auth_session_model.dart';
import '../models/user_model.dart';

/// Remote data source for authentication operations using Supabase
class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._supabase);

  final SupabaseClient _supabase;

  /// Gets the current session from Supabase
  Future<AuthSessionModel?> getCurrentSession() async {
    final session = _supabase.auth.currentSession;
    if (session == null) return null;

    final user = await _getUserProfile(session.user.id);
    return AuthSessionModel.fromSupabaseSession(session, user);
  }

  /// Signs in with email and password
  Future<AuthSessionModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.session == null || response.user == null) {
      throw const AuthException('Failed to sign in');
    }

    final user = await _getUserProfile(response.user!.id);
    return AuthSessionModel.fromSupabaseSession(response.session!, user);
  }

  /// Signs in with phone and password
  Future<AuthSessionModel> signInWithPhone({
    required String phone,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      phone: phone,
      password: password,
    );

    if (response.session == null || response.user == null) {
      throw const AuthException('Failed to sign in');
    }

    final user = await _getUserProfile(response.user!.id);
    return AuthSessionModel.fromSupabaseSession(response.session!, user);
  }

  /// Signs up with email and password
  Future<AuthSessionModel> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw const AuthException('Failed to sign up');
    }

    // Create user profile
    await _createUserProfile(
      userId: response.user!.id,
      displayName: displayName,
      email: email,
    );

    // If session is available, return it; otherwise return a temp session for verification
    if (response.session != null) {
      final user = await _getUserProfile(response.user!.id);
      return AuthSessionModel.fromSupabaseSession(response.session!, user);
    }

    // Return a temporary session for verification flow
    final user = UserModel(
      id: response.user!.id,
      email: email,
      displayName: displayName,
      createdAt: DateTime.now(),
    );

    return AuthSessionModel(
      accessToken: '',
      refreshToken: '',
      user: user,
      expiresAt: DateTime.now(),
      tokenType: 'Bearer',
    );
  }

  /// Signs up with phone and password
  Future<AuthSessionModel> signUpWithPhone({
    required String phone,
    required String password,
    required String displayName,
  }) async {
    final response = await _supabase.auth.signUp(
      phone: phone,
      password: password,
    );

    if (response.user == null) {
      throw const AuthException('Failed to sign up');
    }

    // Create user profile
    await _createUserProfile(
      userId: response.user!.id,
      displayName: displayName,
      phone: phone,
    );

    // If session is available, return it; otherwise return a temp session for verification
    if (response.session != null) {
      final user = await _getUserProfile(response.user!.id);
      return AuthSessionModel.fromSupabaseSession(response.session!, user);
    }

    // Return a temporary session for verification flow
    final user = UserModel(
      id: response.user!.id,
      email: response.user!.email ?? '',
      phone: phone,
      displayName: displayName,
      createdAt: DateTime.now(),
    );

    return AuthSessionModel(
      accessToken: '',
      refreshToken: '',
      user: user,
      expiresAt: DateTime.now(),
      tokenType: 'Bearer',
    );
  }

  /// Sends email verification
  Future<void> sendEmailVerification({required String email}) async {
    await _supabase.auth.resend(
      type: OtpType.signup,
      email: email,
    );
  }

  /// Sends phone verification
  Future<void> sendPhoneVerification({required String phone}) async {
    await _supabase.auth.resend(
      type: OtpType.sms,
      phone: phone,
    );
  }

  /// Verifies email with OTP
  Future<AuthSessionModel> verifyEmail({
    required String email,
    required String otp,
  }) async {
    final response = await _supabase.auth.verifyOTP(
      type: OtpType.email,
      token: otp,
      email: email,
    );

    if (response.session == null || response.user == null) {
      throw const AuthException('Failed to verify email');
    }

    final user = await _getUserProfile(response.user!.id);
    return AuthSessionModel.fromSupabaseSession(response.session!, user);
  }

  /// Verifies phone with OTP
  Future<AuthSessionModel> verifyPhone({
    required String phone,
    required String otp,
  }) async {
    final response = await _supabase.auth.verifyOTP(
      type: OtpType.sms,
      token: otp,
      phone: phone,
    );

    if (response.session == null || response.user == null) {
      throw const AuthException('Failed to verify phone');
    }

    final user = await _getUserProfile(response.user!.id);
    return AuthSessionModel.fromSupabaseSession(response.session!, user);
  }

  /// Refreshes the access token
  Future<AuthSessionModel> refreshToken({required String refreshToken}) async {
    final response = await _supabase.auth.refreshSession(refreshToken);

    if (response.session == null || response.user == null) {
      throw const AuthException('Failed to refresh token');
    }

    final user = await _getUserProfile(response.user!.id);
    return AuthSessionModel.fromSupabaseSession(response.session!, user);
  }

  /// Signs out the current user
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Sends password reset email
  Future<void> sendPasswordReset({required String email}) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  /// Updates user profile
  Future<UserModel> updateProfile({
    required String userId,
    String? displayName,
    String? status,
    String? avatarUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (displayName != null) updates['display_name'] = displayName;
    if (status != null) updates['status'] = status;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    updates['updated_at'] = DateTime.now().toIso8601String();

    await _supabase.from('profiles').update(updates).eq('id', userId);

    return _getUserProfile(userId);
  }

  /// Updates user's online status
  Future<void> updateOnlineStatus({
    required String userId,
    required bool isOnline,
  }) async {
    await _supabase.from('profiles').update({
      'is_online': isOnline,
      'last_seen': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  /// Gets user profile by ID
  Future<UserModel> getUserProfile(String userId) async {
    return _getUserProfile(userId);
  }

  /// Gets user profile from the profiles table
  Future<UserModel> _getUserProfile(String userId) async {
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    final user = _supabase.auth.currentUser!;
    return UserModel.fromSupabaseUser(user.toJson(), response);
  }

  /// Creates a new user profile in the profiles table
  Future<void> _createUserProfile({
    required String userId,
    required String displayName,
    String? email,
    String? phone,
  }) async {
    await _supabase.from('profiles').insert({
      'id': userId,
      'display_name': displayName,
      'email': email,
      'phone': phone,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Stream of authentication state changes
  Stream<AuthSessionModel?> get authStateChanges {
    return _supabase.auth.onAuthStateChange.asyncMap((data) async {
      final session = data.session;
      if (session == null) return null;

      try {
        final user = await _getUserProfile(session.user.id);
        return AuthSessionModel.fromSupabaseSession(session, user);
      } catch (e) {
        return null;
      }
    });
  }
}