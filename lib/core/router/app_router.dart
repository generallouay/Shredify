import 'package:go_router/go_router.dart';
import '../../features/shared/widgets/app_shell.dart';
import '../../features/home/home_screen.dart';
import '../../features/foods/foods_screen.dart';
import '../../features/foods/food_detail_screen.dart';
import '../../features/meals/meal_screen.dart';
import '../../features/meals/meal_history_screen.dart';
import '../../features/daily/daily_screen.dart';
import '../../features/settings/settings_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
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
  ],
);
