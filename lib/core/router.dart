import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/analytics_service.dart';
import '../presentation/main_scaffold.dart';
import '../presentation/currency_manage_screen.dart';
import '../presentation/splash_screen.dart';
import '../presentation/settings_screen.dart';
import '../presentation/shopping_helper_settings_screen.dart';
import '../presentation/help_screen.dart';
import '../presentation/onboarding_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    observers: [AnalyticsObserver()],
    routes: [
      GoRoute(
        path: '/splash',
        name: 'Splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/',
        name: 'Home',
        builder: (context, state) => const MainScaffold(),
      ),
      GoRoute(
        path: '/currency_manage',
        name: 'CurrencyManage',
        builder: (context, state) {
          bool isSelection = false;
          String? initialSelectedId;
          bool excludeKrw = false;

          if (state.extra is bool) {
            isSelection = state.extra as bool;
          } else if (state.extra is Map) {
            final map = state.extra as Map;
            isSelection = map['isSelectionMode'] ?? false;
            initialSelectedId = map['initialSelectedId'];
            excludeKrw = map['excludeKrw'] ?? false;
          }

          return CurrencyManageScreen(
            isSelectionMode: isSelection,
            initialSelectedId: initialSelectedId,
            excludeKrw: excludeKrw,
          );
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'Settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/shopping_helper_settings',
        name: 'ShoppingHelperSettings',
        builder: (context, state) => const ShoppingHelperSettingsScreen(),
      ),
      GoRoute(
        path: '/help',
        name: 'Help',
        builder: (context, state) => const HelpScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'Onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
    ],
  );
});

class AnalyticsObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _logScreen(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) _logScreen(newRoute);
  }

  void _logScreen(Route<dynamic> route) {
    if (route.settings.name != null) {
      AnalyticsService.instance.logScreenView(route.settings.name!);
    } else {
      // If name is null, we can use the path from some other logic or just skip
      // For GoRouter, we might need to be more careful.
    }
  }
}
