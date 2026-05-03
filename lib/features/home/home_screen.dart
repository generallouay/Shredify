import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/models/meal.dart';
import '../../core/models/quick_entry.dart';
import '../../core/models/macro_totals.dart';
import '../../core/models/daily_goals.dart';
import '../../core/providers/daily_provider.dart';
import '../../core/providers/meals_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/providers/quick_entries_provider.dart';
import '../../core/services/update_service.dart';
import '../shared/widgets/macro_row.dart';
import '../shared/widgets/update_dialog.dart';
import 'widgets/quick_entry_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    final info = await UpdateService.checkForUpdate();
    if (info == null || !mounted) return;
    showDialog(
      context: context,
      builder: (_) => UpdateDialog(info: info),
    );
  }

  Future<void> _addQuickEntry() async {
    final entry = await showDialog<QuickEntry>(
      context: context,
      builder: (_) => const QuickEntryDialog(),
    );
    if (entry == null || !mounted) return;
    try {
      await ref.read(quickEntriesProvider.notifier).add(entry);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save entry: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    final mealsAsync = ref.watch(mealsProvider);
    final todayMeals = ref.watch(dailyMealsProvider(todayKey));
    final todayEntries = ref.watch(dailyQuickEntriesProvider(todayKey));
    final todayTotals = ref.watch(dailyTotalsProvider(todayKey));
    final goalsAsync = ref.watch(dailyGoalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shredify',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
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
          goalsAsync.when(
            data: (goals) =>
                _TodayCard(totals: todayTotals, goals: goals),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),

          // ── Today's Meals ──────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Meals${todayMeals.isNotEmpty ? ' (${todayMeals.length})' : ''}",
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (mealsAsync.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (todayMeals.isEmpty)
            _EmptyHint(
              icon: Icons.restaurant_outlined,
              message: 'No meals today — tap New Meal to start',
            )
          else
            ...todayMeals.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _MealListCard(
                    meal: m,
                    onTap: () => context.push('/meals/${m.id}'),
                  ),
                )),

          const SizedBox(height: 24),

          // ── Quick Entries ──────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Entries',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              TextButton.icon(
                onPressed: _addQuickEntry,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add'),
                style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (todayEntries.isEmpty)
            _EmptyHint(
              icon: Icons.bolt_outlined,
              message: 'No quick entries — use Add for snacks or extras',
            )
          else
            ...todayEntries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _QuickEntryCard(
                    entry: e,
                    onDelete: () => ref
                        .read(quickEntriesProvider.notifier)
                        .delete(e.id),
                  ),
                )),

          const SizedBox(height: 90),
        ],
      ),
    );
  }
}

// ── Today summary card ──────────────────────────────────────────────

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
    final progress =
        goal > 0 ? (value / goal).clamp(0.0, 1.0) : 0.0;
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

// ── Meal list card ──────────────────────────────────────────────────

class _MealListCard extends StatelessWidget {
  final Meal meal;
  final VoidCallback onTap;
  const _MealListCard({required this.meal, required this.onTap});

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
                      DateFormat('HH:mm').format(meal.createdAt),
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${meal.items.length} item${meal.items.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 13),
                    ),
                    if (meal.isCalculated) ...[
                      const SizedBox(height: 8),
                      MacroRow(
                        kcal: totals.kcal,
                        protein: totals.protein,
                        carbs: totals.carbs,
                        fat: totals.fat,
                        compact: true,
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

// ── Quick entry card ────────────────────────────────────────────────

class _QuickEntryCard extends StatelessWidget {
  final QuickEntry entry;
  final VoidCallback onDelete;
  const _QuickEntryCard(
      {required this.entry, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.bolt_outlined, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.description ?? 'Quick Entry',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _macroLabel(entry),
                    style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 18, color: Colors.white38),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  String _macroLabel(QuickEntry e) {
    final parts = ['${e.kcal.toStringAsFixed(0)} kcal'];
    if (e.protein != null) parts.add('P ${e.protein!.toStringAsFixed(1)}g');
    if (e.carbs != null) parts.add('C ${e.carbs!.toStringAsFixed(1)}g');
    if (e.fat != null) parts.add('F ${e.fat!.toStringAsFixed(1)}g');
    return parts.join('  ·  ');
  }
}

// ── Empty hint ──────────────────────────────────────────────────────

class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyHint({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: Colors.white38, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
