import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meal.dart';
import 'database_provider.dart';

final mealsProvider =
    AsyncNotifierProvider<MealsNotifier, List<Meal>>(MealsNotifier.new);

class MealsNotifier extends AsyncNotifier<List<Meal>> {
  @override
  Future<List<Meal>> build() => ref.read(mealDaoProvider).getAll();

  Future<void> add(Meal meal) async {
    await ref.read(mealDaoProvider).insert(meal);
    ref.invalidateSelf();
  }

  Future<void> save(Meal meal) async {
    await ref.read(mealDaoProvider).update(meal);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    await ref.read(mealDaoProvider).delete(id);
    ref.invalidateSelf();
  }

  Future<void> reload() async => ref.invalidateSelf();
}

final latestMealProvider = Provider<Meal?>((ref) {
  final meals = ref.watch(mealsProvider);
  return meals.whenOrNull(data: (list) => list.isEmpty ? null : list.first);
});
