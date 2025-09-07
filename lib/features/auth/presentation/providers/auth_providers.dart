import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/providers/service_providers.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../domain/usecases/get_current_session_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/refresh_token_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/verify_email_usecase.dart';
import '../../domain/usecases/send_password_reset_usecase.dart';
import 'auth_notifier.dart';
import 'auth_state.dart';

/// Provider for secure storage
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
});

/// Provider for auth local data source
final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthLocalDataSource(secureStorage);
});

/// Provider for auth repository using service factory
final authRepositoryProvider = FutureProvider<IAuthRepository>((ref) async {
  return ref.watch(authServiceProvider.future);
});

/// Provider for login use case
final loginUseCaseProvider = FutureProvider<LoginUseCase>((ref) async {
  final repository = await ref.watch(authRepositoryProvider.future);
  return LoginUseCase(repository);
});

/// Provider for register use case
final registerUseCaseProvider = FutureProvider<RegisterUseCase>((ref) async {
  final repository = await ref.watch(authRepositoryProvider.future);
  return RegisterUseCase(repository);
});

/// Provider for logout use case
final logoutUseCaseProvider = FutureProvider<LogoutUseCase>((ref) async {
  final repository = await ref.watch(authRepositoryProvider.future);
  return LogoutUseCase(repository);
});

/// Provider for verify email use case
final verifyEmailUseCaseProvider = FutureProvider<VerifyEmailUseCase>((ref) async {
  final repository = await ref.watch(authRepositoryProvider.future);
  return VerifyEmailUseCase(repository);
});

/// Provider for refresh token use case
final refreshTokenUseCaseProvider = FutureProvider<RefreshTokenUseCase>((ref) async {
  final repository = await ref.watch(authRepositoryProvider.future);
  return RefreshTokenUseCase(repository);
});

/// Provider for get current session use case
final getCurrentSessionUseCaseProvider = FutureProvider<GetCurrentSessionUseCase>((ref) async {
  final repository = await ref.watch(authRepositoryProvider.future);
  return GetCurrentSessionUseCase(repository);
});

/// Provider for send password reset use case
final sendPasswordResetUseCaseProvider = FutureProvider<SendPasswordResetUseCase>((ref) async {
  final repository = await ref.watch(authRepositoryProvider.future);
  return SendPasswordResetUseCase(repository);
});

/// Provider for auth state notifier
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});