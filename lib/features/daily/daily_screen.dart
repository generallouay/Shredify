import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/models/meal.dart';
import '../../core/models/macro_totals.dart';
import '../../core/models/daily_goals.dart';
import '../../core/providers/daily_provider.dart';
import '../../core/providers/settings_provider.dart';

class DailyScreen extends ConsumerWidget {
  const DailyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay = ref.watch(selectedDayProvider);
    final dayKey = DateTime(
        selectedDay.year, selectedDay.month, selectedDay.day);
    final meals = ref.watch(dailyMealsProvider(dayKey));
    final totals = ref.watch(dailyTotalsProvider(dayKey));
    final goalsAsync = ref.watch(dailyGoalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined, size: 20),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDay,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                ref.read(selectedDayProvider.notifier).state = picked;
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Date navigation
          _DateNav(
            selected: selectedDay,
            onPrev: () => ref.read(selectedDayProvider.notifier).state =
                selectedDay.subtract(const Duration(days: 1)),
            onNext: selectedDay.day == DateTime.now().day &&
                    selectedDay.month == DateTime.now().month &&
                    selectedDay.year == DateTime.now().year
                ? null
                : () => ref.read(selectedDayProvider.notifier).state =
                    selectedDay.add(const Duration(days: 1)),
          ),
          const SizedBox(height: 16),

          // Macro totals + progress
          goalsAsync.when(
            data: (goals) =>
                _DailyProgress(totals: totals, goals: goals),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 20),

          // Meals list
          Text(
            '${meals.length} meal${meals.length != 1 ? 's' : ''} today',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 10),
          ...meals.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _DailyMealCard(
                  meal: m,
                  onTap: () => context.push('/meals/${m.id}'),
                ),
              )),
          if (meals.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Text('No meals on this day',
                    style: TextStyle(color: Colors.white38)),
              ),
            ),
        ],
      ),
    );
  }
}

class _DateNav extends StatelessWidget {
  final DateTime selected;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  const _DateNav(
      {required this.selected, required this.onPrev, this.onNext});

  @override
  Widget build(BuildContext context) {
    final isToday = selected.day == DateTime.now().day &&
        selected.month == DateTime.now().month &&
        selected.year == DateTime.now().year;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left)),
        const SizedBox(width: 8),
        Text(
          isToday
              ? 'Today'
              : DateFormat('EEE, MMM d').format(selected),
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onNext,
          icon: Icon(Icons.chevron_right,
              color: onNext == null ? Colors.white24 : null),
        ),
      ],
    );
  }
}

class _DailyProgress extends StatelessWidget {
  final MacroTotals totals;
  final DailyGoals goals;
  const _DailyProgress({required this.totals, required this.goals});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _ProgressRow(
              label: 'Calories',
              value: totals.kcal,
              goal: goals.kcal,
              unit: 'kcal',
              color: const Color(0xFF00BFA5),
            ),
            const SizedBox(height: 12),
            _ProgressRow(
              label: 'Protein',
              value: totals.protein,
              goal: goals.protein,
              unit: 'g',
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _ProgressRow(
              label: 'Carbs',
              value: totals.carbs,
              goal: goals.carbs,
              unit: 'g',
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            _ProgressRow(
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

class _ProgressRow extends StatelessWidget {
  final String label;
  final double value;
  final double goal;
  final String unit;
  final Color color;
  const _ProgressRow({
    required this.label,
    required this.value,
    required this.goal,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = goal > 0 ? (value / goal * 100).clamp(0, 999) : 0.0;
    final progress = goal > 0 ? (value / goal).clamp(0.0, 1.0) : 0.0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
            Text(
              '${value.toStringAsFixed(0)} / ${goal.toStringAsFixed(0)} $unit  (${pct.toStringAsFixed(0)}%)',
              style: const TextStyle(
                  fontSize: 12, color: Colors.white54),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
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

class _DailyMealCard extends StatelessWidget {
  final Meal meal;
  final VoidCallback onTap;
  const _DailyMealCard({required this.meal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final totals = meal.totals;
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          DateFormat('HH:mm').format(meal.createdAt),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${meal.items.length} items'
          '${meal.isCalculated ? '  •  ${totals.kcal.toStringAsFixed(0)} kcal' : ''}',
          style: const TextStyle(fontSize: 12, color: Colors.white54),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white38),
      ),
    );
  }
}
