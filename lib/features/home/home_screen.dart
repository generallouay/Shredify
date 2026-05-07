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
  // page 1000 = today; lower = past days
  static const int _todayIndex = 1000;
  late final PageController _pageController;
  int _currentPage = _todayIndex;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _todayIndex);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _checkForUpdate());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _pageToDay(int page) {
    final offset = page - _todayIndex;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.add(Duration(days: offset));
  }

  Future<void> _checkForUpdate() async {
    final info = await UpdateService.checkForUpdate();
    if (info == null || !mounted) return;
    showDialog(
      context: context,
      builder: (_) => UpdateDialog(info: info),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isToday = _currentPage == _todayIndex;

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
      floatingActionButton: isToday
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/meals/new'),
              icon: const Icon(Icons.add),
              label: const Text('New Meal'),
            )
          : null,
      body: PageView.builder(
        controller: _pageController,
        // allow up to ~3 years back, no future
        itemCount: _todayIndex + 1,
        onPageChanged: (page) => setState(() => _currentPage = page),
        itemBuilder: (context, page) {
          final day = _pageToDay(page);
          return _DayPage(day: day);
        },
      ),
    );
  }
}

// ── Day page ─────────────────────────────────────────────────────────

class _DayPage extends ConsumerStatefulWidget {
  final DateTime day;
  const _DayPage({required this.day});

  @override
  ConsumerState<_DayPage> createState() => _DayPageState();
}

class _DayPageState extends ConsumerState<_DayPage> {
  Future<void> _editQuickEntry(QuickEntry entry) async {
    final edited = await showDialog<QuickEntry>(
      context: context,
      builder: (_) => QuickEntryDialog(initialEntry: entry),
    );
    if (edited == null || !mounted) return;
    try {
      await ref.read(quickEntriesProvider.notifier).updateEntry(edited);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update entry: $e')));
      }
    }
  }

  Future<void> _addQuickEntry() async {
    final entry = await showDialog<QuickEntry>(
      context: context,
      builder: (_) => const QuickEntryDialog(),
    );
    if (entry == null || !mounted) return;
    // timestamp the entry to the viewed day (using current time-of-day)
    final now = DateTime.now();
    final stamped = entry.copyWith(
      createdAt: DateTime(
          widget.day.year, widget.day.month, widget.day.day,
          now.hour, now.minute, now.second),
    );
    try {
      await ref.read(quickEntriesProvider.notifier).add(stamped);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save entry: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final day = widget.day;
    final mealsAsync = ref.watch(mealsProvider);
    final dayMeals = ref.watch(dailyMealsProvider(day));
    final dayEntries = ref.watch(dailyQuickEntriesProvider(day));
    final dayTotals = ref.watch(dailyTotalsProvider(day));
    final goalsAsync = ref.watch(dailyGoalsProvider);

    final now = DateTime.now();
    final isToday = day.year == now.year &&
        day.month == now.month &&
        day.day == now.day;
    final yesterday = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 1));
    final isYesterday = day.year == yesterday.year &&
        day.month == yesterday.month &&
        day.day == yesterday.day;

    final dateFmt = DateFormat('EEEE, MMM d').format(day);
    String dayLabel;
    if (isToday) {
      dayLabel = 'Today — $dateFmt';
    } else if (isYesterday) {
      dayLabel = 'Yesterday — $dateFmt';
    } else {
      dayLabel = dateFmt;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        goalsAsync.when(
          data: (goals) => _DaySummaryCard(
              totals: dayTotals, goals: goals, dayLabel: dayLabel),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 24),

        // ── Meals ──────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${isToday ? "Today's" : DateFormat("MMM d").format(day)} Meals'
              '${dayMeals.isNotEmpty ? " (${dayMeals.length})" : ""}',
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
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (dayMeals.isEmpty)
          _EmptyHint(
            icon: Icons.restaurant_outlined,
            message: isToday
                ? 'No meals today — tap New Meal to start'
                : 'No meals on this day',
          )
        else
          ...dayMeals.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _MealListCard(
                  meal: m,
                  onTap: () => context.push('/meals/${m.id}'),
                ),
              )),

        const SizedBox(height: 24),

        // ── Quick Entries ──────────────────────────────────────────
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
        if (dayEntries.isEmpty)
          _EmptyHint(
            icon: Icons.bolt_outlined,
            message: 'No quick entries — use Add for snacks or extras',
          )
        else
          ...dayEntries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _QuickEntryCard(
                  entry: e,
                  onTap: () => _editQuickEntry(e),
                  onDelete: () => ref
                      .read(quickEntriesProvider.notifier)
                      .delete(e.id),
                ),
              )),

        const SizedBox(height: 90),
      ],
    );
  }
}

// ── Day summary card ──────────────────────────────────────────────────

class _DaySummaryCard extends StatelessWidget {
  final MacroTotals totals;
  final DailyGoals goals;
  final String dayLabel;
  const _DaySummaryCard(
      {required this.totals, required this.goals, required this.dayLabel});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dayLabel,
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
              style: _BarStyle.calories,
            ),
            const SizedBox(height: 10),
            _GoalBar(
              label: 'Protein',
              value: totals.protein,
              goal: goals.protein,
              unit: 'g',
              style: _BarStyle.protein,
            ),
            const SizedBox(height: 10),
            _GoalBar(
              label: 'Carbs',
              value: totals.carbs,
              goal: goals.carbs,
              unit: 'g',
              style: _BarStyle.carbs,
            ),
            const SizedBox(height: 10),
            _GoalBar(
              label: 'Fat',
              value: totals.fat,
              goal: goals.fat,
              unit: 'g',
              style: _BarStyle.fat,
            ),
          ],
        ),
      ),
    );
  }
}

enum _BarStyle { calories, protein, carbs, fat }

class _GoalBar extends StatelessWidget {
  final String label;
  final double value;
  final double goal;
  final String unit;
  final _BarStyle style;

  const _GoalBar({
    required this.label,
    required this.value,
    required this.goal,
    required this.unit,
    required this.style,
  });

  Color _barColor(double progress) {
    switch (style) {
      case _BarStyle.calories:
        // green under goal, red over
        return progress >= 1.0 ? Colors.red : const Color(0xFF4CAF50);
      case _BarStyle.protein:
        // red → green as it fills (more protein = better)
        return Color.lerp(
            const Color(0xFFEF5350), const Color(0xFF4CAF50), progress)!;
      case _BarStyle.carbs:
        // orange → green (eating less is fine, not alarming)
        return Color.lerp(
            const Color(0xFFFF9800), const Color(0xFF4CAF50), progress)!;
      case _BarStyle.fat:
        // neutral blueGrey always
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = goal > 0 ? (value / goal).clamp(0.0, 1.0) : 0.0;
    final remaining = goal - value;
    final isOver = remaining < 0;

    String rightText;
    Color rightColor;
    if (isOver) {
      rightText =
          '+${(-remaining).toStringAsFixed(0)} $unit over';
      rightColor = style == _BarStyle.calories
          ? const Color(0xFFEF5350)
          : Colors.white54;
    } else {
      rightText = '${remaining.toStringAsFixed(0)} $unit left';
      rightColor = Colors.white54;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 13, color: Colors.white70)),
            Text(rightText,
                style: TextStyle(fontSize: 12, color: rightColor)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(_barColor(progress)),
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
                    if (totals.kcal > 0) ...[
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
  final VoidCallback? onTap;
  final VoidCallback onDelete;
  const _QuickEntryCard(
      {required this.entry, this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
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
