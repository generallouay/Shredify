import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../features/shared/widgets/app_shell.dart';
import '../../features/auth/sign_in_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/foods/foods_screen.dart';
import '../../features/foods/food_detail_screen.dart';
import '../../features/meals/meal_screen.dart';
import '../../features/meals/meal_history_screen.dart';
import '../../features/meals/food_selector_page.dart';
import '../../features/daily/daily_screen.dart';
import '../../features/settings/settings_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthRouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final user = ref.read(firebaseAuthProvider).currentUser;
      final atSignIn = state.matchedLocation == '/sign-in';
      if (user == null) return atSignIn ? null : '/sign-in';
      if (atSignIn) return '/';
      return null;
    },
    routes: [
      GoRoute(
          path: '/sign-in', builder: (_, __) => const SignInScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/foods',
              builder: (_, __) => const FoodsScreen(),
              routes: [
                GoRoute(
                    path: 'new',
                    builder: (_, __) => const FoodDetailScreen()),
                GoRoute(
                    path: ':id',
                    builder: (_, s) =>
                        FoodDetailScreen(foodId: s.pathParameters['id'])),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/history',
                builder: (_, __) => const MealHistoryScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/daily',
                builder: (_, __) => const DailyScreen()),
          ]),
        ],
      ),
      GoRoute(
          path: '/meals/new',
          builder: (_, __) => const MealScreen()),
      GoRoute(
          path: '/meals/:id',
          builder: (_, s) =>
              MealScreen(mealId: s.pathParameters['id'])),
      GoRoute(
          path: '/settings',
          builder: (_, __) => const SettingsScreen()),
      GoRoute(
          path: '/food-selector',
          builder: (_, __) => const FoodSelectorPage()),
    ],
  );
});

class _AuthRouterNotifier extends ChangeNotifier {
  final Ref _ref;
  late final StreamSubscription<User?> _sub;

  _AuthRouterNotifier(this._ref) {
    _sub = _ref
        .read(firebaseAuthProvider)
        .authStateChanges()
        .listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
