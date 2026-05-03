import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/models/meal.dart';
import '../../core/providers/meals_provider.dart';
import '../../core/providers/daily_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/models/macro_totals.dart';
import '../../core/models/daily_goals.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestMeal = ref.watch(latestMealProvider);
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    final todayTotals = ref.watch(dailyTotalsProvider(todayKey));
    final goalsAsync = ref.watch(dailyGoalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shredify',
            style:
                TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/meals/new'),
        icon: const Icon(Icons.add),
        label: const Text('New Meal'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Today's summary
          goalsAsync.when(
            data: (goals) =>
                _TodayCard(totals: todayTotals, goals: goals),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 20),

          // Last meal
          Text('Last Meal',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          latestMeal == null
              ? _EmptyMealCard(
                  onTap: () => context.push('/meals/new'))
              : _LastMealCard(
                  meal: latestMeal,
                  onTap: () =>
                      context.push('/meals/${latestMeal.id}'),
                ),
        ],
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  final MacroTotals totals;
  final DailyGoals goals;
  const _TodayCard({required this.totals, required this.goals});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today — ${DateFormat('EEEE, MMM d').format(DateTime.now())}',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 14),
            _GoalBar(
              label: 'Calories',
              value: totals.kcal,
              goal: goals.kcal,
              unit: 'kcal',
              color: const Color(0xFF00BFA5),
            ),
            const SizedBox(height: 10),
            _GoalBar(
              label: 'Protein',
              value: totals.protein,
              goal: goals.protein,
              unit: 'g',
              color: Colors.blue,
            ),
            const SizedBox(height: 10),
            _GoalBar(
              label: 'Carbs',
              value: totals.carbs,
              goal: goals.carbs,
              unit: 'g',
              color: Colors.orange,
            ),
            const SizedBox(height: 10),
            _GoalBar(
              label: 'Fat',
              value: totals.fat,
              goal: goals.fat,
              unit: 'g',
              color: Colors.pink,
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalBar extends StatelessWidget {
  final String label;
  final double value;
  final double goal;
  final String unit;
  final Color color;

  const _GoalBar({
    required this.label,
    required this.value,
    required this.goal,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (goal > 0 ? (value / goal).clamp(0.0, 1.0) : 0.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13, color: Colors.white70)),
            Text(
              '${value.toStringAsFixed(0)} / ${goal.toStringAsFixed(0)} $unit',
              style: const TextStyle(
                  fontSize: 12, color: Colors.white54),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 1.0 ? Colors.orange : color,
            ),
          ),
        ),
      ],
    );
  }
}

class _LastMealCard extends StatelessWidget {
  final Meal meal;
  final VoidCallback onTap;
  const _LastMealCard({required this.meal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final totals = meal.totals;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEE, MMM d  •  HH:mm')
                          .format(meal.createdAt),
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${meal.items.length} item${meal.items.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 13),
                    ),
                    if (meal.isCalculated) ...[
                      const SizedBox(height: 6),
                      Text(
                        '${totals.kcal.toStringAsFixed(0)} kcal  •  P ${totals.protein.toStringAsFixed(1)}g',
                        style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context)
                                .colorScheme
                                .primary,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyMealCard extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyMealCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.add_circle_outline,
                    size: 32, color: Colors.white24),
                SizedBox(height: 8),
                Text('No meals yet — tap to create one',
                    style: TextStyle(color: Colors.white38)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
