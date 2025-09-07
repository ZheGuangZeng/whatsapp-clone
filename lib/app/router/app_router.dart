import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../pages/calls_page.dart';
import '../pages/home_page.dart';
import '../pages/meeting_lobby_page.dart';
import '../pages/meeting_room_page.dart';
import '../pages/onboarding_page.dart';
import '../pages/settings_page.dart';
import '../pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/profile_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/verification_page.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/providers/auth_state.dart';
import '../../features/chat/presentation/pages/chat_list_page.dart';
import '../../features/chat/presentation/pages/chat_room_page.dart';

/// Global navigation key for programmatic navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// App router provider using go_router with authentication guards
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);
  
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) => _authGuard(authState, state),
    routes: [
      // Splash and Onboarding
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      
      // Authentication Routes
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const LoginPage(),
        routes: [
          GoRoute(
            path: 'register',
            name: 'register',
            builder: (context, state) => const RegisterPage(),
          ),
          GoRoute(
            path: 'verify',
            name: 'verify',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return VerificationPage(
                email: extra?['email'] as String?,
                phone: extra?['phone'] as String?,
              );
            },
          ),
          GoRoute(
            path: 'profile-setup',
            name: 'profile-setup',
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),
      
      // Main App Shell
      ShellRoute(
        builder: (context, state, child) {
          return HomePage(child: child);
        },
        routes: [
          GoRoute(
            path: '/chats',
            name: 'chats',
            builder: (context, state) => const ChatListPage(),
            routes: [
              GoRoute(
                path: ':roomId',
                name: 'chat-room',
                builder: (context, state) {
                  final roomId = state.pathParameters['roomId']!;
                  // We'll need to get the room object from the provider
                  return ChatRoomPage.fromId(roomId);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/calls',
            name: 'calls',
            builder: (context, state) => const CallsPage(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
      
      // Meeting Routes (outside main shell)
      GoRoute(
        path: '/meeting',
        name: 'meeting',
        routes: [
          GoRoute(
            path: 'lobby/:meetingId',
            name: 'meeting-lobby',
            builder: (context, state) {
              final meetingId = state.pathParameters['meetingId']!;
              return MeetingLobbyPage(meetingId: meetingId);
            },
          ),
          GoRoute(
            path: 'room/:meetingId',
            name: 'meeting-room',
            builder: (context, state) {
              final meetingId = state.pathParameters['meetingId']!;
              return MeetingRoomPage(meetingId: meetingId);
            },
          ),
        ],
      ),
    ],
  );
});

/// Authentication guard to redirect users based on auth state
String? _authGuard(AuthState authState, GoRouterState state) {
  final isOnSplash = state.matchedLocation == '/splash';
  final isOnOnboarding = state.matchedLocation == '/onboarding';
  final isOnAuth = state.matchedLocation.startsWith('/auth');
  final isAuthenticated = authState is AuthenticatedState;
  final needsOnboarding = authState is UnauthenticatedState && 
      authState.isFirstTime;

  // Show splash screen first
  if (isOnSplash) return null;

  // Handle onboarding for first-time users
  if (needsOnboarding && !isOnOnboarding && !isOnAuth) {
    return '/onboarding';
  }

  // Redirect to auth if not authenticated
  if (!isAuthenticated && !isOnAuth && !isOnOnboarding) {
    return '/auth';
  }

  // Redirect to main app if authenticated and on auth/onboarding pages
  if (isAuthenticated && (isOnAuth || isOnOnboarding)) {
    return '/chats';
  }

  // No redirect needed
  return null;
}