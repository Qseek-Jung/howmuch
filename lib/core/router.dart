import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/main_scaffold.dart';
import '../presentation/currency_manage_screen.dart';
import '../presentation/splash_screen.dart';
import '../presentation/settings_screen.dart';
import '../presentation/shopping_helper_settings_screen.dart';
import '../presentation/help_screen.dart';

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
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/shopping_helper_settings',
        builder: (context, state) => const ShoppingHelperSettingsScreen(),
      ),
      GoRoute(path: '/help', builder: (context, state) => const HelpScreen()),
    ],
  );
});
