import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/models/meal.dart';
import '../../core/providers/meals_provider.dart';

class MealHistoryScreen extends ConsumerWidget {
  const MealHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealsAsync = ref.watch(mealsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: mealsAsync.when(
        data: (meals) => meals.isEmpty
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history, size: 48, color: Colors.white24),
                    SizedBox(height: 12),
                    Text('No meals yet',
                        style: TextStyle(color: Colors.white38)),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () => ref.refresh(mealsProvider.future),
                child: ListView.separated(
                  padding:
                      const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: meals.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _MealCard(
                    meal: meals[i],
                    onTap: () => context.push('/meals/${meals[i].id}'),
                  ),
                ),
              ),
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/meals/new'),
        icon: const Icon(Icons.add),
        label: const Text('New Meal'),
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  final Meal meal;
  final VoidCallback onTap;
  const _MealCard({required this.meal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final totals = meal.totals;
    final dateStr =
        DateFormat('EEE, MMM d').format(meal.createdAt);
    final timeStr = DateFormat('HH:mm').format(meal.createdAt);
    final color = Theme.of(context).colorScheme.primary;

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
                    Row(
                      children: [
                        Text(dateStr,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15)),
                        const SizedBox(width: 8),
                        Text(timeStr,
                            style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 13)),
                      ],
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
                        '${totals.kcal.toStringAsFixed(0)} kcal  •  P ${totals.protein.toStringAsFixed(1)}g  •  C ${totals.carbs.toStringAsFixed(1)}g  •  F ${totals.fat.toStringAsFixed(1)}g',
                        style: TextStyle(
                            fontSize: 12,
                            color: color,
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
