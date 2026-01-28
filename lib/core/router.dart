import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/main_scaffold.dart';
import '../presentation/currency_manage_screen.dart';
import '../presentation/splash_screen.dart';
import '../presentation/settings_screen.dart';
import '../presentation/shopping_helper_settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/', builder: (context, state) => const MainScaffold()),
      GoRoute(
        path: '/currency_manage',
        builder: (context, state) => const CurrencyManageScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/shopping_helper_settings',
        builder: (context, state) => const ShoppingHelperSettingsScreen(),
      ),
    ],
  );
});
