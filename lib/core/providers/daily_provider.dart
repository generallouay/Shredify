import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meal.dart';
import '../models/macro_totals.dart';
import 'meals_provider.dart';
import 'quick_entries_provider.dart';

final selectedDayProvider = StateProvider<DateTime>(
    (ref) => DateTime.now());

final dailyMealsProvider =
    Provider.family<List<Meal>, DateTime>((ref, day) {
  final meals = ref.watch(mealsProvider);
  return meals.whenOrNull(data: (list) {
        final start = DateTime(day.year, day.month, day.day);
        final end =
            DateTime(day.year, day.month, day.day, 23, 59, 59, 999);
        return list
            .where((m) =>
                !m.createdAt.isBefore(start) &&
                !m.createdAt.isAfter(end))
            .toList();
      }) ??
      [];
});

final dailyTotalsProvider =
    Provider.family<MacroTotals, DateTime>((ref, day) {
  final meals = ref.watch(dailyMealsProvider(day));
  final entries = ref.watch(dailyQuickEntriesProvider(day));
  final mealTotals =
      meals.fold(MacroTotals.zero, (acc, m) => acc + m.totals);
  final entryTotals = entries.fold(
      MacroTotals.zero, (acc, e) => acc + quickEntryToMacros(e));
  return mealTotals + entryTotals;
});
