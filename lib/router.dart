import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:preset/providers/auth_provider.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/settings_page.dart';

GoRouter createRouter(ProviderContainer container) {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          return const HomePage();
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (BuildContext context, GoRouterState state) {
          return const SettingsPage();
        },
      ),
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) {
          return const LoginPage();
        },
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final authState = container.read(authNotifierProvider);
      final isLoggedIn = authState.isLoggedIn;
      final isGoingToLogin = state.matchedLocation == '/login';
      final isGoingToSettings = state.matchedLocation == '/settings';

      if (!isLoggedIn && isGoingToSettings) {
        return '/login';
      }
      if (isLoggedIn && isGoingToLogin) {
        return '/';
      }
      return null;
    },
    refreshListenable: GoRouterRefreshStream(container),
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(ProviderContainer container) {
    container.listen<AuthState>(
      authNotifierProvider,
      (previous, next) {
        if (previous?.isLoggedIn != next.isLoggedIn) {
          notifyListeners();
        }
      },
    );
  }
}