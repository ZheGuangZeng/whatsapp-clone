import '../../../../core/utils/result.dart';
import '../entities/auth_session.dart';
import '../entities/user.dart';

/// Repository interface for authentication operations
abstract interface class IAuthRepository {
  /// Gets the current authenticated session if available
  Future<Result<AuthSession?>> getCurrentSession();
  
  /// Signs in with email and password
  Future<Result<AuthSession>> signInWithEmail({
    required String email,
    required String password,
  });
  
  /// Signs in with phone number and password
  Future<Result<AuthSession>> signInWithPhone({
    required String phone,
    required String password,
  });
  
  /// Signs up with email and password
  Future<Result<AuthSession>> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  });
  
  /// Signs up with phone number and password
  Future<Result<AuthSession>> signUpWithPhone({
    required String phone,
    required String password,
    required String displayName,
  });
  
  /// Sends email verification for account activation
  Future<Result<void>> sendEmailVerification({
    required String email,
  });
  
  /// Sends SMS verification for phone number
  Future<Result<void>> sendPhoneVerification({
    required String phone,
  });
  
  /// Verifies email with OTP code
  Future<Result<AuthSession>> verifyEmail({
    required String email,
    required String otp,
  });
  
  /// Verifies phone with OTP code
  Future<Result<AuthSession>> verifyPhone({
    required String phone,
    required String otp,
  });
  
  /// Refreshes the access token using refresh token
  Future<Result<AuthSession>> refreshToken({
    required String refreshToken,
  });
  
  /// Signs out the current user
  Future<Result<void>> signOut();
  
  /// Sends password reset email
  Future<Result<void>> sendPasswordReset({
    required String email,
  });
  
  /// Resets password with token and new password
  Future<Result<void>> resetPassword({
    required String token,
    required String newPassword,
  });
  
  /// Updates user profile information
  Future<Result<User>> updateProfile({
    required String userId,
    String? displayName,
    String? status,
    String? avatarUrl,
  });
  
  /// Updates user's online status
  Future<Result<void>> updateOnlineStatus({
    required String userId,
    required bool isOnline,
  });
  
  /// Gets user profile by ID
  Future<Result<User>> getUserProfile({
    required String userId,
  });
  
  /// Stream of authentication state changes
  Stream<AuthSession?> get authStateChanges;
}