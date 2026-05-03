import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_goals.dart';

final dailyGoalsProvider =
    AsyncNotifierProvider<DailyGoalsNotifier, DailyGoals>(
        DailyGoalsNotifier.new);

class DailyGoalsNotifier extends AsyncNotifier<DailyGoals> {
  @override
  Future<DailyGoals> build() async {
    final prefs = await SharedPreferences.getInstance();
    return DailyGoals(
      kcal: prefs.getDouble('goal_kcal') ?? 2000,
      protein: prefs.getDouble('goal_protein') ?? 150,
      fat: prefs.getDouble('goal_fat') ?? 65,
      carbs: prefs.getDouble('goal_carbs') ?? 200,
    );
  }

  Future<void> save(DailyGoals goals) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('goal_kcal', goals.kcal);
    await prefs.setDouble('goal_protein', goals.protein);
    await prefs.setDouble('goal_fat', goals.fat);
    await prefs.setDouble('goal_carbs', goals.carbs);
    state = AsyncData(goals);
  }
}
