import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/get_current_session_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/refresh_token_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/verify_email_usecase.dart';
import 'auth_providers.dart';
import 'auth_state.dart';

/// Auth state notifier that manages authentication state
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref) : super(const AuthState.initial()) {
    _init();
  }

  final Ref _ref;
  StreamSubscription<AuthSession?>? _authSubscription;
  Timer? _tokenRefreshTimer;

  /// Initialize the auth notifier
  void _init() {
    _getCurrentSession();
    _listenToAuthChanges();
  }

  /// Get current session on app start
  Future<void> _getCurrentSession() async {
    state = state.copyWith(isLoading: true);
    
    final useCase = _ref.read(getCurrentSessionUseCaseProvider);
    final result = await useCase.call();
    
    result.when(
      success: (session) {
        if (session != null) {
          state = AuthState.authenticated(session);
          _scheduleTokenRefresh(session);
        } else {
          state = const AuthState.unauthenticated();
        }
      },
      failure: (failure) {
        state = AuthState.error(failure.message);
      },
    );
  }

  /// Listen to auth state changes from Supabase
  void _listenToAuthChanges() {
    final repository = _ref.read(authRepositoryProvider);
    _authSubscription = repository.authStateChanges.listen(
      (session) {
        if (session != null) {
          state = AuthState.authenticated(session);
          _scheduleTokenRefresh(session);
        } else {
          state = const AuthState.unauthenticated();
          _cancelTokenRefresh();
        }
      },
      onError: (error) {
        state = AuthState.error(error.toString());
      },
    );
  }

  /// Login with email or phone
  Future<void> login({
    String? email,
    String? phone,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final useCase = _ref.read(loginUseCaseProvider);
    final params = LoginParams(
      email: email,
      phone: phone,
      password: password,
    );

    final result = await useCase.call(params);

    result.when(
      success: (session) {
        state = AuthState.authenticated(session);
        _scheduleTokenRefresh(session);
      },
      failure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
    );
  }

  /// Register with email or phone
  Future<void> register({
    String? email,
    String? phone,
    required String password,
    required String displayName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final useCase = _ref.read(registerUseCaseProvider);
    final params = RegisterParams(
      email: email,
      phone: phone,
      password: password,
      displayName: displayName,
    );

    final result = await useCase.call(params);

    result.when(
      success: (session) {
        // Check if this is a complete session or needs verification
        if (session.accessToken.isNotEmpty) {
          state = AuthState.authenticated(session);
          _scheduleTokenRefresh(session);
        } else {
          state = AuthState.verificationRequired(
            email: email,
            phone: phone,
            tempSession: session,
          );
        }
      },
      failure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
    );
  }

  /// Verify email with OTP
  Future<void> verifyEmail({
    required String email,
    required String otp,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final useCase = _ref.read(verifyEmailUseCaseProvider);
    final params = VerifyEmailParams(email: email, otp: otp);

    final result = await useCase.call(params);

    result.when(
      success: (session) {
        state = AuthState.authenticated(session);
        _scheduleTokenRefresh(session);
      },
      failure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
    );
  }

  /// Logout current user
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);

    final useCase = _ref.read(logoutUseCaseProvider);
    final result = await useCase.call();

    result.when(
      success: (_) {
        state = const AuthState.unauthenticated();
        _cancelTokenRefresh();
      },
      failure: (failure) {
        state = AuthState.error(failure.message);
      },
    );
  }

  /// Clear any error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Schedule automatic token refresh
  void _scheduleTokenRefresh(AuthSession session) {
    _cancelTokenRefresh();

    if (session.isExpiringSoon) {
      _refreshToken(session.refreshToken);
      return;
    }

    // Schedule refresh 5 minutes before expiry
    final timeUntilRefresh = session.expiresAt
        .subtract(const Duration(minutes: 5))
        .difference(DateTime.now());

    if (timeUntilRefresh.isNegative) {
      _refreshToken(session.refreshToken);
      return;
    }

    _tokenRefreshTimer = Timer(timeUntilRefresh, () {
      _refreshToken(session.refreshToken);
    });
  }

  /// Refresh the access token
  Future<void> _refreshToken(String refreshToken) async {
    final useCase = _ref.read(refreshTokenUseCaseProvider);
    final params = RefreshTokenParams(refreshToken: refreshToken);

    final result = await useCase.call(params);

    result.when(
      success: (session) {
        if (state is AuthenticatedState) {
          state = AuthState.authenticated(session);
          _scheduleTokenRefresh(session);
        }
      },
      failure: (failure) {
        // If refresh fails, logout the user
        state = const AuthState.unauthenticated();
        _cancelTokenRefresh();
      },
    );
  }

  /// Cancel the token refresh timer
  void _cancelTokenRefresh() {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = null;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _tokenRefreshTimer?.cancel();
    super.dispose();
  }
}